import boto3
import os
from botocore.exceptions import ClientError

S3_BUCKET = os.environ.get("S3_BUCKET", "aviation-pipeline-raw")
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REFERENCE_DIR = os.path.join(BASE_DIR, "data", "reference")

s3 = boto3.client("s3")


def exists_in_s3(key):
    try:
        s3.head_object(Bucket=S3_BUCKET, Key=key)
        return True
    except ClientError:
        return False


for file in os.listdir(REFERENCE_DIR):
    if file.endswith(".csv"):
        s3_key = f"reference/{file}"
        if exists_in_s3(s3_key):
            print(f"⚠ {file} already in S3, skipping")
            continue
        s3.upload_file(os.path.join(REFERENCE_DIR, file), S3_BUCKET, s3_key)
        print(f"✅ {file} uploaded to s3://{S3_BUCKET}/{s3_key}")
