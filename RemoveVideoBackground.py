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
import mediapipe as mp
import numpy as np
import tempfile

#################################################################################################
# Get arguments from command line
#################################################################################################
parser = argparse.ArgumentParser(
    description='Search the audio/video/both for frames to retain and remove the rest')
parser.add_argument('--input_file', type=str, help='The video file you want to jump cut')
parser.add_argument('--output_file', type=str, help="the _output location to write the edit video")

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

    with tempfile.TemporaryDirectory() as tmpdirname:
        print('Created temporary directory: ', tmpdirname)

        print("Separating audio and video: {}/video.mp4 + {}/audio.wav".format(tmpdirname, tmpdirname))

        #################################################################################################################
        # Copy the video and audio to separate temporary files.  Re-encode the video in case there are any frame issues.
        # This can help prevent keyframe video/audio sync issues.
        #################################################################################################################
        command = "ffmpeg -i '{}' -c:a copy -c:v libx264 -an {}/video.mp4 -vn {}/audio.wav".format(args.input_file, tmpdirname, tmpdirname)
        subprocess.call(command, shell=True)

        # Creating a VideoCapture object to read the video
        fvs = FileVideoStream("{}/video.mp4".format(tmpdirname)).start()

        # Start time
        start = time.time()

        print("OpenCV major version: {0}".format(fvs.major_ver))
        print("Frames per second: {0}".format(fvs.fps))
        print("Frames to process: {0}".format(fvs.frames))
        print("Scanning frames for things to highlight...")

        bg_image = cv.imread('media/green_sceen.png')
        out = None

        # initialize mediapipe
        mp_selfie_segmentation = mp.solutions.selfie_segmentation
        selfie_segmentation = mp_selfie_segmentation.SelfieSegmentation(model_selection=1)

        # loop over the video frames
        while fvs.more():

            # Capture frame-by-frame
            frame = fvs.read()

            if frame is None:
                break

            height, width, channel = frame.shape
            RGB = cv.cvtColor(frame, cv.COLOR_BGR2RGB)

            # get the result
            results = selfie_segmentation.process(RGB)

            # extract segmented mask
            mask = results.segmentation_mask

            # it returns true or false where the condition applies in the mask
            condition = np.stack(
                (results.segmentation_mask,) * 3, axis=-1) > 0.6

            # resize the background image to the same size of the original frame
            bg_image = cv.resize(bg_image, (width, height))

            # combine frame and background image using the condition
            output_image = np.where(condition, frame, bg_image)

            # Write new video out
            if not out:
                fourcc = cv.VideoWriter_fourcc(*'mp4v')
                out = cv.VideoWriter("{}/videoNew.mp4".format(tmpdirname), fourcc, fvs.fps, (width, height))

            try:
                out.write(frame)

            except cv.error as error:
                print("[Error]: {}".format(error))
                out and out.release()

        out.release()

        # Combine new video back with original audio and produce new file
        command = "ffmpeg -r {} -i {}/videoNew.mp4 -i {}/audio.wav -strict -2 '{}'".format(str(fvs.fps), tmpdirname, tmpdirname, args.output_file)
        print(command)
        subprocess.call(command, shell=True)

    # End time
    end = time.time()

    # Time elapsed
    seconds = end - start

    print('Execution time:', time.strftime("%H:%M:%S", time.gmtime(seconds)))

    # print ("My frames: = ", keep_frames)

    # release the video capture object
    # do a bit of cleanup
    cv.destroyAllWindows()
    fvs.stop()

if __name__ == "__main__":
    main()