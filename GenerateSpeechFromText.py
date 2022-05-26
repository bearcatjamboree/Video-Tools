#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse
import threading

import pyttsx3
import subprocess
from pydub import AudioSegment
from pydub.effects import speedup

from pathlib import Path
import tempfile

# This the os module so we can play the file generated

'''
    Voices:
    
    Alex
    alice
    alva
    amelie
    anna
    carmit
    damayanti
    daniel.premium
    diego
    ellen
    fiona
    Fred
    ioana
    joana
    jorge
    juan
    kanya
    karen.premium
    kyoko
    laura
    lekha
    luca
    luciana
    maged
    mariska
    meijia
    melina
    milena
    moira
    monica
    nora
    paulina
    rishi
    samantha
    sara
    satu
    sinji
    tessa
    thomas
    tingting
    veena
    Victoria
    xander
    yelda
    yuna
    yuri
    zosia
    zuzana
    mei-jia
    sin-ji.premium
    ting-ting

https://gtts.readthedocs.io/en/latest/module.html#localized-accents
'''
#################################################################################################
# Get arguments from command line
#################################################################################################
parser = argparse.ArgumentParser(
    description='Read a text file, convert it to speech, and write to a WAV')
parser.add_argument('--input_file', type=str, help='The text file to read and produce speech from')
parser.add_argument('--output_file', type=str, help="the _output location to write the speech WAV")
parser.add_argument('--language', type=str, default="en", help="the language to detect and speak")
parser.add_argument('--voice', type=str, default="jorge", help="the voice to use")
parser.add_argument('--speed_up', type=bool, default=True, help="Speed up audio to match subtitle duration")

args = parser.parse_args()

#################################################################################################
# Show usage and end if required inputs were not provided
#################################################################################################
if not args.input_file or not args.output_file:
    parser.print_usage()
    quit()

#################################################################################################
#  format time in seconds for calculating diff
#################################################################################################
def get_sec(time_str):
    """Get seconds from time."""
    (time, ms) = time_str.split(',')
    h, m, s = time.split(':')
    return  int(h) * 3600 + int(m) * 60 + int(s) + (int(ms) / 1000)

#################################################################################################
#  calculate difference between start and end time
#################################################################################################
def time_diff(start, end):
    return get_sec(end) - get_sec(start)

#################################################################################################
#  Threader function needed to do translation without hangs
#################################################################################################
def time_limiter_from_stuck_function(target_func, arg1, max_time=10):
    e = threading.Event()
    t = threading.Thread(target=target_func, args=(arg1,))
    t.start()
    t.join(max_time)
    if (t.is_alive()):
        print("This thread got stuck")
        e.set()
    else:
        pass

#################################################################################################
#  Funciton to translate each SRT frame of text and track order of audio clip
#################################################################################################
def tts_generator(dict):

    engine = pyttsx3.init()
    engine.setProperty('voice', "com.apple.speech.synthesis.voice.{}".format(args.voice))
    engine.setProperty("rate", 200)
    engine.save_to_file(dict['text'], "{}/tmp{:05d}.wav".format(tmpdirname, int(dict['counter'].strip())))
    engine.runAndWait()

    source = AudioSegment.from_file("{}/tmp{:05d}.wav".format(tmpdirname, int(dict['counter'].strip())))

    # adjust audio speed if flag is True
    if args.speed_up:
        if source.duration_seconds > dict['diff']:
            speed = (source.duration_seconds / dict['diff'])
            source = speedup(source, speed, 150)

    audio = AudioSegment.silent(duration=dict['diff'] * 1000)
    output = audio.overlay(source, position=0)

    output.export("{}/_output{:05d}.wav".format(tmpdirname, int(dict['counter'].strip())), format="wav")

#################################################################################################
#  *** Begin main part of Program ***
#################################################################################################
def main():

    global tmpdirname

    with tempfile.TemporaryDirectory() as tmpdirname:

        print('Created temporary directory', tmpdirname)

        print("Reading transcript file {}".format(args.input_file))

        # Read SRT file and use time info to generate translation that match video frames
        with open(args.input_file) as fp:

            while True:

                counter = fp.readline()

                if not counter:
                    break

                time = fp.readline()
                text = fp.readline()
                blank = fp.readline()

                # Separate SRT timestamp to produce start, end, and diff values
                (start_time, end_time) = time.split(' --> ')

                print(time.strip())

                diff = time_diff(start_time, end_time)
                print("time_diff = {} ".format(diff))

                print(text.strip())

                dict = {}
                dict['counter'] = counter
                dict['diff'] = diff
                dict['text'] = text.strip()

                if int(counter.strip())  == 1:
                    first_frame_start_time = start_time

                time_limiter_from_stuck_function(tts_generator, dict)

        project_first_frame = AudioSegment.from_file("{}/tmp{:05d}.wav".format(tmpdirname, 1))
        base_frame_rate = project_first_frame.frame_rate

        # Pad the beginning with blank audio so the track matches the video
        diff = time_diff('00:00:00,000', first_frame_start_time)
        #print("start:{}, end:{}, diff:{}".format('0', start_time, diff))
        audio = AudioSegment.silent(duration=diff * 1000)
        audio = audio.set_frame_rate(base_frame_rate)

        #print(base_frame_rate)
        #print(audio.frame_rate)

        audio.export("{}/_output{:05d}.wav".format(tmpdirname, 0), format="wav")

        # iterate over the _output files in the TEMP directory
        files = sorted(Path(tmpdirname).glob('_output*.wav'))

        # Build list of translation clips
        for file in files:
            command = "echo \"file '{}'\" >> {}/file_list.txt".format(file, tmpdirname)
            print(command)
            subprocess.call(command, shell=True)

        # Combine clips into a full translation audio wave file
        command = "ffmpeg -f concat -safe 0 -i file_list.txt -c copy '" + format(
            args.output_file) + "'"
        print(command)
        subprocess.call(command, shell=True)

if __name__ == "__main__":
    main()