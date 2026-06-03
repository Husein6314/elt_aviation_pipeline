import pandas as pd
from sqlalchemy import create_engine, text
import os
from urllib.parse import quote_plus

password = quote_plus("Hussein@14")
engine = create_engine(f"postgresql+psycopg2://postgres:{password}@localhost:5432/aviation_dw")

base_path = "/Users/hussein/Documents/elt_aviation_pipeline/data"
folders = ["flights", "reference"]

for folder in folders:
    folder_path = os.path.join(base_path, folder)
    for file in os.listdir(folder_path):
        if file.endswith(".csv"):
            table_name = file.replace(".csv", "").split("_")[0] if folder == "flights" else file.replace(".csv", "")
            df = pd.read_csv(os.path.join(folder_path, file))

            with engine.connect() as conn:
                conn.execute(text(f"TRUNCATE TABLE raw.{table_name}"))
                conn.commit()

            df.to_sql(table_name, engine, schema="raw", if_exists="append", index=False)
            print(f"✅ {table_name} successfully loaded into raw schema")
