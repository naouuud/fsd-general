-- 1. Calculate the average rental duration and total revenue for each customer, 
-- along with their top 3 most rented film categories.

-- average rental duration using difference between timestamps
SELECT
	myrental.customer_id,
	AVG(myrental.return_date - myrental.rental_date) AS avg_rental_duration
FROM rental as myrental
GROUP BY myrental.customer_id
ORDER BY myrental.customer_id

-- total revenue for each customer
SELECT 
	mycustomer.customer_id,
	SUM(mypayment.amount) as total_revenue
FROM customer as mycustomer
LEFT OUTER JOIN payment as mypayment
ON mycustomer.customer_id = mypayment.customer_id
GROUP BY mycustomer.customer_id
ORDER BY COUNT(mypayment.amount) DESC

-- top 3 most rented categories by customer (NOT SOLVED)
WITH CUSTOMER_CATEGORY_CTE AS
(SELECT
	myrental.customer_id,
	mycategory.name as category_name
FROM rental as myrental
LEFT OUTER JOIN inventory as myinventory
ON myrental.inventory_id = myinventory.inventory_id
LEFT OUTER JOIN film_category as myfilm_category
ON myinventory.film_id = myfilm_category.film_id
LEFT OUTER JOIN category as mycategory
ON myfilm_category.category_id = mycategory.category_id
ORDER BY myrental.customer_id)

SELECT 
*
FROM CUSTOMER_CATEGORY_CTE as CUSTOMER_CATEGORY_CTE1
INNER JOIN CUSTOMER_CATEGORY_CTE as CUSTOMER_CATEGORY_CTE2
ON CUSTOMER_CATEGORY_CTE1.customer_id = CUSTOMER_CATEGORY_CTE2.customer_id
-- not sure how to proceed

-- 2. Identify customers who have never rented films but have made payments.
SELECT
	mypayment.customer_id
FROM rental as myrental
RIGHT OUTER JOIN payment as mypayment
ON myrental.rental_id = mypayment.rental_id
WHERE myrental.rental_id IS NULL

-- 3. Find the correlation between customer rental frequency and the average rating of the rented films.
WITH RENTAL_RATINGS_CTE AS
(SELECT 
myfilm.film_id as myfilm_id,
myfilm.rating myfilm_rating,
COUNT(myrental.rental_id) as total_times_rented_by_film
FROM film as myfilm
INNER JOIN inventory as myinventory
ON myfilm.film_id = myinventory.film_id
INNER JOIN rental as myrental
ON myinventory.inventory_id = myrental.inventory_id
GROUP BY myfilm.film_id
ORDER BY COUNT(myrental.rental_id) DESC)

SELECT 
myfilm_rating,
SUM(total_times_rented_by_film) as total_times_rented_by_rating
FROM
RENTAL_RATINGS_CTE
GROUP BY myfilm_rating
ORDER BY SUM(total_times_rented_by_film) DESC
-- Conclusion: The most frequently rented categories are PG-13 films and NC-17 films.

-- 4. Determine the average number of films rented per customer, broken down by city.
SELECT
	mycity.city,
	COUNT(DISTINCT myrental.rental_id) as unique_rentals,
	COUNT(DISTINCT myrental.customer_id) as unique_customers,
	COUNT(DISTINCT myrental.rental_id) / COUNT(DISTINCT myrental.customer_id) as avg_films_per_customer
FROM city as mycity
LEFT OUTER JOIN address as myaddress
ON mycity.city_id = myaddress.city_id
LEFT OUTER JOIN customer as mycustomer
ON mycustomer.address_id = myaddress.address_id
RIGHT OUTER JOIN rental as myrental
ON myrental.customer_id = mycustomer.customer_id
GROUP BY mycity.city
ORDER BY COUNT(DISTINCT myrental.rental_id) / COUNT(DISTINCT myrental.customer_id) DESC

-- 5. Identify films that have been rented more than the average number of times and are currently not in inventory.
-- query 1 - find average rentals per film (result = 16.74)
SELECT AVG(total_rentals)
FROM
(SELECT
	myfilm.film_id,
	COUNT(myrental.rental_id) as total_rentals
FROM film as myfilm
LEFT OUTER JOIN inventory as myinventory
ON myfilm.film_id = myinventory.film_id
INNER JOIN rental as myrental
ON myrental.inventory_id = myinventory.inventory_id
GROUP BY myfilm.film_id)a

-- query 2 - films that have been rented more than the average number of times and are currently not in inventory
SELECT film_id, total_rentals
FROM
(SELECT
	myfilm.film_id,
	COUNT(myrental.rental_id) as total_rentals
FROM film as myfilm
LEFT OUTER JOIN inventory as myinventory
ON myfilm.film_id = myinventory.film_id
LEFT OUTER JOIN rental as myrental
ON myrental.inventory_id = myinventory.inventory_id
WHERE myinventory.inventory_id IS NULL
GROUP BY myfilm.film_id)a
WHERE a.total_rentals > 16
ORDER BY a.total_rentals DESC

