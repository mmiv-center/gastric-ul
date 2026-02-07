#!/bin/env bash

# check the arguments
mp4="$1"
xml="$2"
# output is the name of the generated zip file with the data
output="$3"

if [ ! -e "${mp4}" ]; then
   echo "Cannot see any mp4 file as the first argument"
   exit
fi

if [ ! -e "${xml}" ]; then
   echo "Cannot see any xml file as the second argument"
   exit
fi

if [ -e "${output}" ]; then
   echo "Output already exists, should be a new file"
   exit
fi


# get the Clip/Depth
clip_depth=$(xml2 < "${xml}" | grep "/Clip/Depth" | cut -d'=' -f2)
exam=$(xml2 < "${xml}" | grep "/Clip/Exam" | cut -d'=' -f2)
content_date=$(xml2 < "${xml}" | grep "/Clip/ContentDate" | cut -d'=' -f2)
content_time=$(xml2 < "${xml}" | grep "/Clip/ContentTime" | cut -d'=' -f2)
frame_time=$(xml2 < "${xml}" | grep "/Clip/Data/FrameTime" | cut -d'=' -f2)
calibration_region_ulx=$(xml2 < "${xml}" | grep "/Clip/Data/RegionOfCalibration/Region/UpperLeft/X" | cut -d'=' -f2)
calibration_region_uly=$(xml2 < "${xml}" | grep "/Clip/Data/RegionOfCalibration/Region/UpperLeft/Y" | cut -d'=' -f2)
calibration_region_lrx=$(xml2 < "${xml}" | grep "/Clip/Data/RegionOfCalibration/Region/LowerRight/X" | cut -d'=' -f2)
calibration_region_lry=$(xml2 < "${xml}" | grep "/Clip/Data/RegionOfCalibration/Region/LowerRight/Y" | cut -d'=' -f2)

# /Clip/Data/RegionOfCalibration/Region/Delta/X=0.017507
# /Clip/Data/RegionOfCalibration/Region/Delta/Y=0.017507
calibration_region_delta_x=$(xml2 < "${xml}" | grep "/Clip/Data/RegionOfCalibration/Region/Delta/X" | cut -d'=' -f2)
calibration_region_delta_y=$(xml2 < "${xml}" | grep "/Clip/Data/RegionOfCalibration/Region/Delta/Y" | cut -d'=' -f2)

mkdir -p "/tmp/frames"
if [ ! /tmp/frames ]; then
   echo "Error: could not create the output folder /tmp/frames"
   exit
fi

ffmpeg -i "${mp4}" -vf format=gray -q:v 2 /tmp/frames/image-%04d.jpg

pname="ANON$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c 8)"
fname=$(basename "${mp4}")

# create a template file for the study info
cat >/tmp/template.dump <<EOL
 (0008,0020) DA [${content_date}]            #  8, 1 StudyDate
 (0008,0021) DA [${content_date}]            #  8, 1 SeriesDate
 (0008,0031) TM [${content_time}]
 (0008,0016) UI =UltrasoundImageStorage        # 26, 1 SOPClassUID
 (0010,0010) PN ${pname}
 (0010,0020) LO ${pname}
 (0008,1030) LO Movie - ${fname%.*}
 (0020,0011) IS 1
 (0008,0050) SH ${pname}
EOL

dump2dcm /tmp/template.dump /tmp/template.dcm
dcmodify -gst -gse -gin -i "0018,5050=${clip_depth}" -i "0018,1063=${frame_time}" -nb /tmp/template.dcm

# convert to grayscale first
find "/tmp/frames" -type f -name "image*.jpg" -exec convert {} -colorspace Gray -depth 16 {} \;
# convert to DICOM
find "/tmp/frames" -type f -name "image*.jpg" -exec bash -c 'img2dcm --series-from /tmp/template.dcm -ii ${0} ${0%.*}.dcm' {} \;

# add some tags back manually
find "/tmp/frames" -type f -name "image*.dcm" -exec dcmodify -i "0018,5050=${clip_depth}" -i "0018,1063=${frame_time}" -i "0008,1030=Movie - ${fname%.*}" -i "0008,0031=${content_time}" -i "0008,103E=${exam}" -nb {} \;

# we need to fix the instance number tag, same value right now, should be the number in the filename
for u in $(ls /tmp/frames/*.dcm); do
   t=$(echo ${u%.*} | cut -d'-' -f2)
   tn=$(echo "$t" | bc)
   dcmodify -i "0020,0013=${tn}" -nb "$u"
done

# copy resulting DICOM into a zip to output
find /tmp/frames/ -type f -name "*.jpg" -delete
zip -r "${output}" /tmp/frames
