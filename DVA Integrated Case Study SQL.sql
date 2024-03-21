create database loan

select * from sys.databases

select TABLE_NAME from INFORMATION_SCHEMA.TABLES

select top 1 * from banker_Data
select top 1 * from Customer_Data
select top 1 * from Home_Loan_Data
select top 1 * from Loan_Records_Data

--Q.(1) Find the total number of different cities for which home loans have been issued

select  count(distinct(city)) number_of_cities 
from Home_Loan_Data
where joint_loan = 1

--Q.(2) Find the maximum property value (using appropriate alias) of each property type,
--ordered by the maximum property value in descending order

select property_type,max(property_value) max_property_value 
from Home_Loan_Data
group by property_type
order by max_property_value desc

--Q.(3) Find the ID, first name, and last name of the top 2 bankers (and corresponding transaction count)
--involved in the highest number of distinct loan records


select  top 2 bd.banker_id,first_name,last_name,count(distinct(loan_id)) transaction_count
from Banker_Data bd
join Loan_Records_Data ld
on bd.banker_id = ld.banker_id
group by bd.banker_id,first_name,last_name 
order by transaction_count desc


--Q.(4) Find the customer ID, first name, last name, and email of customers whose email address contains the term 'amazon'

select customer_id,first_name,last_name,email 
from Customer_Data
where email like '%amazon%'

--Q.(5) Find the average age (at the point of loan transaction, in years and nearest integer) 
--of female customers who took a non-joint loan for townhomes

select avg(datediff(YEAR,dob,transaction_date)) age 
from Customer_Data cd 
join Loan_Records_Data ld
on ld.customer_id = cd.customer_id 
join Home_Loan_Data hd
on hd.loan_id = ld.loan_id
where cd.gender = 'Female' and joint_loan = 0 and property_type = 'Townhome'

--Q(6). Find the number of home loans issued in San Francisco

select count(city) total_city
from Home_Loan_Data
where  city = 'San Francisco'


--Q(7). Find the names of the top 3 cities (based on descending alphabetical order) and corresponding loan percent
--(in ascending order) with the lowest average loan percent

select  top 15 city,avg(loan_percent) avg_loan_percent
from Home_Loan_Data
group by city
order by avg_loan_percent asc , city desc


--Q.(8) Find the average age of male bankers (years, rounded to 1 decimal place) based on the date they joined WBG

select avg(datediff(YEAR,dob,date_joined)) avg_age 
from Banker_Data
where gender = 'Male'

--Q(9). Find the city name and the corresponding average property value (using appropriate alias) for cities where
--the average property value is greater than $3,000,000

select (city),AVG(property_value) avg_property_value 
from Home_Loan_Data
where property_value > 3000000
group by city

--Q(10). Find the average loan term for loans not for semi-detached and townhome property types, and are in the following list
--of cities: Sparks, Biloxi, Waco, Las Vegas, and Lansing

select AVG(loan_term) avg_loan_term from Home_Loan_Data
where property_type not in ('Semi-detached','Townhome') and city  in ('Sparks','Biloxi','Waco','Las Vegas','Lansing')

---------------------------------------------------------------------------------------------------------------------------

--Q(1). Find the number of Chinese customers with joint loans with property values less than $2.1 million
--and served by female bankers. (3 Marks)

select count (nationality ) total_customers from Home_Loan_Data hd
join Loan_Records_Data ld
on ld.loan_id = hd.loan_id 
join Customer_Data cd
on cd.customer_id = ld.customer_id 
join Banker_Data bd
on bd.banker_id = ld.banker_id
where joint_loan = 1 and property_value < 2100000 and nationality = 'China' and bd.gender = 'Female'

--Q(2). Create a view called dallas_townhomes_gte_1m,which returns all the details of loans involving properties 
--of townhome type, located in Dallas, and have loan amount of >$1 million. (3 Marks)

create view dallas_townhomes_gte_1m as

select city,property_type,(property_value * loan_percent / 100)  loan_amt
from Home_Loan_Data
where property_type = 'Townhome' and city = 'Dallas'
group by city,property_type,(property_value * loan_percent / 100)
having (property_value * loan_percent / 100)> 1000000

select * from dallas_townhomes_gte_1m

