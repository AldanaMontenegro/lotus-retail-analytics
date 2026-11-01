-- Creacion de la base de datos --

CREATE DATABASE LotusRetail;
GO
USE LotusRetail;
GO

-- Informacion acerca de las tablas --

SELECT 
    TABLE_NAME,
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
    'dim_customers',
    'dim_date',
    'dim_employees',
    'dim_products',
    'dim_stores',
    'fact_order_details',
    'fact_orders_2022_2023',
    'fact_orders_2024',
    'fact_returns'
)
ORDER BY 
    TABLE_NAME,
    ORDINAL_POSITION;
 
-- Verificacion de cantidad de registros en las tablas --

SELECT 'dim_customers' AS tabla, COUNT(*) AS registros
FROM dim_customers

UNION ALL

SELECT 'dim_date', COUNT(*)
FROM dim_date

UNION ALL

SELECT 'dim_employees', COUNT(*)
FROM dim_employees

UNION ALL

SELECT 'dim_products', COUNT(*)
FROM dim_products

UNION ALL

SELECT 'dim_stores', COUNT(*)
FROM dim_stores

UNION ALL

SELECT 'fact_order_details', COUNT(*)
FROM fact_order_details

UNION ALL

SELECT 'fact_orders_2022_2023', COUNT(*)
FROM fact_orders_2022_2023

UNION ALL

SELECT 'fact_orders_2024', COUNT(*)
FROM fact_orders_2024

UNION ALL

SELECT 'fact_returns', COUNT(*)
FROM fact_returns;

-- Verificacion de datos duplicados -- 

SELECT 
    customer_id,
    COUNT(*) AS cantidad
FROM dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT date_id
FROM dim_date
GROUP BY date_id
HAVING COUNT(date_id) > 1;

SELECT store_id 
FROM dim_stores
GROUP BY store_id
HAVING COUNT(store_id) > 1;

SELECT detail_id
FROM fact_order_details
GROUP BY detail_id
HAVING COUNT(detail_id) > 1;

SELECT order_id
FROM fact_orders_2022_2023
GROUP BY order_id
HAVING COUNT(order_id) > 1;

SELECT order_id
FROM fact_orders_2024
GROUP BY order_id
HAVING COUNT(order_id) > 1;

-- Verificacion de datos duplicados o de datos unicos con el mismo ID --

SELECT * 
FROM dim_customers
WHERE customer_id IN (
    SELECT customer_id
    FROM dim_customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
    )
ORDER BY customer_id;

-- Eliminacion de datos duplicados -- 

WITH duplicados AS (
            SELECT *,
                ROW_NUMBER() OVER(PARTITION BY customer_id 
                ORDER BY customer_id) AS numeracion
            FROM dim_customers
            )
DELETE FROM duplicados 
WHERE numeracion > 1; -- En el caso de que hayan mas de 2 duplicados

-- Verificamos que no queden duplicados con el script anterior a este --

-- Modificamos los tipos de texto necesarios --

ALTER TABLE dim_customers 
ALTER COLUMN phone NVARCHAR(50);

ALTER TABLE dim_date
ALTER COLUMN quarter_name NVARCHAR(10);

UPDATE dim_date 
SET quarter_name =
    CASE WHEN quarter_name = 1.00 THEN 'Q1'
         WHEN quarter_name = 2.00 THEN 'Q2'
         WHEN quarter_name = 3.00 THEN 'Q3'
         WHEN quarter_name = 4.00 THEN 'Q4'
END;

ALTER TABLE dim_products
ALTER COLUMN unit_price DECIMAL(18,2);

ALTER TABLE dim_products
ALTER COLUMN unit_cost DECIMAL(18,2);

SELECT * FROM fact_order_details;
unit_price discount_pct selling_price y unit_cost 

ALTER TABLE fact_order_details
ALTER COLUMN unit_price DECIMAL(18,2);

ALTER TABLE fact_order_details
ALTER COLUMN selling_price DECIMAL(18,2);

ALTER TABLE fact_order_details
ALTER COLUMN unit_cost DECIMAL(18,2);

ALTER TABLE fact_order_details
ALTER COLUMN line_total_revenue DECIMAL(18,2);

ALTER TABLE fact_orders_2022_2023
ALTER COLUMN total_revenue DECIMAL(18,2);

ALTER TABLE fact_orders_2022_2023
ALTER COLUMN total_cost DECIMAL(18,2);

ALTER TABLE fact_orders_2024
ALTER COLUMN total_cost DECIMAL(18,2);

ALTER TABLE fact_orders_2024
ALTER COLUMN total_revenue DECIMAL(18,2);

ALTER TABLE fact_returns
ALTER COLUMN return_amount DECIMAL(18,2);

-- Creacion de claves primarias --

