FROM debian:bookworm-slim

RUN apt update -yq && apt install -y ffmpeg dcmtk xml2 imagemagick zip bc

ENV DCMDICTPATH=/usr/share/libdcmtk17/dicom.dic:/usr/share/libdcmtk17/private.dic

WORKDIR /app
COPY . /app

ENTRYPOINT [ "/app/entrypoint.sh" ]
