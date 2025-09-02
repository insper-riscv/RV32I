# Minimal, portable sim image (works on amd64/arm64)
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Python, GHDL, GTKWave, build tools
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv \
    make git pkg-config \
    gnat ghdl \
    gtkwave \
 && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --upgrade pip && \
    pip3 install --no-cache-dir -r /tmp/requirements.txt

# Non-root dev user (used later by Dev Container; in CI we'll override to root)
RUN useradd -ms /bin/bash dev
USER dev
WORKDIR /work
