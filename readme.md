This shell script came about because I go through a lot of research articles and frequently need to extract the images from them.

The `pdfimages` command works nicely for this, but it's not particularly well maintained and dumps all the images into the working directory.

Furthermore, it prompts for a name for the image root, when I would be perfectly happy with just using the filename of the pdf.

Finally, `pdfimages` defaults to `pnm` and `pbm` formats, when I would prefer `png`.

To fix this, I wrote a very simple wrapper script.

Example usage:

    pdfimages-tidy file.pdf

This will extract all images in file.pdf to file.pdf_images/ and convert them to `png` files while keeping the original images.
