#!/bin/bash

# Configuration
CONTAINER_NAME="oracle-xe"
ORACLE_USER="system"
ORACLE_PASS="oraclepass"
EXPORT_DIR="mongo_exports"

echo "🚀 Début de la migration vers Oracle XE..."

# 1. Copier les fichiers JSON dans le conteneur pour qu'Oracle puisse y accéder
docker exec $CONTAINER_NAME mkdir -p /opt/oracle/scripts/json_data
docker cp ./$EXPORT_DIR/. $CONTAINER_NAME:/opt/oracle/scripts/json_data/

# 2. Exécuter le script SQL via SQL*Plus dans le conteneur
docker exec -i $CONTAINER_NAME sqlplus -s $ORACLE_USER/$ORACLE_PASS <<'EOF'

-- Suppression des tables si elles existent (pour repartir à zéro)
DROP TABLE TASKS CASCADE CONSTRAINTS;
DROP TABLE DEALS CASCADE CONSTRAINTS;
DROP TABLE CONTACTS CASCADE CONSTRAINTS;
DROP TABLE CLIENTS CASCADE CONSTRAINTS;
DROP TABLE USERS CASCADE CONSTRAINTS;

-- Création des tables
CREATE TABLE CLIENTS (
    ID NUMBER PRIMARY KEY,
    NAME VARCHAR2(100),
    EMAIL VARCHAR2(100),
    PHONE VARCHAR2(20)
);

CREATE TABLE CONTACTS (
    ID VARCHAR2(50) PRIMARY KEY,
    NAME VARCHAR2(100),
    EMAIL VARCHAR2(100),
    CLIENT_ID NUMBER REFERENCES CLIENTS(ID)
);

CREATE TABLE DEALS (
    ID VARCHAR2(50) PRIMARY KEY,
    TITLE VARCHAR2(100) UNIQUE,
    AMOUNT NUMBER,
    CLIENT_ID NUMBER REFERENCES CLIENTS(ID),
    STATUS VARCHAR2(20)
);

CREATE TABLE TASKS (
    ID VARCHAR2(50) PRIMARY KEY,
    TITLE VARCHAR2(100),
    DESCRIPTION VARCHAR2(200),
    DEAL_TITLE VARCHAR2(100) REFERENCES DEALS(TITLE),
    DUE_DATE TIMESTAMP
);

CREATE TABLE USERS (
    ID VARCHAR2(50) PRIMARY KEY,
    USERNAME VARCHAR2(50),
    EMAIL VARCHAR2(100),
    ROLE VARCHAR2(20)
);

-- Utilisation des tables externes ou chargement direct via BFILE/JSON_TABLE
-- Pour simplifier, nous allons charger les fichiers via JSON_TABLE
-- Nous créons une table temporaire pour charger le contenu du fichier

CREATE TABLE JSON_LOAD_TEMP (json_content CLOB);

-- Fonction pour charger un fichier JSON
DECLARE
    PROCEDURE load_json(p_file VARCHAR2, p_table VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE 'DELETE FROM JSON_LOAD_TEMP';
        -- On charge le fichier dans la table temporaire
        EXECUTE IMMEDIATE 'INSERT INTO JSON_LOAD_TEMP (json_content) VALUES (get_clob_from_file(''' || p_file || '''))';
    END;
BEGIN
    NULL;
END;
/

-- NOTE: Pour cet exercice, on utilise une insertion directe simplifiée pour Oracle 21c
-- Insertion des CLIENTS
INSERT INTO CLIENTS (ID, NAME, EMAIL, PHONE)
SELECT jt.* FROM JSON_TABLE(bfilename('JSON_DIR', 'clients.json'), '$[*]' 
    COLUMNS (ID NUMBER PATH '$._id', NAME VARCHAR2 PATH '$.name', EMAIL VARCHAR2 PATH '$.email', PHONE VARCHAR2 PATH '$.phone')) jt;

-- Insertion des CONTACTS
INSERT INTO CONTACTS (ID, NAME, EMAIL, CLIENT_ID)
SELECT jt.* FROM JSON_TABLE(bfilename('JSON_DIR', 'contacts.json'), '$[*]' 
    COLUMNS (
        ID VARCHAR2 PATH '$._id."$oid"', 
        NAME VARCHAR2 PATH '$.name', 
        EMAIL VARCHAR2 PATH '$.email', 
        CLIENT_ID NUMBER PATH '$.client_id'
    )) jt;

-- Insertion des DEALS
INSERT INTO DEALS (ID, TITLE, AMOUNT, CLIENT_ID, STATUS)
SELECT jt.* FROM JSON_TABLE(bfilename('JSON_DIR', 'deals.json'), '$[*]' 
    COLUMNS (
        ID VARCHAR2 PATH '$._id."$oid"', 
        TITLE VARCHAR2 PATH '$.title', 
        AMOUNT NUMBER PATH '$.amount', 
        CLIENT_ID NUMBER PATH '$.client_id', 
        STATUS VARCHAR2 PATH '$.status'
    )) jt;

-- Insertion des TASKS
INSERT INTO TASKS (ID, TITLE, DESCRIPTION, DEAL_TITLE, DUE_DATE)
SELECT jt.* FROM JSON_TABLE(bfilename('JSON_DIR', 'tasks.json'), '$[*]' 
    COLUMNS (
        ID VARCHAR2 PATH '$._id."$oid"', 
        TITLE VARCHAR2 PATH '$.title', 
        DESCRIPTION VARCHAR2 PATH '$.description', 
        DEAL_TITLE VARCHAR2 PATH '$.deal_title', 
        DUE_DATE TIMESTAMP PATH '$.due_date'
    )) jt;

-- Insertion des USERS
INSERT INTO USERS (ID, USERNAME, EMAIL, ROLE)
SELECT jt.* FROM JSON_TABLE(bfilename('JSON_DIR', 'users.json'), '$[*]' 
    COLUMNS (
        ID VARCHAR2 PATH '$._id."$oid"', 
        USERNAME VARCHAR2 PATH '$.username', 
        EMAIL VARCHAR2 PATH '$.email', 
        ROLE VARCHAR2 PATH '$.role'
    )) jt;

COMMIT;
EXIT;
EOF

echo "✅ Migration terminée !"