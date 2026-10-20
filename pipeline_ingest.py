import datetime
import pandas as pd
import pyodbc

# ==========================================
# 1. DATABASE CONFIGURATION
# ==========================================
SERVER_NAME = r"localhost\SQLEXPRESS"
DATABASE_NAME = "FintechAnalyticsDB"

CONNECTION_STRING = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER_NAME};"
    f"DATABASE={DATABASE_NAME};"
    "Trusted_Connection=yes;"
)


def run_pipeline(csv_file_path: str):
    start_time = datetime.datetime.now()
    print(
        f"[{start_time.strftime('%Y-%m-%d %H:%M:%S')}] --- INGESTION PIPELINE STARTED ---"
    )

    # ==========================================
    # 2. BRONZE LAYER: EXTRACT & VALIDATE
    # ==========================================
    print(f"\n[BRONZE] Reading raw file from: {csv_file_path}")
    df = pd.read_csv(csv_file_path)
    print(f"[BRONZE] Total raw events loaded into memory: {len(df)}")

    # Data Quality Validation
    if df["user_id"].isnull().any():
        raise ValueError("[ERROR] user_id contains NULL values!")
    if df["event_timestamp"].isnull().any():
        raise ValueError("[ERROR] event_timestamp contains NULL values!")

    # NaN amounts ko SQL NULL (None) mein convert karna
    df["amount"] = df["amount"].where(pd.notnull(df["amount"]), None)
    print("[VALIDATION] Quality checks passed.")

    # Status column check
    if "status" not in df.columns:
        df["status"] = "Success"
    else:
        df["status"] = df["status"].fillna("Success")

    # FIX DUPLICATE PRIMARY KEY: Fresh clean sequence assign karein (1 to Total Rows)
    df["event_id"] = range(1, len(df) + 1)
    print(f"[CLEANSE] Generated clean sequential event_ids from 1 to {len(df)}.")

    # ==========================================
    # 3. SILVER LAYER: BULK LOAD (fct_events)
    # ==========================================
    print("\n[SILVER] Connecting to SQL Server...")
    conn = pyodbc.connect(CONNECTION_STRING)
    cursor = conn.cursor()

    # Table truncate karein taaki fresh load ho sake
    print("[SILVER] Truncating dbo.fct_events for clean load...")
    cursor.execute("TRUNCATE TABLE dbo.fct_events;")
    conn.commit()

    insert_query = """
    INSERT INTO dbo.fct_events (event_id, user_id, event_type, event_timestamp, amount, status)
    VALUES (?, ?, ?, ?, ?, ?)
    """

    records_to_insert = [
        tuple(x)
        for x in df[
            ["event_id", "user_id", "event_type", "event_timestamp", "amount", "status"]
        ].to_numpy()
    ]

    print(
        f"[SILVER] Ingesting {len(records_to_insert)} records into dbo.fct_events..."
    )
    cursor.fast_executemany = True
    cursor.executemany(insert_query, records_to_insert)
    conn.commit()
    print("[SILVER] Records successfully written to dbo.fct_events.")

    # ==========================================
    # 4. GOLD LAYER: TRIGGER STORED PROCEDURE
    # ==========================================
    print(
        "\n[GOLD] Triggering Stored Procedure: dbo.sp_populate_gold_segments..."
    )
    cursor.execute("EXEC dbo.sp_populate_gold_segments;")
    conn.commit()

    cursor.execute("SELECT COUNT(1) FROM dbo.gold_user_segments;")
    gold_count = cursor.fetchone()[0]
    print(
        f"[GOLD] Materialization complete! Total users in gold table: {gold_count}"
    )

    cursor.close()
    conn.close()

    duration = (datetime.datetime.now() - start_time).total_seconds()
    print(f"\n--- PIPELINE FINISHED IN {duration:.2f}s ---")


if __name__ == "__main__":
    run_pipeline("events_raw.csv")