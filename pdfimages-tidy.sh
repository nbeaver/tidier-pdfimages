#!/bin/bash

# Check to make sure pdfimages is installed.
hash pdfimages 2>/dev/null || { echo >&2 "Please install pdfimages."; exit 1; }
# http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script

# Terminate as soon as any command fails.
set -e

# Argument check ($# is the number of arguments)
if [ $# -lt 1 ]; then
    echo "Usage: pdfimages-tidy [options] <PDF-file>"
    pdfimages 2>&1 >/dev/null | tail -n +5 # An underhanded, hacky way of getting all the pdfimages options for free.
    exit
fi

if [ $1 == '-h' -o $1 == '-help' -o $1 == '--help' -o $1 == '-?' ]; then
    echo "Usage: pdfimages-tidy [options] file.pdf"
    echo "This is a wrapper script for pdfimages."
    echo "pdfimages-tidy can use any options that pdfimages does,"
    echo "but it automatically sets the image-root name to be the"
    echo "name of the pdf file and puts the images in a folder."
    echo "Here is the help message from pdfimages:"
    echo "--------------------------------------------------------------------------------"
    pdfimages --help
    exit
fi

if [ $1 == '-v' -o $1 == '-version' -o $1 == '--version' ]; then
    pdfimages -v # I don't understand why pdfimages doesn't permit --version as equivalent to -v.
    exit
fi


FILE_NAME="${@: -1}" # last argument (split by spaces) is the name of the pdf file.
# http://stackoverflow.com/questions/1853946/getting-the-last-argument-passed-to-a-shell-script

# FILE_NAME="${!#}"   # this should work, too.
# http://stackoverflow.com/a/1216239/1608986

ALL_BUT_FILE_NAME="${@:1:$(($#-1))}"
# http://stackoverflow.com/a/1215592/1608986

IMAGE_FOLDER=$FILE_NAME"_images"

DEBUG=0
if [ $DEBUG -eq 1 ]; then
    echo -e "Extracting images from file $FILENAME to folder $IMAGE_FOLDER by running this command:\n$ pdfimages $ALL_BUT_FILE_NAME ../$FILE_NAME $FILE_NAME"
    # http://stackoverflow.com/questions/226703/how-do-i-prompt-for-input-in-a-linux-shell-script
    select CHOICE in "Yes" "No"; do
        case $CHOICE in
            Yes ) break;;
            No ) exit;;
        esac
    done
fi

# If the directory doesn't exist, then create it.
if [ ! -d "$IMAGE_FOLDER" ]; then
    mkdir "$IMAGE_FOLDER"
fi
# http://stackoverflow.com/questions/59838/how-to-check-if-a-directory-exists-in-a-shell-script

# Because pdfimages dumps into the current directory,
# we have to go into the image folder and then reference the parent directory.
cd "$IMAGE_FOLDER"
# Run pdfimages with the necessary flags, and use the filename as the starting point for the images names.
# e.g. file.pdf-000.ppm, file.pdf-001.ppm, ...
pdfimages "$ALL_BUT_FILE_NAME" ../"$FILE_NAME" "$FILE_NAME"
cd - &> /dev/null # go back up to the starting folder, throwing away the output, which is just the name of the directory we started in.
