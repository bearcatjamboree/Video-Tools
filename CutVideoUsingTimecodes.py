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

#################################################################################################
# Get arguments from command line
#################################################################################################
parser = argparse.ArgumentParser(
    description='Search the audio/video/both for frames to retain and remove the rest')
parser.add_argument('--input_file', type=str, help='The video file you want to extract frames from')
parser.add_argument('--output_file', type=str, help="The location where you want to write the output video")
parser.add_argument('--srt_file', type=str, help="The file containing the time codes in the format [start, end, "
                                                      "text]")

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
#  *** Begin main part of Program ***
#################################################################################################                    
def main():

    global tmpdirname
    times = []

    print("Scanning timecode file: {}".format(args.srt_file))

    # Read SRT File and create list of times
    with open(args.srt_file) as fp:

        while True:

            counter = fp.readline()

            if not counter:
                break

            time = fp.readline().strip()
            text = fp.readline()
            blank = fp.readline()

            # separate SRT timestamp into start and end time
            times.append(time.split(' --> '))

    with tempfile.TemporaryDirectory() as tmpdirname:

        print("Created temporary directory: {}".format(tmpdirname))

        count = 0

        print("Extracting clips using timecodes")

        for clip_time in times:

            count += 1

            start_time_arr = clip_time[0].split(',')
            end_time_arr = clip_time[1].split(',')

            start_time="{}.{}".format(start_time_arr[0],start_time_arr[1])
            end_time = "{}.{}".format(end_time_arr[0],start_time_arr[1])

            #start_time = clip_time[0].replace(',', '.')
            #end_time = clip_time[1].replace(',', '.')

            command = "ffmpeg -i \"{}\" -ss {} -to {} -af \"aformat=sample_rates=48000\" -c:v copy {}/video_{:06d}.mp4".format(args.input_file,
                                                                                                                               start_time,
                                                                                                                               end_time,
                                                                                                                               tmpdirname,
                                                                                                                               count)
            print(command)
            subprocess.call(command, shell=True)

        for x in range(1, count):
            command = "echo \"file 'video_{:06d}.mp4'\" >> {}/file_list.txt".format(x, tmpdirname)
            print(command)
            subprocess.call(command, shell=True)

        print("Creating output file: {}".format(args.output_file))

        fvs = FileVideoStream("{}".format(args.input_file)).start()

        #name = input("What is your name? ")

        command = "ffmpeg -r 60.0 -loglevel error -f concat -safe 0 -i {}/file_list.txt -c copy '{}'".format(tmpdirname, args.output_file)
        print(command)
        subprocess.call(command, shell=True)

        quit()

if __name__ == "__main__":
    main()
