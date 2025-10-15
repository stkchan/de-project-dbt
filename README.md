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

3. **Log in to your workspace**  
   - You’ll see the Databricks UI, including the **Sidebar**, **Workspace**, and **Compute** sections.  
   - The **Workspace** is where you can manage notebooks, data, clusters, and SQL queries.  

    

---

### 2️⃣ DBT Extensions
_Set up VS Code extensions and configuration for dbt development._
- Install **dbt Power User** and **SQLFluff** extensions in VS Code.  
- Configure interpreter to use the project’s virtual environment (`.venv`).  
- Enable dbt commands and auto-completion in the VS Code Command Palette.  
- (Later: include screenshots or keyboard shortcuts if needed.)

---

### 3️⃣ DBT Project Setup
_Define project configuration, structure, and basic workflows._
- Initialize dbt project using `dbt init`.  
- Edit `dbt_project.yml` to define paths (models, macros, tests, seeds).  
- Set default schemas for Bronze, Silver, and Gold layers.  
- Create folder structure for models and data layers.  

---

### 4️⃣ DBT Source
_Define and register data sources for dbt models._
- Create `sources.yml` file to define CSVs or tables.  
- Tag each source (e.g., `bronze` layer) and configure column metadata.  
- Use the `{{ source('schema', 'table_name') }}` macro in models.  
- Validate using `dbt source freshness` (if applicable).  

---

### 5️⃣ DBT Model
_Create transformation logic for each Medallion layer._
- Develop `bronze`, `silver`, and `gold` SQL models.  
- Use CTEs for clarity and modularity.  
- Apply schema mapping, joins, and calculations.  
- Configure materialization type (`view` or `table`) per layer in `dbt_project.yml`.  
- Run all transformations using `dbt run`.  

---

### 6️⃣ DBT Test
_Apply data quality rules to validate model outputs._
- Define tests in `properties.yml` files.  
- Use built-in tests like `unique`, `not_null`, and `accepted_values`.  
- Add custom tests (e.g., `generic_non_negative`).  
- Execute tests using `dbt test` and review results in the terminal or UI.  
- Track warnings or errors based on test severity levels.

---

*(More steps such as DBT Documentation, DBT Run & Deploy, and CI/CD integration can be added later.)*

---
