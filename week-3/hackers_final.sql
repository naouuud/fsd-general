CREATE SCHEMA reporting_schema;

CREATE TABLE IF NOT EXISTS reporting_schema.hackers_agg_daily
(
	day_id SERIAL PRIMARY KEY,
	daily_date DATE,
	daily_rentals INTEGER,
	customers_served INTEGER,
	avg_rentals_per_customer NUMERIC,
	running_rentals INTEGER,
	daily_payment_revenue NUMERIC,
	prev_day_payment_revenue NUMERIC,
	percentage_change NUMERIC,
	running_payment_revenue NUMERIC,
	paying_customers INTEGER,
	avg_payment_per_customer NUMERIC,
    number_of_payments INTEGER, 
    payments_by_india_customers INTEGER,
	perc_payments_india NUMERIC
);

WITH ALL_DATES_CTE AS
(
    SELECT
        CAST(myrental.rental_date AS DATE) AS rental_date,
		CAST(mypayment.payment_date AS DATE) AS payment_date
    FROM public.rental AS myrental
    FULL OUTER JOIN public.payment AS mypayment
        ON mypayment.payment_date = myrental.rental_date
), 
MERGED_DATES_CTE AS
(
SELECT 
	CASE 
		WHEN rental_date IS NOT NULL
		THEN rental_date
		ELSE payment_date
	END AS daily_date
FROM ALL_DATES_CTE
),
UNIQUE_DATES_CTE AS
(
SELECT 
	DISTINCT daily_date
FROM MERGED_DATES_CTE
ORDER BY
	daily_date
),
AGG_RENTALS_CUSTOMERS AS
(
	SELECT
		UNIQUE_DATES_CTE.daily_date AS daily_date,
		COALESCE(COUNT(myrental.rental_id), 0) AS daily_rentals,
		SUM(COALESCE(COUNT(myrental.rental_id), 0)) OVER (ORDER BY UNIQUE_DATES_CTE.daily_date) AS running_rentals,
		COALESCE(COUNT(DISTINCT(myrental.customer_id)), 0) AS customers_served
	FROM UNIQUE_DATES_CTE
	LEFT OUTER JOIN public.rental AS myrental
	    ON UNIQUE_DATES_CTE.daily_date = CAST(myrental.rental_date AS DATE)
	GROUP BY 
        UNIQUE_DATES_CTE.daily_date
	ORDER BY 
        UNIQUE_DATES_CTE.daily_date
	),
