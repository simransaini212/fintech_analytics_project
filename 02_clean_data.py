import pandas as pd
import numpy as np

print("=" * 50)
print("PHASE 2: DATA CLEANING & TRANSFORMATION PIPELINE")
print("=" * 50)

# 1. LOAD RAW DATA
print("\n[Step 1] Loading raw CSV files...")
df_users = pd.read_csv("users_raw.csv")
df_events = pd.read_csv("events_raw.csv")

print(f"- Total Users Loaded: {len(df_users)}")
print(f"- Total Raw Events Loaded (with duplicates): {len(df_events)}")

# 2. DEDUPLICATION
# Real-world stream data mein duplicate events ko uniquely identify karke drop karna
initial_event_count = len(df_events)
df_events_clean = df_events.drop_duplicates(subset=['event_id'], keep='first').copy()
dropped_rows = initial_event_count - len(df_events_clean)
print(f"\n[Step 2] Deduplication completed: Dropped {dropped_rows} duplicate rows.")

# 3. DATETIME CONVERSION & SAFE PARSING
print("\n[Step 3] Standardizing timestamps...")
df_users['signup_date'] = pd.to_datetime(df_users['signup_date'], errors='coerce')
df_events_clean['event_timestamp'] = pd.to_datetime(df_events_clean['event_timestamp'], errors='coerce')

# Missing / non-monetary amount values ko clean karna
df_events_clean['amount'] = pd.to_numeric(df_events_clean['amount'], errors='coerce').fillna(0.0)

# 4. PREPARING DATA FOR ML & ANALYTICS
print("\n[Step 4] Engineering User-Level Features for ML & SQL Analytics...")

# A. Target Variable: Kis user ne deposit complete kiya? (1 = Yes, 0 = No)
deposit_users = df_events_clean[df_events_clean['event_type'] == 'First_Deposit']['user_id'].unique()
df_users['converted_to_deposit'] = df_users['user_id'].isin(deposit_users).astype(int)

# B. Feature: Hours to Submit KYC (Latency Feature)
kyc_submits = df_events_clean[df_events_clean['event_type'] == 'KYC_Submitted'][['user_id', 'event_timestamp']]
kyc_submits = kyc_submits.rename(columns={'event_timestamp': 'kyc_submit_time'})

# Merge with users to compute hours difference
df_user_features = pd.merge(df_users, kyc_submits, on='user_id', how='left')

df_user_features['hours_to_kyc_submit'] = (
    (df_user_features['kyc_submit_time'] - df_user_features['signup_date']).dt.total_seconds() / 3600.0
).round(2)

# Jo users drop ho gaye aur KYC submit hi nahi kiya, unka null latency 999.0 hours rakhna (Penalty value)
df_user_features['hours_to_kyc_submit'] = df_user_features['hours_to_kyc_submit'].fillna(999.0)

# Clean table without temp columns
dim_users_final = df_user_features[[
    'user_id', 'signup_date', 'region', 'device_type', 
    'hours_to_kyc_submit', 'converted_to_deposit'
]].copy()

# 5. EXPORT CLEANED DATASETS
print("\n[Step 5] Exporting clean CSV files...")
dim_users_final.to_csv("dim_users_clean.csv", index=False)
df_events_clean.to_csv("fct_events_clean.csv", index=False)

print("\nSUCCESS!")
print(f"-> 'dim_users_clean.csv' created with {len(dim_users_final)} records.")
print(f"-> 'fct_events_clean.csv' created with {len(df_events_clean)} records.")
print("=" * 50)