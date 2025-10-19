# Data Engineering Project — dbt + Databricks + Medallion Architecture

---

## Table of Contents

- [Project Overview](#-project-overview)
- [Project Objectives](#-project-objectives)
- [Steps of Each Process](#-steps-of-each-process)
  - [1️⃣ Environment Setup](#1️⃣-environment-setup)
  - [2️⃣ DBT Extensions](#2️⃣-dbt-extensions)
  - [3️⃣ DBT Project Setup](#3️⃣-dbt-project-setup)
  - [4️⃣ DBT Source](#4️⃣-dbt-source)
  - [5️⃣ DBT Model](#5️⃣-dbt-model)
  - [6️⃣ DBT Test](#6️⃣-dbt-test)

---

## Project Overview
This project demonstrates an end-to-end data transformation pipeline using **dbt Core** with **Databricks** as the compute engine.  
It follows a **Medallion Architecture** approach — organizing data into **Bronze**, **Silver**, and **Gold** layers for better data quality, lineage, and reusability.

---

## Project Objectives
- Just want try

---

## Important dbt Files Overview

1. `macros/` Folder
    **Purpose:**  
    Macros in dbt are reusable SQL/Jinja functions — similar to functions in programming.  
    They allow us to define logic once and use it across multiple models or tests.

    **File in this project:**  
    `macros/generate_schema_name.sql`

    ```sql
    {% macro generate_schema_name(custom_schema_name, node) -%}

        {%- set default_schema = target.schema -%}
        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}

    {%- endmacro %}
    ```

    **Explanation:** 

    -   This macro controls how dbt decides which schema to create models in.

    -   If a model doesn’t specify a schema explicitly, it defaults to the one in our target (from our connection profile).

    -   Otherwise, it uses the provided custom schema name (e.g., `bronze`, `silver`, or `gold`).

    **Use case:** 
    Helps organize models by Medallion layer — ensuring `bronze` models go to the `bronze` schema, `silver` to `silver`, etc.

    **Reference:** [`DBT Macros Documentation`](https://docs.getdbt.com/docs/build/jinja-macros)
---
2. `properties.yml` (inside `models/bronze/`)

    **Purpose:**
    Defines **metadata**, **tests**, and **configurations** for our models and columns.
    It connects our SQL models (like **bronze_sales.sql**) with dbt tests and documentation.

    **Example:**

    ```ymal
    version: 2

    models:
    - name: bronze_sales
        columns:
        - name: sales_id
            tests:
            - unique
            - not_null

        - name: gross_amount
            tests:
            - generic_non_negative

    - name: bronze_dim_store
        columns:
        - name: store_sk
            tests:
            - unique
            - not_null
        - name: store_name
            tests:
            - accepted_values:
                values: ['MegaMart Manhattan', 'MegaMart Brooklyn', 'MegaMart Austin', 'MegaMart San Jose', 'MegaMart Toronto']
                config:
                    severity: warn
    ```
    **Explanation:**

    -   Each model (`bronze_sales`, `bronze_dim_store`) maps to a `.sql` file in the same folder.

    -   Column-level tests check for:

        -   Data uniqueness

        -   Null values

        -   Value validation (accepted list)

        -   Custom logic tests like `generic_non_negative`

    **Reference:** [`DBT Schema Tests`](https://docs.getdbt.com/docs/build/data-tests)

---

3. `sources.yml` (inside `models/source/`)

    **Purpose:**
    Registers raw data sources (e.g., tables or CSVs loaded into Databricks) so dbt can reference them safely using the `{{ source() }}` function.

    **Example:**

    ```ymal

    version: 2

    sources:
    - name: source
        description: "Raw data tables loaded from CSV files into Databricks"
        database: dbt_dev 
        schema: source
        tables:
        - name: fact_sales
            description: "Fact Table: Sales"
        - name: dim_store
            description: "Dimension Table: Store"
    ```

    **Usage in a model:**
    ```sql
    SELECT *
    FROM {{ source('source', 'fact_sales') }}
    ```
    
    **Explanation:**

    -   The first argument `source` refers to the `name` under sources:.

    -   The second argument `fact_sales` refers to the specific table name.

    -   This ensures dbt tracks lineage (we can see how data flows from `raw` → `bronze` → `silver` → `gold`).

    **Reference:** [`DBT Sources Documentation`](https://docs.getdbt.com/docs/build/sources)

---

4. `dbt_project.yml`

    **Purpose:**
    The main configuration file of our dbt project — defines the project structure, default behaviors, and environment paths.

    **Example:**

    ```ymal
    name: 'de_project_dbt'
    version: '1.0.0'
    profile: 'de_project_dbt'

    model-paths: ["models"]
    macro-paths: ["macros"]
    seed-paths: ["seeds"]

    clean-targets:
    - "target"
    - "dbt_packages"

    models:
    de_project_dbt:
        bronze:
        +materialized: table
        schema: bronze
        silver:
        +materialized: table
        schema: silver
        gold:
        +materialized: table
        schema: gold
    ```
    **Explanation:**

    -   `profile:` links this project to a profile defined in our `profiles.yml` (where connection credentials are stored).

    -   `model-paths`, `macro-paths`, etc. tell dbt where to find files.

    -   `clean-targets:` defines which folders are deleted by `dbt clean`.

    -   Under `models:`, each folder (bronze/silver/gold) specifies its materialization type and schema name.

    **Connection Context (for this project):**
    -   We are using Databricks Free Edition.
    -   Our profiles.yml (created automatically after dbt init) includes:

    ```ymal
    de_project_dbt:
        outputs:
            dev:
            type: databricks
            catalog: dbt_dev
            schema: bronze
            host: https://<your-workspace>.cloud.databricks.com
            http_path: /sql/1.0/warehouses/<warehouse-id>
            token: <your-personal-access-token>
        target: dev
    ```
    **Reference:** [`DBT Project Configuration`](https://docs.getdbt.com/reference/dbt_project.yml)

---

## Steps of Each Process

### 1️⃣ Environment Setup
_Set up local environment to run dbt with the Databricks Free Community Edition._

#### Step 1. Install Python and `uv`
1. Install [`uv`](https://github.com/astral-sh/uv) — a **fast Python package and virtual environment manager** (an alternative to `pip` and `venv`).
    ```bash
    pip install uv
    ```
    - `uv` is used in this project because:
        -   It creates and manages Python environments extremely fast (uv venv .venv).
        -   It installs packages (like dbt-core) quicker than pip using compiled wheels.
        -   It keeps dependencies clean and consistent across different machines.

2. Type `uv init` in terminal
    This will:
    - Generate a default pyproject.toml (like package.json for Python)
    - Create and activate a .venv
    - Set up a minimal structure for dependency managemen

3. Activate `Virtual Environment` using `Git Bash`
    ```bash
    source .venv/Scripts/activate
    ```

4. Add dbt Packages with uv - This command both installs the packages and automatically records them in `pyproject.toml` - so no longer need a manual `requirements.txt` file.
    ```bash
    uv add dbt-core dbt-databricks
    ```
    This will:
    -   Install `dbt-core` - the command-line tool used for data transformation, testing, and documentation.
    -   Install `dbt-databricks` - the adapter that connects dbt with Databricks SQL Warehouse or Cluster.
    -   Update `pyproject.toml` file to include both dependencies with exact versions
    -   Example output in `pyproject.toml` file after running the command:
        ```bash
            [project]
            name = "de-project-dbt"
            dependencies = [
                "dbt-core>=1.10.0",
                "dbt-databricks>=1.10.0"
            ]
        ```
    -   Export all currently installed packages in `Virtual Environment` and Saves them into a `requirements.txt` file.
        ```bash
        uv pip freeze > requirements.txt
        ```

#### Step 2. Open Databricks Free Community Edition

This project I uses **Databricks Free Community Edition** as the main platform for developing and running dbt models.

1. **Go to the official signup page**  
   
   [https://www.databricks.com/learn/free-edition](https://www.databricks.com/learn/free-edition)
   

2. **Create & Login yaccount**  
   - Sign up or Login with email account and verify it.  
   - Once completed, the website will be redirected to Databricks workspace.

3. **Log in to our workspace**  
   - We will see the Databricks UI, including the **Workspace**, **Catalog**, **Jobs & Pipelines**, and **Compute** sections.  
   - The **Workspace** is where we can manage notebooks, data, clusters, and SQL queries.  

4. **Create a new Catalog and Schema**  
   In the Databricks **Catalog**:
   - Create a new **Catalog** named **`dbt_dev`**.  
   - In this catalog, create a new **Schema** named **`source`** — this schema will store ourr raw data files (CSV format).

5. **Upload CSV data into the `source` schema**  
   - Go to **Catalog → dbt_dev → source → Add → Upload Data**.  
   - Upload all 6 CSV files from local `data` folder:  
     ```
     dim_customer.csv  
     dim_date.csv  
     dim_product.csv  
     dim_store.csv  
     fact_returns.csv  
     fact_sales.csv
     ```
   - Databricks will automatically create tables from each CSV file in `source` schema.

6. **Verify data upload**  
   - Use the Databricks SQL Editor to confirm each table was created successfully:  
     ```sql
     SELECT COUNT(*) FROM dbt_dev.source.fact_sales;
     ```

---
    


### 2️⃣ DBT Extension
his project uses the **dbt Power User** extension in VS Code to simplify dbt development.

#### What it is
The **dbt Power User** extension provides helpful features like:
- Running and testing dbt models directly from VS Code.  
- Viewing model lineage and dependencies.  
- Syntax highlighting and autocomplete for dbt commands.

#### Installation Steps
1. Open VS Code.  
2. Go to **Extensions** (`Ctrl + Shift + X`).  
3. Search for **dbt Power User**.  
4. Click **Install**.  
5. After installation, select `Virtual Environment` (`.venv`) as Python interpreter to enable dbt commands.
6. In **Associate File Types** config setup
    - **Item** = `*.sql` and **Value** = `jinja-sql`
    - **Item** = `*.yml` and **Value** = `jinja-yaml`
---

### 3️⃣ DBT Project Setup
_Define project configuration, structure, and basic workflows._

#### Initialize dbt Project
1. Run the following command in terminal:
    ```bash
    dbt init
    ```
2. Select database adapter
    - This might be choices: Depends on what databased installed
         ```css
        Which database would you like to use?
        [1] databricks
        [2] spark
        [3] postgres
        [4] bigquery
        ```
    - Type **1** and press Enter to choose **Databricks**.

3. Select compute host in databricks
    - Go to **Databricks** > `Compute` section > Select computer cluster
    - Go to `Connection details` > Copy value in `Server hostname` and `HTTP Path`
    - `Access Token` → generated from `User Settings` > `Developer` > `Access Tokens`
    - Paste the value in terminal
        ```css
        host (yourorg.databricks.com): <value from `Server hostname`>
        http_path (HTTP Path): <value from `HTTP Path`>
        Desired access token option (enter a number): 1
        token (dapiXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX): <Access Token>
        ```
4. Specify use or not use `Unity Catalog` & initial catalog
    ```css
        Which database would you like to use?
        [1] use Unity Catalog
        [2] not use Unity Catalog
        Desired unity catalog option (enter a number):
        catalog (initial catalog): <catalog name>
    ```
    - Type **1** and press Enter to choose use **Unity Catalog**.
    - Type catalog name e.g. `dbt_dev`

5. Specify `default schema` & `threads`
    ```css
        schema (default schema that dbt will build objects in): default
        threads (1 or more) [1]: 1
    ```
6. Navigate into project directory
    ```bash
    cd de_project_dbt
    ```
7. Verify the connection to Databricks
    ```bash
    dbt debug
    ```
    This command checks whether dbt can successfully connect to Databricks workspace.
    We should see messages like:
    
    ```bash
    Connection test: ✅ [OK Connection ok]

    All checks passed!
    ```

#### Checking files profiles.yml & dbt_project.yml
1. What is `profiles.yml`
    profiles.yml is dbt connection configuration file — it tells dbt how to connect to database or data warehouse (Databricks, BigQuery, Postgres, etc.).

    **Location**
    By default, dbt looks for it here:

    ```bash
    ~/.dbt/profiles.yml
    ```
    On Windows

    ```bash
    C:\Users\<your-username>\.dbt\profiles.yml
    ```

    Example `profiles.yml` for Databricks
    ```bash
    de_project_dbt:  # must match the 'profile:' value in dbt_project.yml
        target: dev
        outputs:
            dev:
            type: databricks
            catalog: dbt_dev
            schema: source
            host: adb-1234567890123456.7.azuredatabricks.net
            http_path: /sql/1.0/warehouses/abcd1234efgh5678
            token: dapiXXXXXXXXXXXXXXXXXXXXXXXX
            threads: 1
    ```
    🔹 Key points:

    - `type`: must match database adapter (e.g., `databricks`, `bigquery`, `postgres`).

    - `catalog` and `schema`: define where dbt will create tables/views.

    - `token`, `host`, and `http_path`: come from Databricks workspace.

    - `threads`: controls parallelism (1 for local, 4–8 for production).


2. What is `dbt_project.yml`
    This file lives inside dbt project folder e.g. `/de_project_dbt/`.

    It defines:

    - The project name
    - Which profile from `profiles.yml` to use
    - File/folder structure for models, macros, tests, etc.
    - Default materialization (table/view)

    Example `dbt_project.yml`

    ```bash
        name: 'de_project_dbt'  # project name
        version: '1.0.0'

        profile: 'de_project_dbt'  # must match the key in profiles.yml

        model-paths: ["models"]
        analysis-paths: ["analyses"]
        test-paths: ["tests"]
        seed-paths: ["seeds"]
        macro-paths: ["macros"]
        snapshot-paths: ["snapshots"]

        models:
        de_project_dbt:
            bronze:
            +schema: bronze
            +materialized: table  # Other options: views, table, incremental, ephemeral
            silver:
            +schema: silver
            +materialized: table  # Other options: views, table, incremental, ephemeral
            gold:
            +schema: gold
            +materialized: table  # Other options: views, table, incremental, ephemeral
    ```

    **The most important match is:**
    ```bash
    profile: 'de_project_dbt'
    ```
    in `dbt_project.yml`
    must match the top-level key in `profiles.yml`: 
    ```bash
    de_project_dbt:
    ```
    Otherwise, dbt will say:
    `Could not find profile named 'de_project_dbt'`


    ### What is `materialized` in dbt?
    The `+materialized`: setting tells dbt **how to create and store our model** in our database or data warehouse (Databricks, BigQuery, Snowflake, etc.).

    #### Common Materialization Types

    | Materialization | Description | When to Use |
    |-----------------|--------------|--------------|
    | **`view`** | Creates a **view** (virtual table) that runs the SQL query every time it’s accessed. | Use when data is small or changes frequently — lightweight, no storage. |
    | **`table`** | Creates a **physical table** by running the SQL and saving results. | Use for stable or heavy queries; faster to query but takes up storage. |
    | **`incremental`** | Loads data **only for new or updated rows**, rather than rebuilding the whole table. | Use for large datasets where full refresh is expensive. |
    | **`ephemeral`** | Doesn’t create a table or view; used **only within other models** (like a subquery). | Use for intermediate logic — improves performance during joins. |

    📘 **Reference:** [dbt Documentation — Materializations](https://docs.getdbt.com/docs/build/materializations)



#### Delete "models/example" folder and Create "bronze", "silver", "gold" folders in models folder
1. Delete the default example folder
    ```bash
    rm -r models/example
    ```
2. Create 3 new folders in `models/`
    ```bash
    mkdir models/bronze models/silver models/gold
    ```
    Folder structure:

    ```
    de_project_dbt/
    ├── models/
    │   ├── bronze/
    │   ├── silver/
    │   └── gold/
    ```


---

### 4️⃣ DBT Source
_Define and register data sources for dbt models._
1. Create `sources.yml`
    Example structure of the `sources.yml` file:
    ```yaml
    version: 2

    sources:
    - name: source              # schema name in Databricks
        description: "Raw data tables loaded from CSV files into Databricks"
        database: dbt_dev       # catalog name
        schema: source          # schema name
        tables:
        - name: fact_sales
          description: "Fact Table: Sales"
        - name: fact_returns
          description: "Fact Table: Returns"
        - name: dim_date
          description: "Dimension Table: Date"
        - name: dim_customer
          description: "Dimension Table: Customer"
        - name: dim_product
          description: "Dimension Table: Product"
        - name: dim_store
          description: "Dimension Table: Store"
    ```
    Reference: [Add sources to DAG](https://docs.getdbt.com/docs/build/sources)

2. Create Bronze Models
   Create the following SQL files in models/bronze folder:
   ```
    bronze/
    ├── bronze_dim_customer.sql
    ├── bronze_dim_date.sql
    ├── bronze_dim_product.sql
    ├── bronze_dim_store.sql
    ├── bronze_returns.sql
    └── bronze_sales.sql
   ```
   Each file selects data directly from its source table.
   For example:

   ```sql
   -- models/bronze/bronze_returns.sql
    SELECT
        *
    FROM
        {{ source('source', 'fact_returns') }}
   ```

   ```sql
   -- models/bronze/bronze_dim_customer.sql
    SELECT
        *
    FROM
        {{ source('source', 'dim_customer') }}
   ```

   Understanding `{{ source('source', 'table_name') }}`

   The `{{ source() }}` function is a Jinja macro provided by dbt that safely references source tables defined in `sources.yml`.

   Syntax:

   ```sql
    {{ source('schema_name_in_sources_yml', 'table_name') }}
   ```

   So in example:

   ```sql
    {{ source('source', 'fact_returns') }}
   ```
   means:

   - `"source"` → the schema (or source name) defined in sources.yml.

   - `"fact_returns"` → the table inside that schema.

   dbt automatically resolves this to full Databricks location:
   ```sql
    dbt_dev.source.fact_returns
   ```

3. Run dbt source commands

   List all defined sources:
 
   ```bash
    dbt source list
   ```

   Check freshness (optional, works only if we define loaded_at_field in our sources.yml):
  
   ```bash
    dbt source freshness
   ```

   Dont Forget activate `Virtual Environment` before running these two commands:
   ```bash
   source .venv/Scripts/activate
   ```

---

### 5️⃣ DBT Model
_Create transformation logic for each Medallion layer._

In this step, We will create and run transformation models for the **Bronze**, **Silver**, and **Gold** layers.

Each layer builds upon the previous one — dbt compiles SQL files inside `models/` and runs them in our Databricks environment.

---

#### Common dbt Commands

| Command | Description | Example |
|----------|--------------|----------|
| **`dbt run`** | Executes all models in our project based on dependencies and configurations. | `dbt run` |
| **`dbt run --select <path>`** | Runs only models within a specific folder path (e.g., Bronze layer). | `dbt run --select models/bronze` |
| **`dbt run --select <model_name>`** | Runs a single model by name. | `dbt run --select bronze_dim_customer` |
| **`dbt test`** | Runs all tests defined in `.yml` or `.sql` test files. | `dbt test` |
| **`dbt build`** | **Runs models, tests, snapshots, and seeds together** — all in dependency order. It’s an all-in-one command that ensures the entire project builds cleanly. | `dbt build` |
| **`dbt build --select <path>`** | Builds and tests only the selected layer or model. | `dbt build --select models/bronze` |
| **`dbt build --select <model_name>`** | Builds and tests a specific model and its dependencies. | `dbt build --select bronze_sales` |
| **`dbt debug`** | Checks if dbt can connect to the warehouse and verifies our configuration. | `dbt debug` |
| **`dbt clean`** | Deletes temporary folders (`target/`, `dbt_packages/`) to reset our workspace. | `dbt clean` |

---

#### What is the `target/` Folder?

After every dbt command (like `dbt run` or `dbt compile`), dbt generates compiled SQL code and logs inside the **`target/`** folder.

This folder contains:
- `compiled/` → the actual SQL files dbt sends to our warehouse.  
- `run/` → results of our last run (successful and failed models).  
- `manifest.json` → metadata about our project (used by dbt docs).  

Example structure after running dbt:
```bash
de_project_dbt/
├── target/
│   ├── compiled/
│   │   └── de_project_dbt/
│   │       ├── bronze/
│   │       └── silver/
│   ├── run/
│   └── manifest.json
```

#### What is `dbt clean`?
`dbt clean` is used to remove temporary build files and ensure a clean environment.

When we run:

```bash
dbt clean
```
dbt deletes folders defined under clean-targets in our dbt_project.yml, such as:
```yml
clean-targets:
    - "target"
    - "dbt_packages"
```
This helps when:

-   We switch between environments or branches.

-   We need to reset compiled code and logs.

-   We want to avoid old manifest conflicts or cache issues.

#### Typical Workflow
```bash
# Step 1 — Run only Bronze models
dbt run --select models/bronze

# Step 2 — Once verified, run Silver layer
dbt run --select models/silver

# Step 3 — Build entire project
dbt run

# Step 4 — Test data quality
dbt test

# Step 5 — Clean and rebuild if needed
dbt clean
dbt run
```
**Reference:**
-   [DBT Command Reference](https://docs.getdbt.com/docs/build/sources)
-   [DBT Clean Command](https://docs.getdbt.com/reference/commands/clean)

---

### 6️⃣ DBT Test
_Ensure data quality and reliability across all Medallion layers._

dbt allows us to define **data tests** that validate the integrity of our datasets.  
These tests can be:
- **Generic tests** — predefined checks like `unique`, `not_null`, `accepted_values`.  
- **Custom tests** — user-defined SQL or macros for specific validation logic.

---

1.  What is `properties.yml` Used For?

    The `properties.yml` file defines **model-level and column-level tests**.

    Example (`models/bronze/properties.yml`):

    ```yaml
    version: 2

    models:
      - name: bronze_dim_date
        config:
            materialized: view
            schema: bronze

      - name: bronze_dim_product
        config:
        materialized: view
        schema: bronze

      
      - name: bronze_sales
        columns:
          - name: sales_id
            tests:
              - unique
              - not_null

          - name: gross_amount
            tests:
              - generic_non_negative

      
      - name: bronze_dim_store
        columns:
           - name: store_sk
             tests:
               - unique
               - not_null

           - name: store_name
             tests:
               - accepted_values:
                   values: ['MegaMart Manhattan', 'MegaMart Brooklyn', 'MegaMart Austin', 'MegaMart San Jose', 'MegaMart Toronto']
                   config:
                     everity: warn

           - name: country
             tests:
               - accepted_values:
                   values: ['USA', 'Canada', 'Mexico']
                   config:
                     severity: warn
    ```
    **Explanation:**

    -   dbt automatically runs these validations when we execute `dbt test`.
    -   Each test returns PASS / FAIL status.

    **Reference:** [DBT Tests Documentation](https://docs.getdbt.com/docs/build/data-tests)

    ### Model: `bronze_sales`

    | Column | Test | Description | Purpose |
    |--------|------|--------------|----------|
    | `store_sk` | `unique` | Ensures that each store has a distinct surrogate key (`store_sk`). | Prevents duplicate store IDs, maintaining one record per store. |
    | `store_sk` | `not_null` | Checks that every store record has a valid `store_sk` value. | Guarantees store identifiers are always populated for joins and lookups. |
    | `store_name` | `accepted_values` | Validates that store names are restricted to the allowed list: `'MegaMart Manhattan'`, `'MegaMart Brooklyn'`, `'MegaMart Austin'`, `'MegaMart San Jose'`, `'MegaMart Toronto'`. | Enforces store naming consistency and detects unexpected entries or typos. |
    | `country` | `accepted_values` | Ensures that the store’s country value is only `'USA'`, `'Canada'`, or `'Mexico'`. | Maintains data validity for regional reporting and filtering. |

    #### Custom Generic Test - `generic_non_negative.sql`
    Location: `tests/generic/generic_non_negative.sql`

    ```sql
    {% test generic_non_negative(model, column_name) %}

    SELECT
        *
    FROM
        {{ model }}
    WHERE
            1=1
        AND {{ column_name }} < 0

    {% endtest %}
    ```

    **Explanation:**

    -   This test ensures that numeric fields (e.g. `gross_amount`) are never negative.
    -   dbt automatically passes the `model name` and `column name` to this macro when running tests defined in `properties.yml`.

    If any row violates the condition (`< 0`), the test fails and dbt reports the failing records.

    **Example Result:**

    ```makefile
    03:04:05  5 of 5 FAIL  generic_non_negative_bronze_sales_gross_amount  [FAIL 3 in 2.35s]
    ```

    ✅ If no negative values exist, dbt will report:

    ```nginx
    PASS  generic_non_negative_bronze_sales_gross_amount
    ```


    #### Custom SQL Test - `non_negative_test.sql`
    Location: `tests/non_negative_test.sql`

    ```sql
    SELECT
        *
    FROM
        {{ ref('bronze_sales') }}
    WHERE
        1=1
        AND gross_amount < 0
        AND net_amount < 0
    ```
    Explanation:

    -   Unlike the macro test above, this is a standalone SQL test file.
    -   It checks both gross_amount and net_amount columns at once.
    -   If any record matches the condition, the test fails.

    **Reference:** [Custom SQL Tests in dbt](https://docs.getdbt.com/docs/build/data-tests#write-a-custom-sql-test)


---
2. **Example Project Structure**
    ```pgsql
        models/
        │
        ├── bronze/
        │   ├── bronze_sales.sql
        │   ├── bronze_dim_store.sql
        │   └── properties.yml   ← applies to models in this folder only
        │
        ├── silver/
        │   ├── silver_sales.sql
        │   └── properties.yml   ← applies to models in silver folder
        │
        └── gold/
            ├── gold_aggregates.sql
            └── properties.yml   ← applies to models in gold folder
    ```

    #### How dbt Resolves It
    -   dbt scans all .yml files under our models/ directory.
    -   Each .yml must match the model names found in the same or child directory.
    -   So our models/bronze/properties.yml:
        -   applies to bronze_sales.sql, bronze_dim_store.sql, etc.
        -   does not affect silver or gold models.

    If we want to define tests for Silver or Gold, we should create separate properties.yml files in those folders:

    ```bash
    models/silver/properties.yml
    models/gold/properties.yml
    ```
    **Reference:** [DBT Documentation — Organizing .yml Files](https://docs.getdbt.com/docs/build/sources#organizing-sources-and-tests)

---

### 7️⃣ DBT Seed

#### What Are Seeds?

**Seeds** are **CSV files** that dbt can load directly into our data warehouse (in this project — Databricks).  
They are typically used for **static reference data** such as lookup tables, mapping tables, or default configuration values.

Think of them as small, version-controlled datasets that live inside our dbt project, usually in the `/seeds/` folder.

---

#### 📁 Example: Basic Case

Suppose we have a seed file:  
`/seeds/country_lookup.csv`

```csv
country_code,country_name,region
US,United States,North America
CA,Canada,North America
MX,Mexico,North America
```
We can load it into our warehouse by running:

```bash
dbt seed
```

✅ dbt will:
-   Read country_lookup.csv
-   Create a table (or replace it) in our target schema
-   Use the same name as the file (country_lookup)

This makes it easy to join lookup data with our models:

```sql
SELECT 
    s.store_name,
    c.region
FROM {{ ref('bronze_dim_store') }}    AS s
LEFT JOIN {{ ref('country_lookup') }} AS c
    ON s.country = c.country_name
```

ู**Advanced Case — Custom Configuration**
We can customize how dbt loads seeds in our `dbt_project.yml`.

```yml
seeds:
de_project_dbt:
    +schema: bronze
    +column_types:
    country_code: string
    country_name: string
    region: string
    +quote_columns: false
```
This configuration means:
-   All seed data will be loaded into the bronze schema.
-   dbt will assign explicit column types (useful for Databricks).
-   Column names won’t be quoted (for compatibility with some SQL dialects).

**Reference:** [DBT Docs — Seeding Data](https://docs.getdbt.com/docs/build/seeds)

---

**Commands Reference**
| Command | Description |
|----------|--------------|
| `dbt seed` | Loads all seed CSV files into our data warehouse. |
| `dbt seed --select country_lookup` | Loads only the specified seed file (e.g., `country_lookup.csv`). |
| `dbt seed --full-refresh` | Reloads all seeds from scratch — drops and recreates the tables. |
| `dbt seed --show` | Displays the compiled SQL that dbt will execute for seeding. |

---

### 8️⃣ DBT Jinja & Macros

**dbt Jinja** allows you to add dynamic logic, loops, variables, and macros inside SQL models.  
It uses the [Jinja2 templating language](https://jinja.palletsprojects.com/en/3.1.x/templates/) — the same engine used by Python frameworks like Flask.  
With Jinja, our SQL models become **parametric**, **reusable**, and **context-aware** (e.g., automatically adapting by schema, date, or flags).

---

#### General Concepts

| Syntax | Purpose | Example |
|--------|----------|---------|
| `{% ... %}` | Control statements like loops and conditionals | `{% for item in list %}` |
| `{{ ... }}` | Output variables or expressions | `{{ ref('bronze_sales') }}` |
| `{# ... #}` | Comment (ignored during compilation) | `{# this is ignored #}` |

dbt runs Jinja **before** executing SQL — meaning our logic is rendered into plain SQL first, then executed on Databricks.

---

#### General Example

```jinja
{% set columns = ["sales_id", "date_sk", "gross_amount"] %}

SELECT
    {{ columns | join(', ') }}
FROM
    {{ ref('bronze_sales') }}
```

**Rendered SQL Output:**
```sql
SELECT
    sales_id, 
    date_sk, 
    gross_amount
FROM
    `dbt_dev.bronze.bronze_sales`
```

---

#### For loop example in Jinja

```jinja
{% set countries = ["Japan", "USA", "China", "France", "Spain", "Thailand", "Cambodia"] %}

{% for i in countries %}
    {% if i != "Cambodia" %}
        {{ i }} is allowed
    {% else %}
        {{ i }} is restricted
    {% endif %}
{% endfor %}
```
**What Happens**
-   `set countries` - defines Python list (array) of country names. 
    ["Japan", "USA", "China", "France", "Spain", "Thailand", "Cambodia"]
-   `for i in countries` - loops through each element of the list, one by one.
-   `if i != "Cambodia"` - checks if the current item `(i)` is not equal to `"Cambodia"`.

**Rendered Output**
```csharp
Japan is allowed
USA is allowed
China is allowed
France is allowed
Spain is allowed
Thailand is allowed
Cambodia is restricted
```

---

#### Incremental example in Jinja

```jinja
{% set inc_flag  = 1 %}
{% set last_load = 3 %}
{% set cols_list = ["sales_id", "date_sk", "gross_amount"] %}


SELECT
    {% for i in cols_list %}
        {{ i }}
        {% if not loop.last %}, {% endif%}

    {% endfor%}

FROM
    {{ ref('bronze_sales') }}

{% if inc_flag == 1 %}
    WHERE date_sk > {{ last_load }}
{% endif %}
```

##### Step-by-Step Breakdown
1.  Variables
    -   `inc_flag`  = 1 - acts like a control flag (1 = incremental load, 0 = full load).
    -   `last_load` = 3 - defines the cutoff value for incremental loading (e.g., latest `date_sk`).
    -   `cols_list` - defines a list of columns you want to select dynamically.

2.  Jinja Loop — Dynamic Column Generation
    ```jinja
    {% for i in cols_list %}
        {{ i }}
        {% if not loop.last %}, {% endif %}
    {% endfor %}
    ```
    This loop iterates over the list and prints each column, separated by commas.
    -   The inner condition `{% if not loop.last %}` ensures that no trailing comma appears after the last column.

    **Resulting SQL fragment:**
    ```sql
    sales_id, date_sk, gross_amount
    ```
3. The `if` condition — Dynamic WHERE Clause
    ```jinja
    {% if inc_flag == 1 %}
        WHERE date_sk > {{ last_load }}
    {% endif %}
    ```
    Since `inc_flag = 1`, this condition is true, so the `WHERE` clause will be included.
    If `inc_flag` were 0, this entire block would be skipped. 


    **inal Rendered SQL Output:**

    ```sql
    SELECT
        sales_id,
        date_sk, 
        gross_amount

    FROM
        dbt_dev.bronze.bronze_sales

    WHERE 
        date_sk > 3
    ```



---

#### Example with Custom Macro
We can define reusable logic in the macros/ folder.

File: `macros/multiply.sql`
```jinja
{% macro multiply(a, b) %}
    ROUND({{ a }} * {{ b }}, 2)
{% endmacro %}
```

**Usage inside a model:**
```sql
SELECT
    sales_id,
    {{ multiply('unit_price', 'quantity') }} AS total_revenue
FROM
    {{ ref('bronze_sales') }}
```

**Rendered SQL:**
```sql
SELECT
    sales_id,
    ROUND(unit_price * quantity, 2) AS total_revenue
FROM
    dbt_dev.bronze.bronze_sales
```

**Reference:**
-   [DBT Jinja](https://docs.getdbt.com/docs/build/jinja-macros#jinja)
-   [DBT Macros](https://docs.getdbt.com/docs/build/jinja-macros#macros)


---
### 9️⃣ DBT Snapshot (SCD Type 2)

#### Concept Overview
**DBT Snapshots** are used to capture **historical changes** in dimension tables over time — this is known as **Slowly Changing Dimension Type 2 (SCD Type 2)**.

Normally, when data in a source or bronze layer changes (e.g., a customer’s loyalty tier or a product’s category), the old record is overwritten.  
With a **snapshot**, DBT automatically preserves both the **old** and **new** versions, enabling time-based analysis such as “what was true at a given point in time.”

---

#### Snapshot Configuration (YAML)

In this project, two SCD-Type-2 snapshots are defined in  
`snapshots/bronze_dim_customer.yml`:

```yaml
snapshots:
  - name: bronze_dim_customer_snapshot_scd_type_2
    description: "SCD Type 2 snapshot tracking changes in bronze schema"
    relation: ref('bronze_dim_customer')
    config:
      database: '{{ target.catalog }}'
      schema: scd
      unique_key: customer_sk
      strategy: timestamp
      updated_at: updated_at
      dbt_valid_to_current: NULL  # Specifies that current records should have `dbt_valid_to` set to `'9999-12-31'` instead of `NULL`

  - name: bronze_dim_product_snapshot_scd_type_2
    description: "SCD-Type-2 snapshot tracking changes in bronze_dim_product"
    relation: ref('bronze_dim_product')
    config:
      database: '{{ target.catalog }}'
      schema: scd
      unique_key: product_sk
      strategy: timestamp
      updated_at: updated_at
      dbt_valid_to_current: NULL # Specifies that current records should have `dbt_valid_to` set to `'9999-12-31'` instead of `NULL`
```
---

#### Key Configurations

| **Configuration** | **Type / Example** | **Description** |
|--------------------|--------------------|-----------------|
| `name` | `bronze_dim_customer_snapshot_scd_type_2` | Defines the snapshot’s unique name. This name will also appear as the table name under the configured schema (e.g., `scd.bronze_dim_customer_snapshot_scd_type_2`). |
| `description` | `"SCD Type 2 snapshot tracking changes in bronze schema"` | Human-readable description of what the snapshot is tracking. |
| `relation` | `ref('bronze_dim_customer')` | Points to the model being tracked for changes. DBT uses this as the source for snapshotting. |
| `database` | `{{ target.catalog }}` | Specifies the target database (dynamic — changes based on the active target, e.g. `dbt_dev` or `dbt_production`). |
| `schema` | `scd` | The schema where the snapshot will be created (used to separate historical tables from other layers). |
| `unique_key` | `customer_sk` | Primary key in the source model that uniquely identifies each record (used for comparison). |
| `strategy` | `timestamp` | The method DBT uses to detect changes. `timestamp` is recommended because it’s efficient and resilient to schema drift. |
| `updated_at` | `updated_at` | The column in the model that represents when a record was last updated. DBT compares this to detect new versions. |
| `dbt_valid_to_current` | `NULL` | Controls how current records are marked. If `NULL`, active rows have `dbt_valid_to = NULL`; if a date is specified (e.g., `'9999-12-31'`), it marks the open-ended record. |

**How the Timestamp Strategy Works**

The `timestamp` strategy compares the current data in the source table with the previous version stored in the snapshot:

1.  On the first run, DBT copies all records into the snapshot table.
2.  On subsequent runs, DBT checks the `updated_at` column:
    -   If `updated_at` is newer than the snapshot’s last load → DBT closes the old record (`dbt_valid_to`) and inserts a new one.
    -   If unchanged → no new record is added.

Each record in the snapshot will have the following system columns:
-   `dbt_valid_from` → when the record became active
-   `dbt_valid_to` → when the record was replaced (NULL = current)
-   `dbt_scd_id` → unique hash identifier for the record state

---

#### Implementation Steps
1.  Add `updated_at` column to our bronze models:
    ```sql
    SELECT
        *,
        CURRENT_TIMESTAMP() AS updated_at
    FROM 
        {{ source('source', 'dim_customer') }}
    ```

2.  Create snapshot YAML (as shown above).
3.  Run our models to ensure the base tables exist:
    ```bash
    dbt run --select bronze_dim_customer bronze_dim_product
    ```
4.  Execute the snapshot:
    ```bash
    dbt snapshot
    ```
5.  Verify results in Databricks:
    ```sql
    SELECT * FROM dbt_dev.scd.bronze_dim_customer_snapshot_scd_type_2;
    ```
    We will see multiple versions of records if any `updated_at` values changed.


#### Testing the Snapshot
We can simulate an SCD change:
```sql
UPDATE dbt_dev.bronze.bronze_dim_customer
SET 
    loyalty_tier = CASE
        WHEN customer_sk IN (5, 20, 24, 33, 36, 39) THEN 'Silver'
        WHEN customer_sk IN (10, 12, 17, 19) THEN 'Gold'
        WHEN customer_sk IN (25, 31, 37) THEN 'Platinum'
        ELSE loyalty_tier
    END,
    updated_at = CURRENT_TIMESTAMP()

WHERE 
    customer_sk IN (
    5, 10, 12, 17, 19, 20, 24, 25, 31, 33, 36, 37, 39
);
```
OR

```sql
UPDATE dbt_dev.bronze.bronze_dim_product
SET 
    category = CASE
        WHEN product_sk = 7 THEN 'Toys'
        WHEN product_sk = 5 THEN 'Television'
        ELSE category
    END,
    updated_at = CURRENT_TIMESTAMP()

WHERE product_sk IN (5, 7);
```

Then re-run:
```bash
dbt snapshot
```
DBT will automatically insert a new version of that record in the snapshot table while keeping the previous version with `dbt_valid_to` timestamp.

---

#### Auto-Generated Snapshot Columns

When a snapshot runs, DBT automatically adds several **system columns** to manage versioning and historical tracking.  
These columns appear alongside our model’s original fields (as seen in Databricks).

| **Column Name** | **Example Value (from our data)** | **Description / Purpose** |
|------------------|------------------------------------|----------------------------|
| `dbt_scd_id` | `bb91997384e22331cba12a15569eb364` | Unique hash generated by DBT for each record version. Used internally to track change history. |
| `dbt_updated_at` | `2025-10-19T01:31:20.039+00:00` | Timestamp representing when DBT last detected this record in the source model. |
| `dbt_valid_from` | `2025-10-19T01:31:20.039+00:00` | The time when this record version first became active. |
| `dbt_valid_to` | `2025-10-19T01:41:56.254+00:00` *(NULL if current)* | The time when this record stopped being valid (i.e., was replaced by a newer version). If `NULL`, it’s the currently active record. |
| `updated_at` *(from our source)* | `2025-10-19T01:31:20.039+00:00` | The business timestamp from our bronze model, used as the `timestamp` strategy comparison field. |

---

#### Example Interpretation
In our snapshot table:

- If `dbt_valid_to` = `NULL` → the record is **currently active**.  
- If `dbt_valid_to` has a value → the record is **historical**, replaced by a newer version when the source data changed.  
- Both versions remain in the snapshot, giving you **complete change history** over time.

---

#### Quick Query Example
You can easily check current vs historical records:

```sql
-- Current active records only
SELECT *
FROM dbt_dev.scd.bronze_dim_customer_snapshot_scd_type_2
WHERE dbt_valid_to IS NULL;
```

```sql
-- Full historical view (all versions)
SELECT
  customer_sk,
  first_name,
  last_name,
  loyalty_tier,
  updated_at,
  dbt_updated_at,
  dbt_valid_from,
  dbt_valid_to
  
FROM
  dbt_dev.scd.bronze_dim_customer_snapshot_scd_type_2

WHERE
      1=1
  AND customer_sk IN (5, 10, 25)

ORDER BY
  customer_sk,
  dbt_valid_to
```
**Query Result**

![Result Query](https://github.com/stkchan/de-project-dbt/blob/f4f46b1a438a4e2d6929c341280e634694936b2e/images/Screenshot%202025-10-19%20113850.png)

---
### 🔟 DBT Deployment
This project deploys to two Databricks Unity Catalog catalogs:
-   `dbt_dev` (development)
-   `dbt_production` (production)

Our dbt profile defines both, and your models/sources/snapshots dynamically switch between them using the Jinja variable `{{ target.catalog }}`.

---

```yml
de_project_dbt:
  outputs:
    dev:
      type: databricks
      host: <databricks host>
      http_path: <http path>9
      catalog: dbt_dev           # Unity Catalog catalog (aka database at top-level)
      schema: default            # default schema for unqualified models (we override per layer in dbt_project.yml)
      threads: 1
      token: <your_personal_access_token>
    production:
      type: databricks
      host: <databricks host>
      http_path: <http path>
      catalog: dbt_production
      schema: default
      threads: 1
      token: <your_personal_access_token>
  target: dev
```
**What each key means (Databricks)**
-   type: adapter (`databricks`)
-   host / http_path: our SQL Warehouse connection
-   catalog: Unity Catalog catalog to build into (e.g., `dbt_dev`, `dbt_production`)
-   schema: default schema when a model isn’t otherwise configured (we also set schemas per layer in `dbt_project.yml`)
-   token: Databricks PAT. Tip: don’t hardcode; use an env var: `token: "{{ env_var('DATABRICKS_TOKEN') }}"`

The **active environment** is selected by `target:` (default is `dev`) or by passing `--target production` at runtime.

---
#### What does {{ target.catalog }} do?

Anywhere you use `{{ target.catalog }}`, dbt injects the catalog from the current target:
-   Running `dbt run` (default `target: dev`) → resolves to `dbt_dev`
-   Running `dbt run --target production` → resolves to `dbt_production`
This makes our project environment-agnostic. You write once; the catalog switches based on the target.


**Where you’re using it**
`models/source/sources.yml`
```yml
version: 2
sources:
  - name: source
    description: "Raw data tables loaded from CSV files into Databricks"
    database: "{{ target.catalog }}"   # ← switches between dbt_dev / dbt_production
    schema: source
    tables:
      - name: fact_sales
      - name: fact_returns
      - name: dim_date
      - name: dim_customer
      - name: dim_product
      - name: dim_store
```

`snapshots/bronze_dim_customer.yml`
```yml
snapshots:
  - name: bronze_dim_customer_snapshot_scd_type_2
    relation: ref('bronze_dim_customer')
    config:
      database: "{{ target.catalog }}"  # ← switches catalog by target
      schema: scd
      unique_key: customer_sk
      strategy: timestamp
      updated_at: updated_at
      dbt_valid_to_current: NULL

  - name: bronze_dim_product_snapshot_scd_type_2
    relation: ref('bronze_dim_product')
    config:
      database: "{{ target.catalog }}"
      schema: scd
      unique_key: product_sk
      strategy: timestamp
      updated_at: updated_at
      dbt_valid_to_current: NULL
```
---
#### Deployment Flow (step-by-step)
Run these from our project root (`de_project_dbt/`).
Switch targets with `--target dev` or `--target production`.

1. Create `Catalog`, `Schema`, and `Tables (sources)`
    -   Created `dbt_production` catalog and `source` schema
    -   Copied raw sources from `dev` → `prod`:

    ```sql
    CREATE TABLE dbt_production.source.dim_customer AS SELECT * FROM dbt_dev.source.dim_customer;
    CREATE TABLE dbt_production.source.dim_date     AS SELECT * FROM dbt_dev.source.dim_date;
    CREATE TABLE dbt_production.source.dim_product  AS SELECT * FROM dbt_dev.source.dim_product;
    CREATE TABLE dbt_production.source.dim_store    AS SELECT * FROM dbt_dev.source.dim_store;
    CREATE TABLE dbt_production.source.fact_returns AS SELECT * FROM dbt_dev.source.fact_returns;
    CREATE TABLE dbt_production.source.fact_sales   AS SELECT * FROM dbt_dev.source.fact_sales;
    ```

2.  **Sanity check connection**
    ```bash
    dbt debug --target production
    ```

3. **Build models (Bronze → Silver → Gold)**
    -   Build everything in production:
        ```bash
        dbt run --target production
        ```

    -   Or build a specific layer/model:
        ```bash
        dbt run --select models/bronze --target production
        dbt run --select silver_sales_info --target production
        ```

4. **Snapshots (SCD Type-2) in production**
    ```bash
    dbt snapshot --target production
    ```

5. **One-command CI style build**
    (`Seeds` → `Snapshots` → `Models`)
    ```bash
    dbt build --target production
    ```

6. **Docs (optional)**
    ```bash
    dbt docs generate --target production
    dbt docs serve
    ```

---

## dbt run vs dbt build

| **Feature** | **dbt run** | **dbt build** |
|--------------|----------------|------------------|
| **Purpose** | Runs only **models** defined in our `/models` directory. | Runs the **entire pipeline** — seeds → snapshots → models → tests. |
| **Scope** | Executes transformations only. | Executes all dbt assets end-to-end. |
| **Includes Seeds** | ❌ No | ✅ Yes |
| **Includes Snapshots** | ❌ No | ✅ Yes |
| **Includes Tests** | ❌ No | ✅ Yes (runs after models complete) |
| **Execution Order** | Models only (based on DAG dependencies). | Seeds → Snapshots → Models → Tests (automatic dependency order). |
| **Use Case** | Developing, debugging, or re-running a specific model. | Full CI/CD deployment or validating production pipelines. |
| **Performance** | Faster (limited to model execution). | Slower (runs full pipeline with testing). |
| **Command Example** | `dbt run --select silver_sales_info` | `dbt build --target production` |
| **Output** | Builds models (tables/views) in our target schema. | Builds and validates the entire project with tests. |
| **Best For** | Local development & debugging. | Production deployment & data validation. |

---

## Create Tables in Gold Layer
1.  files for building models is inside `models/gold/` folder
    -   `gold_gender_performance_each_product.sql`

        ```sql
        SELECT 
            product_sk,
            CASE
            WHEN gender = 'F' THEN 'Female'
            WHEN gender = 'M' THEN 'Male'
            ELSE 'Unspecified'
            END AS gender,
            ROUND(SUM(total_sales), 2)      AS total_spent, 
            ROUND(SUM(discount_amount), 2)  AS total_discount

        FROM 
            {{ ref('silver_sales_info') }}

        GROUP BY 
            product_sk,
            gender

        ORDER BY 
            total_discount DESC;
        ```
    
    -   `gold_loyaltier_performance_each_product.sql`

        ```sql
        SELECT 
            product_sk, 
            CASE
                WHEN loyalty_tier = 'None' THEN 'Standard'
                ELSE loyalty_tier
            END AS loyalty_tier, 
            ROUND(SUM(total_sales),2) AS total_spent, 
            ROUND(AVG(total_sales),2) AS avg_transaction_value, 
            COUNT(*) AS purchase_count 

        FROM 
            {{ ref('silver_sales_info') }}

        GROUP BY 
            product_sk, 
            loyalty_tier

        ORDER BY 
            total_spent DESC;
        ```

    -   `gold_payment_method_total_spent_transactions.sql`

        ```sql
        SELECT 
            payment_method,
            ROUND(SUM(total_sales),2) AS total_spent, 
            COUNT(*) AS purchase_count 

        FROM 
            {{ ref('silver_sales_info') }}

        GROUP BY 
            payment_method

        ORDER BY 
            purchase_count DESC;
        ```

2.  Step-by-Step
    -   Write Gold Model Scripts
    -   Run DBT to build these tables
        ```bash
        dbt run --select gold --target dev
        ```
    -   Inspect results in Databricks
    -   Deploy to production
        ```bash
        dbt run --select gold --target production
        ```


3.  Folder Structure
    ```bash
    models/
    ├─ source/
    │   ├─ sources.yml
    │   └─ ...
    ├─ bronze/
    │   ├─ bronze_dim_customer.sql
    │   ├─ ...
    ├─ silver/
    │   └─ silver_sales_info.sql
    └─ gold/
        ├─ gold_gender_performance_each_product.sql
        ├─ gold_loyaltier_performance_each_product.sql
        └─ gold_payment_method_total_spent_transactions.sql
    ```
---

##  Data Lineage Overview

This section describes the **end-to-end lineage flow** of the DBT project — from raw **source tables** to **gold analytical layers** — showing how data evolves through each transformation step.

---
### Overall Data Flow
  ![Overall Data Flow](https://github.com/stkchan/de-project-dbt/blob/89dd6ce5c07d36ce153eec000c1277d9fbaf067c/images/Screenshot%202025-10-19%20132812.png)


### 🔹 1. Source Layer (`source` schema)
Raw data is first loaded from CSV files into the Databricks catalog under the `source` schema.

        | **Table** | **Description** |
        |------------|----------------|
        | `dim_customer` | Raw customer information (names, gender, contact). |
        | `dim_product` | Product details including category and price. |
        | `fact_sales` | Transaction-level sales data. |
        | `fact_returns` | Return transaction data. |
        | `dim_store` | Store metadata including location and country. |
        | `dim_date` | Calendar dimension used for time-based analysis. |

        These are defined in **`models/source/sources.yml`**, using:
        ```yaml
        database: '{{ target.catalog }}'
        schema: source
        ```

---


