import requests
import pandas as pd
import os
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv('API_KEY')

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_DIR = os.path.join(BASE_DIR, "data", "reference")

REFERENCE_ENDPOINTS = [
    "countries",
    "cities",
    "airlines",
    "airports",
    "airplanes",
    "taxes"
]


def fetch_reference(endpoint, limit=1000):
    url = f"https://api.aviationstack.com/v1/{endpoint}"
    params = {"access_key": API_KEY, "limit": limit}
    response = requests.get(url, params=params)
    if response.status_code != 200:
        print(f"❌ Error {response.status_code} for {endpoint}")
        return []
    return response.json().get("data", [])


def save_reference(endpoint, data):
    if not data:
        print(f"⚠ No data for {endpoint}")
        return

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_path = os.path.join(OUTPUT_DIR, f"{endpoint}.csv")
    df = pd.DataFrame(data)
    df.to_csv(output_path, index=False)
    print(f"✅ Saved {len(df)} records → {output_path}")


if __name__ == "__main__":
    for endpoint in REFERENCE_ENDPOINTS:
        data = fetch_reference(endpoint)
        save_reference(endpoint, data)
