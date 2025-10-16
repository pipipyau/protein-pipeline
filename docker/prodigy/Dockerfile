FROM python:3.9

RUN apt update
RUN apt install dos2unix
RUN pip install --no-cache-dir prodigy-prot pandas

COPY ./../../utils/run_prodigy.sh /app/run_prodigy.sh
RUN chmod +x /app/run_prodigy.sh
RUN dos2unix /app/run_prodigy.sh

COPY ./../../utils/analyze.py /app/analyze.py
WORKDIR /app