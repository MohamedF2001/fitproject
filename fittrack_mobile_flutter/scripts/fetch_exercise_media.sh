#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="${SCRIPT_DIR}/../assets/exercises"

mkdir -p "${ASSETS_DIR}"

BASE_URL="https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises"

# Tableau de correspondance : <id_fittrack>:<folder_free_exercise_db>
MAPPINGS=(
  "pec-001:Barbell_Bench_Press_-_Medium_Grip"
  "pec-002:Pushups"
  "pec-003:Dumbbell_Flyes"
  "dos-001:Pullups"
  "dos-002:Bent_Over_Barbell_Row"
  "dos-003:Wide-Grip_Lat_Pulldown"
  "jam-001:Barbell_Squat"
  "jam-002:Dumbbell_Lunges"
  "jam-003:Leg_Press"
  "epa-001:Standing_Military_Press"
  "epa-002:Side_Lateral_Raise"
  "bra-001:Dumbbell_Bicep_Curl"
  "bra-002:Triceps_Pushdown"
  "abd-001:Crunches"
  "abd-002:Plank"
)

echo "Téléchargement des photos d'exercices depuis free-exercise-db..."

for entry in "${MAPPINGS[@]}"; do
  id="${entry%%:*}"
  folder="${entry#*:}"

  for idx in 0 1; do
    out_file="${ASSETS_DIR}/${id}_${idx}.jpg"
    url="${BASE_URL}/${folder}/${idx}.jpg"
    echo "  ${id}_${idx}.jpg <- ${url}"
    curl -fsSL "${url}" -o "${out_file}"
  done
done

echo "Téléchargement terminé avec succès (30 photos)."
