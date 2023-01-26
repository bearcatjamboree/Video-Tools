#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse
from datetime import timedelta
from googletrans import Translator
from youtube_transcript_api import YouTubeTranscriptApi

#################################################################################################
# Get arguments from command line
#################################################################################################
parser = argparse.ArgumentParser(
    description='Download a transcript from a YouTube video')
parser.add_argument('--video_id', type=str, help='The YouTube video_id value for the video being transcribed')
parser.add_argument('--output_folder', type=str, help="the _output location to write the transcript txt")
parser.add_argument('--language', type=str, default='en', help="The language to convert the transcript to")

args = parser.parse_args()

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

out_txt = args.output_folder + "/" + args.video_id + "_" + args.language + ".txt"
out_srt = args.output_folder + "/" + args.video_id + "_" + args.language + ".srt"

# Open _output file
ft = open(out_txt, "w+")
fs = open(out_srt, "w+")

header=True
counter = 1

translator = Translator()
excludes = ['[Music]', '[Laughter]', '[Applause]']

# map for cases where youtube_transcript_api and googletrans language don't match
lang_map = {'zh-Hans': 'zh-cn', 'zh-Hant': 'zh-tw', 'fil': 'tl'}

if args.language in lang_map:
    lang = lang_map[args.language]
else:
    lang = args.language

translations = translator.translate(excludes, src="en", dest=lang)

trans_excludes = []

for translated in translations:
    text=translated.text
    trans_excludes.append(text)

row = 1

# Generate the SRT formatted file from translated transcript
for i in range(len(desired_transcript)):

    transcript = desired_transcript[i]

    if header:
        ft.write("Start\tText\n")
        header=False

    text = transcript['text']

    # skip over excludes
    if text in trans_excludes:
        continue

    ft.write("{}\t{}\n".format(transcript['start'], text))

    start_time = getDateString(transcript['start'])
    end_time = getDateString(transcript['duration']+transcript['start'])

    # Set end time to the start of the next record if: one exists and it's not an excluded subtitle
    for j in range(i + 1, len(desired_transcript)):
        if desired_transcript[j]['text'] in trans_excludes:
            continue
        else:
            # break on first match
            end_time = getDateString(desired_transcript[j]['start'])
            break

    fs.write("{}\n".format(row))
    fs.write("{} --> {}\n".format(start_time, end_time))
    fs.write("{}\n\n".format(text))

    row += 1

ft.close()
fs.close()