ALTER TABLE dim_customers
ADD CONSTRAINT pk_customer_id PRIMARY KEY (customer_id);

ALTER TABLE dim_date
ADD CONSTRAINT pk_date_id PRIMARY KEY (date_id);

ALTER TABLE dim_employees
ADD CONSTRAINT pk_employee_id PRIMARY KEY (employee_id);

ALTER TABLE dim_products
ADD CONSTRAINT pk_product_id PRIMARY KEY (product_id);

ALTER TABLE dim_stores
ADD CONSTRAINT pk_store_id PRIMARY KEY (store_id);

ALTER TABLE fact_order_details
ADD CONSTRAINT pk_detail_id PRIMARY KEY (detail_id);

ALTER TABLE fact_orders_2022_2023
ADD CONSTRAINT pk_order_id PRIMARY KEY (order_id);

ALTER TABLE fact_orders_2024
ADD CONSTRAINT pk_order_id_2024 PRIMARY KEY (order_id);

ALTER TABLE fact_returns
ADD CONSTRAINT pk_return_id PRIMARY KEY (return_id);

-- Creacion de las claves foráneas --

    -- Tabla de órdenes 2022 / 2023 --

ALTER TABLE fact_orders_2022_2023
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id);

ALTER TABLE fact_orders_2022_2023
ADD CONSTRAINT fk_orders_stores
FOREIGN KEY (store_id) REFERENCES dim_stores(store_id);

ALTER TABLE fact_orders_2022_2023
ADD CONSTRAINT fk_orders_employees
FOREIGN KEY (employee_id) REFERENCES dim_employees(employee_id);

ALTER TABLE fact_orders_2022_2023
ADD CONSTRAINT fk_orders_date
FOREIGN KEY (date_id) REFERENCES dim_date(date_id);

    -- Tabla de órdenes 2024 --

ALTER TABLE fact_orders_2024
ADD CONSTRAINT fk_orders_customers_2024
FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id);

ALTER TABLE fact_orders_2024
ADD CONSTRAINT fk_orders_stores_2024
FOREIGN KEY (store_id) REFERENCES dim_stores(store_id);

ALTER TABLE fact_orders_2024
ADD CONSTRAINT fk_orders_employees_2024
FOREIGN KEY (employee_id) REFERENCES dim_employees(employee_id);

ALTER TABLE fact_orders_2024
ADD CONSTRAINT fk_orders_date_2024
FOREIGN KEY (date_id) REFERENCES dim_date(date_id);

-- fact_order_details --

SELECT p.product_id,
    od.order_id
FROM fact_order_details AS od
LEFT JOIN dim_products AS p
    ON od.product_id = p.product_id
WHERE p.product_id IS NULL;

    -- cantidad de ordenes por año --

SELECT año,
    COUNT(order_id) AS cantidad_ordenes
FROM (
    SELECT order_id,
        YEAR(order_date) AS año
    FROM fact_orders_2022_2023
    UNION ALL
    SELECT order_id,
        YEAR(order_date) AS año
    FROM fact_orders_2024
    ) AS ordenes
GROUP BY año;

    -- existencia de ordenes unicas o duplicadas por año --

SELECT o2.order_id AS orden_22_23, 
    o4.order_id AS orden_24
FROM fact_orders_2022_2023 AS o2
INNER JOIN fact_orders_2024 AS o4
    ON o2.order_id = o4.order_id
;

    -- verificacion de ordenes dentro de ordenes 2024 o 22/23 --

SELECT r.order_id AS orden_detalle
FROM fact_returns AS r
WHERE NOT EXISTS (
        SELECT o2.order_id AS orden_2022_o_2023
        FROM fact_orders_2022_2023 AS o2
        WHERE o2.order_id = r.order_id
        )
AND NOT EXISTS (
    SELECT o4.order_id AS orden_2024
        FROM fact_orders_2024 AS o4
        WHERE o4.order_id = r.order_id
        )

    -- unificacion de tablas de ordenes --

SELECT *
INTO fact_orders
FROM (
    SELECT *
    FROM fact_orders_2022_2023

    UNION ALL

    SELECT *
    FROM fact_orders_2024
) AS orders;

    -- declaramos la PK --

ALTER TABLE fact_orders
ADD CONSTRAINT pk_fact_orders PRIMARY KEY (order_id);

    -- declaramos la FK --

ALTER TABLE fact_order_details
ADD CONSTRAINT fk_product_id
FOREIGN KEY (product_id) REFERENCES dim_products(product_id);

ALTER TABLE fact_returns
ADD CONSTRAINT fk_order_id
FOREIGN KEY (order_id) REFERENCES fact_orders(order_id);

ALTER TABLE fact_order_details
ADD CONSTRAINT fk_details_order_id
FOREIGN KEY (order_id) REFERENCES fact_orders(order_id);


