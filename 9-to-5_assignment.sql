USE LaborStatisticsDB;
GO

SELECT supersector_code
FROM dbo.supersector
WHERE supersector_name = 'financial activities';


/*
Database Exploration
1. See "d"
2. nvarchar(100)
3. CES5552211010, CEU5552211010
*/
SELECT series_id
FROM dbo.series AS s
WHERE s.series_title = 'Women Employees' AND 
    s.industry_code = (SELECT industry_code 
        FROM dbo.industry 
        WHERE industry_name ='commercial banking') AND
    s.supersector_code = (SELECT supersector_code
        FROM dbo.supersector
        WHERE supersector_name = 'financial activities');


--Aggregate
--Q1: 2340612; # of employees, 2016, all industrie
SELECT ROUND(SUM(value),0)
FROM dbo.annual_2016
WHERE RIGHT(series_id,2) IN (
    SELECT data_type_code
    FROM dbo.datatype
    WHERE data_type_text='All Employees'
);

--Q2:1125490; # of employees, 2016, all industries, women
SELECT ROUND(SUM(value),0)
FROM dbo.annual_2016
WHERE RIGHT(series_id,2) IN (
    SELECT data_type_code
    FROM dbo.datatype
    WHERE data_type_text='Women Employees'
);

--Q3: 11750497; # of production/nonsupervisory employees
SELECT ROUND(SUM(value),0)
FROM dbo.annual_2016
WHERE RIGHT(series_id,2) IN (
    SELECT data_type_code
    FROM dbo.datatype
    WHERE data_type_text='PRODUCTION AND NONSUPERVISORY EMPLOYEES'
);

--Q4:53413392; Avg weekly hours; 2017, production,nonsupervisory employee, 
SELECT AVG(value)
FROM dbo.january_2017
WHERE RIGHT(series_id,2) IN (
    SELECT data_type_code
    FROM dbo.datatype
    WHERE data_type_text='AVERAGE WEEKLY HOURS OF PRODUCTION AND NONSUPERVISORY EMPLOYEES'
);

--Q5:1838753220; total weekly payroll; production&nonsupervisory employee, 2017, nearrest penny
SELECT ROUND(SUM(value),0)
FROM dbo.january_2017
WHERE RIGHT(series_id,2) IN (
    SELECT data_type_code
    FROM dbo.datatype
    WHERE data_type_text='AGGREGATE WEEKLY PAYROLLS OF PRODUCTION AND NONSUPERVISORY EMPLOYEES'
);

--Q6: highest(Motor vehicle power train components, 49.6), lowest(Fitness and recreational sports centers at 16.85)
-- industry; 2017, avg weekly hours worked by production&nonsupervisory employee highest/lowest
SELECT i.industry_name, AVG(j.value) AS avg_by_industry
FROM dbo.january_2017 AS j
LEFT JOIN dbo.series AS s ON j.series_id=s.series_id
LEFT JOIN dbo.industry AS i on s.industry_code=i.industry_code
WHERE RIGHT(j.series_id,2) IN (
    SELECT data_type_code
    FROM dbo.datatype
    WHERE data_type_text='AVERAGE WEEKLY HOURS OF PRODUCTION AND NONSUPERVISORY EMPLOYEES')
GROUP BY i.industry_name
ORDER BY AVG(j.value) DESC
;


--Q7: highest(total private), lowest(Coin-operated laundries and drycleaners); industy; january 2017, total weekly payroll for production, nonsupervisory employees
SELECT i.industry_name, SUM(j.value) AS avg_by_industry
FROM dbo.january_2017 AS j
LEFT JOIN dbo.series AS s ON j.series_id=s.series_id
LEFT JOIN dbo.industry AS i on s.industry_code=i.industry_code
WHERE RIGHT(j.series_id,2) IN (
    SELECT data_type_code
    FROM dbo.datatype
    WHERE data_type_text='AGGREGATE WEEKLY PAYROLLS OF PRODUCTION AND NONSUPERVISORY EMPLOYEES')
GROUP BY i.industry_name
ORDER BY SUM(j.value) DESC

