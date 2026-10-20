/******************************************************************************************************************/
/* query to check how many users reach to which event
(kitne users ne signup kiya or kitne actually convert hue)
********************************************************************************************************************/

SELECT event_type,count(distinct user_id) as Reach_to_event
from dbo.fct_events
group by event_type;

USE FintechAnalyticsDB;
 
 SELECT TOP 5 * FROM dbo.dim_users;
SELECT TOP 55 * FROM dbo.fct_events;

/******************************************************************************************************************/
/* query to check the conversion rate of each device user 
(check krte h ki khi devices me to koi bug nhi h... but converson rate almost same h mtlb devices me koi issue nhi h)
********************************************************************************************************************/
select device_type, count(distinct user_id) as total_signups, sum(converted_to_deposit) as converted_users,
round((sum(converted_to_deposit)*100.0)/count(distinct user_id),2)as conversion_rate_pct
from dbo.dim_users
group by device_type
order by conversion_rate_pct desc

/******************************************************************************************************************/
/* checking the conversion rate of people submit KYC early VS people submit KYC late
(check krte h ki jinhine jldi KYC submit krdi mtlb 
or jinhone late ki
********************************************************************************************************************/

with user_bucket as(
SELECT user_id, converted_to_deposit,
case when hours_to_kyc_submit<=24 then 'Fast KYC'
else 'Slow KYC'
end as KYC_bucket
       
FROM dbo.dim_users
WHERE hours_to_kyc_submit IS NOT NULL
)

SELECT 
KYC_bucket,
count(distinct user_id)as total_users, sum(converted_to_deposit)as converted_users, 
round((sum(converted_to_deposit)*100.0)/count(distinct user_id),2) as conversion_rate_pct
       
FROM user_bucket
GROUP BY KYC_bucket
ORDER BY conversion_rate_pct DESC;

/******************************************************************************************************************/
/* Funnel Latency Analysis using Timestamps
(Signup se First Deposit karne mein exact kitne ghante (hours) lage?)
Us latency ke basis par overall business ka Average Hours aur Fastest / Slowest conversion time kya hai?
********************************************************************************************************************/

with measure_time as(
select
min (case when event_type='Signup' then event_timestamp end) as signup_time,
min (case when event_type='First_Deposit' then event_timestamp end) as deposit_time,
user_id from dbo.fct_events
where event_type in ('Signup', 'First_Deposit')
group by user_id
HAVING MIN(CASE WHEN event_type = 'First_Deposit' THEN event_timestamp END) IS NOT NULL
)
SELECT 
    COUNT(user_id) AS total_converted_users,
    MIN(DATEDIFF(hour, signup_time, deposit_time)) AS fastest_hours,
    AVG(DATEDIFF(hour, signup_time, deposit_time)) AS avg_hours,
    MAX(DATEDIFF(hour, signup_time, deposit_time)) AS slowest_hours
FROM measure_time;

/*********************************************************************************************************************
Yani user KYC submit toh turant kar deta hai, 
lekin pehla paisa daalne mein usko 5 se 6 din ka average time lag raha hai

Real analytics mein hum yeh dekhte hain: Pichhle 218 dinon ke dauran,
kitne aise users the jinhone Signup toh kiya, par agle 5 dinon tak deposit nahi kiya?   
********************************************************************************************************************/

WITH user_milestones AS (
    SELECT 
        user_id,
        MIN(CASE WHEN event_type = 'Signup' THEN event_timestamp END) AS signup_time,
        MIN(CASE WHEN event_type = 'First_Deposit' THEN event_timestamp END) AS deposit_time
    FROM dbo.fct_events
    WHERE event_type IN ('Signup', 'First_Deposit')
    GROUP BY user_id
)
SELECT 
    CASE 
        WHEN deposit_time IS NULL THEN 'Never Deposited (Lost Users)'
        WHEN DATEDIFF(hour, signup_time, deposit_time) > 120 THEN 'Deposited After 5 Days (Slow)'
        ELSE 'Converted within 5 Days'
    END AS cohort_bucket,
    COUNT(user_id) AS total_users
FROM user_milestones
GROUP BY 
    CASE 
        WHEN deposit_time IS NULL THEN 'Never Deposited (Lost Users)'
        WHEN DATEDIFF(hour, signup_time, deposit_time) > 120 THEN 'Deposited After 5 Days (Slow)'
        ELSE 'Converted within 5 Days'
    END;

/******************************************************************************************************************
    Core Business Takeaway:
Converted logo mein se aadhe se zyada log (235 out of 422, yaani ~55.7%) 5 din ke baad deposit kar rahe hain!

Yahi reason tha ki hamara average latency 132 hours (~5.5 days) par baitha hua tha. User ko signup ke baad 5–10 
din tak platform par laane ke liye koi nudge nahi mil raha tha, isliye conversion itna stretch hua.
********************************************************************************************************************/


/******************************************************************************************************************
Milestone 2: User Segmentation / Deposit Sizing (NTILE)
Ab humein dekhna hai ki in 422 converted users ne paisa kitna daala. 
Kya saare 422 users ne chote amounts daale hain ya kuch top depositors (whales) hain?

Hamare paas 422 converted users hain. Hum in par NTILE(4) chalayenge taaki 4 Quartiles ban jayein:

Bucket 1: Top 25% big ticket deposits (VIP / High Net-worth users).

Bucket 2: Upper middle depositors.

Bucket 3: Lower middle depositors.

Bucket 4: Micro depositors (chote testing deposit wale).

Product team ko isse pata chalta hai ki business ka zyadatar revenue kis bucket se aa raha hai!
********************************************************************************************************************/
GO
CREATE OR ALTER VIEW dbo.vw_user_deposit_segments AS
WITH user_deposits AS (
    SELECT 
        user_id,
        MIN(event_timestamp) AS first_deposit_time,
        MAX(amount) AS first_deposit_amount,
        NTILE(4) OVER (ORDER BY MAX(amount) DESC) AS deposit_quartile
    FROM dbo.fct_events
    WHERE event_type = 'First_Deposit'
    GROUP BY user_id
)


SELECT 
    f.user_id,
    MIN(CASE WHEN f.event_type = 'Signup' THEN f.event_timestamp END) AS signup_time,
    ud.first_deposit_time,
    ud.first_deposit_amount,
    ud.deposit_quartile,
    CASE 
        WHEN ud.deposit_quartile = 1 THEN 'Whale / High Net-Worth'
        WHEN ud.deposit_quartile = 2 THEN 'Upper-Middle Tier'
        WHEN ud.deposit_quartile = 3 THEN 'Lower-Middle Tier'
        WHEN ud.deposit_quartile = 4 THEN 'Micro-Depositor'
        ELSE 'Unconverted / Churned'
    END AS customer_segment_tag
FROM dbo.fct_events f
LEFT JOIN user_deposits ud ON f.user_id = ud.user_id
GROUP BY 
    f.user_id, 
    ud.first_deposit_time, 
    ud.first_deposit_amount, 
    ud.deposit_quartile;
GO

-- View verify karne ke liye:
    SELECT  * 
FROM dbo.vw_user_deposit_segments
ORDER BY first_deposit_amount DESC;