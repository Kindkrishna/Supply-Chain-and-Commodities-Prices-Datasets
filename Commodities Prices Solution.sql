/************************************************************************************************
Question 1: Get the common commodities between the Top 10 costliest commodities of 2019 and 2020.
************************************************************************************************/
USE commodity_db;

WITH year1_summary AS
(
SELECT 
commodity_id, 
MAX(retail_price) as price
FROM price_details
WHERE YEAR(date)=2019
GROUP BY commodity_id
ORDER BY price DESC
LIMIT 10
),
year2_summary AS
(
SELECT 
commodity_id, 
MAX(retail_price) as price
FROM price_details
WHERE YEAR(date)=2020
GROUP BY commodity_id
ORDER BY price DESC
LIMIT 10
),
common_commodities AS
(
SELECT y1.commodity_id
FROM 
year1_summary AS y1
INNER JOIN
year2_summary AS y2
ON y1.commodity_id=y2.commodity_id
)
SELECT DISTINCT ci.commodity AS common_commodity_list
FROM
common_commodities as cc
JOIN
commodities_info as ci
ON cc.commodity_id=ci.id;


/************************************************************************************************
Question 2: What is the maximum difference between the prices of a commodity at one place vs the other 
for the month of Jun 2020? Which commodity was it for?

Algorithm:
Input: price_details: Id, Region_Id, Commodity_Id, Date and Retail_Price; commodities_info: Id and Commodity
Expected Output: Commodity | price difference;  Retain the info for highest difference
Step 1: Filter Jun 2020 in Date column of price_details
Step 2: Aggregation – MIN(retail_price), MAX(retail_price) group by commodity
Step 3: Compute the difference between the Max and Min retail price
Step 4: Sort in descending order of price difference; Retain the top most row
************************************************************************************************/
USE commodity_db;

WITH june_prices AS
(
SELECT commodity_id, 
MIN(retail_price) AS Min_price,
MAX(retail_price) AS Max_price
FROM price_details
WHERE date BETWEEN '2020-06-01' AND '2020-06-30'
GROUP BY commodity_id
)
SELECT ci.commodity,
Max_price-Min_price AS price_difference
FROM
june_prices as jp
JOIN
commodities_info as ci
ON jp.commodity_id=ci.id
ORDER BY price_difference DESC
LIMIT 1; 



/************************************************************************************************
Question 3: Arrange the commodities in order based on the number of varieties in which they are available, 
with the highest one shown at the top. Which is the 3rd commodity in the list?

Algorithm:
Input: commodities_info: Commodity and Variety
Expected Output: Commodity | Variety count;  Sort in descending order of Variety count
Step 1: Aggregation – COUNT(DISTINCT variety), group by Commodity
Step 2: Sort the final table in descending order of Variety count
************************************************************************************************/
USE commodity_db;

SELECT 
Commodity,
COUNT(DISTINCT Variety) AS Variety_count
FROM 
commodities_info
GROUP BY Commodity
ORDER BY Variety_count DESC;


/************************************************************************************************
Question 4: In the state with the least number of data points available. 
Which commodity has the highest number of data points available?

Algorithm:
Input: price_details: Id, region_id, commodity_id region_info: Id and State commodities_info: Id and Commodity
Expected Output: commodity;  Expecting only one value as output
Step 1: Join region info and price details using the Region_Id from price_details with Id from region_info
Step 2: From result of Step 1, perform aggregation – COUNT(Id), group by State; 
Step 3: Sort the result based on the record count computed in Step 2 in ascending order; 
		Filter for the top State
Step 4: Filter for the state identified from Step 3 from the price_details table
Step 5: Aggregation – COUNT(Id), group by commodity_id; Sort in descending order of count 
Step 6: Filter for top 1 value and join with commodities_info to get the commodity name
************************************************************************************************/
USE commodity_db;

WITH raw_data AS
(
SELECT 
pd.id, pd.commodity_id, ri.state
FROM
price_details as pd
LEFT JOIN
region_info as ri
ON pd.region_id = ri.id
),
state_rec_count AS
(
SELECT state, 
COUNT(id) as state_wise_datapoints
FROM raw_data
GROUP BY state
ORDER BY state_wise_datapoints
LIMIT 1
),
commodity_list AS
(
SELECT 
commodity_id,
COUNT(id) AS record_count
FROM 
raw_data
WHERE state IN (SELECT DISTINCT state FROM state_rec_count)
GROUP BY commodity_id
ORDER BY record_count DESC
)
SELECT 
commodity,
SUM(record_count) AS record_count
FROM
commodity_list AS cl
LEFT JOIN
commodities_info AS ci
ON cl.commodity_id = ci.id
GROUP BY commodity
ORDER BY record_count DESC
LIMIT 1;

/*******************************************************************************************************
Question 5: What is the price variation of commodities for each city from Jan 2019 to Dec 2020. 
			Which commodity has seen the highest price variation and in which city?
Algorithm:
Input: price_details: Id, region_id, commodity_id, date, retail_price 
	   region_info: Id and City 
	   commodities_info: Id and Commodity
Expected Output: Commodity | city | Start Price | End Price | Variation absolute | Variation Percentage;  
Sort in descending order of variation %

Step 1: Filter for Jan 2019 from Date column of the price_details table
Step 2: Filter for Dec 2020 from Date column of the price_details table
Step 3: Do an inner join between the results from Step 1 and Step 2 on region_id and commodity id
Step 4: Name the price from Step 1 result as Start Price and Step 2 result as End Price
Step 5: Calculate Variations in absolute and percentage; 
		Sort the final table in descending order of Variation Percentage
Step 6: Filter for 1st record and join with region_info, commodities_info to get city and commodity name
********************************************************************************************************/
USE commodity_db;

WITH jan_2019_data AS
(
SELECT * 
FROM 
price_details
WHERE date BETWEEN '2019-01-01' AND '2019-01-31'
),
dec_2020_data AS
(
SELECT * 
FROM 
price_details
WHERE date BETWEEN '2020-12-01' AND '2020-12-31'
),
price_variation AS
(
SELECT j.region_id,
j.commodity_id,
j.retail_price AS start_price,
d.retail_price AS end_price,
d.retail_price - j.retail_price AS variation,
ROUND( (d.retail_price - j.retail_price)/j.retail_price*100 ,2) AS variation_percentage
FROM 
jan_2019_data as j
INNER JOIN
dec_2020_data as d
ON j.region_id = d.region_id
AND j.commodity_id=d.commodity_id
ORDER BY variation_percentage DESC
LIMIT 1
)
SELECT  
r.centre as city, 
c.commodity as commodity_name,
start_price,
end_price,
variation,
variation_percentage
FROM 
price_variation as p
JOIN
region_info r
ON p.region_id = r.id
JOIN
commodities_info as c
ON p.commodity_id=c.id;