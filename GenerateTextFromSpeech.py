#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse
import os
from shutil import rmtree
import speech_recognition as sr

import subprocess
import time
import tempfile

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
# Get arguments from command line
#################################################################################################
parser = argparse.ArgumentParser(
    description='Translate audio from video file, generate subtitles, and burn them into a new video file')
parser.add_argument('--input_file', type=str, help='The video file you want to generate subtitles for')
parser.add_argument('--output_file', type=str, help="the _output location to write the subtitle file")
parser.add_argument('--language', type=str, default="en-US", help="the _output location to write the subtitled video")

args = parser.parse_args()

#################################################################################################
# Show usage and end if required inputs were not provided
#################################################################################################
if not args.input_file or not args.output_file:
    parser.print_usage()
    quit()

with tempfile.TemporaryDirectory() as tmpdirname:

    print('Created temporary directory', tmpdirname)

    print("Creating audio only file: {}/audio.wav".format(tmpdirname))

    # using only no video (-vn) flag to keep the original sample and bit rate
    command = "ffmpeg -i '{}' -vn {}/audio.wav".format(args.input_file, tmpdirname)
    subprocess.call(command, shell=True)

    print("Generating transcript from: {}/audio.wav".format(tmpdirname))

    # create recognizer instance
    r = sr.Recognizer()
    #r.energy_threshold = 4000

    fh = open(args.output_file, "w+")

    # subtitle count
    subtitle_number = 0

    # Read Audio File
    with sr.WavFile("{}/audio.wav".format(tmpdirname)) as source:        # use "test.wav" as the audio source

        audio_length = source.DURATION  # get length of audio file
        audio = r.record(source)

        # Recognize speech using Google
        try:
            subtitle_number += 1
            rec = r.recognize_google(audio, language=args.language)
            fh.write("{}\n".format(rec))

        except sr.UnknownValueError:
            pass
            #fh.write("*** Could not understand audio ***\n")
        except sr.RequestError as e:
            print("RequestError {0}".format(e))

    fh.close()

    print("Text written to: {}".format(args.output_file))