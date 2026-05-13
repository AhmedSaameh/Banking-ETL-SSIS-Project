Create table Dim_user
(
	UserID_SK int primary key identity(1,1),
	UserID_BK smallint not null,
	current_age tinyint,
	retirement_age tinyint,
	birth_year smallint,
	birth_month tinyint,
	gender nvarchar(50),
	address nvarchar(200),
	latitude float,
	longitude float,
	per_capita_income money,
	yearly_income money,
	total_debt money,
	credit_score smallint,
	num_credit_cards tinyint,

	/*	I choose the date datatype not datetime datatpye because these altitude, longitude,per_capita_income, yearly_income 
		changing in long time period not in the same day
	*/
	start_date datetime,
	end_date datetime,
	is_current bit
)
GO
create table Dim_card
(
	CardID_SK int primary key identity(1,1),
	CardID_BK smallint not null,
	userID_SK int,
	card_brand nvarchar(50),
	card_type nvarchar(50),
	card_number bigint,
	expires nvarchar(50),
	cvv smallint,
	has_ship bit,
	num_cards_issued tinyint,
	credit_limit money,
	acct_open_date nvarchar(50),
	year_pin_last_changed smallint,
	card_on_dark_web nvarchar(50),
	
	-- Slowly Changing Dimension (SCD) for expires, credit_limit, year_pin_last_changed, card_on_dark_web

	start_date datetime,
	end_date datetime,
	is_current bit

)
GO

Create table Dim_merchant 
(
	merchantID_SK int primary key identity(1,1),
	merchantID_BK int not null,
	merchant_city nvarchar(100),
	merchant_state nvarchar(100),
	zip nvarchar(20),
	mcc smallint
)
GO

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

DECLARE @StartDate datetime = '2009-01-01';
DECLARE @EndDate datetime = '2021-01-01'; -- non-inclusive
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

GO

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
GO

Create table Fact_transactions
(
	Fact_transaction_SK int primary key identity(1,1),
	transaction_BK int,
	userID_FK int not null,
	cardID_FK int not null,
	transaction_date_FK int not null,
	transaction_time_FK int not null,
	merchantID_FK int not null,
	amount money,
	use_chip nvarchar(100),
	errors nvarchar(max),

	constraint fk1 foreign key (userID_FK) references dim_user(userID_SK),
	constraint fk2 foreign key (cardID_FK) references dim_card(cardID_SK),
	constraint fk3 foreign key (merchantID_FK) references dim_merchant(merchantID_SK),
	constraint fk4 foreign key (transaction_date_FK) references dim_date(date_SK),
	constraint fk5 foreign key (transaction_time_FK) references dim_time(time_SK)



)
