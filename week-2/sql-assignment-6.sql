-- Determine whether the total rentals for each film is above or below the average, 
-- you can first compute the average count of rentals across all films. 
-- Then, you can compare each film's rental count to this average.

WITH 
RENTALS_BY_FILM AS
(
	SELECT 
		myfilm.film_id,
		myfilm.title,
		COUNT(myrental.rental_id) as total_times_rented
		FROM
		film as myfilm
		LEFT OUTER JOIN inventory as myinventory
		ON myfilm.film_id = myinventory.film_id
		INNER JOIN rental as myrental
		ON myrental.inventory_id = myinventory.inventory_id
		GROUP BY myfilm.film_id, myfilm.title
	),
AVG_RENTALS AS 
(
	SELECT 
		AVG(RENTALS_BY_FILM.total_times_rented) as value
		FROM RENTALS_BY_FILM
	)
SELECT 
	RENTALS_BY_FILM.film_id,
	RENTALS_BY_FILM.title,
	RENTALS_BY_FILM.total_times_rented,
	CASE 
	WHEN RENTALS_BY_FILM.total_times_rented <= AVG_RENTALS.value THEN 'False'
	WHEN RENTALS_BY_FILM.total_times_rented > AVG_RENTALS.value THEN 'True'
	END AS greater_than_average
	FROM RENTALS_BY_FILM, AVG_RENTALS


-- Using Query sent on slack, please update self joins to the CTE to come up with 3 addition columns (first, second, third).

DROP TABLE IF EXISTS TOP3;
CREATE TEMPORARY TABLE TOP3 AS (
WITH FILM_CATEGORY AS
(
	SELECT 
		se_rental.customer_id,
		se_category.name as category_name,
		COUNT(se_rental.rental_id) AS total_rentals
		FROM public.rental AS se_rental
		INNER JOIN public.inventory AS se_inventory
		ON se_inventory.inventory_id = se_rental.inventory_id
		INNER JOIN public.film AS se_film
		ON se_film.film_id = se_inventory.film_id
		INNER JOIN public.film_category AS se_film_category
		ON se_film_category.film_id = se_film.film_id
		INNER JOIN public.category AS se_category
		ON se_category.category_id = se_film_category.category_id
		GROUP BY
		se_rental.customer_id,
		se_category.name
		ORDER BY customer_id, COUNT(se_rental.rental_id) DESC
	),
PART_BY_CUST AS 
(SELECT
		FILM_CATEGORY.customer_id,
		FILM_CATEGORY.category_name,
		FILM_CATEGORY.total_rentals,
		ROW_NUMBER() OVER (PARTITION BY FILM_CATEGORY.customer_id ORDER BY FILM_CATEGORY.total_rentals DESC)
		FROM FILM_CATEGORY)
SELECT
	PART_BY_CUST.customer_id,
	PART_BY_CUST.category_name,
	PART_BY_CUST.total_rentals,
	PART_BY_CUST.row_number
	FROM
	PART_BY_CUST
	WHERE PART_BY_CUST.row_number IN (1, 2, 3)
);

DROP TABLE IF EXISTS FIRST_JOIN;
CREATE TEMPORARY TABLE FIRST_JOIN AS
(SELECT 
	TOP3_1.customer_id,
 	TOP3_1.category_name as top_1,
 	TOP3_2.category_name as category_name,
 	TOP3_2.row_number as row_number
	FROM TOP3 AS TOP3_1
	INNER JOIN TOP3 AS TOP3_2
	ON TOP3_1.customer_id = TOP3_2.customer_id
	AND TOP3_1.row_number = 1);
	
DROP TABLE IF EXISTS SECOND_JOIN;
CREATE TEMPORARY TABLE SECOND_JOIN AS
(SELECT
	FIRST_JOIN.customer_id,
 	FIRST_JOIN.top_1,
 	FIRST_JOIN.category_name as top_2,
 	TOP3.row_number as row_number,
	TOP3.category_name
FROM FIRST_JOIN
INNER JOIN TOP3
ON FIRST_JOIN.customer_id = TOP3.customer_id
AND FIRST_JOIN.row_number = 2);

SELECT
	DISTINCT SECOND_JOIN.customer_id,
	SECOND_JOIN.top_1,
	SECOND_JOIN.top_2,
	SECOND_JOIN.category_name as top_3
FROM SECOND_JOIN
INNER JOIN TOP3
ON SECOND_JOIN.customer_id = TOP3.customer_id
AND SECOND_JOIN.row_number = 3