CREATE TABLE Employee_Demographics
(Employee_ID int,
First_Name varchar(50),
Last_Name varchar(50),
Age int,
Gender varchar(50),
Favorites varchar(50));

CREATE TABLE Employee_Salary
(Employee_ID int,
Department varchar(50),
Job_Title varchar(50),
Salary numeric(50),
Status varchar(50),
Date_of_hire date,
Address varchar(250));

COPY Employee_Demographics
FROM 'C:\Users\Public\Employee_Demographics - Copy.csv'
WITH (format CSV, HEADER);

COPY Employee_Salary
FROM 'C:\Users\Public\Employee_Salary - Copy.csv'
WITH (format CSV, HEADER);

--cleaning employee_demographics table
SELECT * 
FROM employee_demographics
ORDER BY employee_id;

--1. standardize letter case format
UPDATE employee_demographics
SET first_name= initcap(first_name);

UPDATE employee_demographics
SET last_name = initcap(last_name);

--2. change f and m to female and male
UPDATE employee_demographics
SET gender = TRIM(gender);

UPDATE employee_demographics
SET gender = 'Male'
WHERE gender = 'm';

UPDATE employee_demographics
SET gender = 'Female'
WHERE gender = 'f';

--3. remove white space
UPDATE employee_demographics
SET first_name = TRIM(first_name);

--4. remove fired from Pettit's name
UPDATE employee_demographics
SET last_name = REPLACE(last_name,'- Fired','');

--5. remove favorites column
ALTER TABLE employee_demographics
DROP COLUMN favorites;

--6. remove duplicates
CREATE TABLE dem_temp AS
SELECT DISTINCT employee_id, first_name, last_name, age, gender
FROM employee_demographics;

DROP TABLE employee_demographics;

ALTER TABLE dem_temp
RENAME TO employee_demographics;

--cleaning employee_salary table
SELECT * 
FROM employee_salary 
ORDER BY employee_id

--7. change job_titles
UPDATE employee_salary
SET job_title = 'Supervisor'
WHERE job_title LIKE '%Supervisor';

UPDATE employee_salary
SET job_title = 'Peer Support Specialist'
WHERE job_title = 'SAS Peer Specialist';

UPDATE employee_salary
SET job_title = 'Director'
WHERE job_title LIKE '%Director%';

UPDATE employee_salary
SET job_title = 'Therapist'
WHERE job_title LIKE '%Therapist%';

UPDATE employee_salary
SET job_title = 'Registered Nurse'
WHERE job_title = 'ACT RN';

--8. change hourly wages to salaries
UPDATE employee_salary
SET salary = salary * 40 * 52
WHERE salary <21;

--9. separate address (sal)
CREATE TABLE sal_temp AS
SELECT
employee_id, department, job_title, salary, status, date_of_hire,
split_part(address,'. ', 1) AS street,
split_part(address, ' ', 4) AS city,
split_part(address, ' ', 5) AS state,
split_part(address,' ', 6) AS zip_code
FROM employee_salary;

DROP TABLE employee_salary;

ALTER TABLE sal_temp
RENAME TO employee_salary;

UPDATE employee_salary
SET city = 'Kalamazoo'
WHERE city = 'Kalamazoo,';

--DATA EXPLORATION
SELECT * FROM Employee_Demographics;

SELECT DISTINCT(employee_id) FROM Employee_Demographics;
SELECT COUNT(Last_Name) FROM Employee_Demographics;
SELECT MAX(salary) FROM Employee_Salary AS max_salary;
SELECT MIN(salary) FROM Employee_Salary AS min_salary;

SELECT *
FROM Employee_Demographics
WHERE Age <32 AND Gender = 'Male';

SELECT *
FROM Employee_Demographics
WHERE last_name LIKE 'C%';

SELECT * 
FROM Employee_Demographics
WHERE Last_Name IN ('Johnson','Jones');

--Number of female and male employees
SELECT gender, COUNT(gender) AS gender_count
FROM Employee_Demographics
WHERE age >30
GROUP BY gender
ORDER BY gender_count DESC;

