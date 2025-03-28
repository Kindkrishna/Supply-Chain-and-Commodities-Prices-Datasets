-- Database selection
use supply_db;
/* List of tables
department; 
category;
customer_info;
product_info ;
ordered_items ;
FROM orders;
*/

/***************************************************************************************************
Question 1: Get the number of orders by the Type of Transaction. Please exclude orders shipped from 
Sangli and Srinagar. Also, exclude the SUSPECTED_FRAUD cases based on the Order Status. Sort the 
result in the descending order based on the number of orders.

Algorithm:
Input: Orders table: Order_Id, Type, Order_City, Order_Status
Expected Output: Type of Transaction | Orders; Sorted in descending order of Orders
Step 1: Filter out ‘Sangli’ and ‘Srinagar’ from the city column of the data
Step 2: Filter out ‘SUSPECTED_FRAUD ’ from the order_status column of the data
Step 3: Aggregation – COUNT(order_id), group by Transaction_type
Step 4: Sort the result in descending order of Orders
***************************************************************************************************/
use supply_db;

SELECT 
Type AS Type_of_Transaction,
COUNT(order_id) as Orders
FROM orders
WHERE Order_City <>'Sangli' AND Order_City <>'Srinagar'
AND Order_Status<>'SUSPECTED_FRAUD'
GROUP BY Type_of_Transaction
ORDER BY Orders DESC;





/***************************************************************************************************
Question 2: Get the list of the Top 3 customers based on the completed orders along with the following details:
Customer Id, Customer First Name, Customer City, Customer State, Number of completed orders, Total Sales

Algorithm:
Input: Orders table: Order_Id and Order_Status; 
		Ordered_items table: Sales; 
        Customer_info table: Id, First_Name, City, State;
Expected Output: Customer Id | Customer First Name | Customer City | Customer State | 
				Completed orders | Total Sales; Retain only top 3 customer based on Completed orders
Step 1: Join orders and order_items to get order_id level sales
Step 2: Filter for ‘COMPLETE’ orders from the order_status column of the orders table
Step 3: Join above result with Customers table and create customer id level summary
Step 4: Aggregation – COUNT(order_id), SUM(Sales) 
		group by Customer Id, Customer First Name, Customer City and Customer State
***************************************************************************************************/
USE supply_db;

WITH order_summary AS
(
select 
ord.order_id,
ord.customer_id, 
SUM(sales) AS ord_sales
from orders as ord
JOIN
ordered_items as itm
ON ord.order_id=itm.order_id
WHERE ord.order_status='COMPLETE'
GROUP BY ord.order_id,
ord.customer_id
)
SELECT Id AS Customer_id,
First_Name AS Customer_First_Name, 
City AS Customer_City, 
State AS Customer_State,
COUNT(DISTINCT order_id) as Completed_Orders,
SUM(ord_sales) as Total_Sales
FROM 
order_summary as ord
INNER JOIN
customer_info as cust
ON ord.customer_id=cust.id
GROUP BY 
Customer_id,
Customer_First_Name,
Customer_City,
Customer_State
ORDER BY Completed_Orders DESC, Total_Sales DESC
LIMIT 3;



/***************************************************************************************************
Question 3: Get the order count by the Shipping Mode and the Department Name. Consider departments 
with at least 40 closed/completed orders.

Algorithm:
Input: orders: order_id, Shipping_Mode and Order_Status; ordered_items; product_info; department: name;
Expected Output: Shipping Mode | Department Name | Orders; 
				 Retain departments with atleast 40 closed/completed order

Step 1: Join orders, ordered_items, product_info and department to get all the departments and 
		orders associated with them
Step 2: Filter for ‘COMPLETE’ and ‘CLOSED’ from order_status column of the orders table
Step 3: Aggregation – COUNT(order_id), group by department name; 
Step 4: In the above table filter for COUNT(order_id)>=40
Step 5: From Step 1 perform aggregation – COUNT(order_id), group by Shipping mode and department name; 
		Retain only those department names that were left over after the filter applied in Step 4
***************************************************************************************************/
USE supply_db;

WITH ord_dept_summary AS
(
SELECT ord.order_id, ord.shipping_mode, d.name AS department_name, order_status
FROM
orders as ord
JOIN
ordered_items as ord_itm
ON ord.order_id=ord_itm.order_id
JOIN
product_info as p
ON ord_itm.item_id=p.product_id
JOIN
department as d
ON p.department_id=d.id
),
dept_summary AS
(
SELECT 
department_name, 
COUNT(order_id) as order_count
FROM
ord_dept_summary
WHERE order_status IN ('COMPLETE' , 'CLOSED')
GROUP BY department_name
),
dept_list AS
(
SELECT distinct department_name 
FROM 
dept_summary
WHERE order_count>=40
)
SELECT 
shipping_mode, 
department_name, 
COUNT(order_id) as orders
FROM ord_dept_summary
WHERE department_name IN (select * FROM dept_list)
GROUP BY 
shipping_mode, 
department_name;


