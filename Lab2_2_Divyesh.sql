--Name: Divyesh Rajput; NU ID: 002788618
USE AdventureWorks2008R2;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
2-1
Retrieve the salesperson ID, the most recent order date and the total number of orders processed by each salesperson for each salesperson.
*/
SELECT  SalesPersonID , MAX (CAST(OrderDate AS date)) AS "MostRecentOrder" ,COUNT  (*) AS "TotalOrders"
FROM Sales.SalesOrderHeader
WHERE SalesPersonID IS NOT NULL  
GROUP BY SalesPersonID
ORDER BY TotalOrders DESC;

SELECT SalesPersonID, COUNT(SalesPersonID) AS TotalOrders, 
       CAST(MAX(OrderDate) AS DATE) AS MostRecentOrderDate
FROM Sales.SalesOrderHeader
WHERE SalesPersonID IS NOT NULL
GROUP BY SalesPersonID
ORDER BY TotalOrders DESC;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
2-2
Write a query to select the product id, name, and list price for the product(s) that have a list price greater than the average list price plus $500.
*/
SELECT ProductID, Name, ListPrice 
FROM Production.Product
WHERE ListPrice > (SELECT AVG(ListPrice) + 500
						FROM Production.Product)
ORDER BY ListPrice DESC;

select ProductID, Name, ListPrice
from Production.Product
where ListPrice > (select AVG(ListPrice) from Production.Product)+500
order by ListPrice desc;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
2-3
Write a query to calculate the "orders to customer ratio" (number of orders / unique customers) for each sales territory.
Return only the sales territories which have a ratio >= 5. Include the Territory ID and Territory Name in the returned data. Sort the returned data by TerritoryID.
*/

SELECT oh.TerritoryID, st.Name, COUNT (oh.SalesOrderID)/ COUNT(DISTINCT oh.CustomerID) AS "Order_to_Customer_Ratio"
FROM Sales.SalesOrderHeader oh INNER JOIN Sales.SalesTerritory st
ON oh.TerritoryID = st. TerritoryID
GROUP BY oh.TerritoryID, st.Name
HAVING COUNT (oh.SalesOrderID)/ COUNT(DISTINCT oh.CustomerID) >= 5
ORDER BY oh.TerritoryID;

select h.TerritoryID, t.name
from Sales.SalesOrderHeader h
join Sales.SalesTerritory t
on h.TerritoryID = t.TerritoryID
group by h.TerritoryID, t.name
having (count(SalesOrderID) / count(distinct CustomerID)) >= 5
order by TerritoryID;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
2-4
Write a query to retrieve the total sold quantity for each product. Return only the products that have a total sold quantity greater than 3000 and have the black color.
Sort the returned data by the total sold quantity in the descending order. Include the product ID, product name and total sold quantity columns in the report.
*/


SELECT DISTINCT od.ProductID, p.Name, sum (OrderQty) AS "Total Quantity Sold"
FROM Sales.SalesOrderDetail od INNER JOIN Production.Product p
ON od.ProductID = p.ProductID AND p.Color = 'Black'
GROUP BY od.ProductID, p.Name
HAVING sum(OrderQty) > 3000;


Select p.ProductID,
       p.Name,
       sum(sod.OrderQty) as 'Total Sold Quantity'
From Production.Product p 
join Sales.SalesOrderDetail sod
on p.ProductID = sod.ProductID
where Color = 'Black'
Group By p.ProductID, p.Name
Having sum(sod.OrderQty) > 3000
Order by sum(sod.OrderQty) desc;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
2-5
Write a query to retrieve the dates in which there was at least one order placed but no order worth more than $500 was placed. 
Use TotalDue in Sales.SalesOrderHeader as the order value.
Return the "order date" and "total product quantity sold for the date" columns. The order quantity column is in SalesOrderDetail. Display only the date part of the order date.
Sort the returned data by the "total product quantity sold for the date" column in desc.
*/

SELECT CAST (OrderDate AS date) "Order Date", SUM(sd.OrderQty) "Total Product Qty Sold for the day"
FROM Sales.SalesOrderHeader sh INNER JOIN Sales.SalesOrderDetail sd
ON sh.SalesOrderID = sd.SalesOrderID
WHERE OrderDate NOT IN (SELECT OrderDate
							   FROM Sales.SalesOrderHeader
							   WHERE TotalDue > 500)
GROUP BY OrderDate
ORDER BY "Total Product Qty Sold for the day" DESC;							   


SELECT cast(OrderDate as date) Date, sum(OrderQty) TotalProductQuantitySold
FROM Sales.SalesOrderHeader so
JOIN Sales.SalesOrderDetail sd
ON so.SalesOrderID = sd.SalesOrderID
WHERE OrderDate NOT IN
(SELECT OrderDate
 FROM Sales.SalesOrderHeader
 WHERE TotalDue >500)
GROUP BY OrderDate
ORDER BY TotalProductQuantitySold desc;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
2-6
Write a query to return the year and total sales of orders on the new year day for each year. Please keep in mind the database has several years' data.
Include only orders which contained 42 or more unique products when calculating the total sales.
Use TotalDue in SalesOrderHeader as an order's value when calculating the total sales. Return the total sales as an integer. Sort the returned data by year.

*/

SELECT Year (OrderDate)"Order Date", CAST (SUM(DISTINCT TotalDue)as int) "Total Sales of Orders on  that Day"
FROM Sales.SalesOrderHeader sh INNER JOIN Sales.SalesOrderDetail sd
ON sd.SalesOrderID = sh.SalesOrderID
WHERE (DATEPART(MONTH, OrderDate) = 1) AND (DATEPART(DAY, OrderDate) = 1) AND sh.SalesOrderID in ( SELECT SalesOrderID
																										FROM Sales.SalesOrderDetail
																											GROUP BY SalesOrderID
																											HAVING COUNT(ProductID) >= 42)
GROUP BY sh.OrderDate
ORDER BY OrderDate DESC;

with temp as
(select sh.SalesOrderID, count(distinct ProductID) up
 from Sales.SalesOrderHeader sh
 join Sales.SalesOrderDetail sd
 on sh.SalesOrderID =  sd.SalesOrderID
 group by sh.SalesOrderID
 having count(distinct ProductID) >= 42)
select year(OrderDate) Year, cast(sum(TotalDue) as int) TotalPurchase
from Sales.SalesOrderHeader
where month(OrderDate) = 1 and datepart(dd, OrderDate) = 1
      and SalesOrderID in (select SalesOrderID from temp)
group by year(OrderDate)
order by Year;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------