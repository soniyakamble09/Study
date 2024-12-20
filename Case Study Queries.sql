create database salesdata;

use salesdata;

desc customers;

show create table customers;

desc employees;

show create table employees;

desc offices;

show create table offices;

desc products;

show create table products;

show create table productlines;

select * from products;

select * from productlines ;

show create table orders;

show create table orderdetails;

select * from orderdetails order by productcode;

show create table payments;

use salesdata;
show tables;

select * from customers;

select customernumber, creditlimit 
from customers;

select * from payments;

select customernumber,sum(amount)
from payments
group by customernumber;

update customers
set creditlimit = (select sum(amount)
					from payments
					where customernumber = 103
					group by customernumber) - creditlimit
where customernumber = 103;

/* 1. Customer Credit Limit Update:
ARISOFT Corporation wants to implement a system 
where the credit limit of a customer is automatically 
updated based on the total amount of payments received 
for that customer. Design an SQL query or procedure to 
calculate the total payments received for each customer and 
update their credit limit accordingly.*/

delimiter $
create procedure Customer_Credit_Limit_Update()
begin
#declare variables
declare done boolean default false;
declare custid int;
declare totalpayment decimal(10,2);

#declare cursor
declare mycursor cursor for
select customernumber,sum(amount)
from payments
group by customernumber;

#declare error handler
declare continue handler for not found set done = true;

#open cursor
open mycursor;

#fetch the rows and update the customers table
while not done do
fetch mycursor into custid, totalpayment;
update customers 
set creditlimit = creditlimit + totalpayment
where customernumber = custid;
end while;

#close cursor
close mycursor;
end $

select * from customers;

call Customer_Credit_Limit_Update();
#-------------------------------

/*2. Employee Promotion Check:
ARISOFT Corporation wants to identify employees who are 
eligible for promotion based on their job performance. 
Create an SQL query or procedure to check if an employee 
has achieved a specified sales target (consider the orders 
and orderdetails tables) and, if so, update their job title 
to indicate a promotion.*/

select * from employees;

select * from customers order by salesrepemployeenumber;

select * from orderdetails;

select * from orders;

select e.employeenumber
from customers c join employees e
on(c.salesrepemployeenumber = e.employeenumber)
join orders o
on(c.customernumber = o.customernumber)
join orderdetails od
on(o.ordernumber = od.ordernumber)
group by e.employeenumber
having sum(od.priceeach * od.quantityordered) > 700000;

delimiter $
create procedure Employee_Promotion_Check()
begin
declare done boolean default false;
declare empid int;

declare cur cursor for
select e.employeenumber
from customers c join employees e
on(c.salesrepemployeenumber = e.employeenumber)
join orders o
on(c.customernumber = o.customernumber)
join orderdetails od
on(o.ordernumber = od.ordernumber)
group by e.employeenumber
having sum(od.priceeach * od.quantityordered) > 700000;

declare continue handler for not found set done = true;

open cur;

while not done do
fetch cur into empid;
update employees 
set jobtitle = 'Senior Sales Rep'
where employeenumber = empid;
end while;

close cur;
end;

call Employee_Promotion_Check();

select * from employees;

#-------------------------------------------
select count(distinct country)
from customers;

select * from offices;

insert into offices values
(8, 'Mumbai', '+91 22 78384787','andheri','',
'maharashtra','india',400012,'');

/* 3. Office Territory Update:
The territories assigned to each office need to be 
updated based on the country of the office location. 
Design an SQL query or procedure to automatically assign 
the correct territory code to each office based on its country. 
Use the offices table for this operation.
NA (North America)
Europe, Middle East, and Africa (EMEA)
Asia-Pacific (APAC)
South Asian Association for Regional Cooperation (SAARC)
*/

select case 
	when country in ('USA') then 'NA'
    when country in ('france','uk','germany','italy') then 'EMEA'
    when country in ('australia','new zealand') then 'APAC'
    when country in ('india','sri lanka') then 'SAARC'
    else country
end 'territory'
from offices;

update offices
set territory = (select case 
	when country in ('USA') then 'NA'
    when country in ('france','uk','germany','italy') then 'EMEA'
    when country in ('australia','new zealand') then 'APAC'
    when country in ('india','sri lanka') then 'SAARC'
    else country
	end 'territory'
	from offices
    where country = 'india')
where country = 'india';

#------------------------------
/* 4. Product Stock Monitoring:
ARISOFT Corporation wants to monitor product 
stock levels and generate alerts when the quantity 
in stock falls below a specified threshold. 
Create an SQL query or trigger that automatically 
notifies the relevant stakeholders when a product's 
stock level becomes critical.*/

select * from products;

delimiter $
create trigger after_products_update
after update
on products
for each row
begin
	if new.quantityinstock <= 50 then
		/*sqlstate 45000 is used to create
        used defined exception*/
		signal sqlstate '45000' 
        set message_text = 'quantity is low';
	end if;
end $

update products 
set quantityinstock = quantityinstock - 10
where productcode = 'S12_1099';

delimiter $
create trigger after_products_update
after update
on products
for each row
begin
	if new.quantityinstock < 0 then
		/*sqlstate 45000 is used to create
        used defined exception*/
		signal sqlstate '45000' 
        set message_text = 'insufficient quantity';
	end if;
end $

#---------------------------------------------

