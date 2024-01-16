-- Total_cases vs Total_deaths in each country
SELECT
location, date, total_cases, total_deaths, CONCAT(ROUND((total_deaths / total_cases) * 100, 2), '%') AS percentage_deaths_per_case
FROM covid_dt.covid_deaths
ORDER BY 1, 2;

-- Total cases vs Population in each country
SELECT location, date, total_cases, population, CONCAT(ROUND((total_cases / population) * 100, 2), '%') AS percentage_infected
FROM covid_dt.covid_deaths
ORDER BY 1, 2;

-- Countries with highest infection rate compared to population
SELECT location, population, max(total_cases) as highest_infection_count, ROUND(MAX((total_cases / population) * 100), 2) AS percentage_infected
FROM covid_dt.covid_deaths
GROUP BY location, population
ORDER BY percentage_infected DESC;

-- Top 15 countries with highest death count per population in 2020
SELECT location, SUM(total_deaths) AS total_deaths_2020
FROM covid_dt.covid_deaths
WHERE continent IS NOT NULL AND EXTRACT(YEAR FROM date) = 2020
GROUP BY location
ORDER BY total_deaths_2020 DESC
LIMIT 15;

-- Global data
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths) / SUM(new_cases) * 100) AS DeathPercentage
FROM covid_dt.covid_deaths
WHERE continent IS NOT NULL;


WITH population_vs_vacs( continent, location, date, population, new_vaccinations, vaccinated)
as 
(
    SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
           SUM(vac.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location) as vaccinated
    FROM covid_dt.covid_deaths death
    JOIN covid_dt.covid_vac vac ON death.location = vac.location AND death.date = vac.date
    WHERE death.continent IS NOT NULL
)
SELECT *, ROUND((vaccinated/population)*100, 2) as pop_vs_vac
FROM population_vs_vacs;

-- CREATE VIEW FOR DATA VISUALIZATION
USE covid_dt;
CREATE VIEW TOPDEATHS AS
SELECT location, SUM(total_deaths) AS total_deaths_2020
FROM covid_dt.covid_deaths
WHERE continent IS NOT NULL AND EXTRACT(YEAR FROM date) = 2020
GROUP BY location
ORDER BY total_deaths_2020 DESC;

-- Total cases and deaths by WHO Region
SELECT `WHO Region`, SUM(Confirmed) AS TotalConfirmed, SUM(Deaths) AS TotalDeaths
FROM covid_19
GROUP BY `WHO Region`
ORDER BY TotalConfirmed DESC;

-- Countries with highest active cases
SELECT `Country/Region` AS Country, MAX(Active) AS MaxActiveCases
FROM covid_19
GROUP BY `Country/Region`
ORDER BY MaxActiveCases DESC;

-- Active vs Population rate
WITH active_vs_population_rate AS (
    SELECT covid_deaths.location AS Country, covid_deaths.date, SUM(coalesce(covid_19.Active, 0)) AS TotalActive, MAX(coalesce(covid_deaths.population, 0)) AS Population
    FROM covid_deaths 
    JOIN covid_19 ON covid_deaths.location = covid_19.`Country/Region` AND covid_deaths.date = covid_19.date
    WHERE covid_deaths.continent IS NOT NULL
    GROUP BY covid_deaths.location, covid_deaths.date
)
SELECT avp.Country, avp.date, avp.TotalActive, avp.Population, ROUND((avp.TotalActive / avp.Population) * 100, 2) AS ActiveVsPopulationRate
FROM active_vs_population_rate avp
ORDER BY avp.Country, avp.date;
