## End-to-End-Project-Microsoft SQL Server-PBI-Medical-Appointment-No-Show

## Project Overview

A medical data analysis end-to-end project to analyze patient appointments and no-shows data using Microsoft SQL Server, Microsoft Power BI to provide insights into no-show-rate, patient demographics, weekdays distribution of no-shows, lead time analysis, likely neighborhoods by patientrisk score analysis. 

The dashboard enables users to interactively analyze exploring metrics across age buckets, gender, SMS received label.  

## Business Requirements

1) What's our overall no-show rate?
2) Does the day of the week matter?
3) Does the appointment lead time affects the likelihood of patient not showing up?
4) If age affects the no show rate?
5) Do SMS reminders help our patients?
6) Which neighbourhood have the highest risk?
7) Number of total appointments.
8) What's the average lead time?
9) Patient risk score analysis.


## Observations
1. Roughly around 20% of the data or appointments are no-shows. That's the baseline.

2. Saturday has the most no-show rate followed by Friday. Rate of now-show is pretty consistent throughout the week, about 20% for all. 

3. Lead time groups::
 -- same day
-- 1-3 days

-- within a week (4-7 days)

-- long lead (8+ days)
* Hypothesis testing: The longer the someone has to wait for their appointment, the more likely, life is gonna get in the way, and they forget about it or they can't make it to the appointment. 
* Same day appointments barely get missed but the long lead time bucket has dramatically higher no show rate. Which confirms the hypothesis.

4. Age Group::
-- Child 0-12 yrs

-- teen 13-19 yrs

-- young adult 20-39 yrs

-- adult 40-59 yrs

-- senior 60+ yrs
* Hypothesis testing: Young patients are gonna miss more appointments, more often, than adults, as seniors are more on top of their health than younger patients.
* As predicted, younger patients tend to no-show more than seniors. Younger patients are juggling work and life and people who are retired aren't.

5. Patients who received SMS alert has higher no-show rate. Before we conclude, reminders don't work or SMS backfires, we need to think about, why that might me. SMS might be sent to book appointments further in advance. We need ask for correlation between result and causation. Need to get more data about it for analysis.

6. We have got top 15 list of neighbourhoods having highest no-show rates and total appointments >=100.

7. Total number of appointments- 110.52 K

8. Average lead time- 10.18 Days

9. Risk tier breakdown- High risk patients: 17.43%
   Low risk patients: 19.16%
   Medium risk patients: 7.05%
   New Patients- Monitor: 56.37% 


