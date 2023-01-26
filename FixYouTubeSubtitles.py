#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse
import os
from shutil import rmtree


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
    description='Fix YouTube generated subtitle file')
parser.add_argument('--input_file', type=str, help='YouTube ')
parser.add_argument('--output_file', type=str, help="the _output location to write the subtitle file")

args = parser.parse_args()

#################################################################################################
# Show usage and end if required inputs were not provided
#################################################################################################
if not args.input_file or not args.output_file:
    parser.print_usage()
    quit()

#################################################################################################
# Read in the YouTube generated SRT file
#################################################################################################
with open(args.input_file) as fp:

    counters = []
    texts = []
    start_times = []
    end_times = []

    while True:

        counter = fp.readline()

        if not counter:
            break

        time = fp.readline()
        text = fp.readline()
        blank = fp.readline()

        # Separate start and end times
        (start_time, end_time) = time.split(' --> ')

        count_i = int(counter.strip())

        counters.append(counter.strip())
        texts.append(text.strip())

        start_times.insert(count_i, start_time)

        if count_i > 1:
            previous = count_i - 1
            end_times.insert(previous, start_time)

    # keep original end time if last subtitle
    end_times.insert(count_i, end_time)

#################################################################################################
# Write out the correct SRT file
#################################################################################################
fh = open(args.output_file, "w+")

for counter in counters:

    x = int(counter.strip())
    start_time = start_times[x-1].strip()
    end_time = end_times[x-1].strip()

    fh.write("{}\n".format(x))
    fh.write("{} --> {}\n".format(start_time, end_time))
    fh.write(texts[x-1] + "\n\n")

fh.close()

print("Subtitles written to: {}".format(args.output_file))