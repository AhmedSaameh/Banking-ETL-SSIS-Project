BEGIN TRY
 DROP TABLE [Dim_Date];
END TRY
BEGIN CATCH
 -- DO NOTHING
END CATCH;

CREATE TABLE [dbo].[Dim_Date] (
 [Date_SK] int NOT NULL, -- بصيغة YYYYMMDD
 [Date] date NOT NULL,
 [Day] char(2) NOT NULL,
 [DaySuffix] varchar(4) NOT NULL,
 [DayOfWeek] varchar(9) NOT NULL,
 [DOWInMonth] tinyint NOT NULL,
 [DayOfYear] int NOT NULL,
 [WeekOfYear] tinyint NOT NULL,
 [WeekOfMonth] tinyint NOT NULL,
 [Month] char(2) NOT NULL,
 [MonthName] varchar(9) NOT NULL,
 [Quarter] tinyint NOT NULL,
 [QuarterName] varchar(6) NOT NULL,
 [Year] char(4) NOT NULL,
 [StandardDate] varchar(10) NULL,
 [Holiday_name_en] varchar(50) NULL,
 CONSTRAINT [PK_Dim_Date] PRIMARY KEY CLUSTERED ([Date_SK])
);

TRUNCATE TABLE Dim_Date;

DECLARE @tmpDOW TABLE (DOW INT, Cntr INT);
INSERT INTO @tmpDOW(DOW, Cntr) VALUES (1,0),(2,0),(3,0),(4,0),(5,0),(6,0),(7,0);

DECLARE @StartDate datetime = '2020-01-01';
DECLARE @EndDate datetime = '2030-01-01'; -- non-inclusive
DECLARE @Date datetime = @StartDate;
DECLARE @WDofMonth INT;
DECLARE @CurrentMonth INT = MONTH(@StartDate);

WHILE @Date < @EndDate
BEGIN
 IF MONTH(@Date) <> @CurrentMonth
 BEGIN
  SET @CurrentMonth = MONTH(@Date);
  UPDATE @tmpDOW SET Cntr = 0;
 END

 UPDATE @tmpDOW SET Cntr = Cntr + 1 WHERE DOW = DATEPART(WEEKDAY, @Date);
 SELECT @WDofMonth = Cntr FROM @tmpDOW WHERE DOW = DATEPART(WEEKDAY, @Date);

 INSERT INTO Dim_Date (
  Date_SK, Date, Day, DaySuffix, DayOfWeek, DOWInMonth, DayOfYear,
  WeekOfYear, WeekOfMonth, Month, MonthName, Quarter, QuarterName, Year
 )
 SELECT 
  CONVERT(varchar, @Date, 112),
  @Date,
  RIGHT('0' + CAST(DAY(@Date) AS varchar), 2),
  CASE 
   WHEN DAY(@Date) IN (11,12,13) THEN CAST(DAY(@Date) AS varchar) + 'th'
   WHEN RIGHT(CAST(DAY(@Date) AS varchar),1) = '1' THEN CAST(DAY(@Date) AS varchar) + 'st'
   WHEN RIGHT(CAST(DAY(@Date) AS varchar),1) = '2' THEN CAST(DAY(@Date) AS varchar) + 'nd'
   WHEN RIGHT(CAST(DAY(@Date) AS varchar),1) = '3' THEN CAST(DAY(@Date) AS varchar) + 'rd'
   ELSE CAST(DAY(@Date) AS varchar) + 'th'
  END,
  DATENAME(WEEKDAY, @Date),
  @WDofMonth,
  DATEPART(DAYOFYEAR, @Date),
  DATEPART(WEEK, @Date),
  DATEPART(WEEK, @Date) + 1 - DATEPART(WEEK, CAST(CAST(MONTH(@Date) AS varchar) + '/1/' + CAST(YEAR(@Date) AS varchar) AS datetime)),
  RIGHT('0' + CAST(MONTH(@Date) AS varchar), 2),
  DATENAME(MONTH, @Date),
  DATEPART(QUARTER, @Date),
  CASE DATEPART(QUARTER, @Date)
   WHEN 1 THEN 'First'
   WHEN 2 THEN 'Second'
   WHEN 3 THEN 'Third'
   WHEN 4 THEN 'Fourth'
  END,
  CAST(YEAR(@Date) AS char(4));

 SET @Date = DATEADD(DAY, 1, @Date);
END;

-- Format standard date (MM/DD/YYYY)
UPDATE Dim_Date
SET StandardDate = [Month] + '/' + [Day] + '/' + [Year];

-- ✅ Optional: Add US holidays
-- Example: New Year's Day
UPDATE Dim_Date SET Holiday_name_en = 'New Year''s Day' WHERE Month = '01' AND Day = '01';
UPDATE Dim_Date SET Holiday_name_en = 'Valentine''s Day' WHERE Month = '02' AND Day = '14';
UPDATE Dim_Date SET Holiday_name_en = 'Independence Day' WHERE Month = '07' AND Day = '04';
UPDATE Dim_Date SET Holiday_name_en = 'Halloween' WHERE Month = '10' AND Day = '31';
UPDATE Dim_Date SET Holiday_name_en = 'Christmas Day' WHERE Month = '12' AND Day = '25';

-- Example: Thanksgiving (4th Thursday of November)
UPDATE Dim_Date
SET Holiday_name_en = 'Thanksgiving Day'
WHERE Month = '11' AND DayOfWeek = 'Thursday' AND DOWInMonth = 4;

-- ✅ Add any other local holidays manually if حابب تعمل dimension for مصر أو غيرها.

-- ✅ Optional indexes
CREATE INDEX IDX_Dim_Date_Year ON Dim_Date ([Year]);
CREATE INDEX IDX_Dim_Date_Month ON Dim_Date ([Month]);
CREATE INDEX IDX_Dim_Date_StandardDate ON Dim_Date ([StandardDate]);
CREATE INDEX IDX_Dim_Date_Holiday ON Dim_Date ([Holiday_name_en]);

PRINT 'Done at: ' + CONVERT(varchar, GETDATE(), 113);
