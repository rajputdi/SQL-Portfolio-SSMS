USE AdventureWorks2008R2;
--Name: Divyesh Rajput NU ID: 002788618
--Lab 3-1 
/* Modify the following query to add a column that identifies the frequency of repeat customers and contains the following values based on the number of orders:
--'No Order' for count = 0 'One Time' for count = 1 'Regular' for count range of 2-5 'Often' for count range of 6-10 'Loyal' for count greater than 10
--Give the new column an alias to make the report more readable. 
*/


SELECT c.CustomerID, c.TerritoryID, FirstName, LastName, COUNT(o.SalesOrderid) [Total Orders], 
CASE 
	WHEN COUNT(o.SalesOrderID) = 0
		THEN 'No Order'
	WHEN COUNT(o.SalesOrderID) = 1
		THEN 'One Time'
	WHEN COUNT(o.SalesOrderID) between 2 and 5
		THEN 'Regular'
	WHEN COUNT(o.SalesOrderID) between 6 and 10
		THEN 'Often'
	ELSE 'Loyal'
END AS 'Frequency'
FROM Sales.Customer c JOIN Sales.SalesOrderHeader o 
ON c.CustomerID = o.CustomerID JOIN Person.Person p 
ON p.BusinessEntityID = c.PersonID 
WHERE c.CustomerID > 25000
GROUP BY c.TerritoryID, c.CustomerID, FirstName, LastName;


-- Lab 3-2 
/* 
Modify the following query to add a rank without gaps in the ranking based on total orders in the descending order. Also partition by territory.
*/


SELECT c.CustomerID, c.TerritoryID, FirstName, LastName, COUNT(o.SalesOrderid) [Total Orders],
DENSE_RANK() OVER ( PARTITION BY c.TerritoryID 
					ORDER BY COUNT (o.SalesOrderId) DESC
)Rank
FROM Sales.Customer c JOIN Sales.SalesOrderHeader o 
ON c.CustomerID = o.CustomerID JOIN Person.Person p 
ON p.BusinessEntityID = c.PersonID 
WHERE c.CustomerID > 25000 
GROUP BY c.TerritoryID, c.CustomerID, FirstName, LastName;


-- Lab 3-3 
/* 
Retrieve the date, product id, product name, and the total sold quantity of the worst selling (by total quantity sold) product of each date.
If there is a tie for a date, it needs to be retrieved.
Sort the returned data by date in descending. 
*/

Select "Order Date", ProductID, Name, "Total Product Qty Sold for the day" from
	(	SELECT CAST (OrderDate AS date) "Order Date",  sd.ProductID , pp.Name, sum(sd.OrderQty) as "Total Product Qty Sold for the day", dense_rank() over (
																																		partition by OrderDate
																																		Order by sum(sd.Orderqty)
																																		)r
FROM Sales.SalesOrderHeader sh  inner JOIN Sales.SalesOrderDetail sd 
ON sh.SalesOrderID = sd.SalesOrderID inner JOIN Production.Product pp 
on sd.ProductID = pp.ProductID
GROUP BY OrderDate, sd.ProductID, Name
)t
where r = 1
order by [Order Date] DESC;	


select * from
   (select CAST(a.OrderDate as DATE) AS OrderDate,
           b.ProductID, c.Name, sum(b.OrderQty) as total,
           RANK() OVER (PARTITION BY a.OrderDate 
           ORDER BY sum(b.OrderQty)) AS Rank
    from [Sales].[SalesOrderHeader] a
    join [Sales].[SalesOrderDetail] b
         on a.SalesOrderID = b.SalesOrderID
    join [Production].[Product] c
         on c.ProductID = b.ProductID
    group by a.OrderDate, b.ProductID, c.Name
   ) temp
where rank = 1
order by OrderDate desc;





-- Lab 3-4 
/* 
Write a query to retrieve the most valuable salesperson of each year. The most valuable salesperson for each year is the salesperson who has made most sales for AdventureWorks in the year.
Calculate the yearly total of the TotalDue column of SalesOrderHeader as the yearly total sales for each salesperson. 
If there is a tie for the most valuable salesperson, your solution should retrieve it. Exclude the orders which didn't have a salesperson specified.
Include the salesperson id, the bonus the salesperson earned, and the most valuable salesperson's total sales for the year columns in the report. 
Display the total sales as an integer. Sort the returned data by the year. 
*/

