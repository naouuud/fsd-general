--Create a CTE named top_customers that lists the top 10 customers based on the total number of distinct films they've rented.

WITH TOP_CUSTOMERS AS
(SELECT
	mycustomer.customer_id as mycustomer,
	COUNT(DISTINCT myfilm.film_id) as total_films_rented
FROM customer as mycustomer
INNER JOIN rental as myrental
ON myrental.customer_id = mycustomer.customer_id
INNER JOIN inventory as myinventory
ON myrental.inventory_id = myinventory.inventory_id
INNER JOIN film as myfilm
ON myinventory.film_id = myfilm.film_id
GROUP BY mycustomer.customer_id
ORDER BY COUNT(DISTINCT myfilm.film_id) DESC
LIMIT 10)

--For each customer from top_customers, retrieve their average payment amount and the count of rentals they've made.

WITH TOP_CUSTOMERS AS
(SELECT
	mycustomer.customer_id as mycustomer_id,
	COUNT(DISTINCT myfilm.film_id) as total_films_rented
FROM customer as mycustomer
INNER JOIN rental as myrental
ON myrental.customer_id = mycustomer.customer_id
INNER JOIN inventory as myinventory
ON myrental.inventory_id = myinventory.inventory_id
INNER JOIN film as myfilm
ON myinventory.film_id = myfilm.film_id
GROUP BY mycustomer.customer_id
ORDER BY COUNT(DISTINCT myfilm.film_id) DESC
LIMIT 10)
SELECT
TOP_CUSTOMERS.mycustomer_id,
AVG(mypayment.amount) as average_payment,
COUNT(myrental2.rental_id) as total_rentals
FROM TOP_CUSTOMERS
LEFT OUTER JOIN rental as myrental2
ON TOP_CUSTOMERS.mycustomer_id = myrental2.customer_id
INNER JOIN payment as mypayment
ON myrental2.rental_id = mypayment.rental_id
GROUP BY TOP_CUSTOMERS.mycustomer_id
ORDER BY COUNT(myrental2.rental_id) DESC

-- Create a Temporary Table named film_inventory that stores film titles 
-- and their corresponding available inventory count.
DROP TABLE IF EXISTS FILM_INVENTORY;
CREATE TEMPORARY TABLE FILM_INVENTORY AS
(SELECT
myfilm.film_id as film_id,
myfilm.title as film_title,
COUNT(myinventory.inventory_id) as available_inventory
FROM inventory as myinventory
RIGHT OUTER JOIN film as myfilm
ON myinventory.film_id = myfilm.film_id
GROUP BY myfilm.film_id, myfilm.title 
);

-- Populate the film_inventory table with data from the DVD rental database, considering both rentals and returns.
SELECT
*
FROM FILM_INVENTORY
LEFT OUTER JOIN inventory as myinventory
ON FILM_INVENTORY.film_id = myinventory.film_id
LEFT OUTER JOIN rental as myrental
ON myinventory.inventory_id = myrental.inventory_id
WHERE myrental.rental_date IS NOT NULL and myrental.return_date IS NULL
-- This shows films in inventory that have been rented by not returned

-- Retrieve the film title with the lowest available inventory count from the film_inventory table.
SELECT
film_title,
available_inventory
FROM FILM_INVENTORY
ORDER BY available_inventory ASC
LIMIT 1

-- Create a Temporary Table named store_performance that stores store IDs, revenue, and the average payment amount per rental.
DROP TABLE IF EXISTS STORE_PERFORMANCE;
CREATE TEMPORARY TABLE STORE_PERFORMANCE AS
(
WITH STORE_REVENUE AS
(SELECT
mystore.store_id as store_id,
COUNT(myfilm.film_id) as total_rentals,
AVG(myfilm.rental_rate) as avg_rental_rate,
COUNT(myfilm.film_id) * AVG(myfilm.rental_rate) as total_revenue
FROM store as mystore
LEFT OUTER JOIN inventory as myinventory
ON mystore.store_id = myinventory.store_id
LEFT OUTER JOIN rental as myrental
ON myinventory.inventory_id = myrental.inventory_id
LEFT OUTER JOIN film as myfilm
ON myfilm.film_id = myinventory.film_id
GROUP BY mystore.store_id)
SELECT
STORE_REVENUE.store_id,
STORE_REVENUE.total_revenue,
SUM(mypayment.amount) / COUNT(mypayment.payment_id) as avg_payment_amount
FROM 
STORE_REVENUE
LEFT OUTER JOIN customer as mycustomer
ON mycustomer.store_id = STORE_REVENUE.store_id
LEFT OUTER JOIN payment as mypayment
ON mycustomer.customer_id = mypayment.customer_id
GROUP BY STORE_REVENUE.store_id, STORE_REVENUE.total_revenue);

SELECT * FROM STORE_PERFORMANCE

