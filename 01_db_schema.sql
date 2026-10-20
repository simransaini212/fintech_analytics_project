-- 1. Create Analytics Database
CREATE DATABASE FintechAnalyticsDB;
GO

USE FintechAnalyticsDB;
GO

-- 2. Create Dimension Table for Users
IF OBJECT_ID('dbo.dim_users', 'U') IS NOT NULL 
    DROP TABLE dbo.dim_users;
GO

CREATE TABLE dbo.dim_users (
    user_id VARCHAR(50) PRIMARY KEY,
    signup_date DATETIME NOT NULL,
    region VARCHAR(50) NOT NULL,
    device_type VARCHAR(50) NOT NULL,
    hours_to_kyc_submit DECIMAL(10, 2) NOT NULL,
    converted_to_deposit INT NOT NULL
);
GO

-- 3. Create Fact Table for Funnel Events
IF OBJECT_ID('dbo.fct_events', 'U') IS NOT NULL 
    DROP TABLE dbo.fct_events;
GO

CREATE TABLE dbo.fct_events (
    event_id BIGINT PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_timestamp DATETIME NOT NULL,
    amount DECIMAL(18, 2) DEFAULT 0.0,
    status VARCHAR(50) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES dbo.dim_users(user_id)
);
GO