# Aviation ELT Pipeline

An end-to-end ELT data pipeline that ingests live flight and reference data from the AviationStack API, stores it in AWS S3, loads it into Redshift Serverless via Lambda, transforms it with dbt into a star schema, and orchestrates everything daily with Apache Airflow.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Apache Airflow (Daily)                     │
│                                                                     │
│   ┌─────────────────┐          ┌──────────────────┐                 │
│   │  fetch_flights  │          │  fetch_reference │                 │
│   └────────┬────────┘          └────────┬─────────┘                 │
│            │                            │                           │
│   ┌────────▼────────┐          ┌────────▼─────────┐                 │
│   │ upload_to_s3    │          │ upload_ref_to_s3 │                 │
│   └────────┬────────┘          └────────┬─────────┘                 │
│            └──────────────┬─────────────┘                           │
│                    ┌──────▼──────┐                                  │
│                    │   verify    │                                  │
│                    └─────────────┘                                  │
└─────────────────────────────────────────────────────────────────────┘
         │                               │
         ▼                               ▼
  ┌─────────────┐                ┌──────────────────┐
  │   AWS S3    │───S3 trigger──▶│   AWS Lambda     │
  │  (Raw CSV)  │                │  (COPY → Redshift│
  └─────────────┘                └────────┬─────────┘
                                          │
                                          ▼
                          ┌───────────────────────────┐
                          │    Redshift Serverless     │
                          │    schema: raw             │
                          │    flights, airlines,      │
                          │    airports, airplanes,    │
                          │    cities, countries, taxes│
                          └──────────────┬────────────┘
                                         │
                                         ▼
                          ┌───────────────────────────┐
                          │           dbt             │
                          │                           │
                          │  staging  →  7 views      │
                          │  analytics→  7 dim tables │
                          │             1 fact table  │
                          └───────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Orchestration | Apache Airflow |
| Data Source | AviationStack API |
| Storage | AWS S3 |
| Ingestion | AWS Lambda (S3 event → Redshift COPY) |
| Data Warehouse | AWS Redshift Serverless |
| Transformation | dbt-core 1.5 + dbt-redshift |
| Language | Python 3 |
| Version Control | Git / GitHub |

---

## Project Structure

```
elt_aviation_pipeline/
│
├── api_extraction/
│   ├── flights_api.py               # Fetches daily live flight data from AviationStack
│   ├── reference_api.py             # Fetches reference data (airlines, airports, etc.)
│   ├── upload_to_s3.py              # Uploads flight CSVs → S3 (skips duplicates)
│   └── upload_reference_to_s3.py   # Uploads reference CSVs → S3 (skips duplicates)
│
├── dags/
│   └── aviation_pipeline.py         # Airflow DAG — daily schedule, task dependencies
│
├── lambda/
│   └── lambda_function.py           # S3-triggered COPY into Redshift raw schema
│
├── redshift/
│   └── create_tables.sql            # DDL for all raw schema tables
│
├── dbt_aviation/
│   ├── dbt_project.yml              # Schema routing: staging → staging, analytics → analytics
│   ├── macros/
│   │   └── generate_schema_name.sql # Ensures exact schema names (no target prefix)
│   └── models/
│       ├── staging/                 # 7 views — type casting, JSON parsing, null handling
│       │   ├── sr_flights.sql
│       │   ├── sr_airlines.sql
│       │   ├── sr_airports.sql
│       │   ├── sr_airplanes.sql
│       │   ├── sr_cities.sql
│       │   ├── sr_countries.sql
│       │   └── sr_taxes.sql
│       └── analytics/               # Star schema
│           ├── dim/
│           │   ├── dim_airlines.sql
│           │   ├── dim_airports.sql
│           │   ├── dim_airplanes.sql
│           │   ├── dim_cities.sql
│           │   ├── dim_countries.sql
│           │   ├── dim_dates.sql
│           │   └── dim_taxes.sql
│           └── fact/
│               └── fact_flights.sql
│
├── .env.example                     # Environment variable template
└── requirements.txt
```

---

## Pipeline Walkthrough

### Step 1 — Extract
Airflow triggers two parallel tasks daily:

- **`flights_api.py`** calls the AviationStack `/flights` endpoint and saves today's flights as a timestamped CSV to `data/flights/`
- **`reference_api.py`** calls 6 reference endpoints (airlines, airports, airplanes, cities, countries, taxes) and saves each as a CSV to `data/reference/`

### Step 2 — Upload to S3
After extraction two upload tasks run:

- **`upload_to_s3.py`** pushes flight CSVs to `s3://your-bucket/flights/`
- **`upload_reference_to_s3.py`** pushes reference CSVs to `s3://your-bucket/reference/`

Both scripts check if the file already exists in S3 before uploading to prevent duplicate loads.

### Step 3 — Load to Redshift (Lambda)
An **AWS Lambda** function is triggered automatically on S3 `PUT` events. For each uploaded file it issues a `COPY` command into the matching `raw` schema table in Redshift Serverless, using an IAM role for authentication. No manual intervention needed.

### Step 4 — Verify
A final Airflow `PythonOperator` queries each raw table in Redshift and logs row counts, confirming the load was successful before marking the DAG run complete.

### Step 5 — Transform (dbt)

**Staging layer** — 7 views in the `staging` schema:

| Model | What it does |
|---|---|
| `sr_flights` | Parses nested JSON columns (departure, arrival, airline, flight) into typed scalar fields using `jsonb` |
| `sr_airlines` | Type casts, null-safe `country_iso2` via `coalesce` |
| `sr_airports` | Casts coordinates to numeric, GMT offset to interval |
| `sr_airplanes` | Handles `0000-00-00` sentinel dates, coalesces missing IATA/ICAO codes |
| `sr_cities` | Type casts, coordinate precision |
| `sr_countries` | Expands continent codes (AF → Africa, EU → Europe, NA → North America, etc.) |
| `sr_taxes` | Type casts, null-safe IATA code |

**Analytics layer** — star schema in the `analytics` schema:

| Model | Type | Description |
|---|---|---|
| `dim_airlines` | Table | Airline attributes with surrogate key |
| `dim_airports` | Table | Airport attributes with coordinates |
| `dim_airplanes` | Table | Aircraft attributes and specifications |
| `dim_cities` | Table | City attributes with coordinates |
| `dim_countries` | Table | Country attributes, ISO codes, continent |
| `dim_dates` | Table | Date dimension derived from flight dates |
| `dim_taxes` | Table | Tax codes and names |
| `fact_flights` | Table | One row per flight with FKs to all dims and measures |

---

## Star Schema

```
                         dim_dates
                            │
           dim_airlines      │       dim_airports
                 │           │            │
dim_airplanes ───┤           │            ├─── dim_cities
                 │           │            │
dim_taxes ───────┴─── fact_flights ───────┴─── dim_countries
```

**fact_flights measures:**

| Column | Description |
|---|---|
| `departure_delay_minutes` | Actual departure delay in minutes (0 if on time) |
| `arrival_delay_minutes` | Actual arrival delay in minutes (0 if on time) |
| `total_flight_time_minutes` | Actual gate-to-gate duration |
| `scheduled_flight_time_minutes` | Planned gate-to-gate duration |
| `delay_percentage` | Departure delay as a % of scheduled flight time |
| `on_time_performance_score` | Score 0–100, higher is better |
| `delay_status_flag` | `On Time` / `Delayed` / `Cancelled` |
| `number_of_delay` | `1` if delayed, `0` if on time |
| `is_cancelled` | Boolean cancellation flag |

---

## Data Quality

**102 dbt tests** across all 15 models:

| Test type | What it checks |
|---|---|
| `not_null` | All primary and foreign key columns have values |
| `unique` | All surrogate and natural keys are distinct |
| `accepted_values` | `flight_status`, `delay_status_flag`, `number_of_delay`, `continent` match expected enums |

Run all tests:
```bash
dbt test
```

---

## Setup & Installation

### Prerequisites
- Python 3.9+
- AWS account (S3, Lambda, Redshift Serverless, IAM, Secrets Manager)
- AviationStack API key — [free plan](https://aviationstack.com/) works
- Apache Airflow

### 1. Clone the repo
```bash
git clone https://github.com/Husein6314/elt_aviation_pipeline.git
cd elt_aviation_pipeline
```

### 2. Create virtual environment
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Configure environment variables
```bash
cp .env.example .env
```

Open `.env` and fill in your values:
```env
API_KEY=your_aviationstack_api_key

AWS_REGION=us-west-2
S3_BUCKET=your_s3_bucket_name
REDSHIFT_WORKGROUP=your_workgroup_name
REDSHIFT_DATABASE=your_database_name
REDSHIFT_SECRET_ARN=arn:aws:secretsmanager:region:account:secret:your-secret
REDSHIFT_IAM_ROLE=arn:aws:iam::account-id:role/your-role
```

### 4. Create Redshift tables
Run the DDL against your Redshift Serverless endpoint:
```bash
# In Redshift Query Editor or psql
\i redshift/create_tables.sql
```

### 5. Deploy Lambda
1. Go to AWS Lambda → Create function
2. Upload `lambda/lambda_function.zip`
3. Set the required environment variables (`REDSHIFT_WORKGROUP`, `REDSHIFT_DATABASE`, `REDSHIFT_SECRET_ARN`, `REDSHIFT_IAM_ROLE`, `AWS_REGION`)
4. Add an S3 trigger on your bucket for `ObjectCreated` events

### 6. Configure dbt profile
Create `~/.dbt/profiles.yml`:
```yaml
dbt_aviation:
  target: dev
  outputs:
    dev:
      type: redshift
      host: your-workgroup.your-account.us-west-2.redshift-serverless.amazonaws.com
      user: your_user
      password: your_password
      port: 5439
      dbname: your_database
      schema: raw
      threads: 4
```

### 7. Run dbt
```bash
cd dbt_aviation
dbt run     # builds all 15 models — staging views + analytics tables
dbt test    # runs 102 data quality tests
```

### 8. Start Airflow
```bash
airflow db init
airflow scheduler &
airflow webserver
```

The DAG `aviation_pipeline` will run daily at midnight automatically.

---

## Environment Variables Reference

| Variable | Description |
|---|---|
| `API_KEY` | AviationStack API key |
| `S3_BUCKET` | S3 bucket name for raw data storage |
| `REDSHIFT_WORKGROUP` | Redshift Serverless workgroup name |
| `REDSHIFT_DATABASE` | Redshift database name |
| `REDSHIFT_SECRET_ARN` | AWS Secrets Manager ARN for Redshift credentials |
| `REDSHIFT_IAM_ROLE` | IAM role ARN granted S3 read access for COPY |
| `AWS_REGION` | AWS region (default: `us-west-2`) |

---

## Author

**Husein Hadliye**
GitHub: [@Husein6314](https://github.com/Husein6314)
Email: husseinhadliye@gmail.com
