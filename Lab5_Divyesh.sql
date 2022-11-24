--lab 5
--name: Divyesh Singh Rajput
--NU ID: 002788618

--1
/* Create a function in your own database that takes two parameters:
A year parameter A month parameter
The function then calculates and returns the total sales of the requested period for each territory. 
Include the territory id, territory name, and total sales dollar amount in the returned data. Format the total sales as an integer.
Hints: a) Use the TotalDue column of the Sales.SalesOrderHeader table in an AdventureWorks database for calculating the total sale.
	   b) The year and month parameters should have the SMALLINT data type. */

use rajput_divyesh;
drop function getMonthlySales ;

create function getMonthlySales 
(@month SMALLINT, @year SMALLINT)
returns table
as 
return(select sh.TerritoryID, st.Name, cast(sum(TotalDue) as int) "Sales" 
from AdventureWorks2008R2.Sales.SalesOrderHeader sh join AdventureWorks2008R2.Sales.SalesTerritory st 
on sh.TerritoryID = st.TerritoryID
where month(OrderDate) = @month and year(OrderDate) = @year
group by sh.TerritoryID, st.Name);

go

select * from getMonthlySales(12, 2007)
order by TerritoryID;

--2
/* Create a table in your own database using the following statement.
CREATE TABLE DateRange (DateID INT IDENTITY, DateValue DATE, DayOfWeek SMALLINT, Week SMALLINT, Month SMALLINT, Quarter SMALLINT, Year SMALLINT );
Write a stored procedure that accepts two parameters:
A starting date The number of the consecutive dates beginning with the starting date
The stored procedure then inserts data into all columns of the DateRange table according to the two provided parameters. */

use rajput_divyesh;

drop function GetDateRange;

CREATE FUNCTION dbo.GetDateRange
(@StartDate date, @NumberOfDays int)
RETURNS @DateList TABLE ( DateID INT IDENTITY, DateValue date, DayOfWeek SMALLINT, Week SMALLINT, Month int, Quarter SMALLINT, Year SMALLINT)
AS BEGIN
DECLARE @Counter int = 0;
DECLARE @CounterMonth int;
DECLARE @CounterDoW int;
DECLARE @CounterWeek int;
DECLARE @CounterQtr int;
DECLARE @CounterYear int;
DECLARE @startDate_1 date;
set @startDate_1 = (select @StartDate); 
WHILE (@Counter < @NumberOfDays)
	BEGIN
	set @CounterMonth = (select (datepart(month, @StartDate_1)));
	set @CounterDoW = (select (datepart(dw, @StartDate_1)));
	set @CounterWeek = (select (datepart(week, @StartDate_1)));
	set @CounterQtr = (select (datepart(quarter, @StartDate_1)));
	set @CounterYear =(select (datepart(year, @StartDate_1)));
	INSERT INTO @DateList
		VALUES( DATEADD(day,@counter,@StartDate),@CounterDoW,@CounterWeek,@CounterMonth,@CounterQtr,@CounterYear);
	SET @Counter += 1;
	set @StartDate_1 = (Select DATEADD(day, 1, @StartDate_1));
	END
RETURN;
END
GO
-- Execute the new function
SELECT * FROM dbo.GetDateRange('2010-04-26',200);

--3
/* Given the following tables, there is a university rule preventing a student from enrolling in a new class 
if there is an unpaid fine. Please write a table-level CHECK constraint to implement the rule. */

use rajput_divyesh;

create table Course (CourseID int primary key, CourseName varchar(50), InstructorID int, AcademicYear int, Semester smallint);
create table Student (StudentID int primary key, LastName varchar (50), FirstName varchar (50), Email varchar(30), PhoneNumber varchar (20));
create table Enrollment (CourseID int references Course(CourseID), StudentID int references Student(StudentID), RegisterDate date, primary key (CourseID, StudentID));
create table Fine (StudentID int references Student(StudentID), IssueDate date, Amount money, PaidDate date primary key (StudentID, IssueDate));


drop function ufLookUpFine;

create function LookUpFine (@StudentID int)
returns money
begin
   declare @amt money;
   select @amt = sum(Amount)
      from Fine
      where StudentID = @StudentID and PaidDate is null;
   return @amt;
end

alter table Enrollment add CONSTRAINT chkfine CHECK (dbo.LookUpFine (StudentID) = 0);

--test data
INSERT INTO Student VALUES(101,'Shelby', 'Thomas', 'abc@gmail.com', '966'),
						  (102,'Raghu', 'Ram', 'xyz@gmail.com', '977');
INSERT INTO Course VALUES(901,'DMDD', 1700, 2022, 2);

INSERT INTO Fine VALUES (101, '08-10-2022', 2900, '09-10-2022'),
						(102,'4-13-2022',2800,null);
INSERT INTO Enrollment VALUES(901,101,'11-17-2022');
Insert into Enrollment(CourseID, StudentID) values (901,102);
select * from Enrollment;

--4 
/* Write a trigger to put the total sale order amount before tax (unit price * quantity for all items included in an order) 
	in the OrderAmountBeforeTax column of SaleOrder. */

CREATE TABLE Customer (CustomerID VARCHAR(20) PRIMARY KEY, CustomerLName VARCHAR(30), CustomerFName VARCHAR(30), CustomerStatus VARCHAR(10));
CREATE TABLE SaleOrder (OrderID INT IDENTITY PRIMARY KEY, CustomerID VARCHAR(20) REFERENCES Customer(CustomerID), OrderDate DATE, OrderAmountBeforeTax INT);
CREATE TABLE SaleOrderDetail (OrderID INT REFERENCES SaleOrder(OrderID), ProductID INT, Quantity INT, UnitPrice INT, PRIMARY KEY (OrderID, ProductID));




--dropping tables
drop table SaleOrder;
drop table SaleOrderDetail;
drop table Customer;

/*
select * from Customer;
select * from SaleOrder;
select * from SaleOrderDetail;
*/
INSERT INTO Customer VALUES(1,'Shelby','Tommy','New');
INSERT INTO SaleOrder(CustomerID,OrderDate,OrderAmountBeforeTax) VALUES(1,'08-12-2022',null),(1,'07-11-2022',null);
INSERT INTO SaleOrderDetail VALUES(1,15,5,40);

--answer trigger
CREATE TRIGGER UpdateAmountBTax
    ON SaleOrderDetail
    FOR INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @TotalAmount INT;
    DECLARE @Order INT;
    set @Order = (select OrderID from inserted as i)
    set @TotalAmount = (select SUM(Quantity * UnitPrice) 
						from SaleOrderDetail 
						where OrderID = @Order  
						group by OrderID)
    update SaleOrder set OrderAmountBeforeTax = @TotalAmount 
	where OrderID = @Order
END



