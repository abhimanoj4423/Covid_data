SELECT * 
FROM coviddata.cov_data.cov_death    #COVID_DEATH.CSV contains details about daily cases, deaths and population     
ORDER BY 3,4                                   
 
SELECT * 
FROM coviddata.cov_data.cov_vac        #COVID_VAC.CSV contains info regarding vaccinations and covid tests 
ORDER BY 3,4                                    
#orderby 3,4 signifies sorting by 3rd column (location) first and then by 4th column (date) in ascending order

#Daily global new covid cases and deaths due to covid 

SELECT date,SUM(new_cases)AS Daily_new_cases,SUM(new_deaths)AS Daily_deaths
FROM coviddata.cov_data.cov_death 
WHERE continent is not null
GROUP BY date
ORDER BY 1 desc                                 #Data sorted in descending order to determine the accuracy with online sources

#Likelihood of death by contracting covid in each country

SELECT location,MAX(total_cases)AS Max_total_cases,MAX(total_deaths)AS Max_total_deaths,population,
       ROUND((MAX(total_deaths)/MAX(total_cases))*100,2) AS DEATH_PER_100_INFECTED
FROM coviddata.cov_data.cov_death
WHERE continent is not null
GROUP BY location, population
ORDER BY 1

#Peak covid infection rates per population in India

SELECT location,date,new_cases,new_deaths,(new_cases/population)*100 as death_percent
FROM coviddata.cov_data.cov_death
WHERE location LIKE "%India%"
ORDER BY 4 desc

# Running total percentage of population got the infection, 

SELECT location,date,new_cases,total_cases,population,(total_cases/population)*100 AS percentage 
FROM coviddata.cov_data.cov_death
WHERE continent is not null
ORDER BY 1,2 

# Countries with highest widespread infection rate

SELECT location,MAX(total_cases) AS Highest_total_cases,population,(MAX(total_cases)/population)*100 AS Infecton_rate
FROM coviddata.cov_data.cov_death
WHERE continent is not null
GROUP BY location, population
ORDER BY Infecton_rate desc

# Countries with the highest death rate per population-death per 100 people

SELECT location,MAX(total_deaths) AS Highest_total_cases,population,(MAX(total_deaths)/population)*100 AS death_rate
FROM coviddata.cov_data.cov_death
WHERE continent is not null
GROUP BY location, population
ORDER BY death_rate desc

# Total cases per continent

SELECT location,MAX(total_cases) AS Highest_total_cases
FROM coviddata.cov_data.cov_death
WHERE continent is null
GROUP BY location
ORDER BY 2 desc

# Continents with highest infection rate and death rate per population

SELECT location, MAX(total_cases) AS Highest_total_cases, MAX(total_deaths) AS Highest_total_deaths, population,
       (MAX(total_cases)/population)*100 AS Infecton_rate_continent,
       (MAX(total_deaths)/population)*100 AS Death_rate_continent
FROM coviddata.cov_data.cov_death
WHERE continent is null
GROUP BY location, population
ORDER BY 5,6 desc

# Joining vaccination table to covid death table
#Test positivity rate per day

SELECT DEA.date,DEA.new_cases,VACN.new_tests,
       CONCAT(ROUND((DEA.new_cases/VACN.new_tests)*100,2),"%") AS Test_pos_rate,
       ROUND((VACN.new_tests/DEA.new_cases),0) AS Test_per_case
FROM coviddata.cov_data.cov_death AS DEA
JOIN coviddata.cov_data.cov_vac  AS VACN
ON  DEA.location = VACN.location
and DEA.date = VACN.date   
WHERE DEA.continent is not null
     AND VACN.new_tests !=0
     AND DEA.new_cases !=0
group by DEA.date,DEA.new_cases,VACN.new_tests
order by 1 

# Fully vaccinated people in population in descending order

SELECT DEA.location,DEA.population,MAX(VACN.people_fully_vaccinated)AS Fully_Vaccinated,
       ROUND((MAX(VACN.people_fully_vaccinated)/DEA.population)*100,2) AS Vaccination_per_100
FROM coviddata.cov_data.cov_death AS DEA
JOIN coviddata.cov_data.cov_vac   AS VACN
ON  DEA.location = VACN.location
and DEA.date = VACN.date   
WHERE DEA.continent is not null
group by DEA.location,DEA.population
order by 4 desc 

# Create a running total column for Total vaccinations updating every day

SELECT DEA.location,DEA.date,DEA.population,VACN.new_vaccinations,
       SUM(VACN.new_vaccinations)OVER(PARTITION BY vacn.location ORDER BY dea.date ) AS Total_vaccinations
FROM coviddata.cov_data.cov_death AS DEA
JOIN coviddata.cov_data.cov_vac   AS VACN
ON  DEA.location = VACN.location
AND DEA.date = VACN.date   
WHERE DEA.continent is not null
ORDER BY DEA.location,DEA.date

# Total vaccination per hundred of the population (using CTE)

WITH POP_VAC AS
(  
  SELECT DEA.continent,DEA.location,DEA.date,DEA.population,VACN.new_vaccinations,
       SUM(VACN.new_vaccinations)OVER(PARTITION BY vacn.location order by dea.date ) AS Total_vaccinations
FROM coviddata.cov_data.cov_death AS DEA
JOIN coviddata.cov_data.cov_vac  AS VACN
ON  DEA.location = VACN.location
AND DEA.date = VACN.date   
WHERE DEA.continent is not null
)
SELECT *,ROUND((Total_vaccinations/population)*100,4) AS Vaccination_per_hundred
FROM POP_VAC

# Create a new table in the dataset to store the new data

CREATE TABLE VACCINATEDPER100
(
continent varchar(15),
location VARCHAR(30),
date1 DATE,
population INT,
new_vaccinations INT,
Total_vaccinations INT
);

# Insert the required data into the newly created table

INSERT INTO VACCINATEDPER100 (continent, location, date1, population, new_vaccinations, Total_vaccinations)
SELECT DEA.continent,DEA.location,DEA.date,DEA.population,VACN.new_vaccinations,
       SUM(VACN.new_vaccinations)OVER(PARTITION BY vacn.location ORDER BY dea.date ) AS Total_vaccinations
FROM coviddata.cov_data.cov_death AS DEA
JOIN coviddata.cov_data.cov_vac   AS VACN
ON  DEA.location = VACN.location
and DEA.date = VACN.date   
WHERE DEA.continent is not null

SELECT *
FROM VACCINATEDPER100