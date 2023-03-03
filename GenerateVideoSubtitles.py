#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse
import os
from datetime import timedelta
from shutil import rmtree

import whisper


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
# Get arguments from command line
#################################################################################################
parser = argparse.ArgumentParser(
    description='Translate audio from video file, generate subtitles, and burn them into a new video file')
parser.add_argument('--input_file', type=str, help='The video file you want to generate subtitles for')
parser.add_argument('--output_file', type=str, help="the _output location to write the subtitle file")
parser.add_argument('--language', type=str, default="English", help="the _output location to write the subtitled video")

args = parser.parse_args()

#################################################################################################
# Show usage and end if required inputs were not provided
#################################################################################################
if not args.input_file or not args.output_file:
    parser.print_usage()
    quit()

#################################################################################################
#  *** Begin main part of Program ***
#################################################################################################
def main():

    model = whisper.load_model("base")

    transcribe = model.transcribe(args.input_file, fp16=False, language=args.language)
    segments = transcribe['segments']

    fh = open(args.output_file, "w+")

    for segment in segments:

        print("segment: {}".format(segment))
        caption_number = int(segment['id'] + 1)
        startDelta = timedelta(seconds=int(segment['start']))
        endDelta = timedelta(seconds=int(segment['end']))

        startMilli = int((float(segment['start'])-int(segment['start'])) * 1000)
        endMilli = int((float(segment['end'])-int(segment['end'])) * 1000)

        fh.write("{}\n".format(caption_number))
        fh.write("{},{:03d} --> {},{:03d}\n".format(startDelta, startMilli, endDelta, endMilli))
        fh.write("{}\n\n".format(segment['text'].strip()))

    fh.close()

if __name__ == "__main__":

    main()