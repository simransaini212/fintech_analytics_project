IF OBJECT_ID('dbo.gold_user_segments', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.gold_user_segments (
        user_id VARCHAR(50) PRIMARY KEY,
        signup_time DATETIME2,
        first_deposit_time DATETIME2,
        first_deposit_amount DECIMAL(18, 2),
        deposit_quartile INT,
        customer_segment_tag VARCHAR(50),
        last_updated_at DATETIME2 DEFAULT GETDATE()
    );
END
GO

--Procedure


CREATE OR ALTER PROCEDURE dbo.sp_populate_gold_segments
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Purana snapshot clean karo
    TRUNCATE TABLE dbo.gold_user_segments;

    -- 2. View se latest calculated segments load karo
    INSERT INTO dbo.gold_user_segments (
        user_id,
        signup_time,
        first_deposit_time,
        first_deposit_amount,
        deposit_quartile,
        customer_segment_tag
    )
    
    SELECT 
        user_id,
        signup_time,
        first_deposit_time,
        first_deposit_amount,
        deposit_quartile,
        customer_segment_tag
    FROM dbo.vw_user_deposit_segments;

    PRINT 'Gold Table dbo.gold_user_segments refreshed successfully at ' + CONVERT(VARCHAR, GETDATE(), 120);
END
GO


EXEC dbo.sp_populate_gold_segments;

SELECT COUNT(1) AS total_records FROM dbo.gold_user_segments;
SELECT TOP 5 * FROM dbo.gold_user_segments ORDER BY first_deposit_amount DESC;