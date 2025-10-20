#!/bin/bash
show_help() {
    cat << EOF
Usage: ./start.sh [options]

Options:
  -h, --help       Show this help message and exit

Description:
  Этот скрипт запускает контейнеры с Megadock и Prodigy, выполняет последовательность
  расчётов, парсинг и экспорт результатов, а затем останавливает контейнеры.

Структура директорий:
  data/
  ├── input/                        # Входные данные для обработки
  |   ├── ligand/                   # Структуры лигандов
  |   └── receptor/                 # Структуры рецепторов
  └── output/
      ├── alphafold3/               # Результаты от Alphafold3 (PDB)
      │   ├── ligand/
      │   └── receptor/
      ├── megadock/                 # Результаты от Megadock (PDB)
      └── prodigy/                  # Результаты от Prodigy (txt, csv)

Операции скрипта:
  1. Запускает Docker-контейнеры с помощью docker-compose.
  2. Ожидает 10 секунд для их инициализации.
  3. Выполняет docking с помощью Megadock.
  4. Запускает Prodigy.
  5. Парсит результаты Prodigy и экспортирует их в csv.
  6. Останавливает контейнеры.

Пример запуска:
  ./start.sh
EOF
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

echo "Starting containers..."
docker-compose up -d

sleep 10

echo "Run fasta2json conversion..."
python3 utils/fasta2json.py data/input
# TODO
# echo "Alphafold3 for ligand..."
# docker exec alphafold3_container python run_alphafold.py --json_path=/root/af_input/ligand/fold_input.json --model_dir=/root/models --output_dir=/root/af_output/ligand

# echo "Alphafold3 for receptor..."
# docker exec alphafold3_container python run_alphafold.py \
#     --json_path=/root/af_input/receptor/fold_input.json \
#     --model_dir=/root/models \
#     --output_dir=/root/af_output/receptor

echo "Run cif2pdb conversion..."
python3 utils/cif2pdb.py data/alphafold3/output

echo "Run Megadock..."
docker exec megadock_container ./run_multi_megadock.sh

echo "Run Prodigy..."
docker exec prodigy_container ./run_prodigy.sh

echo "Parsing Prodigy..."
docker exec prodigy_container python analyze.py

echo "Done."

docker-compose down
