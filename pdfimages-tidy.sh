#!/bin/bash

# Check to make sure pdfimages is installed.
hash pdfimages 2>/dev/null || { echo >&2 "Please install pdfimages."; exit 1; }
# http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script

# Terminate as soon as any command fails.
set -e

# Argument check ($# is the number of arguments)
if [ $# -lt 1 ]; then
    echo "Usage: pdfimages-tidy.sh [options] <PDF-file>"
    # This shell script doesn't add any options,
    # so just print the usage information from pdfimages.
    pdfimages 2>&1 | tail -n +5
    exit
fi

if [ "$1" == '-h' -o "$1" == '-help' -o "$1" == '--help' -o "$1" == '-?' ]; then
    echo "Usage: pdfimages-tidy [options] /optional/path/to/file.pdf"
    echo "This is a wrapper script for pdfimages."
    echo "pdfimages-tidy can use any options that pdfimages does,"
    echo "but it automatically sets the image-root name to be the"
    echo "name of the pdf file and puts the images in a folder."
    echo "Here is the help message from pdfimages:"
    echo "--------------------------------------------------------------------------------"
    pdfimages --help
    exit
fi

if [ "$1" == '-v' -o "$1" == '-version' -o "$1" == '--version' ]; then
    pdfimages -v # I don't understand why pdfimages doesn't permit --version as equivalent to -v.
    exit
fi

# TODO: Fix this so that filenames can have spaces.
# DONE: Fix this so the script can run on pdfs outside of the working directory.
FILEPATH="${@: -1}" # last argument (split by spaces) is the name of the pdf file.
# http://stackoverflow.com/questions/1853946/getting-the-last-argument-passed-to-a-shell-script

# Check if the file exists
if [ ! -f "$FILEPATH" ]; then
    echo "File not found:$FILEPATH"
    exit 1 # pdfimages man page: 1 Error opening a PDF file.
fi

# Check if the file is a pdf
if [ ! "$(head --bytes=4 "$FILEPATH")" = "%PDF" ]; then
    echo "File is not a pdf."
    echo "File is of type $(file "$FILEPATH")"
    exit 1 # pdfimages man page: 1 Error opening a PDF file.
fi
# http://stackoverflow.com/questions/16152583/tell-if-a-file-is-pdf-in-bash

#DONE: pass these to the script later on
OTHER_ARGUMENTS="${@:1:$(($#-1))}"
# http://stackoverflow.com/a/1215592/1608986

# FILEPATH="${!#}"   # this should work, too.
# http://stackoverflow.com/a/1216239/1608986

FILE_DIR=$(dirname "$FILEPATH")
FILENAME=$(basename "$FILEPATH")

IMAGE_FOLDER=$FILEPATH"_images"

# If the directory doesn't exist, then create it.
if [ ! -d "$IMAGE_FOLDER" ]; then
    mkdir "$IMAGE_FOLDER"
fi
# http://stackoverflow.com/questions/59838/how-to-check-if-a-directory-exists-in-a-shell-script

DEBUG=0
if [ $DEBUG -eq 1 ]; then
    echo -e "Extracting images from file $FILENAME to folder $IMAGE_FOLDER by running this command:"
    echo -e  pdfimages $OTHER_ARGUMENTS "$FILEPATH" "$IMAGE_FOLDER/$FILENAME"
    # http://stackoverflow.com/questions/226703/how-do-i-prompt-for-input-in-a-linux-shell-script
    select CHOICE in "Yes" "No"; do
        case $CHOICE in
            Yes ) break;;
            No ) exit;;
        esac
    done
fi

# Run pdfimages with the necessary flags, and use the filename as the starting point for the images names.
# e.g. file.pdf-000.ppm, file.pdf-001.ppm, ...
echo -n "Extracting images..."
pdfimages $OTHER_ARGUMENTS "$FILEPATH" "$IMAGE_FOLDER/$FILENAME"
echo "done."
number_of_images_extracted=$(find "$IMAGE_FOLDER" -maxdepth 1 -type f -print| wc -l)
echo "$number_of_images_extracted images extracted."
cd "$IMAGE_FOLDER"
# automatically run pnmtopng on the files that end with ppm.
# http://www.cyberciti.biz/faq/bash-loop-over-file/
shopt -s nullglob
for ppm_file in *.ppm
do
    # http://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
    if ! test -f "$ppm_file"
    then
        # Skip the file if it no longer exists.
        printf 'Warning: does not exist: %s\n' "$ppm_file" >&2
        continue
    fi
    echo "Converting $ppm_file to png."
    filename_no_extension="${ppm_file%.*}"
    pnmtopng "$ppm_file" > "$filename_no_extension.png"
done
# There are also files that end in pbm.
# When funning the 'file' command:
# image.ppm: Netpbm PPM "rawbits" image data
# image.pbm: Netpbm PBM "rawbits" image data
# I should really handle this more elegantly, but this fix gets the job done.
for pbm_file in *.pbm
do
    # http://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
    if ! test -f "$pbm_file"
    then
        # Skip the file if it no longer exists.
        printf 'Warning: does not exist: %s\n' "$ppm_file" >&2
        continue
    fi
    echo "Converting $pbm_file to png."
    filename_no_extension="${pbm_file%.*}"
    pnmtopng "$pbm_file" > "$filename_no_extension.png"
done
