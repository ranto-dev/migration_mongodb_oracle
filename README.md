# Migration - MongoDB to Oracle

## Oracle config with docker

```bash
docker run -d --name oracle-xe \
  -p 1521:1521 -p 5500:5500 \
  -e ORACLE_PASSWORD=oraclepass \
  gvenzl/oracle-xe:21

docker ps

docker exec -it oracle-xe sqlplus system/oraclepass@XE
```

## AuraAPI - les routes

| Table        | Route API       | Description                                     |
| :----------- | :-------------- | :---------------------------------------------- |
| **Clients**  | `/api/clients`  | Liste des entreprises clientes                  |
| **Contacts** | `/api/contacts` | Liste des personnes physiques liées aux clients |
| **Deals**    | `/api/deals`    | Opportunités commerciales                       |
| **Tasks**    | `/api/tasks`    | Actions à effectuer sur les deals               |
| **Users**    | `/api/users`    | Utilisateurs (Sales, Managers) de l'application |
