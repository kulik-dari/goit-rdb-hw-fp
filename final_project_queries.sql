-- ========================================
-- ФІНАЛЬНИЙ ПРОЄКТ: Аналіз пандемічних захворювань
-- goit-rdb-fp
-- Автор: Kulik Daria
-- ========================================

-- ========================================
-- ЗАВДАННЯ 1: Створення схеми та імпорт даних
-- ========================================

-- Крок 1: Створити схему pandemic
DROP SCHEMA IF EXISTS pandemic;
CREATE SCHEMA pandemic;

-- Крок 2: Обрати схему за замовчуванням
USE pandemic;

-- Крок 3: Імпортувати дані через Import Wizard
-- Після імпорту перевірити дані:
SELECT * FROM infectious_cases LIMIT 10;

-- Подивитися структуру таблиці
DESCRIBE infectious_cases;

-- Перевірити кількість записів
SELECT COUNT(*) FROM infectious_cases;

-- Перевірити унікальні Entity та Code
SELECT DISTINCT Entity, Code FROM infectious_cases LIMIT 20;


-- ========================================
-- ЗАВДАННЯ 2: Нормалізація до 3НФ
-- ========================================

-- Аналіз даних: Entity та Code повторюються
-- Створюємо окрему таблицю для країн/регіонів (сутностей)

-- Таблиця 1: entities (довідник країн/регіонів)
CREATE TABLE entities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity VARCHAR(255) NOT NULL,
    code VARCHAR(10) NOT NULL,
    UNIQUE KEY unique_entity_code (entity, code)
);

-- Заповнюємо таблицю entities унікальними значеннями
INSERT INTO entities (entity, code)
SELECT DISTINCT Entity, Code
FROM infectious_cases
WHERE Entity IS NOT NULL AND Code IS NOT NULL;

-- Перевірка
SELECT COUNT(*) FROM entities;
SELECT * FROM entities LIMIT 10;


-- Таблиця 2: cases (нормалізовані дані захворювань)
CREATE TABLE cases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity_id INT NOT NULL,
    year INT NOT NULL,
    number_yaws VARCHAR(255),
    polio_cases INT,
    cases_guinea_worm INT,
    number_rabies VARCHAR(255),
    number_malaria VARCHAR(255),
    number_hiv VARCHAR(255),
    number_tuberculosis VARCHAR(255),
    number_smallpox VARCHAR(255),
    number_cholera_cases VARCHAR(255),
    FOREIGN KEY (entity_id) REFERENCES entities(id),
    INDEX idx_entity_year (entity_id, year)
);

-- Заповнюємо таблицю cases даними з infectious_cases
INSERT INTO cases (
    entity_id,
    year,
    number_yaws,
    polio_cases,
    cases_guinea_worm,
    number_rabies,
    number_malaria,
    number_hiv,
    number_tuberculosis,
    number_smallpox,
    number_cholera_cases
)
SELECT 
    e.id,
    ic.Year,
    ic.Number_yaws,
    ic.polio_cases,
    ic.cases_guinea_worm,
    ic.Number_rabies,
    ic.Number_malaria,
    ic.Number_hiv,
    ic.Number_tuberculosis,
    ic.Number_smallpox,
    ic.Number_cholera_cases
FROM infectious_cases ic
INNER JOIN entities e ON ic.Entity = e.entity AND ic.Code = e.code;

-- Перевірка кількості записів
SELECT COUNT(*) FROM cases;
SELECT COUNT(*) FROM infectious_cases;

-- Перевірка нормалізації
SELECT 
    e.entity,
    e.code,
    c.year,
    c.number_rabies,
    c.number_malaria
FROM cases c
INNER JOIN entities e ON c.entity_id = e.id
LIMIT 10;


-- ========================================
-- ЗАВДАННЯ 3: Аналіз даних (Number_rabies)
-- ========================================

