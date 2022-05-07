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
    
	com.apple.speech.synthesis.voice.Alex
	com.apple.speech.synthesis.voice.alice
	com.apple.speech.synthesis.voice.alva
	com.apple.speech.synthesis.voice.amelie
	com.apple.speech.synthesis.voice.anna
	com.apple.speech.synthesis.voice.carmit
	com.apple.speech.synthesis.voice.damayanti
	com.apple.speech.synthesis.voice.daniel.premium
	com.apple.speech.synthesis.voice.diego
	com.apple.speech.synthesis.voice.ellen
	com.apple.speech.synthesis.voice.fiona
	com.apple.speech.synthesis.voice.Fred
	com.apple.speech.synthesis.voice.ioana
	com.apple.speech.synthesis.voice.joana
	com.apple.speech.synthesis.voice.jorge
	com.apple.speech.synthesis.voice.juan
	com.apple.speech.synthesis.voice.kanya
	com.apple.speech.synthesis.voice.karen.premium
	com.apple.speech.synthesis.voice.kyoko
	com.apple.speech.synthesis.voice.laura
	com.apple.speech.synthesis.voice.lekha
	com.apple.speech.synthesis.voice.luca
	com.apple.speech.synthesis.voice.luciana
	com.apple.speech.synthesis.voice.maged
	com.apple.speech.synthesis.voice.mariska
	com.apple.speech.synthesis.voice.meijia
	com.apple.speech.synthesis.voice.melina
	com.apple.speech.synthesis.voice.milena
	com.apple.speech.synthesis.voice.moira
	com.apple.speech.synthesis.voice.monica
	com.apple.speech.synthesis.voice.nora
	com.apple.speech.synthesis.voice.paulina
	com.apple.speech.synthesis.voice.rishi
	com.apple.speech.synthesis.voice.samantha
	com.apple.speech.synthesis.voice.sara
	com.apple.speech.synthesis.voice.satu
	com.apple.speech.synthesis.voice.sinji
	com.apple.speech.synthesis.voice.tessa
	com.apple.speech.synthesis.voice.thomas
	com.apple.speech.synthesis.voice.tingting
	com.apple.speech.synthesis.voice.veena
	com.apple.speech.synthesis.voice.Victoria
	com.apple.speech.synthesis.voice.xander
	com.apple.speech.synthesis.voice.yelda
	com.apple.speech.synthesis.voice.yuna
	com.apple.speech.synthesis.voice.yuri
	com.apple.speech.synthesis.voice.zosia
	com.apple.speech.synthesis.voice.zuzana

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
parser.add_argument('--voice', type=str, default="Alex", help="the voice to use")

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
    engine.setProperty('voice', args.voice)

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