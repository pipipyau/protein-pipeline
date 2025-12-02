FROM nvidia/cuda:12.4.0-runtime-ubuntu22.04

# Python 3.11
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    tar \
    gzip \
    ca-certificates && \
    apt-get install -y python3.11 python3.11-distutils python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN python3.11 -m pip install abcfold

# Install MMseqs2
RUN wget https://mmseqs.com/latest/mmseqs-linux-avx2.tar.gz && \
    tar xzf mmseqs-linux-avx2.tar.gz && \
    mv mmseqs/bin/mmseqs /usr/local/bin/mmseqs && \
    chmod +x /usr/local/bin/mmseqs && \
    rm -rf mmseqs mmseqs-linux-avx2.tar.gz

RUN apt update
RUN apt install dos2unix rsync

COPY ./utils/add_msa_to_json.py /app/add_msa_to_json.py
COPY ./utils/setup_mmseqs_databases.sh /app/setup_mmseqs_databases.sh

RUN chmod +x /app/setup_mmseqs_databases.sh
RUN dos2unix /app/setup_mmseqs_databases.sh

WORKDIR /app

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
