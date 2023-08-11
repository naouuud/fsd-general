<em>Retrieve the title, release year, and length of all movies in the database.</em>

SELECT<br>
	title, release_year, length<br>
FROM film<br>

*List the titles and descriptions of movies released after the year 2000.*

SELECT<br>
    title, description<br>
FROM<br>
    film<br>
WHERE release_year > 2000<br>		

*Display the first 10 movie titles in alphabetical order.*

SELECT<br>
    title<br>
FROM<br> 	
    film<br>
ORDER BY<br> 
    title<br>
LIMIT 10<br>

*Show the titles of movies where the title contains the word "Action".*

SELECT<br>
	title<br>
FROM<br> 
	film<br> 
WHERE<br> 
title LIKE 'Action'<br>
OR<br> 
title LIKE '% Action %'<br>
OR<br> 
title LIKE 'Action %'<br>
OR<br> 
title LIKE '% Action'<br>

*List the titles of movies that contain the word "Love" in any case (case-insensitive)*

SELECT<br>
	title<br>
FROM<br> 
	film<br> 
WHERE<br> 
LOWER(title) LIKE 'love'<br>
OR<br> 
LOWER(title) LIKE '% love %'<br>
OR<br> 
LOWER(title) LIKE 'love %'<br>
OR<br> 
LOWER(title) LIKE '% love'<br>

*Display the title of movies in uppercase and their description in lowercase.*

SELECT<br>
 	UPPER(title) AS uppercase_title,<br> 
	LOWER(description) AS lowercase_description<br>
FROM<br> 
	film<br> 

*Retrieve the first name and last name of customers whose last name starts with "A" and their first name contains "e" or "E"*

SELECT<br>
 	first_name,<br>
	last_name<br>
FROM<br>
	customer<br>
WHERE<br>
SUBSTRING(last_name, 1, 1) = 'A'<br>
AND<br>
LOWER(first_name) LIKE '%e%'<br>

*List the titles of movies with a rental rate greater than $4.00, ordered by rental rate in descending order.*

SELECT<br> 
	title<br>
FROM<br> 
	film<br>
WHERE rental_rate > 4.0<br>
ORDER BY rental_rate DESC<br>

*Display the titles of the 5 longest movies.*

SELECT<br> 
	title<br>
FROM<br> 
	film<br>
ORDER BY length DESC<br>
LIMIT 5<br>

*Find the titles of movies that have "dog" anywhere in their title and were released before the year 2005.*

SELECT<br> 
	title<br>
FROM<br> 
	film<br>
WHERE LOWER(title) LIKE '%dog%' AND release_year < 2005<br>

*List the first name and last name of customers whose last name starts with "M" and their first name has an "a" or "A" in the second position.*

SELECT<br>
	first_name,<br>
	last_name<br>
FROM<br> 
	customer<br>
WHERE last_name LIKE 'M%'<br> 
AND<br>
LOWER(SUBSTRING(first_name,2,1)) = 'a'<br>

*Retrieve the titles of movies that contain the word "fantasy" and sort them in alphabetical order.*

SELECT<br>
 	title<br>
FROM<br>
	film<br>
WHERE LOWER(title) LIKE '%fantasy%'<br>
ORDER BY title<br>
