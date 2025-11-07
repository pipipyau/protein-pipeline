# Copyright 2024 DeepMind Technologies Limited
#
# AlphaFold 3 source code is licensed under CC BY-NC-SA 4.0. To view a copy of
# this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
#
# To request access to the AlphaFold 3 model parameters, follow the process set
# out at https://github.com/google-deepmind/alphafold3. You may only use these
# if received directly from Google. Use is subject to terms of use available at
# https://github.com/google-deepmind/alphafold3/blob/main/WEIGHTS_TERMS_OF_USE.md

FROM nvidia/cuda:12.6.3-base-ubuntu24.04

# Some RUN statements are combined together to make Docker build run faster.
# Get latest package listing, install python, git, wget, compilers and libs.
# * git is required for pyproject.toml toolchain's use of CMakeLists.txt.
# * gcc, g++, make are required for compiling HMMER and AlphaFold 3 libaries.
# * zlib is a required dependency of AlphaFold 3.
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update --quiet \
    && apt-get install --yes --quiet python3.12 python3-pip python3.12-venv python3.12-dev \
    && apt-get install --yes --quiet git wget gcc g++ make zlib1g-dev zstd

# The base image uses Python 3.12. For local installation use 3.11 or greater.
RUN python3 -m venv /alphafold3_venv
ENV PATH="/hmmer/bin:/alphafold3_venv/bin:$PATH"
# Update pip to the latest version. Not necessary in Docker, but good to do when
# this is used as a recipe for local installation since we rely on new pip
# features for secure installs.
RUN pip3 install --no-cache-dir --upgrade pip

# Install HMMER. Do so before copying the source code, so that docker can cache
# the image layer containing HMMER. Alternatively, you could also install it
# using `apt-get install hmmer` instead of bulding it from source, but we want
# to have control over the exact version of HMMER and also apply the sequence
# limit patch. Also note that eddylab.org unfortunately doesn't support HTTPS
# and the tar file published on GitHub is explicitly not recommended to be used
# for building from source.

# Download, check hash, and extract the HMMER source code.
RUN mkdir /hmmer_build /hmmer ; \
    wget http://eddylab.org/software/hmmer/hmmer-3.4.tar.gz --directory-prefix /hmmer_build ; \
    (cd /hmmer_build && echo "ca70d94fd0cf271bd7063423aabb116d42de533117343a9b27a65c17ff06fbf3 hmmer-3.4.tar.gz" | sha256sum --check) && \
    (cd /hmmer_build && tar zxf hmmer-3.4.tar.gz && rm hmmer-3.4.tar.gz)

# Apply the --seq_limit patch to HMMER.
COPY docker/jackhmmer_seq_limit.patch /hmmer_build/
RUN (cd /hmmer_build && patch -p0 < jackhmmer_seq_limit.patch)

# Build HMMER.
RUN (cd /hmmer_build/hmmer-3.4 && ./configure --prefix /hmmer) ; \
    (cd /hmmer_build/hmmer-3.4 && make -j) ; \
    (cd /hmmer_build/hmmer-3.4 && make install) ; \
    (cd /hmmer_build/hmmer-3.4/easel && make install) ; \
    rm -R /hmmer_build

# Copy the AlphaFold 3 source code from the local machine to the container and
# set the working directory to there.
COPY . /app/alphafold
WORKDIR /app/alphafold

# Install setuptools (removed in Python 3.12) which some libraries still need.
# Then install the Python dependencies of AlphaFold 3.
RUN pip3 install --no-cache-dir setuptools \
    && pip3 install --no-cache-dir -r dev-requirements.txt \
    && pip3 install --no-cache-dir --no-deps .

# Build chemical components database (this binary was installed by pip).
RUN build_data

# To work around a known XLA issue causing the compilation time to greatly
# increase, the following environment variable setting XLA flags must be enabled
# when running AlphaFold 3. Note that if using CUDA capability 7 GPUs, it is
# necessary to set the following XLA_FLAGS value instead:
# ENV XLA_FLAGS="--xla_disable_hlo_passes=custom-kernel-fusion-rewriter"
# (no need to disable gemm in that case as it is not supported for such GPU).
ENV XLA_FLAGS="--xla_gpu_enable_triton_gemm=false"
# Memory settings used for folding up to 5,120 tokens on A100 80 GB.
ENV XLA_PYTHON_CLIENT_PREALLOCATE=true
ENV XLA_CLIENT_MEM_FRACTION=0.95

RUN python -m pip install abcfold