--Q(3). Find the top 3 transaction dates (and corresponding loan amount sum) for which 
--the sum of loan amount issued on that date is the highest.  (3 Marks)

select top 3 transaction_date,sum(property_value * loan_percent / 100) sum_loan_amt
from Home_Loan_Data hd 
join Loan_Records_Data ld
on hd.loan_id = ld.loan_id  
group by transaction_date
order by sum_loan_amt desc

--Q(4).Find the sum of the loan amounts ((i.e., property value x loan percent / 100) for each banker ID,
--excluding properties based in the cities of Dallas and Waco. The sum values should be rounded to nearest integer.(3 Marks)

select bd.banker_id ,sum(property_value * loan_percent / 100) laon_amt
from Banker_Data bd 
join Loan_Records_Data ld
on bd.banker_id = ld.banker_id
join Home_Loan_Data hd
on hd.loan_id = ld.loan_id
where city not in ('Dallas','Waco')
group by bd.banker_id

--Q(5).Find the number of bankers involved in loans where the loan amount is greater than the average loan amount.(3 Marks)
 
select distinct (banker_id) from(

select bd.banker_id,(property_value * loan_percent / 100) loan_amt
from Banker_Data bd 
join Loan_Records_Data ld
on ld.banker_id = bd.banker_id 
join Home_Loan_Data hd
on hd.loan_id = ld.loan_id
group by bd.banker_id,(property_value * loan_percent / 100)
having (property_value * loan_percent / 100) > (select avg (property_value * loan_percent / 100) from Home_Loan_Data)
)Q


--Q(6). Create a stored procedure called recent_joiners that returns the ID, concatenated full name,
--date of birth, and join date of bankers who joined within the recent 2 years (as of 1 Sep 2022) 
--Call the stored procedure recent_joiners you created above (5 Marks)

create procedure recent_joiners as 

select banker_id,CONCAT(first_name,' ',last_name) fullname,dob,date_joined 
from Banker_Data
where date_joined > DATEADD(year,-2,'2022-09-01')
go

exec recent_joiners


--Q(7). Find the ID, first name and last name of customers with properties of value between $1.5 and $1.9 million,
--along with a new column 'tenure' 
--that categorizes how long the customer has been with WBG. 
--The 'tenure' column is based on the following logic:
--Long: Joined before 1 Jan 2015
--Mid: Joined on or after 1 Jan 2015, but before 1 Jan 2019
--Short: Joined on or after 1 Jan 2019

select cd.customer_id,first_name,last_name,property_value,
case when cd.customer_since < '2015-01-01' then 'Long'
when cd.customer_since > '2015-01-01' and cd.customer_since < '2019-01-01' then 'Mid'
else 'short' end as tenure
from Customer_Data cd join Loan_Records_Data ld
on cd.customer_id = ld.customer_id join Home_Loan_Data hd
on hd.loan_id = ld.loan_id
where property_value between 1500000 and 1900000

 --Q(8). Create a stored procedure called city_and_above_loan_amt that takes in two parameters (city_name, loan_amt_cutoff) that returns the full details 
--of customers with loans for properties in the input city and 
--with loan amount greater than or equal to the input loan amount cutoff.  
--Call the stored procedure city_and_above_loan_amt you 
--created above, based on the city San Francisco and loan amount cutoff of $1.5 million

create procedure  city_and_above_loan_amt @city varchar(255),@loan_amt_cutoff decimal (12,2) as

select * from Customer_Data cd join Loan_Records_Data ld
on cd.customer_id = ld.customer_id join Home_Loan_Data hd
on hd.loan_id = ld.loan_id
where city = @city and (property_value * loan_percent / 100)>= @loan_amt_cutoff
go

exec city_and_above_loan_amt @city = 'San Francisco',@loan_amt_cutoff = 1500000


--Q(9).Find the ID and full name(first name concatenated with last name)of customers who were served by bankers 
--aged below 30 (as of 1 Aug 2022).

select cd.customer_id,CONCAT(cd.first_name,' ',cd.last_name) fullname 
from Customer_Data cd 
join Loan_Records_Data ld
on ld.customer_id = cd.customer_id 
join Banker_Data bd
on bd.banker_id = ld.banker_id
where DATEDIFF(YEAR,bd.dob,'2022-08-01')<30





