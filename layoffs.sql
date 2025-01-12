/* Dataset:
https://github.com/AlexTheAnalyst/MySQL-YouTube-Series/blob/main/layoffs.csv
/*
Cleaning Data in SQL Queries
*/

-- Creamos una tabla de prueba para no trabajar sobre la base de datos original.
-- Eliminamos los duplicados. Al no contar con ID, utilizamos la funcion ROW_NUMBER y 
-- creamos una tabla alternativa para poder eliminar los duplicados.

use world_layoffs;
CREATE TABLE layoffs_staging like layoffs;

INSERT layoffs_staging
SELECT * FROM layoffs;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) as row_num
FROM layoffs_staging
)

SELECT *
FROM duplicate_cte
WHERE row_num > 1;


CREATE TABLE `layoffs_staging_2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


INSERT INTO layoffs_staging_2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) as row_num
FROM layoffs_staging;

DELETE FROM layoffs_staging_2
WHERE row_num > 1;

-- Estandarizacion de datos

SELECT company, TRIM(company)
FROM layoffs_staging_2;

UPDATE layoffs_staging_2
SET company = TRIM(company);

SELECT distinct industry
FROM layoffs_staging_2
ORDER BY 1;

UPDATE layoffs_staging_2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging_2
SET country = 'United States'
WHERE country LIKE 'United States%';

UPDATE layoffs_staging_2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging_2
MODIFY COLUMN `date` DATE;


-- Revisando valores NULL o blancos

UPDATE layoffs_staging_2
SET industry = NULL
WHERE industry = '';

SELECT distinct t1.company, t1.industry, t2.industry
FROM layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging_2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging_2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Eliminamos la columna que creamos en un principio para ver los duplicados

ALTER TABLE layoffs_staging_2
DROP column row_num;

-- Ya tenemos nuestros datos limpios para empezar a trabajar con ellos

DROP TABLE layoffs_staging;

ALTER TABLE layoffs_staging_2 RENAME TO layoffs_staging;