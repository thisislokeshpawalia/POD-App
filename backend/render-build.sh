#!/usr/bin/env bash
# Install dependencies
pip install -r requirements.txt

# Download and install ffmpeg static build
wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
tar -xf ffmpeg-release-amd64-static.tar.xz
# Move ffmpeg binaries into our accessible path
cp ffmpeg-*-amd64-static/ffmpeg /usr/local/bin/
cp ffmpeg-*-amd64-static/ffprobe /usr/local/bin/
