-- Calculate the average rental duration and total revenue for each customer, 
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

-- top 3 most rented categories (failed)
SELECT
	mycategory.name,
 	COUNT(mycategory.name) as value_occurrence
FROM rental as myrental
LEFT OUTER JOIN inventory as myinventory
ON myrental.inventory_id = myinventory.inventory_id
LEFT OUTER JOIN film_category as myfilm_category
ON myinventory.film_id = myfilm_category.film_id
LEFT OUTER JOIN category as mycategory
ON myfilm_category.category_id = mycategory.category_id
GROUP BY mycategory.name

SELECT
	myrental.customer_id,
	MAX(mycategory.name) as most_frequently_rented
FROM rental as myrental
LEFT OUTER JOIN inventory as myinventory
ON myrental.inventory_id = myinventory.inventory_id
LEFT OUTER JOIN film_category as myfilm_category
ON myinventory.film_id = myfilm_category.film_id
LEFT OUTER JOIN category as mycategory
ON myfilm_category.category_id = mycategory.category_id
GROUP BY myrental.customer_id
ORDER BY myrental.customer_id

-- Identify customers who have never rented films but have made payments.
SELECT
	mypayment.customer_id
FROM rental as myrental
RIGHT OUTER JOIN payment as mypayment
ON myrental.rental_id = mypayment.rental_id
WHERE myrental.rental_id IS NULL

-- Determine the average number of films rented per customer, broken down by city.
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
LEFT OUTER JOIN inventory as myinventory
ON myrental.inventory_id = myinventory.inventory_id
LEFT OUTER JOIN film as myfilm
ON myinventory.film_id = myfilm.film_id
GROUP BY mycity.city
ORDER BY COUNT(DISTINCT myrental.rental_id) / COUNT(DISTINCT myrental.customer_id) DESC

-- Identify films that have been rented more than the average number of times and are currently not in inventory.
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
INNER JOIN rental as myrental
ON myrental.inventory_id = myinventory.inventory_id
WHERE myinventory.inventory_id IS NULL
GROUP BY myfilm.film_id)a
WHERE a.total_rentals > 16
ORDER BY a.total_rentals DESC

--- Calculate the replacement cost of lost films for each store, considering the rental history.
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
