#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse
import os
import subprocess
import sys
import time
from shutil import rmtree
from threading import Thread

import cv2 as cv

#################################################################################################
# Get arguments from command line
#################################################################################################
parser = argparse.ArgumentParser(
    description='Convert a video file to a pencil sketch style video')
parser.add_argument('--input_file', type=str, help='The video file you want to convert')
parser.add_argument('--output_file', type=str, help="the output location to write the pencil sketch style video")

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
#  Create pencil effect on image to make matching easier
#################################################################################################
def pencil_it(image):

    gray_image = cv.cvtColor(image, cv.COLOR_BGR2GRAY)
    inverted = 255 - gray_image
    blurred = cv.GaussianBlur(inverted, (21, 21), 0)
    invertedBlur = 255 - blurred
    pencilSketch = cv.divide(gray_image, invertedBlur, scale=256.0)

    return pencilSketch

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
    # Creating a VideoCapture object to read the video
    fvs = FileVideoStream(args.input_file).start()

    # Start time
    start = time.time()

    print("OpenCV major version: {0}".format(fvs.major_ver))
    print("Frames per second: {0}".format(fvs.fps))
    print("Frames to process: {0}".format(fvs.frames))

    print("Creating temporary directory: TEMP")

    createPath("TEMP")

    print("Creating audio only file: TEMP/audio.wav")

    # using only no video (-vn) flag to keep the original sample and bit rate
    command = "ffmpeg -i '" + args.input_file + "' -vn TEMP/audio.wav"
    subprocess.call(command, shell=True)

    current_iteration = 0
    out = None

    # loop over the frames from the video
    while fvs.more():

        printProgressBar(current_iteration, fvs.frames, prefix='Frame Conversion Progress:', suffix='Complete', length=50)

        img_rgb = fvs.read()

        if img_rgb is None:
            break

        # Read the frame from the video
        current_frame = pencil_it(img_rgb)
        keep_frame = cv.cvtColor(current_frame, cv.COLOR_GRAY2BGR)

        if not out:
            (height, width) = keep_frame.shape[:2]
            print("height = {}, width = {}".format(height, width))
            fourcc = cv.VideoWriter_fourcc(*'mp4v')
            out = cv.VideoWriter("TEMP/videoNew.mp4", fourcc, fvs.fps, (width, height))

        try:
            out.write(keep_frame)

        except cv.error as error:
            print("[Error]: {}".format(error))
            out and out.release()

        end = time.time()
        it_time = end - start

        print("Frame Read Time : {0} seconds".format(it_time))

        current_iteration += 1

    out.release()

    print("Merging edited video back to audio to produce final file")
    command = "ffmpeg -r " + str(fvs.fps) + " -i TEMP/videoNew.mp4 -i TEMP/audio.wav -strict -2 '" + format(args.output_file) + "'"
    print(command)
    subprocess.call(command, shell=True)

    deletePath("TEMP")

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
