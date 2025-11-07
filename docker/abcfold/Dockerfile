FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y \
    python3.11 python3.11-venv python3-pip git wget mmseqs2 \
    && rm -rf /var/lib/apt/lists/*

RUN python3.11 -m venv /opt/abcfold_venv
ENV PATH="/opt/abcfold_venv/bin:$PATH"

RUN python -m pip install abcfold

WORKDIR /app
