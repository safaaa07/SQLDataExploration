-- Checking if the data was imported properly
SELECT *
FROM SQLDataExploration..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

SELECT *
FROM SQLDataExploration..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3, 4;

-- Query #1 : Selecting the data we'll be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM SQLDataExploration..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY Location, date;

-- Query #2 : Total cases vs Total deaths in Canada
SELECT Location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM SQLDataExploration..CovidDeaths
WHERE Location like 'canada'
ORDER BY Location, date;

-- Query #3 : Total cases vs Population in Canada
-- Shows what percentage of Canada's population got Covid
SELECT Location, date, total_cases, population, (total_cases / population ) * 100 AS PercentageInfected
FROM SQLDataExploration..CovidDeaths
WHERE Location like 'canada'
ORDER BY Location, date;

-- Query #4 : Countries with highest infection rate
SELECT Location, MAX(total_cases) AS HighestCount, population, MAX(total_cases / population ) * 100 AS HighestPercentageInfected
FROM SQLDataExploration..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY HighestPercentageInfected DESC;

-- Query #5 : Countries with highest death count
SELECT Location, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount
FROM SQLDataExploration..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY HighestDeathCount DESC;

-- Query #6 : Total Cases Count by Continent
SELECT Location, MAX(CAST(total_cases AS INT)) AS TotalCasesCount
FROM SQLDataExploration..CovidDeaths
WHERE continent IS NULL
GROUP BY Location
ORDER BY TotalCasesCount DESC;

-- Query #7 : Continents with highest death count
SELECT Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM SQLDataExploration..CovidDeaths
WHERE continent IS NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Query #8 : Global Numbers by date
SELECT date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT)) / SUM(new_cases) AS DeathPercentage
FROM SQLDataExploration..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Query #9 : Global total cases, total deaths and death percentage
SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT)) / SUM(new_cases) AS DeathPercentage
FROM SQLDataExploration..CovidDeaths
WHERE continent IS NOT NULL;

-- Query #10 : Total population vs New Vaccinations
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations 
FROM SQLDataExploration..CovidDeaths deaths
JOIN SQLDataExploration..CovidVaccinations vacc
ON vacc.location = deaths.location AND vacc.date = deaths.date
WHERE deaths.continent IS NOT NULL
ORDER BY deaths.location;

-- Query #11 : Total Population vs Sum of New Vaccinations vs Percentage of Vaccinated people
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, SUM(CONVERT(INT, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) AS RollingVaccinations, (SUM(CONVERT(INT, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) / deaths.population) * 100 AS PercentageVaccinated
FROM SQLDataExploration..CovidDeaths deaths
JOIN SQLDataExploration..CovidVaccinations vacc
ON vacc.location = deaths.location AND vacc.date = deaths.date
WHERE deaths.continent IS NOT NULL
ORDER BY deaths.location, deaths.date;

-- Query #12 : Using CTE for query #11
WITH PopulationVacc (continent, location, date, population, new_vaccinations, RollingVaccinations)
AS 
(
	SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, SUM(CONVERT(INT, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) AS RollingVaccinations
	FROM SQLDataExploration..CovidDeaths deaths
	JOIN SQLDataExploration..CovidVaccinations vacc
	ON vacc.location = deaths.location AND vacc.date = deaths.date
	WHERE deaths.continent IS NOT NULL
)
SELECT *, (RollingVaccinations / population) * 100 AS PercentageVaccinated
FROM PopulationVacc
ORDER BY location, date;

-- Query #13 : Using Temp Table for query #11
DROP TABLE IF EXISTS #PercentageVaccinated
CREATE TABLE #PercentageVaccinated (
	continent VARCHAR(225),
	location VARCHAR(225),
	date DATE,
	population NUMERIC,
	new_vaccinations NUMERIC,
	RollingVaccinations NUMERIC
)

INSERT INTO #PercentageVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, SUM(CONVERT(INT, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) AS RollingVaccinations
FROM SQLDataExploration..CovidDeaths deaths
JOIN SQLDataExploration..CovidVaccinations vacc
ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL

SELECT *, (RollingVaccinations / population ) * 100 AS PercentageVaccinated
FROM #PercentageVaccinated
ORDER BY location, date

-- Query #14 : Using a View for query #11 to store data
CREATE VIEW PercentageVaccinated AS 
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations, SUM(CONVERT(INT, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.date) AS RollingVaccinations
FROM SQLDataExploration..CovidDeaths deaths
JOIN SQLDataExploration..CovidVaccinations vacc
ON deaths.location = vacc.location AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL