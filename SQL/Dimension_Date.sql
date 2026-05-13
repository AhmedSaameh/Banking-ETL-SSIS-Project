SET ANSI_PADDING OFF;
BEGIN TRY
 DROP TABLE [Dim_Time];
END TRY
BEGIN CATCH
 --DO NOTHING
END CATCH;

CREATE TABLE [dbo].[Dim_Time] (
 [Time_SK] int IDENTITY(1,1) NOT NULL,
 [Time] time(0) NOT NULL,
 [Hour] char(2) NOT NULL,
 [MilitaryHour] char(2) NOT NULL,
 [Minute] char(2) NOT NULL,
 [Second] char(2) NOT NULL,
 [AmPm] char(2) NOT NULL,
 [StandardTime] char(11) NULL,
 CONSTRAINT [PK_Dim_Time] PRIMARY KEY CLUSTERED (
  [Time_SK] ASC
 ) WITH (
  PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
  ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
 ) ON [PRIMARY]
) ON [PRIMARY];

GO
SET ANSI_PADDING OFF;

PRINT CONVERT(varchar, GETDATE(), 113); -- Start time

-- Load time data for every second of the day
DECLARE @Time datetime;
SET @Time = '00:00:00';

TRUNCATE TABLE [Dim_Time];

WHILE @Time <= '23:59:59'
BEGIN
 INSERT INTO [dbo].[Dim_Time] ([Time], [Hour], [MilitaryHour], [Minute], [Second], [AmPm])
 SELECT 
  CONVERT(varchar, @Time, 108),
  CASE 
   WHEN DATEPART(HOUR, @Time) = 0 THEN 12
   WHEN DATEPART(HOUR, @Time) > 12 THEN DATEPART(HOUR, @Time) - 12
   ELSE DATEPART(HOUR, @Time)
  END,
  RIGHT('0' + CAST(DATEPART(HOUR, @Time) AS varchar), 2),
  RIGHT('0' + CAST(DATEPART(MINUTE, @Time) AS varchar), 2),
  RIGHT('0' + CAST(DATEPART(SECOND, @Time) AS varchar), 2),
  CASE WHEN DATEPART(HOUR, @Time) >= 12 THEN 'PM' ELSE 'AM' END;

 SET @Time = DATEADD(SECOND, 1, @Time);
END;

-- Fix formatting
UPDATE [Dim_Time] SET [Hour] = '0' + [Hour] WHERE LEN([Hour]) = 1;
UPDATE [Dim_Time] SET [Minute] = '0' + [Minute] WHERE LEN([Minute]) = 1;
UPDATE [Dim_Time] SET [Second] = '0' + [Second] WHERE LEN([Second]) = 1;
UPDATE [Dim_Time] SET [MilitaryHour] = '0' + [MilitaryHour] WHERE LEN([MilitaryHour]) = 1;

UPDATE [Dim_Time]
SET [StandardTime] = 
  CASE WHEN [Hour] = '00' THEN '12' ELSE [Hour] END + ':' + [Minute] + ':' + [Second] + ' ' + [AmPm]
WHERE [StandardTime] IS NULL;

-- Create indexes
CREATE UNIQUE NONCLUSTERED INDEX [IDX_Dim_Time_Time] ON [dbo].[Dim_Time] ([Time]);
CREATE NONCLUSTERED INDEX [IDX_Dim_Time_Hour] ON [dbo].[Dim_Time] ([Hour]);
CREATE NONCLUSTERED INDEX [IDX_Dim_Time_MilitaryHour] ON [dbo].[Dim_Time] ([MilitaryHour]);
CREATE NONCLUSTERED INDEX [IDX_Dim_Time_Minute] ON [dbo].[Dim_Time] ([Minute]);
CREATE NONCLUSTERED INDEX [IDX_Dim_Time_Second] ON [dbo].[Dim_Time] ([Second]);
CREATE NONCLUSTERED INDEX [IDX_Dim_Time_AmPm] ON [dbo].[Dim_Time] ([AmPm]);
CREATE NONCLUSTERED INDEX [IDX_Dim_Time_StandardTime] ON [dbo].[Dim_Time] ([StandardTime]);

PRINT CONVERT(varchar, GETDATE(), 113); -- End time
