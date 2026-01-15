// -----------------------------------------
// Query 1: Basic ETL flow
// -----------------------------------------
// Shows how jobs read from and write to datasets
// across the pipeline.
MATCH (j:Job)-[:READS|WRITES]->(d:Dataset)
RETURN j, d;


// -----------------------------------------
// Query 2: Downstream impact from raw.sfcc_orders
// -----------------------------------------
// If the SFCC orders feed changes, this shows
// which jobs and datasets are directly affected.
MATCH (raw:Dataset {name: "raw.sfcc_orders"})
MATCH (raw)<-[:READS]-(j:Job)-[:WRITES]->(downstream:Dataset)
RETURN j.name AS job, downstream.name AS affected_dataset;


// -----------------------------------------
// Query 3: Dashboards using a dataset
// -----------------------------------------
// Lists dashboards that read from fact_orders.
MATCH (d:Dataset {name: "fact_orders"})
MATCH (dash:Dashboard)-[:READS]->(d)
RETURN dash.name AS dashboard;


// -----------------------------------------
// Query 4: Upstream lineage for a mart
// -----------------------------------------
// Shows which datasets feed into mart_daily_sales.
MATCH (mart:Dataset {name: "mart_daily_sales"})
MATCH (mart)<-[:WRITES]-(j:Job)-[:READS]->(upstream:Dataset)
RETURN j.name AS job, upstream.name AS source_dataset;


// -----------------------------------------
// Query 5: Teams impacted by a dataset
// -----------------------------------------
// Shows which teams are affected when a dataset
// feeds dashboards they use.
MATCH (d:Dataset {name: "fact_orders"})
MATCH (dash:Dashboard)-[:READS]->(d)
MATCH (team:Team)-[:USES]->(dash)
RETURN DISTINCT team.name AS impacted_team, dash.name AS dashboard;
