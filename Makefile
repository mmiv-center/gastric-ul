build: entrypoint.sh Dockerfile
	docker build --no-cache -t gastric_ul:latest -f Dockerfile .

up:
	docker run --rm -it -v /Users/haukebartsch/src/GASTRIC_UL/data:/data -v /tmp/output:/output --entrypoint /bin/bash gastric_ul:latest
