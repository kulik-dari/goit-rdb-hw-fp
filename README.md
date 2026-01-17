# Фінальний Проєкт: Аналіз пандемічних захворювань


---

## 📋 Зміст

1. [Завдання 1: Створення схеми та імпорт](#завдання-1)
2. [Завдання 2: Нормалізація до 3НФ](#завдання-2)
3. [Завдання 3: Аналіз даних Number_rabies](#завдання-3)
4. [Завдання 4: Колонка різниці в роках](#завдання-4)
5. [Завдання 5: Власна функція](#завдання-5)

---

## Завдання 1: Створення схеми та імпорт даних (10 балів)

### Опис
Створити схему `pandemic`, імпортувати дані з CSV файлу `infectious_cases.csv`.

### SQL:
```sql
-- Створити схему
CREATE SCHEMA pandemic;

-- Обрати як схему за замовчуванням
USE pandemic;

-- Імпорт через Import Wizard
-- Table Data Import Wizard → infectious_cases.csv

-- Перевірка
SELECT COUNT(*) FROM infectious_cases;
```

### Кроки імпорту:
1. MySQL Workbench → Server → Data Import
2. Import from Self-Contained File → infectious_cases.csv
3. Default Target Schema: pandemic
4. Start Import

### Результат:
Таблиця `infectious_cases` з усіма даними

**Скриншоти:** 
- `p1_create_schema.png`
- `p1_import_data.png`
- `p1_count_records.png`

---

## Завдання 2: Нормалізація до 3НФ (30 балів)

### Проблема
Атрибути `Entity` та `Code` постійно повторюються → порушення нормалізації.

### Рішення
Створити дві таблиці:

#### Таблиця 1: `entities` (довідник країн/регіонів)
```sql
CREATE TABLE entities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity VARCHAR(255) NOT NULL,
    code VARCHAR(10) NOT NULL,
    UNIQUE KEY unique_entity_code (entity, code)
);

INSERT INTO entities (entity, code)
SELECT DISTINCT Entity, Code
FROM infectious_cases
WHERE Entity IS NOT NULL AND Code IS NOT NULL;
```

#### Таблиця 2: `cases` (нормалізовані дані)
```sql
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

INSERT INTO cases (entity_id, year, number_rabies, ...)
SELECT e.id, ic.Year, ic.Number_rabies, ...
FROM infectious_cases ic
INNER JOIN entities e ON ic.Entity = e.entity AND ic.Code = e.code;
```

### Перевірка:
```sql
SELECT COUNT(*) FROM infectious_cases;  -- Оригінальна таблиця
SELECT COUNT(*) FROM entities;          -- Довідник країн
SELECT COUNT(*) FROM cases;             -- Нормалізовані дані
```

### Нормальні форми:
- **1НФ:** Всі значення атомарні ✅
- **2НФ:** Немає часткових залежностей від ключа ✅
- **3НФ:** Немає транзитивних залежностей ✅

**Скриншоти:**
- `p2_create_entities.png`
- `p2_create_cases.png`
- `p2_verification.png`

---

## Завдання 3: Аналіз даних Number_rabies (20 балів)

### Опис
Для кожної унікальної комбінації Entity та Code порахувати:
- Середнє значення (AVG)
- Мінімальне значення (MIN)
- Максимальне значення (MAX)
- Суму (SUM)

для атрибута `Number_rabies`.

### SQL:
```sql
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
  AND c.number_rabies REGEXP '^[0-9.]+$'
GROUP BY e.entity, e.code, e.id
ORDER BY avg_rabies DESC
LIMIT 10;
```

### Вимоги:
- ✅ Відфільтрувати порожні значення (`''`)
- ✅ Відсортувати за середнім у порядку спадання
- ✅ Вивести тільки 10 рядків

**Скриншот:** `p3_rabies_analysis.png`

---

## Завдання 4: Колонка різниці в роках (20 балів)

### Опис
Побудувати 3 нові колонки:
1. Дата першого січня року (1996 → '1996-01-01')
2. Поточна дата
3. Різниця в роках

### SQL:
```sql
SELECT 
    id,
    year,
    MAKEDATE(year, 1) AS year_start_date,
    CURDATE() AS current_date,
    YEAR(CURDATE()) - year AS years_difference
FROM cases
LIMIT 20;
```

### Функції:
- **MAKEDATE(year, 1)** - створює дату 1 січня заданого року
- **CURDATE()** - повертає поточну дату
- **YEAR(CURDATE())** - витягує рік з поточної дати

### Приклад результату:
| year | year_start_date | current_date | years_difference |
|------|-----------------|--------------|------------------|
| 1996 | 1996-01-01 | 2026-01-15 | 30 |
| 2000 | 2000-01-01 | 2026-01-15 | 26 |

**Скриншот:** `p4_years_difference.png`

---

## Завдання 5: Власна функція (20 балів)

### Опис
Створити функцію для розрахунку різниці в роках.

### SQL:
```sql
DROP FUNCTION IF EXISTS calculate_years_difference;

DELIMITER //

CREATE FUNCTION calculate_years_difference(input_year INT)
RETURNS INT
DETERMINISTIC
NO SQL
BEGIN
    DECLARE years_diff INT;
    SET years_diff = YEAR(CURDATE()) - input_year;
    RETURN years_diff;
END //

DELIMITER ;

-- Використання
SELECT 
    id,
    year,
    calculate_years_difference(year) AS years_from_now
FROM cases
LIMIT 20;
```

### Альтернативна функція (захворювання за період):
```sql
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
    IF period_divisor = 0 THEN
        RETURN NULL;
    END IF;
    RETURN yearly_cases / period_divisor;
END //

DELIMITER ;

-- Використання (12 = місяць, 4 = квартал, 2 = півріччя)
SELECT 
    year,
    number_rabies AS yearly,
    calculate_disease_per_period(CAST(number_rabies AS DECIMAL(10,2)), 12) AS monthly_avg
FROM cases
WHERE number_rabies != ''
LIMIT 10;
```

**Скриншоти:**
- `p5_function_create.png`
- `p5_function_usage.png`

---

## 📁 Структура репозиторію

```
goit-rdb-fp/
├── final_project_queries.sql      # Всі SQL запити
├── README.md                      # Цей файл
├── p1_create_schema.png           # Завдання 1
├── p1_import_data.png
├── p1_count_records.png
├── p2_create_entities.png         # Завдання 2
├── p2_create_cases.png
├── p2_verification.png
├── p3_rabies_analysis.png         # Завдання 3
├── p4_years_difference.png        # Завдання 4
├── p5_function_create.png         # Завдання 5
└── p5_function_usage.png
```

---

## 🎓 Використані SQL концепції

### DDL (Data Definition Language):
- `CREATE SCHEMA`
- `CREATE TABLE`
- `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE KEY`
- `INDEX`
- `CREATE FUNCTION`

### DML (Data Manipulation Language):
- `INSERT INTO ... SELECT`

### DQL (Data Query Language):
- `SELECT`, `JOIN`
- `WHERE`, `GROUP BY`, `ORDER BY`, `LIMIT`
- `AVG()`, `MIN()`, `MAX()`, `SUM()`, `COUNT()`
- `CAST()`, `REGEXP`

### Функції роботи з датами:
- `MAKEDATE()` - створення дати
- `CURDATE()` - поточна дата
- `YEAR()` - витягування року

### Функції користувача:
- `CREATE FUNCTION`
- `DELIMITER`
- `RETURNS`, `DETERMINISTIC`, `NO SQL`


---

## ✨ Висновки

Виконано всі завдання фінального проєкту:
- ✅ Створено схему `pandemic` та імпортовано дані
- ✅ Нормалізовано таблицю до 3НФ (entities + cases)
- ✅ Проаналізовано дані з розрахунком агрегатних функцій
- ✅ Побудовано колонки з різницею в роках
- ✅ Створено користувацькі функції

**Ключові навички:**
- Проектування реляційних баз даних
- Нормалізація таблиць
- Робота з агрегатними функціями
- Робота з датами та часом
- Створення користувацьких функцій
- Аналіз великих обсягів даних

Фінальний проєкт готовий до здачі! 🎉
