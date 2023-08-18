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
)
SELECT 
RENTALS_BY_FILM.film_id,
RENTALS_BY_FILM.title,
RENTALS_BY_FILM.total_times_rented,
CASE 
WHEN RENTALS_BY_FILM.total_times_rented <= (
SELECT 
AVG(RENTALS_BY_FILM.total_times_rented) 
FROM RENTALS_BY_FILM
) THEN 'False'
WHEN RENTALS_BY_FILM.total_times_rented > (
SELECT 
AVG(RENTALS_BY_FILM.total_times_rented) 
FROM RENTALS_BY_FILM
) THEN 'True'
END AS greater_than_average
FROM RENTALS_BY_FILM

-- Using Query sent on slack, please update self joins to the CTE to come up with 3 addition columns (first, second, third).
-- (in progress)

WITH FILM_CATEGORY AS
(
	SELECT 
			se_rental.customer_id,
			se_category.name,
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
SELF_JOIN_1 AS 
(
	SELECT 
	FC1.customer_id as customer_id,
	FC1.name as name1,
	FC2.name as name2
	FROM FILM_CATEGORY as FC1
	INNER JOIN FILM_CATEGORY as FC2
	ON FC1.customer_id = FC2.customer_id
	),
TOP_1 AS
(
	SELECT 
		customer_id,
		name1,
		name2,
		CASE WHEN name1 = name2 THEN name1
		END AS top_1
	FROM SELF_JOIN_1
	)
SELECT
customer_id,
name1,
name2
FROM TOP_1

-- still in progress (please don't laugh)
