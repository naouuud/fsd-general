-- Using a CTE, find out the total number of films rented for each rating (like 'PG', 'G', etc.) in the year 2005. 
-- List the ratings that had more than 50 rentals.

WITH RENTALS_BY_RATING AS 
(
	SELECT
		myfilm.rating as film_rating,
		COALESCE(COUNT(myrental.rental_id), 0) as total_rentals
	FROM public.rental as myrental
	INNER JOIN public.inventory as myinventory
		ON myinventory.inventory_id = myrental.inventory_id
	INNER JOIN public.film as myfilm
		ON myinventory.film_id = myfilm.film_id
	WHERE EXTRACT(YEAR FROM myrental.rental_date) = 2005
	GROUP BY 
		myfilm.rating
)
SELECT 
	film_rating,
	total_rentals
FROM RENTALS_BY_RATING
WHERE 
	RENTALS_BY_RATING.total_rentals > 50

-- Identify the categories of films that have an average rental duration greater than 5 days. 
-- Only consider films rated 'PG' or 'G'.

SELECT
	mycategory.name as category_name,
	COALESCE(AVG(myfilm.rental_duration), 0) as avg_rental_duration
FROM public.category as mycategory
LEFT OUTER JOIN public.film_category as myfilm_category
	ON myfilm_category.category_id = mycategory.category_id
LEFT OUTER JOIN public.film as myfilm
	ON myfilm_category.film_id = myfilm.film_id
WHERE 
	LOWER(CAST(myfilm.rating AS TEXT)) = 'pg' 
OR 
	LOWER(CAST(myfilm.rating AS TEXT)) = 'g'
GROUP BY 
	mycategory.name
HAVING AVG(myfilm.rental_duration) > 5

-- Determine the total rental amount collected from each customer. 
-- List only those customers who have spent more than $100 in total.

WITH RENTAL_AMOUNT_BY_CUSTOMER AS (
SELECT  
	mypayment.customer_id as customer_id,
	SUM(mypayment.amount) as total_rental_amount
FROM public.rental as myrental
INNER JOIN public.payment as mypayment
	ON myrental.rental_id = mypayment.rental_id
GROUP BY 
	mypayment.customer_id
)
SELECT
	*
FROM RENTAL_AMOUNT_BY_CUSTOMER
WHERE 
	total_rental_amount > 100

--OR

WITH RENTAL_AMOUNT_BY_CUSTOMER AS (
SELECT  
	mycustomer.customer_id as customer_id,
	COALESCE(SUM(mypayment.amount), 0) as total_rental_amount
FROM public.customer as mycustomer
LEFT OUTER JOIN public.rental as myrental
	ON myrental.customer_id = mycustomer.customer_id
INNER JOIN public.payment as mypayment
	ON myrental.rental_id = mypayment.rental_id
GROUP BY 
	mycustomer.customer_id
)
SELECT
	customer_id,
	total_rental_amount
FROM RENTAL_AMOUNT_BY_CUSTOMER
WHERE 
	total_rental_amount > 100

-- Create a temporary table containing the names and email addresses of 
-- customers who have rented more than 10 films.

DROP TABLE IF EXISTS RENTED_TEN_PLUS_FILMS;
CREATE TEMPORARY TABLE RENTED_TEN_PLUS_FILMS AS
(
	SELECT 
		mycustomer.customer_id as customer_id,
		CONCAT(mycustomer.first_name, ' ', mycustomer.last_name) as customer_name,
		mycustomer.email as customer_email,
		COUNT(DISTINCT myfilm.film_id) as total_films_rented
	FROM public.rental as myrental
	INNER JOIN public.inventory as myinventory
		ON myinventory.inventory_id = myrental.inventory_id
	INNER JOIN public.film as myfilm
		ON myinventory.film_id = myfilm.film_id
	INNER JOIN public.customer as mycustomer
		ON myrental.customer_id = mycustomer.customer_id
	GROUP BY 
		mycustomer.customer_id, CONCAT(mycustomer.first_name, ' ', mycustomer.last_name)
	HAVING 
		COUNT(DISTINCT myfilm.film_id) > 10
);
SELECT
	customer_name, 
	customer_email
FROM RENTED_TEN_PLUS_FILMS

-- From the temporary table created in Task 3.1, 
-- identify customers who have a Gmail email address (i.e., their email ends with '@gmail.com').

SELECT
	customer_name
FROM RENTED_TEN_PLUS_FILMS
WHERE customer_email LIKE '%@gmail.com'

-- Start by creating a CTE that finds the total number of films rented for each category.
-- Create a temporary table from this CTE.
-- Using the temporary table, list the top 5 categories with the highest number of rentals. Ensure the results are in descending order.

DROP TABLE IF EXISTS FILMS_RENTED_BY_CATEGORY;
CREATE TEMPORARY TABLE FILMS_RENTED_BY_CATEGORY AS
(
	WITH FILMS_RENTED_BY_CATEGORY_CTE AS 
	(
		SELECT
			mycategory.name as category_name,
			COALESCE(COUNT(myrental.rental_id)) as total_films_rented
		FROM public.category as mycategory
		LEFT OUTER JOIN public.film_category as myfilm_category
			ON myfilm_category.category_id = mycategory.category_id
		LEFT OUTER JOIN public.inventory as myinventory
			ON myinventory.film_id = myfilm_category.film_id
		LEFT OUTER JOIN public.rental as myrental
			ON myinventory.inventory_id = myrental.inventory_id
		GROUP BY 
			mycategory.name
	)
	SELECT * FROM FILMS_RENTED_BY_CATEGORY_CTE
);

