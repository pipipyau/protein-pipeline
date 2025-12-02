# CUDA + Ubuntu база (пример: CUDA 12.4)
FROM nvidia/cuda:12.4.0-runtime-ubuntu22.04

# Python 3.11
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y python3.11 python3.11-distutils python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app/abcfold
COPY . /app/abcfold

RUN pip3 install --upgrade pip && pip3 install .

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
