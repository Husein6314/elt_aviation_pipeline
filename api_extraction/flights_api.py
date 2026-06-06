import requests
import pandas as pd
import json
from datetime import date
import os
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv('API_KEY')

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_DIR = os.path.join(BASE_DIR, "data", "flights")


def fetch_flights():
    url = "https://api.aviationstack.com/v1/flights"
    params = {"access_key": API_KEY, "limit": 100}
    response = requests.get(url, params=params)
    if response.status_code != 200:
        print(f"❌ Error {response.status_code} for flights")
        return []
    return response.json().get("data", [])


def serialize_nested(df):
    for col in df.columns:
        if df[col].apply(lambda x: isinstance(x, dict)).any():
            df[col] = df[col].apply(lambda x: json.dumps(x) if isinstance(x, dict) else x)
    return df


def save_flights(data, flight_date):
    if not data:
        print(f"⚠ No data returned for {flight_date}")
        return

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_path = os.path.join(OUTPUT_DIR, f"flights_{flight_date}.csv")

    if os.path.exists(output_path):
        print(f"⚠ Already extracted for {flight_date}, skipping.")
        return

    df = serialize_nested(pd.DataFrame(data))
    df.to_csv(output_path, index=False)
    print(f"✅ Saved {len(df)} records → {output_path}")


if __name__ == "__main__":
    today = date.today().isoformat()
    all_data = fetch_flights()

    todays_flights = [f for f in all_data if f.get("flight_date") == today]

    if not todays_flights:
        print(f"⚠ No flights found for {today}, saving all returned data instead.")
        save_flights(all_data, today)
    else:
        save_flights(todays_flights, today)
