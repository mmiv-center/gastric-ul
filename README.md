# Convert mp4 and xml into DICOM

To create a DICOM version of the image stack in the mp4. Add the information from the XML file to the DICOM tags.

The mp4 should, in a first step, be converted to a stack of png images using ffmpeg.

In a second step the ordered images should be converted to DICOM using dcmtk (png2dcm).

Architecture: The computation should be done inside a docker container in the entrypoint.sh. Data should be provided as a mounted volume path.

