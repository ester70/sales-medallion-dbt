# sales_medallion_dbt

dbT wrap of the sales medallion pipeline: bronze -> silver -> gold star schema.

## Schemas (dbt_*)
The existing Spark Declarative Pipeline already publishes `main.bronze`,
`main.silver`, `main.gold`. This project writes to `main.dbt_bronze`,
`main.dbt_silver`, `main.dbt_gold` so both can coexist. To fully replace the
SDP pipeline: stop it, then change the `+schema` values in `dbt_project.yml`.

## Design decisions

- **Inserts** — `merge` on `transactionID` adds new rows.
- **Updates to existing rows** — each run compares the full source (no
  watermark), so a changed row is updated in place in bronze and flows through
  silver and fact_sales via merge.
- **Soft delete** — the bronze `post_hook` flips `is_active = false` for rows
  that no longer exist upstream. Rows are never physically deleted, so
  history stays queryable. If a row re-appears upstream, merge flips `is_active`
  back to true (resurrection handled automatically).
- **Time travel (“how the table looked 2 hours ago”)** — Delta Lake versioning,
  no dbt snapshots needed. Every dbt run creates a new Delta version, so with
  an hourly schedule:

  ```sql
  select * from main.dbt_silver.silver_sales_transactions_clean
  timestamp as of current_timestamp() - interval 2 hours
  where is_active = true;
  ```

  Delta retains only changed files plus the transaction log (default 30 days),
  which is far cheaper than dbt snapshot full-row copies.

## Setup (local run)

1. `pip install dbt-databricks`
2. `export DBT_TOKEN=<your Databricks personal access token>`
3. Fill `http_path` in `profiles.yml` (SQL Warehouses -> warehouse ->
   Connection details -> HTTP Path)
4. `dbt run` — builds bronze, silver, then the gold star schema

Note: when run as a Databricks Job dbt task, the profile is generated
automatically from job settings — `profiles.yml` is only needed for local runs.

## Scheduling for time travel
Run `dbt run` hourly (Databricks Job with a dbt task, or cron). Delta resolves
`TIMESTAMP AS OF` to the latest version at or before that moment, so an hourly
job gives hourly-restorable states.

## Tests
`dbt test` — not_null / unique / non_negative across all layers.

## DAG
```
source(samples.bakehouse.sales_transactions)
  -> bronze_sales_transactions   (incremental + merge + soft delete)
  -> silver_sales_transactions_clean (quality filters + is_active)
  -> dim_customer, dim_franchise, dim_product, dim_payment_method, dim_date
  -> fact_sales (star-schema center)
```