/***************************************************************************************************
Question 4: Create a new field as shipment compliance based on Real_Shipping_Days and Scheduled_Shipping_Days. 
It should have the following values:
	Cancelled shipment - If the Order Status is SUSPECTED_FRAUD or CANCELED
	Within schedule - If shipped within the scheduled number of days 
	On time - If shipped exactly as per schedule
	Upto 2 days of delay - If shipped beyond schedule but delay upto 2 days
	Beyond 2 days of delay - If shipped beyond schedule with delay beyond 2 days

Which shipping mode was observed to have the greatest number of delayed orders?

Algorithm:
Input: orders: order_id, Real_Shipping_Days, Scheduled_Shipping_Days and Shipping_Mode
Expected Output: 1) order_id | shipment_compliance; 2) shipping_mode | Number of delayed orders
Step 1: Create a shipment compliance column based on the criteria 
Step 2: Test and confirm if all the cases are taken care of. Check for null values too
Step 3: Filter for delayed orders only
Step 4: Aggregation – COUNT(order_id), group by shipping mode; 
		Sort in descending order of order count; Retain the top most row
***************************************************************************************************/
USE supply_db;

WITH compliance_summary AS
(
SELECT
DISTINCT
order_id,
Real_Shipping_Days, Scheduled_Shipping_Days, 
Shipping_Mode, 
order_status,
CASE WHEN order_status = 'SUSPECTED_FRAUD' OR order_status = 'CANCELED' THEN 'Cancelled shipment'
	 WHEN Real_Shipping_Days<Scheduled_Shipping_Days THEN 'Within schedule'
     WHEN Real_Shipping_Days=Scheduled_Shipping_Days THEN 'On Time'
     WHEN Real_Shipping_Days<=Scheduled_Shipping_Days+2 THEN 'Upto 2 days of delay'
     WHEN Real_Shipping_Days>Scheduled_Shipping_Days+2 THEN 'Beyond 2 days of delay'
ELSE 'Others' END AS shipment_compliance
FROM
orders
)
SELECT shipping_mode,
COUNT(order_id) as orders
FROM 
compliance_summary
WHERE shipment_compliance IN ('Upto 2 days of delay', 'Beyond 2 days of delay')
GROUP BY shipping_mode
ORDER BY orders DESC
LIMIT 1;


/***************************************************************************************************
Question 5: An order is cancelled when the status of the order is either CANCELED or SUSPECTED_FRAUD. 
Obtain the list of states by the order cancellation % and sort them in the descending order of the 
cancellation %.         Definition: Cancellation % = Cancelled order / Total Orders

Algorithm:
Input: Orders: Order_Id, Order_State and Order_Status
Expected Output: Order State | Cancellation Percentage;  Sort in descending order of cancellation %
Step 1: Filter for ‘CANCELED’ and ‘SUSPECTED_FRAUD’ from order_status column of the orders table
Step 2: From result of Step 1, perform aggregation – COUNT(order_id), group by Order_State; 
Step 3: Create separate aggregation of orders table - COUNT(order_id), group by Order_State; to get total orders
Step 4: Join results of Step 2 and Step 3 on Order_State
Step 5: Create new column with calculation Cancellation Percentage =Cancelled Orders / Total Orders
Step 6: Sort the final table in descending order of Cancellation Percentage
***************************************************************************************************/
USE supply_db;

WITH cancelled_orders_summary AS
(
SELECT
Order_State, 
COUNT(order_id) as cancelled_orders
FROM Orders
WHERE order_status='CANCELED' OR order_status='SUSPECTED_FRAUD'
GROUP BY Order_State
),
total_orders_summary AS
(
SELECT
Order_State, 
COUNT(order_id) as total_orders
FROM Orders
GROUP BY Order_State
)
SELECT t.order_state,
ROUND(COALESCE(cancelled_orders,0)/total_orders*100,2) as Cancellation_Percentage
FROM 
cancelled_orders_summary as c
RIGHT JOIN
total_orders_summary as t
ON c.Order_State=t.Order_state
ORDER BY Cancellation_Percentage DESC;