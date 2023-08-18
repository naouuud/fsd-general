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

