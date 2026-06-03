# ELT Aviation Pipeline

An end-to-end ELT (Extract, Load, Transform) data pipeline for aviation flight data, built with Python, PostgreSQL, and dbt.

---

## Architecture

```
Aviation Stack API
       │
       ▼
[ Extract & Load ]
  Python scripts
  (api_extraction/)
       │
       ▼
[ PostgreSQL - raw schema ]
  Raw tables: flights, airlines, airplanes,
              airports, cities, countries, taxes
       │
       ▼
[ dbt - Transform ]
  Staging  → sr_flights, sr_airlines, sr_airports ...
  Dims     → dim_airlines, dim_airports, dim_dates ...
  Fact     → fact_flights
       │
       ▼
[ Analytics / BI ]
```

---

## Tech Stack

| Layer | Tool |
|---|---|
| Data Source | [Aviation Stack API](https://aviationstack.com/) |
| Language | Python 3.13 |
| Database | PostgreSQL 15 |
| Transformation | dbt 1.5.2 |
| Version Control | Git / GitHub |

---

## Project Structure

```
elt_aviation_pipeline/
├── api_extraction/
│   ├── flights_api.py        # Extracts flights + reference data from API
│   └── upload_into_psql.py   # Loads CSV files into PostgreSQL raw schema
├── dbt_aviation/
│   ├── models/
│   │   ├── staging/          # Cleans and casts raw data (views)
│   │   │   ├── sr_flights.sql
│   │   │   ├── sr_airlines.sql
│   │   │   ├── sr_airplanes.sql
│   │   │   ├── sr_airports.sql
│   │   │   ├── sr_cities.sql
│   │   │   ├── sr_countries.sql
│   │   │   ├── sr_taxes.sql
│   │   │   └── staging_schema.yml
│   │   └── analytics/
│   │       ├── dim/          # Dimension tables with surrogate keys
│   │       │   ├── dim_airlines.sql
│   │       │   ├── dim_airplanes.sql
│   │       │   ├── dim_airports.sql
│   │       │   ├── dim_cities.sql
│   │       │   ├── dim_countries.sql
│   │       │   ├── dim_dates.sql
│   │       │   ├── dim_taxes.sql
│   │       │   └── dim_schema.yml
│   │       └── fact/         # Fact table with measures
│   │           ├── fact_flights.sql
│   │           └── fact_schema.yml
│   ├── dbt_project.yml
│   └── profiles.yml
└── requirements.txt
```

---

## Data Model (Star Schema)

```
                    dim_airlines
                    dim_airplanes
                    dim_airports
fact_flights  ───►  dim_cities
                    dim_countries
                    dim_taxes
                    dim_dates
```

**fact_flights** contains one row per flight with:
- Surrogate keys pointing to all dimension tables
- Measures: departure/arrival delay, flight time, on-time performance score
- Flags: delay status, is_cancelled, number_of_delay

---

## How to Run

### 1. Install dependencies
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Set up environment variables
Create a `.env` file in the project root:
```
API_KEY=your_aviationstack_api_key
```

### 3. Extract data from API
```bash
cd api_extraction
python3 flights_api.py
```

### 4. Load data into PostgreSQL
```bash
python3 upload_into_psql.py
```

### 5. Run dbt transformations
```bash
cd ../dbt_aviation
dbt run
```

### 6. Run dbt tests
```bash
dbt test
```

### 7. View documentation
```bash
dbt docs generate
dbt docs serve
# Open http://localhost:8080
```

---

## dbt Tests

The pipeline has **102 tests** covering:
- `not_null` — critical columns are never null
- `unique` — surrogate keys have no duplicates
- `accepted_values` — status flags and categories are valid

---

## Data Quality Handling

Null values from the source API are handled in the staging layer using `coalesce()`:
- Missing `country_iso2` → `'XX'`
- Missing `population` → `0`
- Missing `iata_code` / ICAO codes → `'N/A'`
- Missing `continent` → `'Unknown'`
- Continent codes (e.g. `'AF'`) are expanded to full names (e.g. `'Africa'`)
