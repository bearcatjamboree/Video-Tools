# imports
import argparse

import matplotlib.pyplot as plt
import numpy as np
import wave, sys
import tempfile
import subprocess

#################################################################################################
# Get arguments from command line
#################################################################################################
parser = argparse.ArgumentParser(
    description='Produce a plot of the sound frame audio')
parser.add_argument('--input_file', type=str, help='The video file you want to analyze')
parser.add_argument('--output_file', type=str, help='The video file you want to analyze')

args = parser.parse_args()

# shows the sound waves
def visualize(path: str, out_path: str):
    # reading the audio file
    raw = wave.open(path)

    # reads all the frames
    # -1 indicates all or max frames
    signal = raw.readframes(-1)
    signal = np.frombuffer(signal, dtype="int16")

    # gets the frame rate
    f_rate = raw.getframerate()

    # to Plot the x-axis in seconds
    # you need get the frame rate
    # and divide by size of your signal
    # to create a Time Vector
    # spaced linearly with the size
    # of the audio file
    time = np.linspace(
        0,  # start
        len(signal) / f_rate,
        num=len(signal)
    )

    # using matplotlib to plot
    # creates a new figure
    plt.figure(1)

    # title of the plot
    plt.title("Sound Wave")

    # label of x-axis
    plt.xlabel("Time")

    # actual plotting
    plt.plot(time, signal)

    # shows the plot
    # in new window
    plt.show()

    # out file
    plt.savefig(out_path)

if __name__ == "__main__":

    global tmpdirname

    with tempfile.TemporaryDirectory() as tmpdirname:

        print('Created temporary directory', tmpdirname)
        print("Creating temporary audio and video files: {}/video.mp4 + {}/audio.wav".format(tmpdirname, tmpdirname))

        #################################################################################################################
        # Copy the video and audio to separate temporary files.  Re-encode the video in case there are any frame issues.
        # This can help prevent keyframe video/audio sync issues.
        #################################################################################################################
        command = "ffmpeg -i '{}' -vn {}/audio.wav".format(args.input_file, tmpdirname)
        subprocess.call(command, shell=True)

        visualize("{}/audio.wav".format(tmpdirname), args.output_file)