--- 6. Calculate the replacement cost of lost films for each store, considering the rental history.
SELECT 
mystore.store_id,
SUM(myfilm.replacement_cost) as total_replacement_cost
FROM film as myfilm
LEFT OUTER JOIN inventory as myinventory
ON myfilm.film_id = myinventory.film_id
LEFT OUTER JOIN rental as myrental
ON myinventory.inventory_id = myrental.inventory_id
INNER JOIN store as mystore
ON myinventory.store_id = mystore.store_id
WHERE myrental.return_date IS NULL
GROUP BY mystore.store_id

-- 7. Create a report that shows the top 5 most rented films in each category
-- along with their corresponding rental counts and revenue (NOT SOLVED)
WITH RENTALS_BY_CATEGORY AS
(SELECT
mycategory.category_id as mycategory_id,
myfilm.film_id as myfilm_id
FROM category as mycategory
INNER JOIN film_category as myfilm_category
ON mycategory.category_id = myfilm_category.category_id
INNER JOIN film as myfilm
ON myfilm_category.film_id = myfilm.film_id
LEFT OUTER JOIN inventory as myinventory
ON myfilm.film_id = myinventory.film_id
LEFT OUTER JOIN rental as myrental
ON myinventory.inventory_id = myrental.inventory_id
ORDER BY mycategory.category_id, myfilm.film_id)

SELECT 
mycategory_id,
myfilm_id,
COUNT(myfilm_id) as total_films
FROM RENTALS_BY_CATEGORY
GROUP BY mycategory_id, myfilm_id
ORDER BY mycategory_id, COUNT(myfilm_id) DESC

-- 8. Develop a query that automatically updates the top 10 most frequently rented films, 
-- considering a rolling 3-month window.
SELECT 
myfilm.title,
COUNT(myrental.rental_id) as total_rentals
FROM rental as myrental
INNER JOIN inventory as myinventory
ON myrental.inventory_id = myinventory.inventory_id
INNER JOIN film as myfilm
ON myinventory.film_id = myfilm.film_id
WHERE EXTRACT (DAY FROM (CURRENT_TIMESTAMP - myrental.rental_date)) < 90
GROUP BY myfilm.title
ORDER BY COUNT(myrental.rental_id) DESC
LIMIT 10

-- 9. Identify stores where the revenue from film rentals exceeds the revenue from payments for all customers.
-- revenue from film rentals by store
SELECT
mystore.store_id,
SUM(mypayment.amount) as total_revenue
FROM store as mystore
LEFT OUTER JOIN inventory as myinventory
ON mystore.store_id = myinventory.store_id
LEFT OUTER JOIN rental as myrental
ON myinventory.inventory_id = myrental.inventory_id
LEFT OUTER JOIN payment as mypayment
ON myrental.rental_id = mypayment.rental_id
GROUP BY mystore.store_id

-- revenue from all payments linked to customer
SELECT
	SUM(mypayment.amount) as total_payments
FROM payment as mypayment 
WHERE mypayment.customer_id IS NOT NULL
-- THEN compare values from each query

-- 10. Determine the average rental duration and total revenue for each store, considering different payment methods
-- Not sure what is meant by different payment methods
SELECT
mystore.store_id,
AVG(myrental.return_date - myrental.rental_date) as avg_rental_duration,
SUM(mypayment.amount) as total_revenue
FROM store as mystore
LEFT OUTER JOIN inventory as myinventory
ON mystore.store_id = myinventory.store_id
LEFT OUTER JOIN rental as myrental
ON myinventory.inventory_id = myrental.inventory_id
LEFT OUTER JOIN payment as mypayment
ON myrental.rental_id = mypayment.rental_id
GROUP BY mystore.store_id

-- 11. Analyze the seasonal variation in rental activity and payments for each store.
-- Use WHERE statement in the above example to limit timeframe, then compare different seasons/quarters
-- E.g., in the below, I look at Q2 (April, May, June)
SELECT
mystore.store_id,
AVG(myrental.return_date - myrental.rental_date) as avg_rental_duration,
SUM(mypayment.amount) as total_revenue
FROM store as mystore
LEFT OUTER JOIN inventory as myinventory
ON mystore.store_id = myinventory.store_id
LEFT OUTER JOIN rental as myrental
ON myinventory.inventory_id = myrental.inventory_id
LEFT OUTER JOIN payment as mypayment
ON myrental.rental_id = mypayment.rental_id
WHERE EXTRACT(MONTH FROM mypayment.payment_date) > 3
AND EXTRACT(MONTH FROM mypayment.payment_date) < 7
GROUP BY mystore.store_id
--Findings: All rentals and payments were made between January - June, and none in the second half of the year