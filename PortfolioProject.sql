/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4


-- Selecting the relevant data for exploration

SELECT Location, Date, Population, total_cases, total_deaths
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Total Infection Count by Continent and Country

SELECT Continent, Location, MAX(total_cases) AS TotalInfectionCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, Location
ORDER BY 3 DESC


-- Population Infection Percentage by Continent and Country

SELECT Continent, Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PopulationInfectionPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location,continent, Population
ORDER BY 5 DESC


-- Total Death Count by Continent and Country

SELECT Continent, Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, Location
ORDER BY 3 DESC


-- Population Death Percentage by Continent and Country

SELECT Continent, Location, Population, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount, MAX(CAST(total_deaths AS INT)/population)*100 AS PopulationDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, Location, Population
ORDER BY 5 DESC


-- Total Cases vs Total deaths by Date, Country and Continent
--Showing likelihood of death if covid19 is contracted 

SELECT Continent, Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 2,3


-- Total Cases vs Total deaths by Date in Nigeria
--Showing likelihood of death if covid19 is contracted in Nigeria

SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Nigeria%'
ORDER BY 2


-- GLOBAL NUMBERS OF COVID19 CASES VS DEATHS

SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS INT)) AS TotalDeaths, SUM(cast(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

-- GLOBAL NUMBERS OF COVID19 CASES VS DEATHS BY DATE

SELECT Date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1


-- TOTAL NUMBER OF COVID19 CASES VS DEATHS BY CONTINENT AND COUNTRY

SELECT Continent, Location, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS INT)) AS TotalDeaths, (SUM(cast(new_deaths AS INT))/SUM(New_Cases))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY 5

-- TOTAL NUMBER OF COVID19 CASES VS DEATHS IN NIGERIA

SELECT location, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Nigeria%'
and continent IS NOT NULL
GROUP BY location
--ORDER BY 1

-- TOTAL NUMBER OF COVID19 CASES AND DEATH BY CONTINENT

SELECT Continent, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC



-- POPULATION VS TESTS

-- JOINING COVID DEATHS TABLE AND COVID VACCINATIONS TABLE 

SELECT *
FROM PortfolioProject..CovidDeaths Cdeath
	JOIN PortfolioProject..CovidVaccinations Cvacc
	ON Cdeath.location = Cvacc.location
	and Cdeath.date = Cvacc.date


--Showing Rolling Tests Rate

SELECT cdeath.continent, Cdeath.Location, cdeath.date, Cdeath.population, cvacc.new_tests, SUM(CONVERT(INT,cvacc.new_tests)) OVER (PARTITION BY Cdeath.Location ORDER BY cdeath.location,cdeath.date) AS RollingTestsRate
FROM PortfolioProject..CovidDeaths Cdeath
	JOIN PortfolioProject..CovidVaccinations Cvacc
	ON Cdeath.location = Cvacc.location
	and Cdeath.date = Cvacc.date
WHERE Cdeath.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE to perform calculation on Partition By in previous query, showing Percentage of Population that have been tested

WITH PopvsTest (Continent, Location, Date, Population, New_Tests, RollingTestsRate)
	AS
	(
		SELECT cdeath.continent, Cdeath.Location, cdeath.date, Cdeath.population, cvacc.new_tests, SUM(CONVERT(INT,cvacc.new_tests)) OVER (PARTITION BY Cdeath.Location ORDER BY cdeath.location,cdeath.date) AS RollingTestsRate
		FROM PortfolioProject..CovidDeaths Cdeath
			JOIN PortfolioProject..CovidVaccinations Cvacc
			ON Cdeath.location = Cvacc.location
			and Cdeath.date = Cvacc.date
		WHERE Cdeath.continent IS NOT NULL
		--ORDER BY 2,3
	)

SELECT *, (RollingTestsRate/Population)*100 AS TestedPopPercentage
FROM PopvsTest


-- POPULATION VS VACCINATION

-- JOINING COVID DEATHS TABLE AND COVID VACCINATIONS TABLE

SELECT *
FROM PortfolioProject..CovidDeaths Cdeath
	JOIN PortfolioProject..CovidVaccinations Cvacc
	ON Cdeath.location = Cvacc.location
	and Cdeath.date = Cvacc.date


--Showing Rolling Rate of Vaccinations

SELECT cdeath.continent, Cdeath.Location, cdeath.date, Cdeath.population, cvacc.new_vaccinations, SUM(CONVERT(INT,cvacc.new_vaccinations)) OVER (PARTITION BY Cdeath.Location ORDER BY cdeath.location,cdeath.date) AS RollingVaccinationsRate
FROM PortfolioProject..CovidDeaths Cdeath
	JOIN PortfolioProject..CovidVaccinations Cvacc
	ON Cdeath.location = Cvacc.location
	and Cdeath.date = Cvacc.date
WHERE Cdeath.continent IS NOT NULL
ORDER BY 2,3

-- Using Temp Table to perform calculation on Partition By in previous query, showing Percentage of Population that have been Vaccinated

DROP TABLE IF EXISTS #PopvsVac
Create Table #PopvsVac
	(
		Continent nvarchar(255),
		Location nvarchar(255),
		Date datetime,
		Population numeric,
		New_Vaccinations numeric,
		RollingVaccinationsRate numeric
	)

