#!/bin/bash

# 🚀 Script pour exporter les collections MongoDB en JSON
# Assure-toi que MongoDB est en cours d'exécution

MONGO_CONTAINER="mongo7"
DB_NAME="crmDB"
EXPORT_DIR="./mongo_exports"

# Crée le dossier d'export si nécessaire
mkdir -p "$EXPORT_DIR"

# Liste des collections à exporter
collections=("users" "clients" "contacts" "deals" "tasks")

for col in "${collections[@]}"; do
    echo "📦 Export de la collection $col ..."
    docker exec "$MONGO_CONTAINER" mongoexport \
        --db="$DB_NAME" \
        --collection="$col" \
        --out="/tmp/$col.json" \
        --jsonArray

    # Copie le fichier JSON depuis le container vers le dossier local
    docker cp "$MONGO_CONTAINER:/tmp/$col.json" "$EXPORT_DIR/$col.json"
done

echo "✅ Toutes les collections ont été exportées dans $EXPORT_DIR"./