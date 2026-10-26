#!/usr/bin/env bash
set -e

DB_NAME="ecommerce_analytics"
DB_USER="postgres"
DATA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/data/raw"

echo "=== Starting Data Ingestion into PostgreSQL Database: $DB_NAME ==="

echo "1. Ingesting customers..."
psql -U "$DB_USER" -d "$DB_NAME" -c "\copy customers FROM '$DATA_DIR/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');"

echo "2. Ingesting products..."
psql -U "$DB_USER" -d "$DB_NAME" -c "\copy products FROM '$DATA_DIR/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');"

echo "3. Ingesting orders..."
psql -U "$DB_USER" -d "$DB_NAME" -c "\copy orders FROM '$DATA_DIR/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');"

echo "4. Ingesting order_items..."
psql -U "$DB_USER" -d "$DB_NAME" -c "\copy order_items FROM '$DATA_DIR/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');"

echo "5. Ingesting order_payments..."
psql -U "$DB_USER" -d "$DB_NAME" -c "\copy order_payments FROM '$DATA_DIR/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true, NULL '');"

echo "=== Ingestion Completed Successfully! ==="
