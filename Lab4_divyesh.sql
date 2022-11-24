7--Lab 4
--Name: Divyesh Rajput
--NU ID: 002788618

create database rajput_divyesh;
Go 

use rajput_divyesh;

create table Student
(
StudentID varchar(5) not null primary key,
LastName varchar(20) not null,
FirstName varchar(20) not null,
DateOfBirth date not null
);

create table Term 
(
TermID int not null primary key,
Year char(4) not null,
Term varchar(10) not null
);

Create table Course
(
CourseID int not null primary key,
Name varchar(30) not null,
Description varchar(30) not null
);

Create table Enrollment
(
StudentID varchar(5) not null
references Student(StudentID),
CourseID int not null
references Course(CourseID),
TermID int not null
references Term(TermID)
constraint EnrollmentKey primary key clustered
(StudentID, CourseID, TermID)
);



--part B-1
/* Write a query to retrieve the top 3 products for each year. 
Use OrderQty of SalesOrderDetail to calculate the total sold quantity. 
The top 3 products have the 3 highest total sold quantities. 
Also calculate the top 3 products' total sold quantity for the year. 
Return the data in the following format.
*/

use AdventureWorks2008R2;

with cte_1 as(
select year(OrderDate) as Year, ProductID, sum(OrderQty) as Sale,
rank () over (partition by year(OrderDate) order by sum(OrderQty) DESC) rank
from Sales.SalesOrderDetail sd join Sales.SalesOrderHeader sh
on sd.SalesOrderID = sh.SalesOrderID
group by year(OrderDate), ProductID)

select distinct ct1.Year, sum(ct1.Sale)"Total Sale",
stuff ((Select ', ' + cast (ProductID as varchar)
		from cte_1 ct2
		where ct2.Year = ct1.Year
		and ct2.rank <=3
		for xml path('')),1,2,'') as Products
from cte_1 ct1
where ct1.rank <=3
group by ct1.Year; 


--testing query. Don't consider for assignment
/*
select ProductID, sum(OrderQty), year(OrderDate)
from Sales.SalesOrderDetail sd join Sales.SalesOrderHeader sh
on sd.SalesOrderID = sh.SalesOrderID
where ProductID = 709 and year(OrderDate) = 2005
group by ProductID, year(OrderDate);
*/
-------------------------------------------------------

--Part B-2
/*
Using AdventureWorks2008R2, write a query to return the salesperson id, 
number of unique products sold, highest order value, total sales amount, 
and top 3 orders for each salesperson. 
Use TotalDue in SalesOrderHeader when calculating the highest order value and total sales amount. 
The top 3 orders have the 3 highest total order quantities. 
If there is a tie, the tie must be retrieved. Exclude orders which don't have a salesperson for this query.
Return the order value as int. Sort the returned data by SalesPersonID. The returned data should have a format displayed below. Use the sample format for formatting purposes only.
*/

With cte_1 as(
select sd.SalesOrderID, sh.SalesPersonID, sum(sd.OrderQty) as TotalSum, rank() over(partition by SalesPersonID order by sum(sd.OrderQty)DESC) rank
from Sales.SalesOrderDetail sd join Sales.SalesOrderHeader sh
on sd.SalesOrderID = sh.SalesOrderID
where SalesPersonID is not null
group by sd.SalesOrderID, sh.SalesPersonID
)

select distinct SalesPersonID, count(distinct ProductID) as TotalUniqueProducts, cast (max(TotalDue) as int) as "OrderValue",
	stuff ((Select ', ' + cast (SalesOrderID as varchar)
		from cte_1 ct2
		where ct2.SalesPersonID = sh.SalesPersonID
		and ct2.rank <=3
		for xml path('')),1,2,'') as Orders
from Sales.SalesOrderDetail sd join Sales.SalesOrderHeader sh
on sd.SalesOrderID = sh.SalesOrderID
where SalesPersonID is not null
group by SalesPersonID
order by SalesPersonID;


--Part C
/*
The following code retrieves the components required for manufacturing the "Mountain-500 Black, 48" (Product 992). 
Modify the code to retrieve the most expensive component(s) that cannot be manufactured internally. 
Use the list price of a component to determine the most expensive component. 
If there is a tie, your solutions must retrieve it. */

WITH Parts(AssemblyID, ComponentID, PerAssemblyQty, EndDate, ComponentLevel) AS 
( SELECT b.ProductAssemblyID, b.ComponentID, b.PerAssemblyQty, b.EndDate, 0 AS ComponentLevel 
FROM Production.BillOfMaterials AS b 
WHERE b.ProductAssemblyID = 992 AND b.EndDate IS NULL
UNION ALL
SELECT bom.ProductAssemblyID, bom.ComponentID, bom.PerAssemblyQty, bom.EndDate, ComponentLevel + 1
FROM Production.BillOfMaterials AS bom INNER JOIN Parts AS p ON bom.ProductAssemblyID = p.ComponentID AND bom.EndDate IS NULL ) 

Select AssemblyID, ComponentID, Name, ComponentLevel
from 
( Select AssemblyID, ComponentID, Name, ComponentLevel, rank() over( order by ListPrice DESC) rnk, ListPrice
from (SELECT AssemblyID, 
ComponentID, Name, PerAssemblyQty, ComponentLevel, pr.ListPrice
FROM Parts AS p INNER JOIN Production.Product AS pr 
ON p.ComponentID = pr.ProductID )t
where ComponentLevel = 0 and ComponentID not in (Select AssemblyID from Parts p INNER JOIN Production.Product AS pr 
													on p.ComponentID = pr.ProductID
													where ComponentLevel = 1
													)
--Order by ListPrice DESC
) t 
where t.rnk =1;


