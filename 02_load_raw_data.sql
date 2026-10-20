USE FintechAnalyticsDB;
GO

-- 1. Load Dimension Users
BULK INSERT dbo.dim_users
FROM 'C:\Users\DELL\OneDrive\Desktop\fintech_analytics_project\dim_users_clean.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,           -- Skips header row
    FIELDTERMINATOR = ',',  -- Comma separated
    ROWTERMINATOR = '\n',   -- Windows row delimiter (\r\n ya \n)
    TABLOCK
);
GO

-- 2. Load Fact Events
BULK INSERT dbo.fct_events
FROM 'C:\Users\DELL\OneDrive\Desktop\fintech_analytics_project\fct_events_clean.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
GO