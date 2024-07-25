select * from CovidDeaths

--select * from CovidVaccination

-- selecting some columns

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
order by 1,2

--looking at total cases and deaths(converting to float to get decimal result)
--shows probability of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float)) *100 as DeathPercentage
from CovidDeaths
where location like '%urkey%'
order by 1,2

-- looking at total cases vs population
-- shows what percentage of population got covid-19
select location, date, total_cases, population, (cast(total_cases as float)/cast(population as float)) *100 as infectedPercentage
from CovidDeaths
where location like '%urkey%'
order by 1,2


-- looking at countiries with highest infection rate comparet to population

select location, population, max(total_cases) as HighestInfectionCount, max((cast(total_cases as float)/cast(population as float)) *100) as infectedPercentage
from CovidDeaths
--where location like '%urkey%'
group by location, population
order by infectedPercentage desc

--showing countries with highest death count per population
select location, population, max(total_deaths) as HighestDeathCount, max((cast(total_deaths as float)/cast(population as float)) *100) as deathPercentage
from CovidDeaths
--where location like '%urkey%'
where continent is not null --to eliminate continent
group by location, population
order by deathPercentage desc


-- total death in continents

select continent, sum(new_deaths) as totalDeath
from CovidDeaths
--where location like '%urkey%'
where continent is not null --to eliminate continent
group by continent
order by totalDeath desc

-- total death in world

select sum(new_cases) as total_case, sum(new_deaths) as total_death, (sum(cast(new_deaths as float))/sum(cast(new_cases as float))) * 100 as deathpercentage
from CovidDeaths
where continent is not null
order by 1,2


---JOIN TABLES

-- Looking at total population and vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over(partition by dea.location order by dea.date) as RollingPeopleVaccinated --, (RollingPeopleVaccinated/dea.population)*100
from CovidDeaths dea join CovidVaccination vac
	on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- USING CTE

with PopvsVac (continent, location, date, population, new_vaccination, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.date) as RollingPeopleVaccinated 
from CovidDeaths dea join CovidVaccination vac
	on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null 
)
select *, (cast(RollingPeopleVaccinated as float)/cast(population as float))*100 as vaccinatedPercentage
from PopvsVac

-- USING TEMP TABLE

drop table if exists #PercentagePopulationVaccinated
create table #PercentagePopulationVaccinated(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
rolling_people_vaccinated numeric
)

insert into #PercentagePopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date desc) as RollingPeopleVaccinated 
from CovidDeaths dea join CovidVaccination vac
	on dea.location = vac.location and dea.date = vac.date
--where dea.continent is not null 

select *, (cast(rolling_people_vaccinated as float)/cast(population as float))*100 as vaccinatedPercentage
from #PercentagePopulationVaccinated



-- Creating view to store data for later visualization
Create View PercentagePopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date desc) as RollingPeopleVaccinated 
from CovidDeaths dea join CovidVaccination vac
	on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null


select * 
from PercentagePopulationVaccinated