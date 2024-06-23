## Data Analyst Portfolio Project | SQL Data Exploration

**SETUP:**

1. Download SQL Server Management Studio (SSMS) [Download SSMS Link](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms?view=sql-server-ver16#download-ssms)
    
    →An integrated environment for **managing any SQL infrastructure**, from SQL Server to Azure SQL Database. 
    
    →SSMS provides tools to configure, monitor, and administer instances of SQL Server and databases
    
    →Use SSMS to **deploy, monitor, and upgrade the data-tier components used by your applications** and **build queries and scripts**
    
2. Download SQL Server (Express) [Download SQL Server Link](https://www.microsoft.com/en-sg/sql-server/sql-server-downloads)
3. download data set from resource ([Github](https://github.com/owid/covid-19-data/tree/master/public/data)) / [Official Website](https://ourworldindata.org/covid-deaths)) /[ProjectSourceGithub](https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/CovidVaccinations.xlsx)

**ISSUES:**

1. Error Encounter:
    
    ```
    SQL Server Excel Import - The 'Microsoft.ACE.OLEDB.12.0' provider is not registered on the local machine.
    ```
    
    Cannot Import Excel (Data Source) into Database as SQL Import Wizard is still 32 bits even if the “SQL SERVER IMPORT AND EXPORT DATA” is 64-bit.
    
    Solution : Install **Microsoft Access Database Engine 2016 Redistributable (accessdatabaseengine.exe) →** run cmd> cd “download location” > ****accessdatabaseengine.exe /quiet
    
    → [Download DataAccessEngine.exe (32 bits)](https://www.microsoft.com/en-us/download/details.aspx?id=54920)
    

**STEPS:**

1. Open SSMS > connect to SQL SERVER >DATABASE ENGINE (type).
2. Create a new database named “PortfolioProject”
3. ProjectPortfolio >Task >Import Data… >
    1.  Choose DATA SOURCE as “Mircosoft Excel” > pick the xlsx file needed
    2.  Choose Destination as SQL SERVER  NATIVE CLIENT 11.0 (Remember: check servername & database)
    3. pick ‘copy data from one…’ and the rest just click Next/finish
4. Start Quering

**QUERING STEPS:**

### 1. Looking at Total Cases vs Total Deaths

-show likelihood of dying if you contract covid in your country

```sql
Select
Location, date, total_cases, total_deaths,
(CONVERT(float,total_deaths)/ NULLIF(CONVERT(float,total_cases),0))*100 as DeathPercentage
FROM ProfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE location like 'Singapore'AND continent is not null
ORDER BY 1,2
--ORDER BY 1,DeathPercentage DESC
```

### 2. looking at Total Cases vs Population

shows what percentage of population got covid

```sql
Select Location, date, population, total_cases,
(CONVERT(float,total_cases)/ NULLIF(CONVERT(float,population),0))*100 as PercentPopulationInfected
FROM ProfolioProject.dbo.CovidDeaths
--WHERE location like 'Sing%'
WHERE continent is not null
ORDER BY 1,2
```

### **3. Looking at Countries with Highest Infection Rate compared to Population**

MaxCases as CTE (Common Table Expression)

```sql
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
```

or

```sql
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
```

### 4. Showing Countries with highest Death Count per Population

```sql
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
```

### 5. Showing continents with highest death counts (Breakdown by Continent)

```sql
SELECT continent, MAX(CAST(total_deaths AS FLOAT)) as TotalDeathsCount
FROM ProfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathsCount DESC
```

### 6. Showing location with highest death counts per location

```sql
SELECT location, MAX(CAST(total_deaths AS FLOAT)) as TotalDeathsCount
FROM ProfolioProject.dbo.CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathsCount DESC
```

### 7. Showing total deaths and percentage per days

```sql
Select date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as float)) as total_deaths, SUM(CAST(new_deaths as float))/NULLIF(SUM(new_cases),0) *100 as DeathPercentage
FROM ProfolioProject.dbo.CovidDeaths
--WHERE location like 'Sing%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2
```

### 8. Showing total cases, total deaths and death percentage in the world

```sql
Select SUM(new_cases) as total_cases, SUM(CAST(new_deaths as float)) as total_deaths, SUM(CAST(new_deaths as float))/NULLIF(SUM(new_cases),0) *100 as DeathPercentage
FROM ProfolioProject.dbo.CovidDeaths
--WHERE location like 'Sing%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2
```

### 9. Looking at Total Population vs Vaccination

MAXRollingPeopleVaccinated per Continent

```sql
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
```

New_vaccinations VS Population Per Day

```sql
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM ProfolioProject.dbo.CovidDeaths dea
Join ProfolioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
and dea.location like 'alba%'
ORDER BY 2,3

```

### 9. Create Temp Table

```sql
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
```

```sql
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS FLOAT))
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM ProfolioProject.dbo.CovidDeaths dea
Join ProfolioProject.dbo.CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
```

```sql
SELECT *, (RollingPeopleVaccinated/population)*100 as PercentVacVsPop
FROM #PercentPopulationVaccinated
ORDER BY location, date
```

### 10. Create View to store data for later visualizations

```sql
CREATE VIEW PercentPopulationVaccinated AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations AS FLOAT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
	FROM ProfolioProject.dbo.CovidDeaths dea
	Join ProfolioProject.dbo.CovidVaccinations vac
		On dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null
```

```sql
SELECT * 
FROM PercentPopulationVaccinated
```
