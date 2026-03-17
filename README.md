# Migration - MongoDB vers Oracle

## Setup

```bash
# Pull de l'image Oracle XE
sudo docker pull gvenzl/oracle-xe:21

# Pull de l'image MongoDB
sudo docker pull mongo:7

# Lister les processus
sudo docker ps
sudo docker ps -a
```

## Setup MongoDB

```yml
version: "3"

services:
  mongo:
    image: mongo:7
    container_name: mongo7
    restart: always
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_DATABASE: crmDB
    volumes:
      - mongo-data:/data/db
      - ./data:/data/import
```

Accédez à `mongosh` :

```bash
sudo docker exec -it mongo7 mongosh
```

Lancer le script pour construire la base de données :

```bash
# Donner la permission d'exécution au script
sudo chmod +x mongosh.sh

# Lancer le script
./mongosh.sh
```

## Setup Oracle

```bash
# Lancer un conteneur Oracle XE
docker run -d --name oracle-xe \
  -p 1521:1521 -p 5500:5500 \
  -e ORACLE_PASSWORD=oraclepass \
  gvenzl/oracle-xe:21

docker exec -it oracle-xe sqlplus system/oraclepass@XE
```

Note : créer un répertoire dans le conteneur Docker

```bash
docker exec -i oracle-xe sqlplus system/oraclepass <<EOF
CREATE OR REPLACE DIRECTORY JSON_DIR AS '/opt/oracle/scripts/json_data';
-- GRANT READ, WRITE ON DIRECTORY JSON_DIR TO system;
EXIT;
EOF
```

On exporte d’abord en JSON les données présentes dans MongoDB :

```bash
# Donner la permission d'exécution au script
sudo chmod +x export_mongo.sh

# Ensuite, exécuter le script
./export_mongo.sh
```

Enfin, on peut passer à la migration des données :

```bash
# Donner la permission d'exécution au script
sudo chmod +x migrate_to_oracle.sh

# Ensuite, exécuter le script
./migrate_to_oracle.sh
```

## Vérification sur AuraAPI

On peut tester l’intégrité des données via une API REST.

```bash
# Lancer l'API
cd api && cargo run
```

Les différentes routes disponibles sont les suivantes :

| Table        | Route API       | Description                                     |
| :----------- | :-------------- | :---------------------------------------------- |
| **Clients**  | `/api/clients`  | Liste des entreprises clientes                  |
| **Contacts** | `/api/contacts` | Liste des personnes physiques liées aux clients |
| **Deals**    | `/api/deals`    | Opportunités commerciales                       |
| **Tasks**    | `/api/tasks`    | Actions à effectuer sur les deals               |
| **Users**    | `/api/users`    | Utilisateurs (Sales, Managers) de l'application |
