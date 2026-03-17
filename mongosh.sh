#!/bin/bash

MONGO_CONTAINER="mongo7"
DB_NAME="crmDB"

echo "🚀 Importation des fichiers JSON dans MongoDB container '$MONGO_CONTAINER'..."

# Supprimer la base si existante
docker exec -i $MONGO_CONTAINER mongosh $DB_NAME --eval "db.dropDatabase();"
echo "✅ Base $DB_NAME supprimée si existante."

# Liste des collections et fichiers
collections=("users" "clients" "contacts" "deals" "tasks")

for collection in "${collections[@]}"
do
  FILE="/data/import/$collection.json"
  docker exec -i mongo7 mongoimport \
    --db crmDB \
    --collection "$collection" \
    --file "$FILE" \
    --jsonArray
done

echo "🎉 Base de données '$DB_NAME' prête avec toutes les collections et données !"