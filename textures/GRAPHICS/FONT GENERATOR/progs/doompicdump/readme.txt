DoomPicDump - a doom-friendly batch image converter. 

This tool is used to batch convert doom format images to PNG format 
while preserving the image's origin offsets. 

For now, you will need to use a tool like XWE or Slumped to export the 
images before they can be processed by this tool.

SIMPLE INSTRUCTIONS

 - Run XWE and load up a WAD
 
 - Highlight all image files you want to dump.
 
 - Click "Entry -> Save As" and save them somewhere. They should save 
   as bitmaps.
 
 - Click "Entry -> View Raw Data"
 
 - Highlight all image files you want to preserve offsets for.
 
 - Click "Entry -> Save As" and save them where you saved the bitmaps. 
   They should save as "lmp" files.
   
 - Run this tool and point it at the folder with all that stuff in it. 
   The rest should go smoothly ;)


DETAILED STUFF

As input, this tool needs a folder full of bitmaps (as exported by XWE 
or similar). If the folder also contains files with the same names as 
the bitmaps, but with the .lmp extension, the tool will extract offsets 
from those files to be placed into the corresponding PNG image.

The bitmap images are converted to PNG format. PNGs are compressed with
PngCrush and quantized with PngQuant. Offsets are stored in special
'grAb' chunks in the png files using setpng.

Please read license.txt and the third-party licenses in ./doc .

NOTE TO LINUX USERS

You will need to have PngCrush and PngQuant installed. These programs
should be available in your distribution's package repository.

You will also need wine installed in order to run setpng.
