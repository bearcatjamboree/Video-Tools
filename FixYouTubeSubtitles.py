#################################################################################################
# importing the necessary libraries
#################################################################################################
import argparse

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