SELECT  
	category_name,
	total_films_rented
FROM FILMS_RENTED_BY_CATEGORY
ORDER BY 
	total_films_rented DESC
LIMIT 5


-- Identify films that have never been rented out. Use a combination of CTE and LEFT JOIN for this task.

WITH RENTED_FILMS AS (
SELECT 
	DISTINCT myinventory.film_id
FROM public.rental as myrental
INNER JOIN public.inventory as myinventory
	ON myinventory.inventory_id = myrental.inventory_id
)
SELECT
	myfilm.title
FROM public.film as myfilm
LEFT OUTER JOIN RENTED_FILMS
	ON RENTED_FILMS.film_id = myfilm.film_id
WHERE RENTED_FILMS.film_id IS NULL

-- (INNER JOIN): Find the names of customers who rented films with a replacement cost greater 
--than $20 and which belong to the 'Action' or 'Comedy' categories.

WITH SELECTED_CUSTOMERS AS 
(
SELECT 
DISTINCT mycustomer.customer_id
FROM rental as myrental
INNER JOIN inventory as myinventory
ON myrental.inventory_id = myinventory.inventory_id
INNER JOIN film as myfilm
ON myinventory.film_id = myfilm.film_id
INNER JOIN customer as mycustomer 
ON myrental.customer_id = mycustomer.customer_id
INNER JOIN film_category as myfilm_category
ON myfilm_category.film_id = myfilm.film_id
INNER JOIN category as mycategory
ON myfilm_category.category_id = mycategory.category_id
WHERE myfilm.replacement_cost > 20
AND LOWER(mycategory.name) = 'action' OR LOWER(mycategory.name) = 'comedy'
)
SELECT
CONCAT(mycustomer2.first_name, ' ', mycustomer2.last_name) as customer_name
FROM SELECTED_CUSTOMERS
INNER JOIN customer as mycustomer2
ON SELECTED_CUSTOMERS.customer_id = mycustomer2.customer_id

-- (LEFT JOIN): List all actors who haven't appeared in a film with a rating of 'R'.
WITH ACTORS_IN_R_FILMS AS
(
SELECT 
DISTINCT myactor.actor_id,
myfilm.rating
FROM actor as myactor
LEFT OUTER JOIN film_actor as myfilm_actor
ON myfilm_actor.actor_id = myactor.actor_id
LEFT OUTER JOIN film as myfilm
ON myfilm_actor.film_id = myfilm.film_id
WHERE LOWER(CAST(myfilm.rating AS TEXT)) = 'r'
)
SELECT
myactor2.actor_id,
CONCAT(myactor2.first_name, ' ', myactor2.last_name) as actor_name
FROM actor as myactor2
LEFT OUTER JOIN ACTORS_IN_R_FILMS
ON myactor2.actor_id = ACTORS_IN_R_FILMS.actor_id
WHERE ACTORS_IN_R_FILMS.actor_id IS NULL

-- (Combination of INNER JOIN and LEFT JOIN): 
-- Identify customers who have never rented a film from the 'Horror' category.

WITH HORROR_RENTALS AS 
(
	SELECT
	myrental.rental_id as rental_id,
	myrental.customer_id as customer_id,
	mycategory.name as category_name
	FROM rental as myrental
	INNER JOIN inventory as myinventory
	ON myrental.inventory_id = myinventory.inventory_id
	INNER JOIN film as myfilm
	ON myinventory.film_id = myfilm.film_id
	INNER JOIN film_category as myfilm_category
	ON myfilm_category.film_id = myfilm.film_id
	INNER JOIN category as mycategory
	ON mycategory.category_id = myfilm_category.category_id
	WHERE LOWER(mycategory.name) = 'horror'
)
SELECT 
mycustomer.customer_id,
CONCAT(mycustomer.first_name, ' ', mycustomer.last_name)
FROM customer as mycustomer
LEFT OUTER JOIN HORROR_RENTALS
ON HORROR_RENTALS.customer_id = mycustomer.customer_id
WHERE HORROR_RENTALS.rental_id IS NULL

-- (Multiple INNER JOINs): Find the names and email addresses of customers who rented films directed 
--  by a specific actor (let's say, for the sake of this task, that the actor's first name is 
-- 'Nick' and last name is 'Wahlberg', 
--  although this might not match actual data in the DVD Rental database).

SELECT 
DISTINCT(mycustomer.customer_id),
CONCAT(mycustomer.first_name, ' ', mycustomer.last_name) as customer_name,
mycustomer.email 
FROM actor as myactor
INNER JOIN film_actor as myfilm_actor
ON myactor.actor_id = myfilm_actor.actor_id
INNER JOIN film as myfilm
ON myfilm_actor.film_id = myfilm.film_id
INNER JOIN inventory as myinventory
ON myfilm.film_id = myinventory.film_id
INNER JOIN rental as myrental
ON myinventory.inventory_id = myrental.inventory_id
INNER JOIN customer as mycustomer
ON myrental.customer_id = mycustomer.customer_id
WHERE myactor.first_name = 'Nick'
AND myactor.last_name = 'Wahlberg'