INSERT INTO #PopvsVac
	SELECT cdeath.continent, Cdeath.Location, cdeath.date, Cdeath.population, cvacc.new_vaccinations, SUM(CONVERT(INT,cvacc.new_vaccinations)) OVER (PARTITION BY Cdeath.Location ORDER BY cdeath.location,cdeath.date) AS RollingVaccinationsRate
	FROM PortfolioProject..CovidDeaths Cdeath
		JOIN PortfolioProject..CovidVaccinations Cvacc
		ON Cdeath.location = Cvacc.location
		and Cdeath.date = Cvacc.date
	WHERE Cdeath.continent IS NOT NULL
	--ORDER BY 2,3

SELECT *, (RollingVaccinationsRate/Population)*100 AS VaccinatedPopPercentage
From #PopvsVac

-- OR Using CTE to perform calculation on Partition By in previous query, showing Percentage of Population that have been Vaccinated
WITH PopvsVac (Continent, Location, Date, Population, New_Tests, RollingVaccinationsRate)
	AS
	(
		SELECT cdeath.continent, Cdeath.Location, cdeath.date, Cdeath.population, cvacc.new_vaccinations, SUM(CONVERT(INT,cvacc.new_vaccinations)) OVER (PARTITION BY Cdeath.Location ORDER BY cdeath.location,cdeath.date) AS RollingVaccinationsRate
		FROM PortfolioProject..CovidDeaths Cdeath
			JOIN PortfolioProject..CovidVaccinations Cvacc
			ON Cdeath.location = Cvacc.location
			and Cdeath.date = Cvacc.date
		WHERE Cdeath.continent IS NOT NULL
		--ORDER BY 2,3
	)

SELECT *, (RollingVaccinationsRate/Population)*100 AS VaccinatedPopPercentage
FROM PopvsVac


-- Creating View to store data for later visualizations

CREATE VIEW TotalInfectionCount 
	AS
	SELECT Continent, Location, MAX(total_cases) AS TotalInfectionCount
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY continent, Location
	--ORDER BY 3 DESC


CREATE VIEW TotalDeathCount 
	AS
	SELECT Continent, Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY continent, Location
	--ORDER BY 3 DESC

CREATE VIEW PopulationInfectionPercentage 
	AS
	SELECT Continent, Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PopulationInfectionPercentage
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY Location,continent, Population
	--ORDER BY 5 DESC

CREATE VIEW PopulationInfectionPercentageByDate
	AS
	SELECT Continent, Location, Date, Population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PopulationInfectionPercentage
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY Location,continent, Date, Population
	--ORDER BY 6 DESC

CREATE VIEW PopulationDeathPercentage 
	AS
	SELECT Continent, Location, Population, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount, MAX(CAST(total_deaths AS INT)/population)*100 AS PopulationDeathPercentage
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY continent, Location, Population
	--ORDER BY 5 DESC


CREATE VIEW TotalCasesVsTotalDeath 
	AS
	SELECT Continent, Location, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths AS INT)) AS TotalDeaths, (SUM(cast(new_deaths AS INT))/SUM(New_Cases))*100 AS DeathPercentage
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY continent, location
	--ORDER BY 5

CREATE VIEW TestedPopPercentage 
	AS
	WITH PopvsTest (Continent, Location, Date, Population, New_Tests, RollingTestsRate)
		AS
		(
			SELECT cdeath.continent, Cdeath.Location, cdeath.date, Cdeath.population, cvacc.new_tests, SUM(CONVERT(INT,cvacc.new_tests)) OVER (PARTITION BY Cdeath.Location ORDER BY cdeath.location,cdeath.date) AS RollingTestsRate
			FROM PortfolioProject..CovidDeaths Cdeath
				JOIN PortfolioProject..CovidVaccinations Cvacc
				ON Cdeath.location = Cvacc.location
				and Cdeath.date = Cvacc.date
			WHERE Cdeath.continent IS NOT NULL
			--ORDER BY 2,3
		)

SELECT *, (RollingTestsRate/Population)*100 AS TestedPopPercentage
FROM PopvsTest


CREATE VIEW VaccinatedPopPercentage 
	AS
	WITH PopvsVac (Continent, Location, Date, Population, New_Tests, RollingVaccinationsRate)
		AS
		(
			SELECT cdeath.continent, Cdeath.Location, cdeath.date, Cdeath.population, cvacc.new_vaccinations, SUM(CONVERT(INT,cvacc.new_vaccinations)) OVER (PARTITION BY Cdeath.Location ORDER BY cdeath.location,cdeath.date) AS RollingVaccinationsRate
			FROM PortfolioProject..CovidDeaths Cdeath
				JOIN PortfolioProject..CovidVaccinations Cvacc
				ON Cdeath.location = Cvacc.location
				and Cdeath.date = Cvacc.date
			WHERE Cdeath.continent IS NOT NULL
			--ORDER BY 2,3
		)

SELECT *, (RollingVaccinationsRate/Population)*100 AS VaccinatedPopPercentage
FROM PopvsVac