AVG_RENTALS AS
(
	SELECT 
		daily_date,
		ROUND(COALESCE(CAST(daily_rentals AS NUMERIC) / NULLIF(customers_served, 0), 0), 1) AS avg_rentals_per_customer
	FROM 
	AGG_RENTALS_CUSTOMERS
),
AGG_PAYMENTS AS
(
	SELECT
		UNIQUE_DATES_CTE.daily_date AS daily_date,
		COALESCE(SUM(mypayment.amount), 0) AS daily_payment_revenue,
		SUM(COALESCE(SUM(mypayment.amount), 0)) OVER (ORDER BY UNIQUE_DATES_CTE.daily_date) as running_payment_revenue,
		COUNT(DISTINCT mypayment.customer_id) as paying_customers,
		ROUND(COALESCE(COALESCE(SUM(mypayment.amount), 0) / NULLIF(COUNT(mypayment.customer_id), 0),0), 2) as avg_payment_per_customer
	FROM UNIQUE_DATES_CTE
	LEFT OUTER JOIN public.payment AS mypayment
	    ON UNIQUE_DATES_CTE.daily_date = CAST(mypayment.payment_date AS DATE)
	GROUP BY 
        UNIQUE_DATES_CTE.daily_date
	ORDER BY 
        UNIQUE_DATES_CTE.daily_date
),
PAYMENTS_BY_COUNTRY AS (
SELECT
	UNIQUE_DATES_CTE.daily_date AS daily_date,
	COUNT(mypayment.payment_id) AS number_of_payments,
	COUNT(
		CASE 
			WHEN mycountry.country = 'India'
			THEN mypayment.payment_id
		END
	) AS payments_by_india_customers, 
	COUNT(
		CASE 
			WHEN mycountry.country NOT IN ('India')
			THEN mypayment.payment_id
		END
	) AS payments_by_non_india_customers,
	COALESCE(ROUND(CAST(COUNT(
		CASE
			WHEN mycountry.country = 'India'
			THEN mypayment.payment_id
	END) AS NUMERIC) / NULLIF(CAST(COUNT(mypayment.payment_id) AS NUMERIC), 0) * 100, 1), 0) as perc_payments_india,
	COALESCE(ROUND(CAST(COUNT(
		CASE
			WHEN mycountry.country NOT IN ('India')
			THEN mypayment.payment_id
	END) AS NUMERIC) / NULLIF(CAST(COUNT(mypayment.payment_id) AS NUMERIC), 0) * 100, 1), 0) as perc_payments_non_india
FROM UNIQUE_DATES_CTE 
LEFT OUTER JOIN public.payment AS mypayment
	ON UNIQUE_DATES_CTE.daily_date = CAST(mypayment.payment_date AS DATE)
LEFT OUTER JOIN public.customer AS mycustomer
    ON mypayment.customer_id = mycustomer.customer_id
LEFT OUTER JOIN public.address AS myaddress
    ON mycustomer.address_id = myaddress.address_id
LEFT OUTER JOIN public.city AS mycity
    ON myaddress.city_id = mycity.city_id
LEFT OUTER JOIN public.country AS mycountry
    ON mycountry.country_id = mycity.country_id
GROUP BY 
    UNIQUE_DATES_CTE.daily_date
),
PERCENT_CHANGE_CTE AS
(
    SELECT
        daily_date,
        daily_payment_revenue,
        COALESCE(LAG(daily_payment_revenue) OVER (ORDER BY daily_date), 0) AS prev_day_payment_revenue,
        CASE
            WHEN LAG(daily_payment_revenue) OVER (ORDER BY daily_date) IS NOT NULL
            THEN ROUND(
            COALESCE(
                (daily_payment_revenue - LAG(daily_payment_revenue) OVER (ORDER BY daily_date)) / NULLIF(LAG(daily_payment_revenue) OVER (ORDER BY daily_date), 0) * 100, 0), 1)
        END AS percentage_change
    	FROM AGG_PAYMENTS
),
DAILY_RESULTS_CTE AS (
	SELECT
		AGG_RENTALS_CUSTOMERS.daily_date,
		AGG_RENTALS_CUSTOMERS.daily_rentals,
        AGG_RENTALS_CUSTOMERS.customers_served,
		AVG_RENTALS.avg_rentals_per_customer,
		AGG_RENTALS_CUSTOMERS.running_rentals,
		AGG_PAYMENTS.daily_payment_revenue,
		PERCENT_CHANGE_CTE.prev_day_payment_revenue,
		COALESCE(PERCENT_CHANGE_CTE.percentage_change, 0) AS percentage_change,
		AGG_PAYMENTS.running_payment_revenue,
		AGG_PAYMENTS.paying_customers,
		AGG_PAYMENTS.avg_payment_per_customer,
		PAYMENTS_BY_COUNTRY.number_of_payments,
		PAYMENTS_BY_COUNTRY.payments_by_india_customers,
		PAYMENTS_BY_COUNTRY.perc_payments_india
	FROM AGG_RENTALS_CUSTOMERS 
	INNER JOIN AVG_RENTALS
		ON AGG_RENTALS_CUSTOMERS.daily_date = AVG_RENTALS.daily_date
	INNER JOIN AGG_PAYMENTS 
	    ON AGG_RENTALS_CUSTOMERS.daily_date = AGG_PAYMENTS.daily_date
	INNER JOIN PAYMENTS_BY_COUNTRY
		ON AGG_RENTALS_CUSTOMERS.daily_date = PAYMENTS_BY_COUNTRY.daily_date
	INNER JOIN PERCENT_CHANGE_CTE
       ON AGG_RENTALS_CUSTOMERS.daily_date = PERCENT_CHANGE_CTE.daily_date
	ORDER BY
		AGG_RENTALS_CUSTOMERS.daily_date
)

