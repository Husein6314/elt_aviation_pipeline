import os
import time
import boto3
from datetime import datetime, timedelta
from dotenv import load_dotenv
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

load_dotenv("/Users/hussein/Documents/elt_aviation_pipeline/.env")

PROJECT_DIR = "/Users/hussein/Documents/elt_aviation_pipeline"
PYTHON      = f"{PROJECT_DIR}/venv/bin/python"

WORKGROUP  = os.environ["REDSHIFT_WORKGROUP"]
DATABASE   = os.environ["REDSHIFT_DATABASE"]
SECRET_ARN = os.environ["REDSHIFT_SECRET_ARN"]

TABLES = [
    '"raw".flights',
    '"raw".airlines',
    '"raw".airports',
    '"raw".airplanes',
    '"raw".cities',
    '"raw".countries',
    '"raw".taxes',
]


def verify_redshift():
    client = boto3.client("redshift-data", region_name="us-west-2")
    for table in TABLES:
        resp = client.execute_statement(
            WorkgroupName=WORKGROUP,
            Database=DATABASE,
            SecretArn=SECRET_ARN,
            Sql=f"SELECT COUNT(*) FROM {table}",
        )
        stmt_id = resp["Id"]
        while True:
            desc = client.describe_statement(Id=stmt_id)
            if desc["Status"] == "FINISHED":
                count = client.get_statement_result(Id=stmt_id)["Records"][0][0]["longValue"]
                print(f"✅ {table}: {count} rows")
                break
            elif desc["Status"] in ("FAILED", "ABORTED"):
                raise Exception(f"Query failed for {table}: {desc.get('Error')}")
            time.sleep(1)


default_args = {
    "owner": "airflow",
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

with DAG(
    dag_id="aviation_pipeline",
    default_args=default_args,
    description="ELT Aviation Pipeline: API → S3 → Redshift",
    schedule_interval="@daily",
    start_date=datetime(2026, 6, 1),
    catchup=False,
) as dag:

    fetch_flights = BashOperator(
        task_id="fetch_flights",
        bash_command=f"{PYTHON} {PROJECT_DIR}/api_extraction/flights_api.py",
    )

    fetch_reference = BashOperator(
        task_id="fetch_reference",
        bash_command=f"{PYTHON} {PROJECT_DIR}/api_extraction/reference_api.py",
    )

    upload_flights = BashOperator(
        task_id="upload_flights_to_s3",
        bash_command=f"{PYTHON} {PROJECT_DIR}/api_extraction/upload_to_s3.py",
    )

    upload_reference = BashOperator(
        task_id="upload_reference_to_s3",
        bash_command=f"{PYTHON} {PROJECT_DIR}/api_extraction/upload_reference_to_s3.py",
    )

    verify = PythonOperator(
        task_id="verify_redshift",
        python_callable=verify_redshift,
    )

    fetch_flights >> upload_flights
    fetch_reference >> upload_reference
    [upload_flights, upload_reference] >> verify
