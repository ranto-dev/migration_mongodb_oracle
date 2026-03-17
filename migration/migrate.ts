import pkg from "mongodb";
const { MongoClient, WithId } = pkg;
import oracledb from "oracledb";
import dotenv from "dotenv";

dotenv.config();

type MongoDoc = { [key: string]: any };

function mapType(value: any): string {
  if (typeof value === "string") return "VARCHAR2(255)";
  if (typeof value === "number") return "NUMBER";
  if (value instanceof Date) return "DATE";
  if (typeof value === "boolean") return "NUMBER(1)";
  return "CLOB"; // pour objets ou autres
}

function normalizeValue(value: any): any {
  if (value === null || value === undefined) return null;
  if (value instanceof Date) return value;
  if (typeof value === "boolean") return value ? 1 : 0;
  if (typeof value === "object") return JSON.stringify(value);
  return value;
}

async function migrateDynamic() {
  const mongoClient = new MongoClient(process.env.MONGO_URI!);
  await mongoClient.connect();
  const db = mongoClient.db();

  await oracledb.createPool({
    user: process.env.ORACLE_USER,
    password: process.env.ORACLE_PASSWORD,
    connectionString: process.env.ORACLE_CONNECTIONSTRING,
    poolMin: 1,
    poolMax: 5,
  });

  const conn = await oracledb.getConnection();

  try {
    const collections = await db.listCollections().toArray();

    for (const col of collections) {
      const colName = col.name;
      const docs: WithId<MongoDoc>[] = await db
        .collection(colName)
        .find()
        .toArray();
      if (docs.length === 0) continue;

      // --- Créer table dynamique ---
      const firstDoc = docs[0];
      const columns = Object.keys(firstDoc).map((k) => {
        const type = k === "_id" ? "VARCHAR2(24)" : mapType(firstDoc[k]);
        return `"${k}" ${type}`;
      });

      const createSql = `BEGIN
                           EXECUTE IMMEDIATE 'CREATE TABLE "${colName}" (${columns.join(", ")})';
                         EXCEPTION
                           WHEN OTHERS THEN
                             IF SQLCODE != -955 THEN RAISE; END IF;
                         END;`;

      await conn.execute(createSql);

      // --- Préparer executeMany ---
      const keys = Object.keys(firstDoc);
      const sql = `INSERT INTO "${colName}" (${keys.map((k) => `"${k}"`).join(", ")})
                   VALUES (${keys.map((k) => `:${k}`).join(", ")})`;

      const bindsArray = docs.map((doc) => {
        const bindObj: any = {};
        keys.forEach((k) => {
          if (k === "_id") bindObj[k] = doc[k].toString();
          else bindObj[k] = normalizeValue(doc[k]);
        });
        return bindObj;
      });

      console.log(
        `🚀 Insertion de ${docs.length} lignes dans ${colName.toUpperCase()}...`,
      );
      await conn.executeMany(sql, bindsArray);
    }

    await conn.commit();
    console.log("✅ Migration dynamique terminée !");
  } catch (err) {
    console.error("❌ Erreur de migration :", err);
  } finally {
    await mongoClient.close();
    await conn.close();
    await oracledb.getPool().close();
  }
}

migrateDynamic();