-- Порахувати середнє, мінімальне, максимальне значення та суму для Number_rabies
-- Для кожної унікальної комбінації Entity та Code (або їх id)
-- Відфільтрувати порожні значення ('')
-- Відсортувати за середнім значенням у порядку спадання
-- Вивести тільки 10 рядків

SELECT 
    e.entity,
    e.code,
    COUNT(*) AS record_count,
    AVG(CAST(c.number_rabies AS DECIMAL(10,2))) AS avg_rabies,
    MIN(CAST(c.number_rabies AS DECIMAL(10,2))) AS min_rabies,
    MAX(CAST(c.number_rabies AS DECIMAL(10,2))) AS max_rabies,
    SUM(CAST(c.number_rabies AS DECIMAL(10,2))) AS sum_rabies
FROM cases c
INNER JOIN entities e ON c.entity_id = e.id
WHERE c.number_rabies IS NOT NULL 
  AND c.number_rabies != ''
  AND c.number_rabies REGEXP '^[0-9.]+$'  -- Тільки числові значення
GROUP BY e.entity, e.code, e.id
ORDER BY avg_rabies DESC
LIMIT 10;

-- Альтернативний варіант з використанням тільки id
SELECT 
    c.entity_id,
    e.entity,
    e.code,
    COUNT(*) AS record_count,
    AVG(CAST(c.number_rabies AS DECIMAL(10,2))) AS avg_rabies,
    MIN(CAST(c.number_rabies AS DECIMAL(10,2))) AS min_rabies,
    MAX(CAST(c.number_rabies AS DECIMAL(10,2))) AS max_rabies,
    SUM(CAST(c.number_rabies AS DECIMAL(10,2))) AS sum_rabies
FROM cases c
INNER JOIN entities e ON c.entity_id = e.id
WHERE c.number_rabies IS NOT NULL 
  AND c.number_rabies != ''
GROUP BY c.entity_id, e.entity, e.code
ORDER BY avg_rabies DESC
LIMIT 10;


-- ========================================
-- ЗАВДАННЯ 4: Побудова колонки різниці в роках
-- ========================================

-- Побудувати 3 нові атрибути:
-- 1) Дата першого січня відповідного року (Year → '1996-01-01')
-- 2) Поточна дата
-- 3) Різниця в роках між поточною датою та датою з року

SELECT 
    id,
    year,
    MAKEDATE(year, 1) AS year_start_date,           -- '1996-01-01'
    CURDATE() AS current_date,                       -- Поточна дата
    YEAR(CURDATE()) - year AS years_difference      -- Різниця в роках
FROM cases
LIMIT 20;

-- Альтернативний варіант з використанням CONCAT
SELECT 
    id,
    year,
    CONCAT(year, '-01-01') AS year_start_date,
    CURDATE() AS current_date,
    TIMESTAMPDIFF(YEAR, CONCAT(year, '-01-01'), CURDATE()) AS years_difference
FROM cases
LIMIT 20;

-- З JOIN для повного контексту
SELECT 
    e.entity,
    e.code,
    c.year,
    MAKEDATE(c.year, 1) AS year_start_date,
    CURDATE() AS current_date,
    YEAR(CURDATE()) - c.year AS years_difference
FROM cases c
INNER JOIN entities e ON c.entity_id = e.id
LIMIT 20;


-- ========================================
-- ЗАВДАННЯ 5: Створення власної функції
-- ========================================

-- Функція для розрахунку різниці в роках
DROP FUNCTION IF EXISTS calculate_years_difference;

DELIMITER //

CREATE FUNCTION calculate_years_difference(input_year INT)
RETURNS INT
DETERMINISTIC
NO SQL
BEGIN
    DECLARE year_date DATE;
    DECLARE years_diff INT;
    
    -- Створюємо дату з року
    SET year_date = MAKEDATE(input_year, 1);
    
    -- Рахуємо різницю в роках
    SET years_diff = YEAR(CURDATE()) - input_year;
    
    RETURN years_diff;
END //

DELIMITER ;

