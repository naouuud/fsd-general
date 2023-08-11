*Retrieve the title, release year, and length of all movies in the database.*

SELECT
	title, release_year, length
FROM film

*List the titles and descriptions of movies released after the year 2000.*

SELECT
	title, description
FROM 
	film
WHERE release_year > 2000

*Display the first 10 movie titles in alphabetical order.*

SELECT
	title
FROM 	
	film
ORDER BY 
	title
LIMIT 10

*Show the titles of movies where the title contains the word "Action".*

SELECT
	title
FROM 
	film 
WHERE 
title LIKE 'Action'
OR 
title LIKE '% Action %'
OR 
title LIKE 'Action %'
OR 
title LIKE '% Action'

*List the titles of movies that contain the word "Love" in any case (case-insensitive)*

SELECT
	title
FROM 
	film 
WHERE 
LOWER(title) LIKE 'love'
OR 
LOWER(title) LIKE '% love %'
OR 
LOWER(title) LIKE 'love %'
OR 
LOWER(title) LIKE '% love'

*Display the title of movies in uppercase and their description in lowercase.*

SELECT
 	UPPER(title) AS uppercase_title, 
	LOWER(description) AS lowercase_description
FROM 
	film 

*Retrieve the first name and last name of customers whose last name starts with "A" and their first name contains "e" or "E"*

SELECT
 	first_name,
	last_name
FROM
	customer
WHERE 
SUBSTRING(last_name, 1, 1) = 'A'
AND
LOWER(first_name) LIKE '%e%'

*List the titles of movies with a rental rate greater than $4.00, ordered by rental rate in descending order.*

SELECT 
	title
FROM 
	film
WHERE rental_rate > 4.0
ORDER BY rental_rate DESC

*Display the titles of the 5 longest movies.*

SELECT 
	title
FROM 
	film
ORDER BY length DESC
LIMIT 5

*Find the titles of movies that have "dog" anywhere in their title and were released before the year 2005.*

SELECT 
	title
FROM 
	film 
WHERE LOWER(title) LIKE '%dog%' AND release_year < 2005

*List the first name and last name of customers whose last name starts with "M" and their first name has an "a" or "A" in the second position.*

SELECT
	first_name,
	last_name
FROM 
	customer
WHERE last_name LIKE 'M%' 
AND 
LOWER(SUBSTRING(first_name,2,1)) = 'a'

*Retrieve the titles of movies that contain the word "fantasy" and sort them in alphabetical order.*

SELECT
 	title
FROM
	film
WHERE LOWER(title) LIKE '%fantasy%'
ORDER BY title
