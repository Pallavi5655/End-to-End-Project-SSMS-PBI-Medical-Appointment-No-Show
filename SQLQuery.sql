
Create database healthcare_analytics
use healthcare_analytics

select top 10 * from [dbo].[Medical Appointment No Shows]

--Change the datetime and date columns from string to datetime & Date

ALTER TABLE [dbo].[Medical Appointment No Shows]
ALTER COLUMN scheduledday DATETIME;

ALTER TABLE [dbo].[Medical Appointment No Shows]
ALTER COLUMN AppointmentDay DATE;

--To check data for statistics or any incorrect data

select min(age) as Min_Age, Max(age) as Max_age from [dbo].[Medical Appointment No Shows]

-- To calculate lead days( days btween when someone booked the appointment and when appo. happended)

ALTER TABLE [dbo].[Medical Appointment No Shows]
ADD lead_time_days INT

UPDATE [dbo].[Medical Appointment No Shows]
SET lead_time_days = DATEDIFF(DAY, ScheduledDay, AppointmentDay)

SELECT MIN(lead_time_days), MAX(lead_time_days) FROM [dbo].[Medical Appointment No Shows]

--- To check how many rows are there with data error in dates of ScheduledDay, AppointmentDay
SELECT * FROM [dbo].[Medical Appointment No Shows]
WHERE lead_time_days <0

--- AS only 5 rows are with data error in dates, we are going to delete them
DELETE FROM [dbo].[Medical Appointment No Shows]
WHERE lead_time_days <0 



--DATA EXPLORATION: 
--1. What's our overall no-show rate?

SELECT 
	No_show, 
	count(*),
	ROUND(count(*) * 100.0 / (SELECT count(*) FROM [dbo].[Medical Appointment No Shows]), 2) as
	pct_of_total
FROM [dbo].[Medical Appointment No Shows]
GROUP BY No_show 

/*        Roughly around 20% of the data or appointments are no-shows. That's the baseline.      */

--2. Does the day of the week matter?

select 
	DATENAME(WEEKDAY, [AppointmentDay]) AS Appointment_day,
	COUNT(*) AS total_appointments,
	SUM(CASE WHEN no_show='Yes' THEN 1 ELSE 0 END) as no_show,
	ROUND(SUM(CASE WHEN no_show='Yes' THEN 1 ELSE 0 END) * 100.0/ COUNT(*), 2) as
	rate_of_no_shows
FROM [dbo].[Medical Appointment No Shows]
GROUP BY DATENAME(WEEKDAY, [AppointmentDay])
ORDER BY rate_of_no_shows DESC         

/*     Saturday has by far the least nor. of appointments which shows the clinic might be open on 
       every once in a while, very rarely. That explains why there is only 39. Rate of now-show
	   is pretty consistent throughout the week, about 20% for all. 
				But the outliers are Tuesday & Wednesday, Saturday, for total
	   nor. of appointments. They both get THE most appointments. As a result, they are getting 
	   pretty similar rate of no-show, 20%.    */

--3. Does the appointment lead time affects the likelihood of pt not showing up?

-- same day
-- 1-3 days
-- within a week (4-7 days)
-- long lead (8+ days)

/* Hypothesis testing: The longer the someone has to wait for their appointment, the more likely, 
life is gonna get in the way, and they forget about it or they can't make it to the appointment. */ 

WITH appointment_buckets AS (
    SELECT 
        CASE
            WHEN lead_time_days = 0 THEN 'Same Day'
            WHEN lead_time_days BETWEEN 1 AND 3 THEN 'Short (1-3 days)'
            WHEN lead_time_days BETWEEN 4 AND 7 THEN 'Within a week'
            ELSE 'Long Lead (8+ days)'
        END AS lead_time_bucket,
        no_show
    FROM [dbo].[Medical Appointment No Shows]
)

SELECT 
    lead_time_bucket,
	COUNT(*) as total_appointments,
	CAST(
		ROUND(SUM(CASE WHEN no_show='Yes' THEN 1 ELSE 0 END) * 100.0/ count(*), 2) as DECIMAL(10,2)
		) as no_show_rate
FROM appointment_buckets
GROUP BY lead_time_bucket
ORDER BY no_show_rate DESC

/* Same day appointments barely get missed but the long lead time bucket has dramatically higher no show rate. Which confirms 
   the hypothesis. */
	
-- If age affects the no show rate?

select top 10 * from [dbo].[Medical Appointment No Shows]

-- Child 0-12
-- teen 13-19
-- young adult 20-39
-- adult 40-59
-- senior 60+

/* Hypothesis testing: Young patients are gonna miss more appointments, more often, than adults, as seniors are more on top of 
   their health than younger patients. */


WITH age_buckets AS (
	SELECT
		CASE
			WHEN Age BETWEEN 0 AND 12 THEN 'Child'
			WHEN Age BETWEEN 13 AND 19 THEN 'Teen'
			WHEN Age BETWEEN 20 AND 39 THEN 'Young Adult'
			WHEN Age BETWEEN 40 AND 59 THEN 'Adult'
			ELSE 'Senior'
		END AS age_group,
        no_show
    FROM [dbo].[Medical Appointment No Shows]
)

SELECT 
    age_group,
	COUNT(*) as total_appointments,
	CAST(
		ROUND(SUM(CASE WHEN no_show='Yes' THEN 1 ELSE 0 END) * 100.0/ count(*), 2) as DECIMAL(10,2)
		) as no_show_rate
FROM age_buckets
GROUP BY age_group
ORDER BY no_show_rate DESC

/* As predicted, younger patients tend to no-show more than seniors. Younger patients are juggling
 work and life and people who are retired aren't. */

-- 5. Do SMS reminders help our patients?

