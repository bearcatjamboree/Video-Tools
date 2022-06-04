#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse
import audioop
import concurrent.futures
import glob
import os
import subprocess
import sys
import time
import wave
from functools import partial
from shutil import rmtree
from threading import Thread

import cv2 as cv
import numpy as np
import imutils
import tempfile

from os.path import exists

#################################################################################################
# Get arguments from command line
#################################################################################################
parser = argparse.ArgumentParser(
    description='Search the audio/video/both for frames to retain and remove the rest')
parser.add_argument('--input_file', type=str, help='The video file you want to jump cut')
parser.add_argument('--output_file', type=str, help="the _output location to write the edit video")
parser.add_argument('--frame_margin', type=int, default=75,
                    help="The number of adjacent (not matched) frames to retrain for additional context")
parser.add_argument('--frame_quality', type=int, default=1,
                    help="The quality of frames to be extracted from input video. 1 is highest, 31 is lowest, 1 is the default.")
parser.add_argument('--video_method', type=int, default=0,
                    help="The video selection method: 0=don't use video, 1=use matchTemplate and thumbnail matching, 2=use face recognition.")
parser.add_argument('--audio_method', type=int, default=0,
                    help="Whether to use audio selection: 0=don't use video, 1=use audio high points to add frames to the highlights video.  The default value is 0.")
parser.add_argument('--volume_selection', type=str, default="max",
                    help="The audio selection method to use: max=uses audioop.max to determine volume and max volume, rms=uses audioop.rms to determine volume and max volume.  The default value is max.")
parser.add_argument('--audio_threshold', type=float, default=0.1,
                    help="the minimum volume level for audio frames to be selected. It ranges from 0 (silence) to 1 (max volume)")
parser.add_argument('--minimum_faces', type=int, default=1,
                    help="The minimum number of faces found to included in the final video.  The default is 0 which means any frame containing a face will be included.")
parser.add_argument('--minimum_size', type=tuple, default=(64,64),
                    help="The minimum number of faces found to included in the final video.  The default is 0 which means any frame containing a face will be included.")
parser.add_argument('--haarcascades', type=str, default="haarcascade_frontalface_default.xml",
                    help="the model used if facial recognition [--video_method=2] is the video scan method.  The default model is: haarcascade_frontalface_default.xml.")

args = parser.parse_args()

#################################################################################################
# Show usage and end if required inputs were not provided
#################################################################################################
if not args.input_file or not args.output_file:
    parser.print_usage()
    quit()

# import the Queue class from Python 3
if sys.version_info >= (3, 0):
    from queue import Queue
# otherwise, import the Queue class for Python 2.7
# else:
# from Queue import Queue

#################################################################################################
# Use IMUTILS FileVideoStream to help increase the cv.VideoCapture read speed.
#################################################################################################
class FileVideoStream:
    def __init__(self, path, transform=None, queue_size=128):
        # initialize the file video stream along with the boolean
        # used to indicate if the thread should be stopped or not
        self.stream = cv.VideoCapture(path)
        # Find OpenCV version
        # noinspection PyUnresolvedReferences
        (self.major_ver, self.minor_ver, self.subminor_ver) = cv.__version__.split('.')
        if int(self.major_ver) < 3:
            # noinspection PyUnresolvedReferences
            self.fps = self.stream.get(cv.cv.CAP_PROP_FPS)
            # noinspection PyUnresolvedReferences
            self.frames = int(self.stream.get(cv.cv.CAP_PROP_FRAME_COUNT))
        else:
            self.fps = self.stream.get(cv.CAP_PROP_FPS)
            self.frames = int(self.stream.get(cv.CAP_PROP_FRAME_COUNT))
        self.stopped = False
        self.transform = transform
        # initialize the queue used to store frames read from
        # the video file
        self.Q = Queue(maxsize=queue_size)
        # initialize thread
        self.thread = Thread(target=self.update, args=())
        self.thread.daemon = True

    def start(self):
        # start a thread to read frames from the file video stream
        self.thread.start()
        return self

    def update(self):
        # keep looping infinitely
        while True:
            # if the thread indicator variable is set, stop the
            # thread
            if self.stopped:
                break

            # otherwise, ensure the queue has room in it
            if not self.Q.full():
                # read the next frame from the file
                (grabbed, frame) = self.stream.read()

                # if the `grabbed` boolean is `False`, then we have
                # reached the end of the video file
                if not grabbed:
                    self.stopped = True

                # if there are transfominmax to be done, might as well
                # do them on producer thread before handing back to
                # consumer thread. i.e. Usually the producer is so far
                # ahead of consumer that we have time to spare.
                #
                # Python is not parallel but the transform operations
                # are typically OpenCV native so release the GIL.
                #
                # Really just trying to avoid spinning up additional
                # native threads and overheads of additional
                # producer/consumer queues since this one was generally
                # idle grabbing frames.
                if self.transform:
                    frame = self.transform(frame)

                # add the frame to the queue
                self.Q.put(frame)
            else:
                time.sleep(0.1)  # Rest for 10ms, we have a full queue

        self.stream.release()

    def read(self):
        # return next frame in the queue
        return self.Q.get()

    # Insufficient to have consumer use while(more()) which does
    # not take into account if the producer has reached end of
    # file stream.
    def running(self):
        return self.more() or not self.stopped

    def more(self):
        # return True if there are still frames in the queue. If stream is not stopped, try to wait a moment
        tries = 0
        while self.Q.qsize() == 0 and not self.stopped and tries < 5:
            time.sleep(0.1)
            tries += 1

        return self.Q.qsize() > 0

    def stop(self):
        # indicate that the thread should be stopped
        self.stopped = True
        # wait until stream resources are released (producer thread might be still grabbing frame)
        self.thread.join()


