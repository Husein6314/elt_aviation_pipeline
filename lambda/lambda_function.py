import os
import boto3
import urllib.parse

WORKGROUP  = os.environ["REDSHIFT_WORKGROUP"]
DATABASE   = os.environ["REDSHIFT_DATABASE"]
SECRET_ARN = os.environ["REDSHIFT_SECRET_ARN"]
IAM_ROLE   = os.environ["REDSHIFT_IAM_ROLE"]
REGION     = os.environ.get("AWS_REGION", "us-west-2")

TABLE_MAP = {
    "flights":  '"raw".flights',
    "airlines": '"raw".airlines',
    "airports": '"raw".airports',
    "airplanes":'"raw".airplanes',
    "countries":'"raw".countries',
    "cities":   '"raw".cities',
    "taxes":    '"raw".taxes',
}

redshift_data = boto3.client("redshift-data", region_name=REGION)


def get_table(s3_key):
    filename = s3_key.split("/")[-1].replace(".csv", "")
    if filename.startswith("flights_"):
        return TABLE_MAP["flights"]
    return TABLE_MAP.get(filename)


def lambda_handler(event, context):
    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        table = get_table(key)
        if not table:
            print(f"Unknown file {key}, skipping")
            continue

        sql = f"""
            COPY {table}
            FROM 's3://{bucket}/{key}'
            IAM_ROLE '{IAM_ROLE}'
            CSV
            IGNOREHEADER 1
            TRUNCATECOLUMNS
            BLANKSASNULL
            EMPTYASNULL;
        """

        response = redshift_data.execute_statement(
            WorkgroupName=WORKGROUP,
            Database=DATABASE,
            SecretArn=SECRET_ARN,
            Sql=sql,
        )

        print(f"COPY submitted: {key} -> {table} | ID: {response['Id']}")

    return {"statusCode": 200}