Select SalesPersonID, OrderYear, "Total Sales", Bonus from 
(
	select year(OrderDate) as OrderYear, SalesPersonID, CAST(sum(TotalDue) as int) as "Total Sales", sp.Bonus , DENSE_RANK() over ( 
																											partition by year(OrderDate)
																											order by sum(TotalDue) DESC
																													)r
			from Sales.SalesOrderHeader sh inner join Sales.SalesPerson sp
			on sh.SalesPersonID = sp.BusinessEntityID
			where SalesPersonID is not null
			group by year(OrderDate), SalesPersonID, Bonus
			)t
			where r = 1
			Order by OrderYear DESC;



select Year, temp.SalesPersonID, cast(TotalSale as int) [Total Sales], Bonus 
from
(
  select year(OrderDate) Year, SalesPersonID, sum(TotalDue) TotalSale,
         rank() over (partition by year(OrderDate) order by sum(TotalDue) desc) as 
rank
  from Sales.SalesOrderHeader
  where SalesPersonID is not null
  group by year(OrderDate), SalesPersonID) temp
join Sales.SalesPerson s
on temp.SalesPersonID = s.BusinessEntityID
where rank = 1
order by Year;


-- Lab 3-5 
/* Write a query to return the salesperson id, the most sold product id, and the order id that contained the highest total order quantity for each salesperson. 
The most sold product had the highest total order quantity.
Return only the salesperson(s) who had at least one order that contained a total sold quantity greater than 450. 
Exclude orders which don't have a salesperson for this query. Sort the returned data by the salesperson id. 
*/

select A.SalesPersonID, A.ProductID, B.SalesOrderID from
(Select SalesPersonID, ProductID from 
(Select SalesPersonID, sd.ProductID, sum(sd.OrderQty) "Total Qty", DENSE_Rank() over (
																	partition by SalesPersonID
																	order by sum(sd.OrderQty) DESC
																			) r
			From Sales.SalesOrderHeader sh inner join Sales.SalesOrderDetail sd
			on sh.SalesOrderID = sd.SalesOrderID
			where sh.SalesPersonID is not null 
			group by SalesPersonID, ProductID
			--order by SalesPersonID, [Total Qty] DESC
			)t
			where r = 1 ) A join


(Select SalesPersonID, SalesOrderID from
(Select SalesPersonID, sd.SalesOrderID, sum(sd.OrderQty) "Total Qty", DENSE_Rank() over (
																	partition by SalesPersonID
																	order by sum(sd.OrderQty) DESC
																	) x
from Sales.SalesOrderHeader sh inner join Sales.SalesOrderDetail sd
on sh.SalesOrderID = sd.SalesOrderID
where SalesPersonID is not NULL
Group by SalesPersonID, sd.SalesOrderID
having sum(OrderQty) > 450)p
where x = 1
) B 
on A.SalesPersonID = B.SalesPersonID;



-----------------------------------------

with t1 as
(select SalesPersonID, ProductID, sum(OrderQty) ProductQuantity,
 rank() over (partition by SalesPersonID order by sum(OrderQty) desc) rp
 from Sales.SalesOrderHeader sh
 join Sales.SalesOrderDetail sd
 on sh.SalesOrderID = sd.SalesOrderID
 where SalesPersonID is not null
 group by SalesPersonID, ProductID),
t2 as
(select SalesPersonID, sh.SalesOrderID, sum(OrderQty) OrderQuantity,
 rank() over (partition by SalesPersonID order by sum(OrderQty) desc) ro
 from Sales.SalesOrderHeader sh
 join Sales.SalesOrderDetail sd
 on sh.SalesOrderID = sd.SalesOrderID
 where SalesPersonID is not null
 group by SalesPersonID, sh.SalesOrderID)
select t1.SalesPersonID, ProductID, SalesOrderID
from t1 join t2 on t1.SalesPersonID = t2.SalesPersonID
where rp = 1 and ro = 1 and OrderQuantity > 450
order by SalesPersonID;