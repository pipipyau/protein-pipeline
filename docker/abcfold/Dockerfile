FROM nvidia/cuda:12.4.0-runtime-ubuntu22.04

# Python 3.11
RUN apt-get update && \
    apt-get install -y python3.11 python3.11-distutils python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN python3.11 -m pip install abcfold

COPY ./utils/add_msa_to_json.py /app/add_msa_to_json.py
WORKDIR /app

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