--Average Salary for each Job Title
SELECT Job_Title, round(AVG(salary)) AS avg_salary
FROM Employee_Salary 
GROUP BY Job_Title
ORDER BY avg_salary DESC;

--Case Statement: assign generational labels
SELECT First_Name, Last_Name, Age,
CASE
 WHEN Age>58 THEN 'Boomer'
 WHEN Age BETWEEN 43 AND 58 THEN 'Gen X'
 WHEN Age BETWEEN 27 AND 42 THEN 'Millenial'
 ELSE 'Gen Z'
END
FROM Employee_Demographics
ORDER BY Age;

--Join demographic and salary tables
SELECT First_Name, Last_Name, Job_Title, Salary
FROM Employee_Demographics dem
JOIN Employee_Salary sal
ON dem.employee_id = sal.employee_id;

--Give raises to frontline employees and cut salary for executives
SELECT First_Name, Last_Name, Job_Title, Salary,
CASE
 WHEN Job_Title = 'Case Manager' THEN salary + (salary*.10)
 WHEN Job_Title = 'ACT Team Advocate' THEN salary + (salary*.10)
 WHEN Job_Title = 'Front Desk Staff' THEN salary + (salary*.10)
 WHEN Job_Title in ('CEO','COO') THEN salary - (salary*.10)
 ELSE salary + (salary* .03)
END as salary_adjustments
FROM Employee_Demographics dem
JOIN Employee_Salary sal
ON dem.employee_id = sal.employee_id

--Number of employees in each job_title category
SELECT job_title, COUNT(job_title) AS job_title_count
FROM Employee_demographics dem
JOIN Employee_salary sal
ON dem.employee_id = sal.employee_id
GROUP BY job_title
ORDER BY job_title_count DESC;

--Number of employees in each job_title category with >1
SELECT job_title, COUNT(job_title)
FROM employee_demographics dem
JOIN employee_salary sal
ON dem.employee_id = sal.employee_id
GROUP BY job_title 
HAVING COUNT(job_title) >1

--Average salary of each job_title making more than $45,000
SELECT job_title, round(AVG(salary))
FROM employee_demographics dem
JOIN employee_salary sal
ON dem.employee_id = sal.employee_id
GROUP BY job_title
HAVING AVG(salary) > 45000
ORDER BY AVG(salary)

--Partition employees by gender
SELECT first_name, last_name, gender, salary,
 COUNT(gender) OVER (PARTITION BY gender) AS total_gender
FROM employee_demographics dem
JOIN employee_salary sal
ON dem.employee_id = sal.employee_id

--CTE: partition by gender and include avg salary per gender
WITH CTE_Employee AS
 (SELECT first_name, last_name, gender, salary,
 COUNT(gender) OVER (PARTITION BY gender) AS total_gender,
 AVG(salary) OVER (PARTITION BY gender) AS avg_salary
 FROM employee_demographics dem
 JOIN employee_salary sal
 ON dem.employee_id = sal.employee_id
 WHERE salary>'45000')
 
SELECT *
FROM CTE_Employee;

--Temp Table
DROP TABLE IF EXISTS temp_employee;
CREATE TEMP TABLE temp_employee(
Employee_ID int,
Department varchar (50),
Job_Title varchar(50),
Salary numeric,
Status varchar(50),
date_of_hire date,
street varchar(50),
city varchar(50),
state varchar(50), 
zip_code varchar(50));

INSERT INTO temp_employee
SELECT *
FROM Employee_Salary;

SELECT * FROM temp_employee;

--create temp table with job, employee count, avg ages, avg salaries
DROP TABLE IF EXISTS temp_employee_2;
CREATE TEMP TABLE temp_employee_2(
Job_Title varchar(50),
Employees_Per_Job int,
Avg_Age int,
Avg_Salary int);

INSERT INTO temp_employee_2
SELECT Job_Title, COUNT(Job_Title), AVG(Age), AVG(Salary)
FROM employee_demographics dem
JOIN employee_salary sal
ON dem.employee_id = sal.employee_id
GROUP BY job_title;

SELECT * FROM temp_employee_2;