#################################################################################################
#  Print progress bar
#################################################################################################
def printProgressBar(iteration, total, prefix='', suffix='', decimals=1, length=100, fill='█', printEnd="\r"):
    """
    Call in a loop to create terminal progress bar
    @params:
        iteration   - Required  : current iteration (Int)
        total       - Required  : total iterations (Int)
        prefix      - Optional  : prefix string (Str)
        suffix      - Optional  : suffix string (Str)
        decimals    - Optional  : positive number of decimals in percent complete (Int)
        length      - Optional  : character length of bar (Int)
        fill        - Optional  : bar fill character (Str)
        printEnd    - Optional  : end character (e.g. "\r", "\r\n") (Str)
    """
    percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
    filledLength = int(length * iteration // total)
    bar = fill * filledLength + '-' * (length - filledLength)
    print(f'\r{prefix} |{bar}| {percent}% {suffix}', end=printEnd)
    # Print New Line on Complete
    if iteration == total:
        print()

#################################################################################################
#  Insert frames before and after match frames to add "context"
#################################################################################################
def AddMarginFrames(frames):
    """
    Call in a loop to create terminal progress bar
    @params:
        frames      - Required  : frame indexlist (Int)
    """
    print("Adding adjacent frames...")

    # print("frames length {}".format(len(frames)))
    # Create copy
    t_frames = set(frames)
    max_frames = len(frames)

    current_iteration = 0

    for frame in t_frames:

        printProgressBar(current_iteration, len(t_frames), prefix='Inserting Margin Frames: ', suffix='Complete',
                         length=50)

        bottom = frame - args.frame_margin

        # Add context frames before highlight frames
        if bottom > 0:
            for j in range(bottom, frame):
                frames.append(j)
        else:
            for j in range(0, frame):
                frames.append(j)

        top = frame + args.frame_margin

        # Add context frames after highlight frames
        if top < max_frames:
            for j in range(frame, top):
                frames.append(j)
        else:
            for j in range(frame, max_frames):
                frames.append(j)

        current_iteration += 1

    # Sort and remove duplicates
    frames.sort()
    res = list(dict.fromkeys(frames))

    # Return res
    return res

#################################################################################################
#  Write the selected video frames to a last temp video file
#################################################################################################        
def write_video_frames(output_frames, fps):
    out = None
    fvs = FileVideoStream("{}/video.mp4".format(tmpdirname)).start()

    highlight_frame = 0

    while fvs.more():

        printProgressBar(highlight_frame, fvs.frames, prefix='Writing Edited Video:', suffix='Complete', length=50)

        frame = fvs.read()

        if highlight_frame in output_frames:

            if not out:
                (height, width) = frame.shape[:2]
                fourcc = cv.VideoWriter_fourcc(*'mp4v')
                out = cv.VideoWriter("{}/videoNew.mp4".format(tmpdirname), fourcc, fps, (width, height))

            try:
                out.write(frame)

            except cv.error as error:
                print("[Error]: {}".format(error))
                out and out.release()

        highlight_frame += 1

    out.release()

#################################################################################################
#  Write the selected audio frames to a last temp audio file
#################################################################################################
def write_audio_frames(output_frames, fps):

    wave_r = wave.open("{}/audio.wav".format(tmpdirname), 'rb')

    # Get basic information.
    n_channels = wave_r.getnchannels()  # Number of channels. (1=Mono, 2=Stereo).
    sample_width = wave_r.getsampwidth()  # Sample width in bytes.
    framerate = wave_r.getframerate()  # Frame rate.
    n_frames = wave_r.getnframes()  # Number of frames.
    comp_type = wave_r.getcomptype()  # Compression type (only supports "NONE").
    comp_name = wave_r.getcompname()  # Compression name.

    duration = n_frames / float(framerate)

    print("# Number of channels. (1=Mono, 2=Stereo): {}".format(n_channels))
    print("# Sample width in bytes: {}".format(sample_width))
    print("# Frame rate: {}".format(framerate))
    print("# Number of frames: {}".format(n_frames))
    print("# Compression type (only supports \"NONE\"): {}".format(comp_type))
    print("# Compression name: {}".format(comp_name))
    print("# Audio duration: {}".format(duration))

    # Calculate the frame size
    framesize = sample_width * n_channels
    print("# Audio frame size: {}".format(framesize))

    # Resets the pointer to beginning of the stream
    wave_r.rewind()

    wave_w = wave.open("{}/audioNew.wav".format(tmpdirname), 'wb')

    # Write audio data.
    params = (n_channels, sample_width, framerate, n_frames, comp_type, comp_name)
    wave_w.setparams(params)

    chunk_size = int(framerate / fps)
    max_loops = int(n_frames / chunk_size)

    current_iteration = 0

    # keep_frames[:-1] to not read past end of file
    for audio_scan in output_frames:

        if audio_scan > max_loops:
            break

        wave_r.setpos(audio_scan * chunk_size)

        try:
            chunk_read = wave_r.readframes(chunk_size)
            wave_w.writeframes(chunk_read)

        except wave.Error:
            print("Error writing {}/audioNew.wav".format(tmpdirname))
            print(wave.Error)

        current_iteration += 1
        printProgressBar(current_iteration, len(output_frames), prefix='Writing Edited Audio: ', suffix='Complete',
                         length=50)

    wave_r.close()
    wave_w.close()

#################################################################################################
#  Create pencil effect on image to make matching easier
#################################################################################################
def pencil_it(image):

    inverted = 255 - image
    blurred = cv.GaussianBlur(inverted, (21, 21), 0)
    invertedBlur = 255 - blurred
    pencilSketch = cv.divide(image, invertedBlur, scale=256.0)

    return pencilSketch

#################################################################################################
#  Scan a selected frame for all images in the FACES folder for matches
#################################################################################################                    
def needle_match(needle, haystack, current_frame, keep_frames):
    (height, width) = needle.shape[:2]

    for scale in np.linspace(0.8, 1.0, 20)[::-1]:

        resized = imutils.resize(haystack, width=int(haystack.shape[1] * scale))

        if resized.shape[0] < height or resized.shape[1] < width:
            break

        pencil_resized = pencil_it(resized)
        pencil_needle = pencil_it(needle)

        # Uncommon 4 lines below to write out each frame as a pencil drawing image
        #needle_file = "{}{}{}".format("test/needle_file",current_frame,".png")
        #resized_file = "{}{}{}".format("test/edge_file", current_frame, ".png")
        #cv.imwrite(needle_file, pencil_needle)
        #cv.imwrite(resized_file, pencil_resized)

        result = cv.matchTemplate(pencil_resized, pencil_needle, cv.TM_CCOEFF_NORMED)
        min_val, max_val, min_loc, max_loc = cv.minMaxLoc(result)

        threshold = 0.8

        if max_val >= threshold:

            loc = np.where(result >= threshold)

            for pt in zip(*loc[::-1]):
                cv.rectangle(resized, pt, (pt[0] + width, pt[1] + height), (0, 0, 255), 2)

            keep_frames.append(current_frame)
            # print("keep frame = {}".format(current_frame))

            #cv.imwrite('match.png', resized)

            return 0

#################################################################################################
#  Scan a selected from for all images in the FACES folder for matches
#################################################################################################                    
def face_scan(haystack, current_frame, keep_frames):
    if not exists("models/" + args.haarcascades):
        assert False, "Error locating haarcascades: {}".format("models/" + args.haarcascades)

    # Create the haar cascade
    faceCascade = cv.CascadeClassifier("models/" + args.haarcascades)

    # Detect faces in the image
    #faces, rejectLevels, levelWeights = faceCascade.detectMultiScale3(
    faces = faceCascade.detectMultiScale(
        haystack,
        scaleFactor=1.1,                # How much the image size is reduced at each image scaling (iteration)
        minNeighbors=3,                 # How many neighbors each candidate rectangle should have to retain
        minSize=args.minimum_size       # Minimum possible object size. Objects smaller than that are ignored.
    )                                   # "maxSize" can be added to set a limit on face image matches

    if len(faces) >= args.minimum_faces:

        #print("Found {0} faces!".format(len(faces)))

        # Draw a rectangle around the faces
        for (x, y, w, h) in faces:
            cv.rectangle(haystack, (x, y), (x + w, y + h), (0, 255, 0), 2)

        keep_frames.append(current_frame)
        # print("keep frame = {}".format(current_frame))

        #cv.imwrite('match.png',haystack)

        return 0


#################################################################################################
#  Scan a selected frame for all images in the template folder for matches
#################################################################################################                    
def needle_scan(needles, haystack, current_frame, keep_frames):
    try:

        # Search for needles (images) in the frame (haystack)
        with concurrent.futures.ThreadPoolExecutor() as executor:
            executor.map(partial(needle_match, haystack=haystack, current_frame=current_frame, keep_frames=keep_frames),
                         needles)

    except cv.error as error:
        print("[Error]: {}".format(error))

#################################################################################################
#  Create folder routine
#################################################################################################                    
def createPath(s):
    try:
        os.mkdir(s)
    except OSError:
        assert False, "Creation of the directory %s failed (The TEMP directory may already exist.)"

#################################################################################################
#  Folder cleanup routine
#################################################################################################                    
def deletePath(s):  # Dangerous! Watch out!
    try:
        rmtree(s, ignore_errors=False)
    except OSError:
        print("Deletion of the directory %s failed" % s)
        print(OSError)

#################################################################################################
#  *** Begin main part of Program ***
#################################################################################################                    
def main():

    global tmpdirname

    with tempfile.TemporaryDirectory() as tmpdirname:
    
        print('Created temporary directory', tmpdirname)
        print("Creating temporary audio and video files: {}/video.mp4 + {}/audio.wav".format(tmpdirname, tmpdirname))

        #################################################################################################################
        # Copy the video and audio to separate temporary files.  Re-encode the video in case there are any frame issues.
        # This can help prevent keyframe video/audio sync issues.
        #################################################################################################################
        command = "ffmpeg -i '{}' -c:a copy -c:v libx264 -an {}/video.mp4 -vn {}/audio.wav".format(args.input_file, tmpdirname, tmpdirname)
        #print(command)
        subprocess.call(command, shell=True)

        # Creating a VideoCapture object to read the video
        fvs = FileVideoStream("{}/video.mp4".format(tmpdirname)).start()

        # Start time
        start = time.time()

        print("OpenCV major version: {0}".format(fvs.major_ver))
        print("Frames per second: {0}".format(fvs.fps))
        print("Frames to process: {0}".format(fvs.frames))
        print("Scanning frames for things to highlight...")

        # where retained frame numbers are stored
        keep_frames = []

        ################################################################
        #  Process using audio_method (or skip if args.audio_method==0)
        ################################################################
        if args.audio_method == 1:

            wave_r = wave.open("{}/audio.wav".format(tmpdirname), 'rb')

            # Get basic information.
            framerate = wave_r.getframerate()       # Frame rate of audio
            n_frames = wave_r.getnframes()          # Number of audio frames
            s_width = wave_r.getsampwidth()         # Audio sample width
            chunk_size = int(framerate / fvs.fps)   # Audio chunks to read
            max_loops = int(n_frames / chunk_size)  # Max loops possible

            print("Frame rate: {}".format(framerate))
            print("Frame count: {}".format(n_frames))
            print("Sample width: {}".format(s_width))
            print("Chunk size: {}".format(chunk_size))
            print("Max loops {}".format(max_loops))

            # Get max volume using audioop.max
            if args.volume_selection == "max":
                max_volume = audioop.max(wave_r.readframes(-1), s_width)

            # Get max volume using audioop.rms
            elif args.volume_selection == "rms":
                rms_list = []

                # Read entire file and calculate highest rms volume
                for audio_scan in range(fvs.frames):

                    if audio_scan > max_loops:
                        break

                    wave_r.setpos(audio_scan * chunk_size)

                    try:
                        # Read the number of bytes in each video/audio frame
                        audioData = wave_r.readframes(chunk_size)
                        frame_rms = audioop.rms(audioData, s_width)
                        rms_list.append(frame_rms)

                    except wave.Error:
                        print("Error reading {}/audio.wav".format(tmpdirname))
                        print(wave.Error)

                max_volume = max(rms_list)

            else:
                print("Invalid audio selection method")
                quit()

            print("max_volume = {}".format(max_volume))

            # Resets pointer to beginning of audio file
            wave_r.rewind()

            # Loop through all video frames
            for audio_scan in range(fvs.frames):

                if audio_scan > max_loops:
                    break

                wave_r.setpos(audio_scan * chunk_size)

                try:
                    # Read the number of bytes in each video/audio frame
                    chunk_read = wave_r.readframes(chunk_size)

                    # Get frame volume using audioop.max
                    if args.volume_selection == "max":
                        frame_volume = audioop.max(chunk_read, s_width)

                    # Get frame volume using audioop.rms
                    elif args.volume_selection == "rms":
                        frame_volume = audioop.rms(chunk_read, s_width)

                    else:
                        print("Invalid audio selection method")
                        quit()

                    volume = frame_volume / max_volume
                    #print("frame_volume = {} / max_volume = {} / volume = {}".format(frame_volume, max_volume, volume))

                    # Include frames with volume at or above the threshold
                    if volume > args.audio_threshold:
                        keep_frames.append(audio_scan)

                except wave.Error:
                    print("Error reading {}/audio.wav".format(tmpdirname))
                    print(wave.Error)

                printProgressBar(audio_scan, fvs.frames, prefix='Scanning Audio Frames: ', suffix='Complete', length=50)

            wave_r.close()

        ################################################################
        #  Process using video_method (or skip if args.video_method==0)
        ################################################################
        if args.video_method > 0:

            needles = []
            # Only load with images if doing template match
            if args.video_method == 1:
                needles = [cv.imread(file, cv.IMREAD_GRAYSCALE) for file in glob.glob("templates/*.png")]

            current_frame = -1

            # loop over the video frames
            while fvs.more():

                current_frame += 1

                printProgressBar(current_frame, fvs.frames, prefix='Scanning Video Frames: ', suffix='Complete', length=50)

                # Capture frame-by-frame
                img_rgb = fvs.read()

                if img_rgb is None:
                    break

                # Skip any frames already selected using Audio jump
                if current_frame in keep_frames:
                    continue

                haystack = cv.cvtColor(img_rgb, cv.COLOR_BGR2GRAY)

                t1 = time.time()

                if args.video_method == 1:
                    needle_scan(needles, haystack, current_frame, keep_frames)
                elif args.video_method == 2:
                    face_scan(haystack, current_frame, keep_frames)
                else:
                    raise Exception("An error occurred in main()")

                t2 = time.time()
                it_time = t2 - t1

                print("Frame Scan Time : {0} seconds".format(it_time))

        if keep_frames:

            #print("keep {}".format(keep_frames))
            keep_frames = AddMarginFrames(keep_frames)

            print("Writing edited video (only) file: {}/videoNew.mp4".format(tmpdirname))

            write_video_frames(keep_frames, fvs.fps)

            print("Creating edited audio (only) file: {}/audioNew.wav".format(tmpdirname))

            write_audio_frames(keep_frames, fvs.fps)

            print("Producing Final Edited Video...")

            command = "ffmpeg -r {} -i {}/videoNew.mp4 -i {}/audioNew.wav -strict -2 '{}'".format(str(fvs.fps), tmpdirname, tmpdirname, args.output_file)
            print(command)
            subprocess.call(command, shell=True)

        else:

            print("**** No highlights were found ****")

        # End time
        end = time.time()

        # Time elapsed
        seconds = end - start

        print('Execution time:', time.strftime("%H:%M:%S", time.gmtime(seconds)))

        # release the video capture object
        # do a bit of cleanup
        cv.destroyAllWindows()
        fvs.stop()

if __name__ == "__main__":
    main()