--Join
--Q1: 
SELECT TOP 50 *
FROM annual_2016 AS a
LEFT JOIN series AS s
ON a.series_id=s.series_id
ORDER BY id;

--Q2:
SELECT TOP 50 *
FROM series AS s
LEFT JOIN datatype AS d
ON s.data_type_code=d.data_type_code;
ORDER BY id

--Q3:
SELECT TOP 50*
FROM series AS s
LEFT JOIN industry AS i
ON s.industry_code=i.industry_code
ORDER BY id;

--Subqueries, Unions etc
--Q1:
SELECT j.series_id, s.industry_code, i.industry_name, value
FROM dbo.january_2017 AS j
LEFT JOIN dbo.series AS s ON j.series_id=s.series_id
LEFT JOIN dbo.industry AS i on s.industry_code=i.industry_code
WHERE value >
    (SELECT AVG(a.value)
    FROM dbo.annual_2016 AS a
    WHERE RIGHT(a.series_id,2)=82);

--Q1 (Bonus):
WITH avg_value_for_82 AS (
    SELECT AVG(a.value) AS avg_value
    FROM dbo.annual_2016 AS a 
    WHERE RIGHT(a.series_id,2)=82
) 

SELECT j.series_id, s.industry_code, i.industry_name, value
FROM dbo.january_2017 AS j
LEFT JOIN dbo.series AS s ON j.series_id=s.series_id
LEFT JOIN dbo.industry AS i on s.industry_code=i.industry_code
WHERE value > (SELECT avg_value FROM avg_value_for_82);

/*Q2:union, 
average weekly earnings of production&nonsupervisory employees between annual 2016, january 2017
data type 30
Round to near penny 
Column for avg earning, year,period */

SELECT year, period, ROUND(AVG(value),2) AS avg_weekly_earnings
FROM dbo.annual_2016
WHERE RIGHT(series_id,2)=30
GROUP BY year, period
Union
SELECT year, period, ROUND(AVG(value),2) AS avg_weekly_earnings
FROM dbo.january_2017
WHERE RIGHT(series_id,2)=30
GROUP BY year, period

--Summary
--Q1: during which time period did production and nonsupervisory employees fare better 
--Answer: ACcording to average weekly earnings, production and nonsupervisory employees fared better during M1 in 2017 than M13 in 2016. 
SELECT year, period, ROUND(AVG(value),2) AS avg_weekly_earnings
FROM dbo.annual_2016
WHERE RIGHT(series_id,2) IN
    (SELECT data_type_code
    FROM dbo.datatype
    WHERE data_type_text='AVERAGE WEEKLY EARNINGS OF PRODUCTION AND NONSUPERVISORY EMPLOYEES')
GROUP BY year, period
Union
SELECT year, period, ROUND(AVG(value),2) AS avg_weekly_earnings
FROM dbo.january_2017
WHERE RIGHT(series_id,2) IN
 (SELECT data_type_code
    FROM dbo.datatype
    WHERE data_type_text='AVERAGE WEEKLY EARNINGS OF PRODUCTION AND NONSUPERVISORY EMPLOYEES')
GROUP BY year, period

--Q2: Industries did production and nonsupervisory employees fare better
--Answer: They performed better in the "Reinsurance carriers" sector according to average weekly earnings of production and nonsupervisory employees.
SELECT i.industry_name, AVG(j.value) AS avg_by_industry
FROM dbo.january_2017 AS j
LEFT JOIN dbo.series AS s ON j.series_id=s.series_id
LEFT JOIN dbo.industry AS i on s.industry_code=i.industry_code
WHERE RIGHT(j.series_id,2) IN (
    SELECT data_type_code
    FROM dbo.datatype
    WHERE data_type_text='AVERAGE WEEKLY EARNINGS OF PRODUCTION AND NONSUPERVISORY EMPLOYEES')
GROUP BY i.industry_name
ORDER BY AVG(j.value) DESC

--Q3: The annual 2016 table only included information from M13 period so it wasn't representitive of the whole year. I wish there was more extensive annual data.
