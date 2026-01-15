// =====================================================
// Demo seed: Ecommerce ETL lineage (SFCC) + teams + light column lineage
// =====================================================

// ---------------------------
// Constraints (idempotent)
// ---------------------------
CREATE CONSTRAINT team_name IF NOT EXISTS
FOR (t:Team) REQUIRE t.name IS UNIQUE;

CREATE CONSTRAINT job_name IF NOT EXISTS
FOR (j:Job) REQUIRE j.name IS UNIQUE;

CREATE CONSTRAINT dataset_name IF NOT EXISTS
FOR (d:Dataset) REQUIRE d.name IS UNIQUE;

CREATE CONSTRAINT dashboard_name IF NOT EXISTS
FOR (b:Dashboard) REQUIRE b.name IS UNIQUE;

CREATE CONSTRAINT column_key IF NOT EXISTS
FOR (c:Column) REQUIRE c.key IS UNIQUE;

// ---------------------------
// Teams
// ---------------------------
MERGE (:Team {name: "Data"});
MERGE (:Team {name: "Finance"});
MERGE (:Team {name: "Operations"});

// ---------------------------
// Datasets (SFCC -> raw -> staging -> warehouse -> mart)
// ---------------------------

// Raw (source of truth: SFCC)
MERGE (:Dataset {name: "raw.sfcc_orders", system: "SFCC", layer: "raw", aliases: ["sfcc orders", "orders feed"]});
MERGE (:Dataset {name: "raw.sfcc_customers", system: "SFCC", layer: "raw", aliases: ["sfcc customers", "customers feed"]});

// Staging
MERGE (:Dataset {name: "stg_orders", system: "warehouse", layer: "staging", aliases: ["staging orders"]});
MERGE (:Dataset {name: "stg_customers", system: "warehouse", layer: "staging", aliases: ["staging customers"]});

// Warehouse (dims/facts)
MERGE (:Dataset {name: "dim_customer", system: "warehouse", layer: "warehouse", aliases: ["customer dim"]});
MERGE (:Dataset {name: "fact_orders", system: "warehouse", layer: "warehouse", aliases: ["orders fact"]});

// Mart (business-ready)
MERGE (:Dataset {name: "mart_daily_sales", system: "warehouse", layer: "mart", aliases: ["daily sales mart", "sales mart"]});

// ---------------------------
// Jobs (pipelines/transforms)
// ---------------------------

// Ingest SFCC raw
MERGE (:Job {name: "ingest_sfcc_orders", schedule: "hourly", tool: "S3->Warehouse"});
MERGE (:Job {name: "ingest_sfcc_customers", schedule: "daily", tool: "S3->Warehouse"});

// Transform raw -> staging
MERGE (:Job {name: "transform_stg_orders", schedule: "hourly", tool: "SQL"});
MERGE (:Job {name: "transform_stg_customers", schedule: "daily", tool: "SQL"});

// Build warehouse tables
MERGE (:Job {name: "build_dim_customer", schedule: "daily", tool: "SQL"});
MERGE (:Job {name: "build_fact_orders", schedule: "hourly", tool: "SQL"});

// Build mart
MERGE (:Job {name: "build_mart_daily_sales", schedule: "daily", tool: "SQL"});

// ---------------------------
// Dashboards
// ---------------------------
MERGE (:Dashboard {name: "Sales Overview", tool: "Looker", aliases: ["sales dashboard", "daily sales dashboard"]});
MERGE (:Dashboard {name: "Order Operations", tool: "Looker", aliases: ["ops dashboard", "order ops dashboard"]});

// ---------------------------
// Ownership & usage
// ---------------------------

// Data team owns all jobs + datasets (simple demo assumption)
MATCH (data:Team {name:"Data"})
MATCH (j:Job)
MERGE (data)-[:OWNS]->(j);

MATCH (data:Team {name:"Data"})
MATCH (d:Dataset)
MERGE (data)-[:OWNS]->(d);

// Dashboards feed Finance and Operations
MATCH (fin:Team {name:"Finance"}), (ops:Team {name:"Operations"})
MATCH (sales:Dashboard {name:"Sales Overview"}), (orderOps:Dashboard {name:"Order Operations"})
MERGE (fin)-[:USES]->(sales)
MERGE (ops)-[:USES]->(orderOps);

// ---------------------------
// Lineage (READS / WRITES)
// ---------------------------

// Ingest writes raw
MATCH (j:Job {name:"ingest_sfcc_orders"}), (d:Dataset {name:"raw.sfcc_orders"})
MERGE (j)-[:WRITES]->(d);

MATCH (j:Job {name:"ingest_sfcc_customers"}), (d:Dataset {name:"raw.sfcc_customers"})
MERGE (j)-[:WRITES]->(d);

// raw -> staging
MATCH (j:Job {name:"transform_stg_orders"}),
      (raw:Dataset {name:"raw.sfcc_orders"}),
      (stg:Dataset {name:"stg_orders"})
