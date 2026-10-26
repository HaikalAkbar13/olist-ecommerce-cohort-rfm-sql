-- ==============================================================================
-- Project: E-Commerce Customer Retention & Cohort Analytics (PostgreSQL)
-- Script: 00_schema_ddl.sql
-- Author: Muh Haikal Akbar, S.E.
-- Description: DDL Schema creation for Olist Brazilian E-Commerce database.
--              Defines 5 relational tables, primary keys, foreign keys, and indexes.
-- ==============================================================================

-- 1. Customers Table
-- Note: 'customer_id' is unique per order, while 'customer_unique_id' is the true customer entity.
CREATE TABLE IF NOT EXISTS customers (
    customer_id              VARCHAR(32) PRIMARY KEY,
    customer_unique_id       VARCHAR(32) NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city            VARCHAR(100),
    customer_state           VARCHAR(10)
);

CREATE INDEX IF NOT EXISTS idx_customers_unique_id ON customers(customer_unique_id);
CREATE INDEX IF NOT EXISTS idx_customers_state ON customers(customer_state);

-- 2. Products Table
CREATE TABLE IF NOT EXISTS products (
    product_id                 VARCHAR(32) PRIMARY KEY,
    product_category_name      VARCHAR(100),
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           NUMERIC(10,2),
    product_length_cm          NUMERIC(10,2),
    product_height_cm          NUMERIC(10,2),
    product_width_cm           NUMERIC(10,2)
);

CREATE INDEX IF NOT EXISTS idx_products_category ON products(product_category_name);

-- 3. Orders Table
CREATE TABLE IF NOT EXISTS orders (
    order_id                      VARCHAR(32) PRIMARY KEY,
    customer_id                   VARCHAR(32) NOT NULL REFERENCES customers(customer_id),
    order_status                  VARCHAR(30) NOT NULL,
    order_purchase_timestamp      TIMESTAMP NOT NULL,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_purchase_timestamp ON orders(order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(order_status);

-- 4. Order Items Table
CREATE TABLE IF NOT EXISTS order_items (
    order_id            VARCHAR(32) NOT NULL REFERENCES orders(order_id),
    order_item_id       INT NOT NULL,
    product_id          VARCHAR(32),
    seller_id           VARCHAR(32),
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10,2) NOT NULL,
    freight_value       NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- 5. Order Payments Table
CREATE TABLE IF NOT EXISTS order_payments (
    order_id             VARCHAR(32) NOT NULL REFERENCES orders(order_id),
    payment_sequential   INT NOT NULL,
    payment_type         VARCHAR(30) NOT NULL,
    payment_installments INT NOT NULL,
    payment_value        NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE INDEX IF NOT EXISTS idx_order_payments_order_id ON order_payments(order_id);
