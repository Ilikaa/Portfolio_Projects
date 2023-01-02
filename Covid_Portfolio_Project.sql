---- checking if data is complete
Select*
From Portfolio_Project.dbo.Covid_Deaths
order by 3,4

Select*
From Portfolio_Project.dbo.Covid_Vaccinations
order by 3,4


--selecting data to be used
Select location, date, total_cases, new_cases, total_deaths, population
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
order by location, date


--Exploring Total Cases vs Total Deaths
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
order by location, date


--Total Cases vs Total Deaths in India
--shows probability of dying if one contracts Covid in India
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
	and location like '%india%'
order by location, date
-- first death was reported on 11/03/2020 
-- on 11/03/2020
--		Death Percentage was at 1.6%
--		Total reported cases were 62
-- by end of year 2020
--		total reported cases were 1,02,66,674
--		total number of deaths were 1,48,738
--		death rate was at 1.4%


--Highest and Lowest Covid caused Death Rate in India till 30/04/2021
Select location, max((total_deaths/total_cases)*100) as Max_Death_Percentage, min((total_deaths/total_cases)*100) as Min_Death_Percentage
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
	and location like '%india%'
Group by location
-- max death percentage = 3.6%
-- min death percentage = 1.1%



--Total Cases vs Population
--shows percentage of population in India that contracted Covid
Select location, date, population, total_cases, (total_cases/population)*100 as Infected_Population_Percentage
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
	and location like '%india%'
order by location, date
-- 1% of India's populations was infected by 13/04/2021
-- on 13/04/2021  
--		India's population was 1,38,00,04,385
--		total reported cases in India were 1,38,73,825


--Infection rate by country
Select location, population, max(total_cases) as Highest_Infected_Count, max((total_cases/population)*100) as Infected_Population_Percentage
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
Group by location, population
order by Infected_Population_Percentage desc
-- India stands at 96th position


--Death count by country
Select location, max(cast(total_deaths as int)) as Total_Death_Count
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
Group by location
order by Total_Death_Count desc
-- India stands at 4th position


--Death count by continent
Select continent, max(cast(total_deaths as int)) as Total_Death_Count
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
Group by continent
order by Total_Death_Count desc
--Asia stands at 3rd position


--GLOBAL NUMBERS

--Death Percentage
Select date, sum(new_cases) as Total_Cases, sum(cast(new_deaths as int)) as Total_Deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as Global_Death_Percentage
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
Group by date
order by 1,2
--1st death in the world reported on 23/1/2020
--On 23/1/2020
--		Total global cases were 98
--      Global death percentage was 1%


--Overall Death Percentage till 30/04/2021
Select sum(new_cases) as Total_Cases, sum(cast(new_deaths as int)) as Total_Deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as Global_Death_Percentage
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
order by 1,2
--Total cases - 15,05,74,977
--Total Deaths - 31,80,206
--Global death Percentage - 2.1%


--Total population vs vaccinations
Select death.continent,death.location,death.date,death.population,vacc.new_vaccinations,
	sum(convert(int,vacc.new_vaccinations)) over (partition by death.location
	order by death.location, death.date) as Rolling_People_Vaccinated
From Portfolio_Project.dbo.Covid_Deaths as death
join Portfolio_Project.dbo.Covid_Vaccinations as vacc
	on death.location = vacc.location
	and death.date = vacc.date
Where death.continent is not null
	and death.location like '%India%'
order by 2,3
--Total people vaccinated in India - 14,25,86,233


--Using CTE to find out total percent population vaccinated
With PopulationvsVaccinations (Continent, Location, Date, Population, New_vaccinations, Rolling_People_Vaccinated)
as
(
Select death.continent,death.location,death.date,death.population,vacc.new_vaccinations,
	sum(convert(int,vacc.new_vaccinations)) over (partition by death.location
	order by death.location, death.date) as Rolling_People_Vaccinated
From Portfolio_Project.dbo.Covid_Deaths as death
join Portfolio_Project.dbo.Covid_Vaccinations as vacc
	on death.location = vacc.location
	and death.date = vacc.date
Where death.continent is not null
)
Select*, (Rolling_People_Vaccinated/Population)*100 as Percent_Population_Vaccinated
From PopulationvsVaccinations
Where Location = 'India'
-- by 30/04/2021, 10.3% of India's population was vaccinated


--Using TEMP TABLE to find out total percent population vaccinated
Drop Table if exists #Percent_Population_Vaccinated
Create table #Percent_Population_Vaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_People_Vaccinated numeric
)
Insert into #Percent_Population_Vaccinated
Select death.continent,death.location,death.date,death.population,vacc.new_vaccinations,
	sum(convert(int,vacc.new_vaccinations)) over (partition by death.location
	order by death.location, death.date) as Rolling_People_Vaccinated
From Portfolio_Project.dbo.Covid_Deaths as death
join Portfolio_Project.dbo.Covid_Vaccinations as vacc
	on death.location = vacc.location
	and death.date = vacc.date
Where death.continent is not null

Select*, (Rolling_People_Vaccinated/Population)*100 as Percent_Population_Vaccinated
From #Percent_Population_Vaccinated
Where Location = 'India'
-- by 30/04/2021, 10.3% of India's population was vaccinated


--Creating Views to use for visualizations

--Total Population Vaccinated per country
Create View Total_Population_Vaccinated_per_Country as 
Select death.continent,death.location,death.date,death.population,vacc.new_vaccinations,
	sum(convert(int,vacc.new_vaccinations)) over (partition by death.location
	order by death.location, death.date) as Rolling_People_Vaccinated
From Portfolio_Project.dbo.Covid_Deaths as death
join Portfolio_Project.dbo.Covid_Vaccinations as vacc
	on death.location = vacc.location
	and death.date = vacc.date
Where death.continent is not null


--Percent Population Vaccinated per country
Create View Percent_Population_Vaccinated_per_Country as
Select continent, location, date, population, (Rolling_People_Vaccinated/population)*100 as Percent_Population_Vaccinated
From dbo.Total_Population_Vaccinated_per_Country


--Global Death Percentage per day
Create View Global_Death_Percentage_per_Day as
Select date, sum(new_cases) as Total_Cases, sum(cast(new_deaths as int)) as Total_Deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as Global_Death_Percentage
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
Group by date


--Total Death Count per Continent
Create View Total_Death_Count_by_Continent as
Select continent, max(cast(total_deaths as int)) as Total_Death_Count_by_Continent
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
Group by continent


--Total Death Count per Country
Create View Total_Death_Count_by_Country as
Select location, max(cast(total_deaths as int)) as Total_Death_Count
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
Group by location


--Total Infection Rate per Country
Create View Total_Infection_Rate_per_Country as
Select location, population, max(total_cases) as Highest_Infected_Count, max((total_cases/population)*100) as Infected_Population_Percentage
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
Group by location, population


--Total Cases vs Population
Create View Total_Cases_vs_Population as
Select location, date, population, total_cases, (total_cases/population)*100 as Infected_Population_Percentage
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null


--Total Cases vs Total Deaths
Create View Total_Cases_vs_Total_Deaths as
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From Portfolio_Project.dbo.Covid_Deaths
Where continent is not null
