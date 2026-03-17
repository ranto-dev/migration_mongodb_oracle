#

```bash
docker run -d --name oracle-xe \
  -p 1521:1521 -p 5500:5500 \
  -e ORACLE_PASSWORD=oraclepass \
  gvenzl/oracle-xe:21

docker ps

docker exec -it oracle-xe sqlplus system/oraclepass@XE
```
