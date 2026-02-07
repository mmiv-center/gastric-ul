# Convert mp4 and xml into DICOM

Create the docker container with:

```
docker build --no-cache -t gastric_ul:latest -f Dockerfile .
```

Run the conversion of a single pair of mp4 and xml files:

```
docker run --rm -it -v $(pwd)/data:/data gastric_ul:latest /data/test.mp4 /data/test.xml /data/test_dicoms.zip
```

