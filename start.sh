#!/bin/bash
show_help() {
    cat << EOF
Usage: ./start.sh [options]

Options:
  -h, --help       Показать это сообщение и выйти

Описание:
  Этот скрипт автоматизирует биоинформатический пайплайн, включая запуск контейнеров,
  конвертацию входных данных, структурное моделирование, молекулярный докинг, оценку взаимодействий
  и экспорт результатов.

Структура директорий:
  data/
  ├── input/                        # Входные данные для обработки
  │   ├── ligand/                   # Структуры лигандов (FASTA)
  │   └── receptor/                 # Структуры рецепторов (FASTA)
  └── output/
      ├── alphafold3/               # Результаты от AlphaFold3 (PDB)
      │   ├── ligand/
      │   └── receptor/
      ├── megadock/                 # Результаты от Megadock (PDB)
      └── prodigy/                  # Результаты от Prodigy (txt, csv)

Операции скрипта:
  1. Запускает Docker-контейнеры с помощью docker-compose.
  2. Ожидает 10 секунд для инициализации контейнеров.
  3. Конвертирует входные FASTA-файлы в JSON (fasta2json).
  4. Выполняет структурное моделирование с помощью AlphaFold3 (лиганды и рецепторы).
  5. Конвертирует результаты AlphaFold3 из CIF в PDB (cif2pdb).
  6. Выполняет docking с помощью Megadock.
  7. Запускает анализ взаимодействий с помощью Prodigy.
  8. Парсит результаты Prodigy и экспортирует их в CSV.
  9. Останавливает контейнеры.

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
python utils/fasta2json.py data/input

echo "ABCFold for ligand..."
docker exec alphafold3_container abcfold /root/af_input/ligand  /root/af_output/ligand -abc --mmseqs2 --model_params /root/models

echo "Alphafold3 for ligand..."
docker exec alphafold3_container python run_alphafold.py --input_dir=/root/af_input/ligand --model_dir=/root/models --output_dir=/root/af_output/ligand

echo "ABCFold for receptor..."
docker exec alphafold3_container abcfold /root/af_input/receptor  /root/af_output/receptor -abc --mmseqs2 --model_params /root/models

echo "Alphafold3 for receptor..."
docker exec alphafold3_container python run_alphafold.py --input_dir=/root/af_input/receptor --model_dir=/root/models --output_dir=/root/af_output/receptor

echo "Run cif2pdb conversion..."
python utils/cif2pdb.py data/output/alphafold3

echo "Run Megadock..."
docker exec megadock_container ./run_multi_megadock.sh

echo "Run Prodigy..."
docker exec prodigy_container ./run_prodigy.sh

echo "Parsing Prodigy..."
docker exec prodigy_container python analyze.py

echo "Done."

docker-compose down
