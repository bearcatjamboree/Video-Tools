#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse
import time
from datetime import datetime
from datetime import timedelta

#################################################################################################
# Get arguments from command line
#################################################################################################
parser = argparse.ArgumentParser(
    description='Download a transcript from a YouTube video')
parser.add_argument('--video_id', type=str, help='The YouTube video_id value for the video being transcribed')
parser.add_argument('--output_folder', type=str, help="the output location to write the transcript txt")

args = parser.parse_args()

from youtube_transcript_api import YouTubeTranscriptApi

#################################################################################################
#  Insert frames before and after match frames to add "context"
#################################################################################################
def getDateString(seconds):
    td = str(timedelta(seconds=seconds))
    s = td.split('.')

    if len(s) == 1:
        s.append('000')

    new_date = "{},{}".format(s[0], s[1][:3])
    return new_date

# Must be a single transcript.
transcript_list = YouTubeTranscriptApi.get_transcript(args.video_id)

out_txt = args.output_folder + "/" + args.video_id + ".txt"
out_srt = args.output_folder + "/" + args.video_id + ".srt"

# Open output file
ft = open(out_txt, "w+")
fs = open(out_srt, "w+")

header=True
counter = 1

# Iterate over all available transcripts
for transcript in transcript_list:

    if header:
        ft.write("Start\tText\n")
        header=False

    ft.write("{}\t{}\n".format(transcript['start'], transcript['text']))

    start_time = getDateString(transcript['start'])
    end_time = getDateString(transcript['duration'])

    fs.write("{}\n".format(counter))
    fs.write("{} --> {}\n".format(start_time, end_time))
    fs.write("{}\n\n".format(transcript['text']))

    counter += 1

ft.close()
fs.close()