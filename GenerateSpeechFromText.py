#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse
import subprocess
import tempfile
import threading
from pathlib import Path

import pyttsx3
#import logging

#l = logging.getLogger("pydub.converter")
#l.setLevel(logging.DEBUG)
#l.addHandler(logging.StreamHandler())

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
parser.add_argument('--output_file', type=str, help="The _output location to write the speech WAV")
parser.add_argument('--language', type=str, default="en", help="The language to detect and speak")
parser.add_argument('--voice', type=str, default="jorge", help="The voice to use")
parser.add_argument('--handle_length', type=int, default=0, help="If TTS runs long: 0=truncate, 1=speed up, 2=skip. Default=0")

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

    global engine

    print(dict['text'])
    # call nsss and write AIFF to file
    engine.save_to_file(dict['text'], "{}/_tmp{:05d}.aiff".format(tmpdirname, int(dict['counter'])))
    #engine.runAndWait()

    #try:
    #    source = AudioSegment.from_wav("{}/tmp{:05d}.aiff".format(tmpdirname, int(dict['counter'])))
    #except:
    #    source = AudioSegment.from_file("{}/tmp{:05d}.aiff".format(tmpdirname, int(dict['counter'])), format="wav")

    #audio = AudioSegment.silent(0)

    # How to handle TTS running past frame length
    #   Options:    0=Truncate TTS to frame length
    #               1=Speed up TTS to frame length
    #               2=Leave frame TTS-less (Skip)
    #if args.handle_length == 1:
    #    if source.duration_seconds > 0:
    #        speed = (source.duration_seconds / 0)
    #        source = speedup(source, speed, 150)
    #elif args.handle_length == 2:
    #    if source.duration_seconds > 0:
    #        source = audio

    #output = audio.overlay(source, position=0)

    #output.export("{}/_output{:05d}.aiff".format(tmpdirname, int(dict['counter'].strip())), format="wav")

#################################################################################################
#  *** Begin main part of Program ***
#################################################################################################
def main():

    global tmpdirname

    with tempfile.TemporaryDirectory() as tmpdirname:

        print('Created temporary directory', tmpdirname)

        print("Reading transcript file {}".format(args.input_file))
        counter = 1

        # Read SRT file and use time info to generate translation that match video frames
        with open(args.input_file) as fp:

            while True:

                text = fp.readline()
                print("text read: {}".format(text))

                if not text:
                    break

                #print(text.strip())

                dict = {}
                dict['counter'] = counter
                dict['text'] = text.strip()

                counter = counter + 1
                time_limiter_from_stuck_function(tts_generator, dict)

        #project_first_frame = AudioSegment.from_wav("{}/tmp{:05d}.aiff".format(tmpdirname, 1))
        #base_frame_rate = project_first_frame.frame_rate

        #audio = AudioSegment.silent(duration=0)
        #audio = audio.set_frame_rate(base_frame_rate)

        #audio.export("{}/_output{:05d}.aiff".format(tmpdirname, 0), format="wav")

        # iterate over the _output files in the TEMP directory
        files = sorted(Path(tmpdirname).glob('_tmp*.aiff'))

        # Build list of translation clips
        for file in files:
            command = "echo \"file '{}'\" >> {}/file_list.txt".format(file, tmpdirname)
            print(command)
            subprocess.call(command, shell=True)

        # Wait for the user input to terminate the program
        input("Please review SRT file for inaccuracies before continuing...")

        # Combine clips into a full translation audio wave file
        command = "ffmpeg -f concat -safe 0 -i {}/file_list.txt -c copy '{}'".format(tmpdirname, args.output_file)
        print(command)
        subprocess.call(command, shell=True)

if __name__ == "__main__":

    engine = pyttsx3.init()
    engine.setProperty('voice', "com.apple.speech.synthesis.voice.{}".format(args.voice))
    engine.setProperty("rate", 200)
    #engine.setProperty('volume', 1.0)

    #voices = engine.getProperty('voices')
    # engine.setProperty('voice', voices[0].id)  #changing index, changes voices. o for male
    #engine.setProperty('voice', voices[1].id)  # changing index, changes voices. 1 for female

    #for voice  in voices:
    #    print("{}\n".format(voice))

    #from pydub import AudioSegment
    #AudioSegment.from_file(args.input_file).export(args.output_file, format="mp3")

    print("Voice: {}".format(args.voice))

    #engine.say("I will speak this text")
    #quit()

    global tmpdirname

    with tempfile.TemporaryDirectory() as tmpdirname:

        print('Created temporary directory', tmpdirname)

        print("Reading transcript file {}".format(args.input_file))
        counter = 1

        # Read SRT file and use time info to generate translation that match video frames
        with open(args.input_file) as fp:

            while True:

                text = fp.readline()
                print("text read: {}".format(text))

                if not text:
                    break

                engine.save_to_file(text, "{}/_tmp{:05d}.aiff".format(tmpdirname,counter))
                counter = counter + 1

        engine.runAndWait()

        # iterate over the _output files in the TEMP directory
        files = sorted(Path(tmpdirname).glob('_tmp*.aiff'))

        # Build list of translation clips
        for file in files:
            command = "echo \"file '{}'\" >> {}/file_list.txt".format(file, tmpdirname)
            print(command)
            subprocess.call(command, shell=True)

        # Wait for the user input to terminate the program
        input("Please review SRT file for inaccuracies before continuing...")

        # Combine clips into a full translation audio wave file
        command = "ffmpeg -f concat -safe 0 -i {}/file_list.txt -c copy '{}'".format(tmpdirname, args.output_file)
        print(command)
        subprocess.call(command, shell=True)

    main()

    engine.stop()
    del(engine)