INSERT INTO reporting_schema.hackers_agg_daily 
(
    daily_date,
	daily_rentals,
	customers_served,
	avg_rentals_per_customer,
	running_rentals,
	daily_payment_revenue,
	prev_day_payment_revenue,
	percentage_change,
	running_payment_revenue,
	paying_customers,
	avg_payment_per_customer,
    number_of_payments, 
    payments_by_india_customers,
	perc_payments_india)
    
    SELECT 
        *
    FROM DAILY_RESULTS_CTE;

CREATE TABLE IF NOT EXISTS reporting_schema.hackers_agg_monthly
(
	month_id SERIAL PRIMARY KEY,
	month TEXT,
	monthly_rentals INTEGER,
	customers_served INTEGER,
	avg_rentals_per_customer NUMERIC,
	running_rentals INTEGER,
	monthly_payment_revenue NUMERIC,
	prev_month_payment_revenue NUMERIC,
	percentage_change NUMERIC,
	running_payment_revenue NUMERIC,
	paying_customers INTEGER,
	avg_payment_per_customer NUMERIC,
    number_of_payments INTEGER, 
    payments_by_india_customers INTEGER,
	perc_payments_india NUMERIC
);

WITH MONTHLY_CTE AS (
SELECT 
	CONCAT(EXTRACT(YEAR FROM daily_date), '-0', EXTRACT(MONTH FROM daily_date)) as month,
	SUM(daily_rentals) as monthly_rentals,
	SUM(customers_served) as customers_served,
-- 	avg_rentals_per_customer
-- 	running rentals
	SUM(daily_payment_revenue) as monthly_payment_revenue,
-- 	prev_day_payment_revenue
--	percentage_change
-- 	running_payment_revenue,
	SUM(paying_customers) as paying_customers,
-- 	avg_payment_per_customer
	SUM(number_of_payments) as number_of_payments,
	SUM(payments_by_india_customers) as payments_by_india_customers
-- 	perc_payments_india
FROM reporting_schema.hackers_agg_daily
GROUP BY
	EXTRACT(YEAR FROM daily_date),
	EXTRACT(MONTH FROM daily_date)
ORDER BY
	EXTRACT(YEAR FROM daily_date),
	EXTRACT(MONTH FROM daily_date)
), 
MONTHLY_AGG_CTE AS (
SELECT
	month,
	monthly_rentals,
	customers_served,
	ROUND(COALESCE(monthly_rentals / NULLIF(CAST(customers_served AS NUMERIC), 0), 0), 1) as avg_rentals_per_customer,
	SUM(monthly_rentals) OVER (ORDER BY month) AS running_rentals,
	monthly_payment_revenue,
    COALESCE(LAG(monthly_payment_revenue) OVER (ORDER BY month), 0) AS prev_month_payment_revenue,
    CASE
        WHEN LAG(monthly_payment_revenue) OVER (ORDER BY month) IS NOT NULL
        THEN ROUND(
        COALESCE(
            (monthly_payment_revenue - LAG(monthly_payment_revenue) OVER (ORDER BY month)) / NULLIF(LAG(monthly_payment_revenue) OVER (ORDER BY month), 0) * 100, 0), 1)
    END AS percentage_change,
	SUM(monthly_payment_revenue) OVER (ORDER BY month) AS running_payment_revenue,
	paying_customers,
	ROUND(COALESCE(monthly_payment_revenue / NULLIF(paying_customers, 0), 0), 2) as avg_payment_per_customer,
	number_of_payments,
	payments_by_india_customers,
	ROUND(COALESCE(CAST(payments_by_india_customers AS NUMERIC) / NULLIF(CAST(number_of_payments AS NUMERIC), 0) * 100, 0), 1) as perc_payments_india
FROM MONTHLY_CTE
) 

INSERT INTO reporting_schema.hackers_agg_monthly
(
	month,
	monthly_rentals,
	customers_served,
	avg_rentals_per_customer,
	running_rentals,
	monthly_payment_revenue,
	prev_month_payment_revenue,
	percentage_change,
	running_payment_revenue,
	paying_customers,
	avg_payment_per_customer,
    number_of_payments, 
    payments_by_india_customers,
	perc_payments_india
) SELECT 
    month,
    monthly_rentals,
	customers_served,
	avg_rentals_per_customer,
	running_rentals,
	monthly_payment_revenue,
	prev_month_payment_revenue,
	COALESCE(percentage_change, 0) as percentage_change,
	running_payment_revenue,
	paying_customers,
	avg_payment_per_customer,
    number_of_payments, 
    payments_by_india_customers,
	perc_payments_india
 FROM MONTHLY_AGG_CTE;

