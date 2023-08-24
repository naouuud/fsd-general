CREATE SCHEMA reporting_schema;

CREATE TABLE IF NOT EXISTS reporting_schema.nouraoude_agg_daily
(
	day_id SERIAL PRIMARY KEY,
	year INTEGER,
 	month INTEGER,
	day INTEGER,
	total_rentals INTEGER,
	total_rental_revenue NUMERIC
-- 	total_customers_served INTEGER,
-- 	avg_payment_per_customer NUMERIC
);

WITH DAYS AS 
(
	SELECT *,
		EXTRACT(YEAR FROM rental_date) as year,
		EXTRACT(MONTH FROM rental_date) as month,
		EXTRACT(DAY FROM rental_date) as day
	FROM public.rental
	),
AGG_RENTALS AS
(
	SELECT
		DAYS.year as year,
		DAYS.month as month,
		DAYS.day as day,
		COALESCE(COUNT(DAYS.rental_id), 0) as total_rentals
	FROM DAYS
	GROUP BY DAYS.year, DAYS.month, DAYS.day
	ORDER BY DAYS.year, DAYS.month, DAYS.day
	),
AGG_PAYMENTS AS
(
	SELECT
		DAYS.year as year,
		DAYS.month as month,
		DAYS.day as day,
		COALESCE(SUM(daily_payment.amount), 0) as total_rental_revenue
	FROM DAYS
	LEFT OUTER JOIN public.payment as daily_payment
	ON DAYS.rental_id = daily_payment.rental_id
	GROUP BY DAYS.year, DAYS.month, DAYS.day
	ORDER BY DAYS.year, DAYS.month, DAYS.day
),
DAILY_RESULT_CTE AS (
	SELECT
		AGG_RENTALS.year,
		AGG_RENTALS.month,
		AGG_RENTALS.day,
		AGG_RENTALS.total_rentals,
		AGG_PAYMENTS.total_rental_revenue
	FROM AGG_RENTALS 
	INNER JOIN AGG_PAYMENTS 
	ON AGG_RENTALS.year = AGG_PAYMENTS.year
	AND AGG_RENTALS.month = AGG_PAYMENTS.month
	AND AGG_RENTALS.day = AGG_PAYMENTS.day
)

INSERT INTO reporting_schema.nouraoude_agg_daily (year, month, day, total_rentals, total_rental_revenue)
SELECT 
	*
FROM DAILY_RESULT_CTE;

WITH MONTHLY_RESULT_CTE AS
(
SELECT 
year,
month,
COALESCE(SUM(total_rentals), 0) as total_rentals, 
COALESCE(SUM(total_rental_revenue), 0) as total_rental_revenue
FROM reporting_schema.nouraoude_agg_daily
GROUP BY year, month
ORDER BY year, month
	)
SELECT * FROM MONTHLY_RESULT_CTE