WITH SMS AS (
	SELECT 
		CASE 
			WHEN SMS_received= 0 THEN 'No SMS'
			WHEN SMS_received= 1 THEN 'Received SMS'
		END as SMS_status,
		No_show
	FROM [dbo].[Medical Appointment No Shows]
)

SELECT 
	SMS_status,
	COUNT(*) as total_appointments,
	CAST(
		ROUND(SUM(CASE WHEN no_show='Yes' THEN 1 ELSE 0 END) * 100.0/ count(*), 2) as DECIMAL(10,2)
		) as no_show_rate
FROM SMS
GROUP BY SMS_status
ORDER BY no_show_rate DESC

/*  Patients who received SMS alert has higher no-show rate. Before we conclude, reminders don't work or SMS backfires, we need
   to think about, why that might me. SMS might be sent to book appointments further in advance. We need ask for correlation 
   between result and causation. Need to get more data about it for analysis. */

-- 6. Which neighbourhood have the highest risk?

SELECT top 15
	Neighbourhood,
	COUNT(*) as total_appointments,
	CAST(
		ROUND(SUM(CASE WHEN no_show='Yes' THEN 1 ELSE 0 END) * 100.0/ count(*), 2) as DECIMAL(10,2)
		) as no_show_rate
FROM [dbo].[Medical Appointment No Shows]
Group by Neighbourhood
HAVING COUNT(*) >= 100
ORDER BY no_show_rate DESC

-- 7. Patint level 'Risk Scoring'.


SELECT 
	patientID,
	AppointmentID,
	AppointmentDay,
	No_show,
	COUNT(*) over (
		PARTITION BY CAST(patientID AS VARCHAR(50)) -- We want to group the WINDOW by patientID, serves as GROUP BY w/o collapsing rows,
											-- keeps every appointment row, but performs the calculation separately for each patient
		ORDER BY Appointmentday --- sort it within each patient group of the WINDOW Fx
		ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING ) AS prior_appointments, --- we can get from very 1st row upto but 
													-- not incuding current row
	SUM(CASE WHEN no_show='Yes' THEN 1 ELSE 0 END) over (
		PARTITION BY CAST(patientID AS VARCHAR(50))
		ORDER BY appointmentday
		ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING ) AS prior_NO_shows 
FROM [dbo].[Medical Appointment No Shows]
ORDER BY CAST(patientID AS VARCHAR(50)), AppointmentDay  -- After calculating everything, display the final results sorted 
														-- by patient and appointment date

/*  prior_no_shows is NULL for all the 1st appointments of each pt. 
    It is 0 when pt has no prior_no_shows. 
	It is 1 when pt has 1 prior_no_shows.
	Its count increases as we have used SUM() to calulate prior_no_shows column.   */


-- FOR RISK SCORING VIEW.

CREATE VIEW v2_appointment_risk AS   -- Change CREATE VIEW name everytime we execute. As V2, V3 etc.
WITH patient_history AS (               -- CTE is temporary named result set that exists only while the query is running.
	
	SELECT 
		patientID,
		AppointmentID,
		AppointmentDay,
		neighbourhood,
		lead_time_days,
		sms_received,
		Scholarship,
		No_show,
		COUNT(*) over (
			PARTITION BY CAST(patientID AS VARCHAR(50)) -- We want to group the WINDOW by patientID, serves as GROUP BY w/o collapsing rows,
												-- keeps every appointment row, but performs the calculation separately for each patient
			ORDER BY Appointmentday, AppointmentID --- sort it within each patient group of the WINDOW Fx
			ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING ) AS prior_appointments, --- we can get from very 1st row upto but 
														-- not incuding current row
		SUM(CASE WHEN no_show='Yes' THEN 1 ELSE 0 END) over (
			PARTITION BY CAST(patientID AS VARCHAR(50))
			ORDER BY appointmentday, AppointmentID
			ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING ) AS prior_NO_shows 
	FROM [dbo].[Medical Appointment No Shows]
)

SELECT 
		patientID,
		AppointmentID,
		AppointmentDay,
		neighbourhood,
		lead_time_days,
		prior_appointments,
		prior_no_shows,
		ROUND(prior_no_shows /NULLIF(prior_appointments,0 ),2)as prior_no_show_rate,
		CASE
			WHEN prior_appointments=0 THEN 'New Patient- Monitor'
			WHEN (prior_no_shows /NULLIF(prior_appointments,0 ))>=0.5
				OR lead_time_days >=8 THEN 'High Risk'
			WHEN (prior_no_shows /NULLIF(prior_appointments,0 ))>=0.2
				OR lead_time_days BETWEEN 4 AND 7 THEN 'Medium Risk'
			ELSE 'Low Risk'
		END AS risk_tier
FROM patient_history
GO

SELECT TOP 50
*
FROM v2_appointment_risk
WHERE risk_tier ='High Risk'
ORDER BY appointmentDay


---------------------------------------------------------
--Export the datasets as CSV files for visualization.

SELECT * FROM [dbo].[Medical Appointment No Shows]

SELECT * FROM v2_appointment_risk

---------------------------------------------------------

-- Checking for Duplicates and NULLS.

SELECT 
    AppointmentID,
    COUNT(*) AS ID_count
FROM [dbo].[Medical Appointment No Shows]
GROUP BY AppointmentID
HAVING COUNT(*) > 1

SELECT COUNT(*) AS Null_AppointmentIDs
FROM [dbo].[Medical Appointment No Shows]
WHERE AppointmentID IS NULL

SELECT 
    AppointmentID,
    COUNT(*) AS ID_count
FROM v1_appointment_risk
GROUP BY AppointmentID
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS Null_AppointmentIDs
FROM v1_appointment_risk
WHERE AppointmentID IS NULL

