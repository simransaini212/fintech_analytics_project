import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Fixed seeds taaki data predictable aur standard rahe
np.random.seed(42)
random.seed(42)

num_users = 1000

# 1. Users Table Generation (Demographics & Signup Info)
user_ids = [f"USR_{1000 + i}" for i in range(num_users)]
signup_dates = [datetime(2024, 1, 1) + timedelta(days=random.randint(0, 180)) for _ in range(num_users)]
regions = random.choices(['North', 'South', 'West', 'East'], weights=[0.35, 0.25, 0.25, 0.15], k=num_users)
device_types = random.choices(['Android', 'iOS', 'Web'], weights=[0.6, 0.3, 0.1], k=num_users)

df_users = pd.DataFrame({
    'user_id': user_ids,
    'signup_date': signup_dates,
    'region': regions,
    'device_type': device_types
})

# 2. Transaction & Funnel Events Log
events_data = []
event_id = 50000

for idx, user in df_users.iterrows():
    curr_time = user['signup_date']
    u_id = user['user_id']
    
    # Stage 1: Signup Event
    events_data.append([event_id, u_id, 'Signup', curr_time, 0.0, 'Success'])
    event_id += 1
    
    # Stage 2: KYC Submitted (85% user conversion)
    if random.random() < 0.85:
        curr_time += timedelta(hours=random.randint(1, 24))
        events_data.append([event_id, u_id, 'KYC_Submitted', curr_time, 0.0, 'Success'])
        event_id += 1
        
        # Stage 3: KYC Approved (75% user conversion)
        if random.random() < 0.75:
            curr_time += timedelta(hours=random.randint(2, 48))
            events_data.append([event_id, u_id, 'KYC_Approved', curr_time, 0.0, 'Success'])
            event_id += 1
            
            # Stage 4: First Deposit (60% user conversion)
            if random.random() < 0.60:
                curr_time += timedelta(days=random.randint(1, 7))
                deposit_amt = round(random.uniform(500, 25000), 2)
                events_data.append([event_id, u_id, 'First_Deposit', curr_time, deposit_amt, 'Success'])
                event_id += 1
                
                # Stage 5: Regular Transactions
                for _ in range(random.randint(1, 4)):
                    curr_time += timedelta(days=random.randint(1, 15))
                    tx_amt = round(random.uniform(100, 10000), 2)
                    status = random.choices(['Success', 'Failed'], weights=[0.92, 0.08])[0]
                    events_data.append([event_id, u_id, 'Transaction_Completed', curr_time, tx_amt, status])
                    event_id += 1

columns = ['event_id', 'user_id', 'event_type', 'event_timestamp', 'amount', 'status']
df_events = pd.DataFrame(events_data, columns=columns)

# Real-world Dirty Data Simulation: 50 duplicate rows add kar rahe hain
duplicates = df_events.sample(n=50, random_state=42)
df_events_dirty = pd.concat([df_events, duplicates], ignore_index=True)

# CSV Files Save Karna
df_users.to_csv("users_raw.csv", index=False)
df_events_dirty.to_csv("events_raw.csv", index=False)

print("SUCCESS: Raw files generated successfully!")
print(f"1. users_raw.csv ({len(df_users)} rows)")
print(f"2. events_raw.csv ({len(df_events_dirty)} rows)")