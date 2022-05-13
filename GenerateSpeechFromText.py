#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse

# import pyttsx3
# Import the gTTS module
import pyttsx3

# This the os module so we can play the MP3 file generated

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

https://gtts.readthedocs.io/en/latest/module.html#localized-accents
'''
#################################################################################################
# Get arguments from command line
#################################################################################################
parser = argparse.ArgumentParser(
    description='Read a text file, convert it to speech, and write to an MP3')
parser.add_argument('--input_file', type=str, help='The text file to read and produce speech from')
parser.add_argument('--output_file', type=str, help="the output location to write the speech mp3")
parser.add_argument('--language', type=str, default="en", help="the language to detect and speak")
parser.add_argument('--voice', type=str, default="jorge", help="the voice to use")

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

    engine = pyttsx3.init()
    engine.setProperty('voice', "com.apple.speech.synthesis.voice.{}".format(args.voice))

    mytext = ''

    with open(args.input_file) as fp:
        line = fp.readline()
        while line:
            mytext += line.strip() + '\n'
            line = fp.readline()

    engine.save_to_file(mytext, args.output_file)
    engine.runAndWait()

if __name__ == "__main__":
    main()