MERGE (j)-[:READS]->(raw)
MERGE (j)-[:WRITES]->(stg);

MATCH (j:Job {name:"transform_stg_customers"}),
      (raw:Dataset {name:"raw.sfcc_customers"}),
      (stg:Dataset {name:"stg_customers"})
MERGE (j)-[:READS]->(raw)
MERGE (j)-[:WRITES]->(stg);

// staging -> warehouse
MATCH (j:Job {name:"build_dim_customer"}),
      (stg:Dataset {name:"stg_customers"}),
      (dim:Dataset {name:"dim_customer"})
MERGE (j)-[:READS]->(stg)
MERGE (j)-[:WRITES]->(dim);

MATCH (j:Job {name:"build_fact_orders"}),
      (stg:Dataset {name:"stg_orders"}),
      (dim:Dataset {name:"dim_customer"}),
      (fact:Dataset {name:"fact_orders"})
MERGE (j)-[:READS]->(stg)
MERGE (j)-[:READS]->(dim)
MERGE (j)-[:WRITES]->(fact);

// warehouse -> mart
MATCH (j:Job {name:"build_mart_daily_sales"}),
      (fact:Dataset {name:"fact_orders"}),
      (mart:Dataset {name:"mart_daily_sales"})
MERGE (j)-[:READS]->(fact)
MERGE (j)-[:WRITES]->(mart);

// dashboards read mart
MATCH (sales:Dashboard {name:"Sales Overview"}), (mart:Dataset {name:"mart_daily_sales"})
MERGE (sales)-[:READS]->(mart);

MATCH (opsDash:Dashboard {name:"Order Operations"}), (fact:Dataset {name:"fact_orders"})
MERGE (opsDash)-[:READS]->(fact);

// ---------------------------
// Light column lineage (orders + customers only)
// ---------------------------

// Columns use a stable key: "<dataset>.<column>"
MERGE (:Column {key:"raw.sfcc_orders.order_total", name:"order_total", dataset:"raw.sfcc_orders", aliases:["order total"]});
MERGE (:Column {key:"raw.sfcc_orders.order_status", name:"order_status", dataset:"raw.sfcc_orders", aliases:["status"]});
MERGE (:Column {key:"raw.sfcc_orders.customer_id", name:"customer_id", dataset:"raw.sfcc_orders", aliases:["cust id"]});

MERGE (:Column {key:"raw.sfcc_customers.customer_id", name:"customer_id", dataset:"raw.sfcc_customers", aliases:["cust id"]});
MERGE (:Column {key:"raw.sfcc_customers.email", name:"email", dataset:"raw.sfcc_customers", aliases:["email"]});

MERGE (:Column {key:"dim_customer.customer_id", name:"customer_id", dataset:"dim_customer"});
MERGE (:Column {key:"dim_customer.email", name:"email", dataset:"dim_customer"});

MERGE (:Column {key:"fact_orders.gross_revenue", name:"gross_revenue", dataset:"fact_orders", aliases:["gross revenue"]});
MERGE (:Column {key:"mart_daily_sales.daily_revenue", name:"daily_revenue", dataset:"mart_daily_sales", aliases:["daily revenue"]});

// Attach columns to datasets
MATCH (d:Dataset {name:"raw.sfcc_orders"}), (c:Column)
WHERE c.dataset = "raw.sfcc_orders"
MERGE (d)-[:HAS_COLUMN]->(c);

MATCH (d:Dataset {name:"raw.sfcc_customers"}), (c:Column)
WHERE c.dataset = "raw.sfcc_customers"
MERGE (d)-[:HAS_COLUMN]->(c);

MATCH (d:Dataset {name:"dim_customer"}), (c:Column)
WHERE c.dataset = "dim_customer"
MERGE (d)-[:HAS_COLUMN]->(c);

MATCH (d:Dataset {name:"fact_orders"}), (c:Column)
WHERE c.dataset = "fact_orders"
MERGE (d)-[:HAS_COLUMN]->(c);

MATCH (d:Dataset {name:"mart_daily_sales"}), (c:Column)
WHERE c.dataset = "mart_daily_sales"
MERGE (d)-[:HAS_COLUMN]->(c);

// Column derivations
// dim_customer.email derived from raw.sfcc_customers.email
MATCH (src:Column {key:"raw.sfcc_customers.email"}),
      (dst:Column {key:"dim_customer.email"})
MERGE (dst)-[:DERIVED_FROM]->(src);

// fact_orders.gross_revenue derived from raw.sfcc_orders.order_total
MATCH (src:Column {key:"raw.sfcc_orders.order_total"}),
      (dst:Column {key:"fact_orders.gross_revenue"})
MERGE (dst)-[:DERIVED_FROM]->(src);

// mart_daily_sales.daily_revenue derived from fact_orders.gross_revenue
MATCH (src:Column {key:"fact_orders.gross_revenue"}),
      (dst:Column {key:"mart_daily_sales.daily_revenue"})
MERGE (dst)-[:DERIVED_FROM]->(src);