/* 5. Product Line Description Analysis:
The marketing team at ARISOFT Corporation is interested in analyzing 
the effectiveness of product line descriptions. 
Develop an SQL query to retrieve the average length of 
product line descriptions (textDescription column in the 
productlines table) and identify which product lines have 
descriptions above or below the average length.*/
/*above 400 characters*/

select * from productlines;

select avg(length(textdescription))
from productlines;

select productline, textdescription, length(textdescription)
from productlines
where length(textdescription) > 
		(select avg(length(textdescription))
		from productlines);

/*below 400 characters*/
select productline, textdescription, length(textdescription)
from productlines
where length(textdescription) < 
		(select avg(length(textdescription))
		from productlines);
#-----------------------------------------------
/* 6. Customer Order History::
ARISOFT Corporation wants to provide customers 
with a summary of their order history, including 
the total amount spent and the number of orders 
placed. Design an SQL query or procedure to 
retrieve this information for a specific customer.*/

select * from customers;

select * from orders;

select * from orderdetails;

select c.customernumber,
		count(o.ordernumber) 'totalorders',
        sum(od.quantityordered * od.priceeach) 'totalamountspent'
from customers c
join orders o
using(customernumber)
join orderdetails od
using(ordernumber)
group by c.customernumber;
#------------------------------------------------

select * from orders;

select * from customers;

/* 7. Identify Late Shipments:
The logistics department needs a way to identify orders 
with late shipments. Develop an SQL query or procedure to 
list orders that have a status of 'Shipped' but where the 
shipped date is later than the required date.*/
select customername, country 
from orders, customers
where orders.customernumber = customers.customernumber
		and status = 'shipped'
		and shippeddate > requireddate;

select customername, country 
from orders join customers
on(orders.customernumber = customers.customernumber)
where status = 'shipped'
		and shippeddate > requireddate;
        
select customername, country 
from orders o join customers c
on(c.customernumber = o.customernumber)
where status = 'shipped'
		and shippeddate > requireddate;
        
select customername, country 
from orders o join customers c
using(customernumber)
where status = 'shipped'
		and shippeddate > requireddate;
        
select customername, country 
from orders o natural join customers c
where status = 'shipped'
		and shippeddate > requireddate;
        
# --- natural join -if column name and 
# --- datatype is same between two tables
#-----------------------

/* 8. Product Vendor Analysis:
The procurement team wants to analyze the distribution 
of products among different vendors. 
Create an SQL query to retrieve the count of products 
supplied by each vendor (productVendor column in 
the products table) and order the results by the 
count in descending order.*/

select * from products;

select productvendor, count(productname) 'productcount'
from products
group by productvendor
order by count(productname);

#---------------------------------
/* 9. Employee Reporting Hierarchy:
ARISOFT Corporation wants to ensure that the reporting 
hierarchy of employees is correctly represented. 
Design an SQL query or procedure to validate that the 
reportsTo field in the employees table accurately 
reflects the organizational reporting structure.*/

use salesdata;

select * from employees;

select emp.firstname 'employee', emp.reportsTo 'reportto', 
mgr.employeenumber 'managerid', mgr.firstname 'manager'
from employees emp
left outer join employees mgr
on(emp.reportsto = mgr.employeenumber);

#--------------------------------------------
/* 10. Customer Payment History:
The finance department needs a comprehensive 
report on customer payment history. 
Create an SQL query to retrieve the payment 
details for a specific customer, including check 
numbers, payment dates, and amounts.*/

select * from payments;

select customername, checknumber, paymentdate, amount
from customers
join 
payments
using (customernumber);

#-----------------------------------------------
/*Indexes
--------
an index is a database object that improves the speed of
data retrieval operations on a table by providing quick
access to specific rows within the table. It is similar
to an index in a book, which allows you to quickly 
locate information.
CREATE INDEX index_name ON table_name (column_name);
CREATE INDEX index_name ON table_name (column1, column2);
ex:
CREATE INDEX idx_department_id ON employees(department_id);
CREATE INDEX idx_salary ON employees(salary);

SELECT * FROM employees WHERE department_id = 101;
SELECT * FROM employees WHERE salary > 50000;

this resulting in improved query performance.
faster execution

   */


#######################################
#Triggers

use salesdata;

create table student(
	sid int primary key,
    sname varchar(20) not null,
    age int);
    
create table audit(
	id int primary key auto_increment,
    sid int,
    sname varchar(20),
    age int, 
    action_date datetime,
    action varchar(10));
    
delimiter $
create trigger after_student_insert
after insert 
on student
for each row
begin
	/*insert into audit
    set action = 'insert',
    action_date = now(),
    sid = new.sid,
    sname = new.sname,
    age = new.age;*/
	insert into audit(sid, sname, age, 
				action_date,action)
    values(new.sid, new.sname, new.age, now(), 'insert');
end $

show triggers;

insert into student values(14,'scott',15);

select * from student;

select * from audit;

delimiter $
create trigger after_student_delete
after delete
on student
for each row
begin
	insert into audit
    set action = 'delete',
    action_date = now(),
    sid = old.sid,
    sname = old.sname,
    age = old.age;
end $

delete from student where sid = 1;

delete from student;

delimiter $
create trigger after_student_update
after update
on student
for each row
begin
	insert into audit
    set action = 'update_old',
    action_date = now(),
    sid = old.sid,
    sname = old.sname,
    age = old.age;
    insert into audit
    set action = 'update_new',
    action_date = now(),
    sid = new.sid,
    sname = new.sname,
    age = new.age;
end $

insert into student values(14,'scott',15);

select * from audit;

update student set age = 16 where sid = 14;




