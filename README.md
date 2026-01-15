# Neo4j ETL Lineage Demo (Ecommerce / SFCC)

This repository is a small Neo4j project created to get hands-on exposure to graph databases and Cypher by modeling a simplified ecommerce ETL lineage flow.

The graph represents how data moves from an SFCC storefront source through raw, staging, warehouse, and mart layers, and how that data ultimately feeds dashboards used by Finance and Operations. The focus is on understanding graph modeling, traversal, and common lineage/impact questions—not on building a production system.

---

## What this project demonstrates

- Basic graph modeling with Neo4j
- Using nodes and relationships to represent ETL pipelines
- Writing Cypher queries to answer common lineage questions:
  - What is impacted downstream if a source dataset changes?
  - Where does a business-facing mart get its data from?
  - Which dashboards and teams are affected by a dataset change?

---

## Seeded graph overview

### Node types
- **Team** – Data, Finance, Operations
- **Job** – ETL pipelines and transforms
- **Dataset** – Raw, staging, warehouse, and mart tables
- **Dashboard** – Business-facing dashboards
- **Column** – A small sample of order and customer fields

### Relationship types
- `(:Job)-[:READS]->(:Dataset)`
- `(:Job)-[:WRITES]->(:Dataset)`
- `(:Dashboard)-[:READS]->(:Dataset)`
- `(:Team)-[:OWNS]->(:Job|:Dataset)`
- `(:Team)-[:USES]->(:Dashboard)`
- `(:Column)-[:DERIVED_FROM]->(:Column)` (limited examples)

The Data team owns all pipelines and datasets. Finance and Operations consume data through dashboards.

---

## Running Neo4j

From the repo root:

```
docker compose up -d
```


Neo4j Browser will be available at:
```
http://localhost:7474
```


Bolt endpoint
```
bolt://localhost:7687
```

### Login

Default credentials (from docker-compose.yml):

Username: `neo4j`

Password: `password`


### Seeding the data
The seed file lives here:
```
seed/seed.cypher
```

The seed directory is mounted into the Neo4j container at:
```
/var/lib/neo4j/import
```

To seed the database manually:
```
docker exec -it neo4j-lineage-demo cypher-shell \
  -a bolt://localhost:7687 \
  -u neo4j \
  -p password \
  -f /var/lib/neo4j/import/seed.cypher
```

### Demo queries
Example Cypher queries are located in:
```
queries/demo_queries.cypher
```


These queries cover:

- Basic ETL flow visualization
- Downstream impact from a raw dataset
- Dashboard dependencies on datasets
- Upstream lineage for a mart
- Teams impacted by dataset changes
- Run them directly in Neo4j Browser.


### Notes

This project is intentionally small and focused. It exists as a learning exercise and a practical reference for discussing graph databases and lineage concepts, rather than as a full production implementation.