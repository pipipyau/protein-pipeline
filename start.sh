#!/bin/bash

echo "Starting containers..."
docker-compose up -d

sleep 10

echo "Run Megadock..."
docker exec megadock_container ./run_multi_megadock.sh

echo "Run Prodigy..."
docker exec prodigy_container ./run_prodigy.sh

echo "Parsing Prodigy..."
docker exec prodigy_container python analyze.py

echo "Done."

docker-compose down