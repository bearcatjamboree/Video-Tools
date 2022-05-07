#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse
import os
from shutil import rmtree
import speech_recognition as sr

import subprocess
import time

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
parser.add_argument('--output_srt', type=str, help="the output location to write the subtitle file")
parser.add_argument('--output_video', type=str, help="the output location to write video with the subtitles added")
parser.add_argument('--subtitle_seconds', type=int, default=2, help="the number of seconds of audio to transcribe and display at a time")
parser.add_argument('--subtitle_font', type=str, default="Bangers", help="Default font name to use in generated subtitles")
parser.add_argument('--subtitle_fontsize', type=int, default=48, help="Default font size to use in generated subtitles")
parser.add_argument('--subtitle_fontcolor', type=str, default="ffffff", help="Default color for generated subtitles")
parser.add_argument('--language', type=str, default="en-US", help="the output location to write the subtitled video")

args = parser.parse_args()

#################################################################################################
# Show usage and end if required inputs were not provided
#################################################################################################
if not args.input_file or not args.output_srt or not args.output_video:
    parser.print_usage()
    quit()

print("Creating temporary directory: TEMP")

createPath("TEMP")

print("Creating audio only file: TEMP/audio.wav")

# using only no video (-vn) flag to keep the original sample and bit rate
command = "ffmpeg -i '" + args.input_file + "' -vn TEMP/audio.wav"
subprocess.call(command, shell=True)

print("Generating transcript from: TEMP/audio.wav")

# create recognizer instance
r = sr.Recognizer()
#r.energy_threshold = 4000

fh = open(args.output_srt, "w+")

# subtitle count
subtitle_number = 0

# Read Audio File
with sr.WavFile("TEMP/audio.wav") as source:        # use "test.wav" as the audio source

    audio_length = source.DURATION  # get length of audio file

    # Calculate the number of 1-second iterations
    iterations = int(audio_length / args.subtitle_seconds)

    for i in range(iterations):

        # Display current progress
        printProgressBar(i, iterations, prefix='Generate Transcript Progress:', suffix='Complete', length=50)

        # Access 2-seconds each iteration
        audio = r.record(source, duration=args.subtitle_seconds)

        # Recognize speech using Google
        try:
            subtitle_number += 1
            rec = r.recognize_google(audio, language=args.language)
            #fh.write(rec + ".\n")
            fh.write("{}\n".format(subtitle_number))
            start_time = time.strftime('%H:%M:%S', time.gmtime(i*args.subtitle_seconds))
            end_time = time.strftime('%H:%M:%S', time.gmtime(args.subtitle_seconds*(i+1)))
            fh.write("{},000 --> {},000\n".format(start_time, end_time))
            fh.write(rec + "\n\n")

        except sr.UnknownValueError:
            pass
            #fh.write("*** Could not understand audio ***\n")
        except sr.RequestError as e:
            print("RequestError {0}".format(e))

    printProgressBar(1, 1, prefix='Generate Subtitles Progress:', suffix='Complete', length=50)

fh.close()

print("Subtitles written to: {}".format(args.output_srt))

# Wait for the user input to terminate the program
input("Please review SRT file for inaccuracies before continuing...")

# using only no video (-vn) flag to keep the original sample and bit rate
command = "ffmpeg -i '" + args.input_file + "' -vf subtitles=\"'" + args.output_srt + "':force_style='FontName="+args.subtitle_font+",Fontsize={}".format(args.subtitle_fontsize)+",PrimaryColour=&H"+args.subtitle_fontcolor+"&'\" '" + args.output_video + "'"
print(command)
subprocess.call(command, shell=True)

deletePath("TEMP")