CREATE TABLE IF NOT EXISTS reporting_schema.hackers_agg_yearly
(
	year_id SERIAL PRIMARY KEY,
	year NUMERIC,
	yearly_rentals INTEGER,
	customers_served INTEGER,
	avg_rentals_per_customer NUMERIC,
	running_rentals INTEGER,
	yearly_payment_revenue NUMERIC,
	prev_year_payment_revenue NUMERIC,
	percentage_change NUMERIC,
	running_payment_revenue NUMERIC,
	paying_customers INTEGER,
	avg_payment_per_customer NUMERIC,
    number_of_payments INTEGER, 
    payments_by_india_customers INTEGER,
	perc_payments_india NUMERIC
);

WITH YEARLY_CTE AS
(
SELECT 
	EXTRACT(YEAR FROM daily_date) as year,
	SUM(daily_rentals) as yearly_rentals,
	SUM(customers_served) as customers_served,
-- 	avg_rentals_per_customer
-- 	running rentals
	SUM(daily_payment_revenue) as yearly_payment_revenue,
-- 	prev_day_payment_revenue
--	percentage_change
-- 	running_payment_revenue,
	SUM(paying_customers) as paying_customers,
-- 	avg_payment_per_customer
	SUM(number_of_payments) as number_of_payments,
	SUM(payments_by_india_customers) as payments_by_india_customers
-- 	perc_payments_india
FROM reporting_schema.hackers_agg_daily
GROUP BY
	EXTRACT(YEAR FROM daily_date)
ORDER BY
	EXTRACT(YEAR FROM daily_date)
),
YEARLY_AGG_CTE AS (
SELECT
	year,
	yearly_rentals,
	customers_served,
	ROUND(COALESCE(yearly_rentals / NULLIF(CAST(customers_served AS NUMERIC), 0), 0), 1) as avg_rentals_per_customer,
	SUM(yearly_rentals) OVER (ORDER BY year) AS running_rentals,
	yearly_payment_revenue,
	COALESCE(LAG(yearly_payment_revenue) OVER (ORDER BY year), 0) AS prev_year_payment_revenue,
	CASE
        WHEN LAG(yearly_payment_revenue) OVER (ORDER BY year) IS NOT NULL
        THEN ROUND(
        COALESCE(
            (yearly_payment_revenue - LAG(yearly_payment_revenue) OVER (ORDER BY year)) / NULLIF(LAG(yearly_payment_revenue) OVER (ORDER BY year), 0) * 100, 0), 1)
    END AS percentage_change,
	SUM(yearly_payment_revenue) OVER (ORDER BY year) AS running_payment_revenue,
	paying_customers,
	ROUND(COALESCE(yearly_payment_revenue / NULLIF(paying_customers, 0), 0), 2) as avg_payment_per_customer,
	number_of_payments,
	payments_by_india_customers,
	ROUND(COALESCE(CAST(payments_by_india_customers AS NUMERIC) / NULLIF(CAST(number_of_payments AS NUMERIC), 0) * 100, 0), 1) as perc_payments_india
FROM YEARLY_CTE
)

INSERT INTO reporting_schema.hackers_agg_yearly
(
	year,
	yearly_rentals,
	customers_served,
	avg_rentals_per_customer,
	running_rentals,
	yearly_payment_revenue,
	prev_year_payment_revenue,
	percentage_change,
	running_payment_revenue,
	paying_customers,
	avg_payment_per_customer,
    number_of_payments, 
    payments_by_india_customers,
	perc_payments_india
) SELECT 
    year,
    yearly_rentals,
	customers_served,
	avg_rentals_per_customer,
	running_rentals,
	yearly_payment_revenue,
	prev_year_payment_revenue,
	COALESCE(percentage_change, 0) as percentage_change,
	running_payment_revenue,
	paying_customers,
	avg_payment_per_customer,
    number_of_payments, 
    payments_by_india_customers,
	perc_payments_india
 FROM YEARLY_AGG_CTE;