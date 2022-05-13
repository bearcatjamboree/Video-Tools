#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse
from datetime import timedelta

#################################################################################################
# Get arguments from command line
#################################################################################################
parser = argparse.ArgumentParser(
    description='Download a transcript from a YouTube video')
parser.add_argument('--video_id', type=str, help='The YouTube video_id value for the video being transcribed')
parser.add_argument('--output_folder', type=str, help="the output location to write the transcript txt")
parser.add_argument('--language', type=str, default='en', help="The language to convert the transcript to")

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

transcript_list = YouTubeTranscriptApi.list_transcripts(args.video_id)

# See if document needs translating
try:
    find = transcript_list.find_transcript([args.language])
    desired_transcript = YouTubeTranscriptApi.get_transcript(args.video_id, languages=[args.language])
except:
    # Translate to destination language
    for transcript in transcript_list:
        # fetch the actual transcript data
        transcript.fetch()
        desired_transcript = transcript.translate(args.language).fetch()


out_raw = args.output_folder + "/" + args.video_id + ".raw"
out_txt = args.output_folder + "/" + args.video_id + ".txt"
out_srt = args.output_folder + "/" + args.video_id + ".srt"

# Open output file
fr = open(out_raw, "w+")
ft = open(out_txt, "w+")
fs = open(out_srt, "w+")

header=True
counter = 1

# Generate the SRT formatted file from translated transcript
for i in range(len(desired_transcript)):

    transcript = desired_transcript[i]

    if header:
        ft.write("Start\tText\n")
        header=False

    text = transcript['text']
    fr.write("{}\n".format(text))

    ft.write("{}\t{}\n".format(transcript['start'], text))

    if i < len(desired_transcript)-1:
        start_time = getDateString(transcript['start'])
        end_time = getDateString(desired_transcript[i+1]['start'])
    else:
        start_time = getDateString(transcript['start'])
        end_time = getDateString(transcript['duration'])

    fs.write("{}\n".format(i+1))
    fs.write("{} --> {}\n".format(start_time, end_time))
    fs.write("{}\n\n".format(text))

fr.close()
ft.close()
fs.close()