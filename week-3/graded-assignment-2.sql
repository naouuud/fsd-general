-- CREATE SCHEMA reporting_schema;

-- CREATE TABLE IF NOT EXISTS reporting_schema.nouraoude_agg_monthly
-- (
-- 	month_id SERIAL PRIMARY KEY,
-- 	month INTEGER,
--  year INTEGER,
-- 	total_rentals INTEGER,
-- 	total_films_rented INTEGER,
-- 	total_customers_served INTEGER,
-- 	total_payments INTEGER,
-- 	avg_payment_per_customer INTEGER
-- );

WITH MONTHLY AS 
(
	SELECT *,
	EXTRACT(YEAR FROM rental_date) as year,
	EXTRACT(MONTH FROM rental_date) as month
	FROM rental
	),
AGG_RENTALS AS
(
	SELECT
	MONTHLY.year,
	MONTHLY.month,
	COUNT(myrental.rental_id) as total_rentals
	FROM MONTHLY
	INNER JOIN rental as myrental --no need to join to rentals but useful for later
	ON MONTHLY.rental_id = myrental.rental_id
	GROUP BY MONTHLY.year, MONTHLY.month
	ORDER BY MONTHLY.year, MONTHLY.month
	)
SELECT * FROM AGG_RENTALS