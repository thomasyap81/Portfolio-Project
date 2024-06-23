Select *
FROM ProfolioProject..CovidDeaths
--where continent is not null
ORDER BY 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
FROM ProfolioProject.dbo.CovidDeaths
ORDER BY 1,2;

--1. Looking at Total Cases vs Total Deaths
-- show likelihood of dying if you contract convid in your country
Select 
	Location, date, total_cases, total_deaths, 
	(CONVERT(float,total_deaths)/ NULLIF(CONVERT(float,total_cases),0))*100 as DeathPercentage
FROM ProfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE location like 'Singapore'AND continent is not null
ORDER BY 1,2
--ORDER BY 1,DeathPercentage DESC


--2. looking at Total Cases vs Population
-- % wildcard
-- shows what percentage of population got covid
Select Location, date, population, total_cases, 
	(CONVERT(float,total_cases)/ NULLIF(CONVERT(float,population),0))*100 as PercentPopulationInfected
FROM ProfolioProject.dbo.CovidDeaths
--WHERE location like 'Sing%'
WHERE continent is not null
ORDER BY 1,2

--3. Looking at Countries with Highest Infection Rate compared to Population
--MaxCases as CTE (Common Table Expression)
WITH MaxCases AS (
    SELECT 
        Location, 
        CAST(population AS FLOAT) as population, 
        MAX(CAST(total_cases AS FLOAT)) as HighestInfectionCount
    FROM ProfolioProject.dbo.CovidDeaths
	WHERE continent is not null
    GROUP BY location, population
)
SELECT 
    Location, 
    population, 
    HighestInfectionCount, 
    (HighestInfectionCount / NULLIF(population, 0)) * 100 as PercentPopulationInfected
FROM MaxCases
ORDER BY PercentPopulationInfected DESC
--OR--
SELECT 
    location, 
    CAST(population AS FLOAT) as population, 
    MAX(CAST(total_cases AS FLOAT)) as HighestInfectionCount, 
    MAX(CAST(total_cases AS FLOAT) / NULLIF( CAST(population AS FLOAT), 0)) * 100 as PercentPopulationInfected
FROM ProfolioProject.dbo.CovidDeaths
--WHERE location = 'Singapore'
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

--4. Showing Countries with highest Death Count per Population
SELECT 
    location, 
    CAST(population AS FLOAT) as population, 
    MAX(CAST(total_deaths AS FLOAT)) as TotalDeathsCount, 
    MAX(CAST(total_deaths AS FLOAT) / NULLIF( CAST(population AS FLOAT), 0)) * 100 as PercentPopulationDeaths
FROM ProfolioProject.dbo.CovidDeaths
--WHERE location like '%State%'
WHERE continent is not null
GROUP BY location, population
ORDER BY TotalDeathsCount DESC


--Breakdown by Continent
--5. Showing continents with highest death counts
SELECT continent, MAX(CAST(total_deaths AS FLOAT)) as TotalDeathsCount
FROM ProfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathsCount DESC

--6. Showing location with highest death counts per location
SELECT location, MAX(CAST(total_deaths AS FLOAT)) as TotalDeathsCount
FROM ProfolioProject.dbo.CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathsCount DESC

--7. Showing total deaths and percentage per days
Select date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as float)) as total_deaths, SUM(CAST(new_deaths as float))/NULLIF(SUM(new_cases),0) *100 as DeathPercentage
FROM ProfolioProject.dbo.CovidDeaths
--WHERE location like 'Sing%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--8. Showing total cases, total deaths and death percentage in the world
Select SUM(new_cases) as total_cases, SUM(CAST(new_deaths as float)) as total_deaths, SUM(CAST(new_deaths as float))/NULLIF(SUM(new_cases),0) *100 as DeathPercentage
FROM ProfolioProject.dbo.CovidDeaths
--WHERE location like 'Sing%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2


--9. Looking at Total Population vs Vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM ProfolioProject.dbo.CovidDeaths dea
Join ProfolioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
and dea.location like 'alba%'
ORDER BY 2,3

--Using CTE (Common Table Expression)
With VacVsPop AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS FLOAT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
	FROM ProfolioProject.dbo.CovidDeaths dea
	Join ProfolioProject.dbo.CovidVaccinations vac
		On dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null
)
--SELECT *, (RollingPeopleVaccinated/population)*100 as PercentVacVsPop
SELECT continent, MAX(RollingPeopleVaccinated) AS MAXRollingPeopleVaccinated
FROM VacVsPop
GROUP BY continent
ORDER BY 1,2


--11. CREATE TABLE
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS FLOAT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
	FROM ProfolioProject.dbo.CovidDeaths dea
	Join ProfolioProject.dbo.CovidVaccinations vac
		On dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100 as PercentVacVsPop
FROM #PercentPopulationVaccinated
ORDER BY location, date


--12. Create View to store data for later visualisations
CREATE VIEW PercentPopulationVaccinated AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS FLOAT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
	FROM ProfolioProject.dbo.CovidDeaths dea
	Join ProfolioProject.dbo.CovidVaccinations vac
		On dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null


SELECT * 
FROM PercentPopulationVaccinated