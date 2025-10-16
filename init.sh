#!/bin/bash
show_help() {
    cat << EOF
Usage: ./start.sh [options]

Options:
  -h, --help       Show this help message and exit

Description:
  Этот скрипт останавливает контейнеры и пересобирает их.

Пример запуска:
  ./init.sh
EOF
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

docker-compose down
docker-compose build