-- Використання функції
SELECT 
    id,
    year,
    calculate_years_difference(year) AS years_from_now
FROM cases
LIMIT 20;

-- З JOIN для повного контексту
SELECT 
    e.entity,
    e.code,
    c.year,
    calculate_years_difference(c.year) AS years_from_now,
    c.number_rabies,
    c.number_malaria
FROM cases c
INNER JOIN entities e ON c.entity_id = e.id
LIMIT 20;


-- ========================================
-- ДОДАТКОВО: Альтернативна функція для розрахунку захворювань за період
-- ========================================

-- Функція для розрахунку середньої кількості захворювань за період
DROP FUNCTION IF EXISTS calculate_disease_per_period;

DELIMITER //

CREATE FUNCTION calculate_disease_per_period(
    yearly_cases DECIMAL(10,2),
    period_divisor INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
NO SQL
BEGIN
    DECLARE result DECIMAL(10,2);
    
    -- Перевірка на нульовий дільник
    IF period_divisor = 0 THEN
        RETURN NULL;
    END IF;
    
    -- Розрахунок
    SET result = yearly_cases / period_divisor;
    
    RETURN result;
END //

DELIMITER ;

-- Використання функції для розрахунку захворювань
-- period_divisor: 12 = місяць, 4 = квартал, 2 = півріччя

-- Приклад: середня кількість випадків сказу на місяць
SELECT 
    e.entity,
    e.code,
    c.year,
    c.number_rabies AS yearly_rabies,
    calculate_disease_per_period(
        CAST(c.number_rabies AS DECIMAL(10,2)), 
        12
    ) AS monthly_avg_rabies,
    calculate_disease_per_period(
        CAST(c.number_rabies AS DECIMAL(10,2)), 
        4
    ) AS quarterly_avg_rabies
FROM cases c
INNER JOIN entities e ON c.entity_id = e.id
WHERE c.number_rabies IS NOT NULL 
  AND c.number_rabies != ''
  AND c.number_rabies REGEXP '^[0-9.]+$'
LIMIT 20;

-- Приклад: середня кількість випадків малярії на місяць
SELECT 
    e.entity,
    e.code,
    c.year,
    c.number_malaria AS yearly_malaria,
    calculate_disease_per_period(
        CAST(c.number_malaria AS DECIMAL(10,2)), 
        12
    ) AS monthly_avg_malaria
FROM cases c
INNER JOIN entities e ON c.entity_id = e.id
WHERE c.number_malaria IS NOT NULL 
  AND c.number_malaria != ''
LIMIT 20;


-- ========================================
-- ДОДАТКОВІ ЗАПИТИ для аналізу
-- ========================================

-- Перевірка нормалізації: порівняння кількості записів
SELECT 
    'Original table' AS table_name,
    COUNT(*) AS record_count
FROM infectious_cases
UNION ALL
SELECT 
    'Normalized entities' AS table_name,
    COUNT(*) AS record_count
FROM entities
UNION ALL
SELECT 
    'Normalized cases' AS table_name,
    COUNT(*) AS record_count
FROM cases;

-- Топ-10 країн за сумою випадків сказу
SELECT 
    e.entity,
    e.code,
    SUM(CAST(c.number_rabies AS DECIMAL(10,2))) AS total_rabies
FROM cases c
INNER JOIN entities e ON c.entity_id = e.id
WHERE c.number_rabies IS NOT NULL AND c.number_rabies != ''
GROUP BY e.entity, e.code
ORDER BY total_rabies DESC
LIMIT 10;

-- Динаміка захворювань по роках (приклад для сказу)
SELECT 
    c.year,
    COUNT(*) AS countries_reported,
    AVG(CAST(c.number_rabies AS DECIMAL(10,2))) AS avg_rabies,
    SUM(CAST(c.number_rabies AS DECIMAL(10,2))) AS total_rabies
FROM cases c
WHERE c.number_rabies IS NOT NULL AND c.number_rabies != ''
GROUP BY c.year
ORDER BY c.year;
