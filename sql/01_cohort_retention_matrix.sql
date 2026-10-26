-- Understanding Customer section
WITH summary AS (
    SELECT
        (SELECT COUNT(*) FROM orders) AS "Total Orders",
        (SELECT COUNT(customer_id) FROM customers) AS "Total Customers Rows",
        (SELECT COUNT(DISTINCT customer_unique_id) FROM customers) AS "Total Customers"
)
SELECT
    "Total Orders",
    "Total Customers Rows",
    "Total Customers",
    "Total Customers Rows" - "Total Customers" AS "Sum of Repeat Orders"
FROM summary;

-- Garbage in Garbage Out
-- Melihat status yang tersedia  di order_status
SELECT 
    order_status AS "Order Status",
    COUNT(*) AS "Total Orders",
	ROUND((COUNT(*)::numeric / SUM(COUNT(*)) OVER()) * 100, 2) AS "%" 
FROM orders
GROUP BY order_status
ORDER BY "Total Orders" DESC;

-- Menghitung Frekuensi Transaksi (Repeat Orders) berdasarkan order status "delivered"
WITH repeat_orders AS (
	SELECT 
		c.customer_unique_id AS "Customer ID",
		COUNT(*) AS "Total Repeated Orders"
	FROM customers AS c
	JOIN orders AS o ON c.customer_id = o.customer_id
	WHERE o.order_status = 'delivered'
	GROUP BY c.customer_unique_id
)
SELECT 
	"Total Repeated Orders", 
	COUNT(*) AS "Total Customer",
	ROUND((COUNT(*)::numeric / SUM(COUNT(*)) OVER()) * 100, 2) AS "Percentage"
FROM repeat_orders
GROUP BY "Total Repeated Orders"
ORDER BY "Total Repeated Orders";

--- Menghitung Cohort Index
WITH first_purchases AS (
	-- Mencari Cohort Customer 
    SELECT 
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp))::date AS cohort_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_activities AS (
    -- Mencari seluruh bulan pesanan dari setiap pelanggan
    SELECT 
        c.customer_unique_id,
        fp.cohort_month,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN first_purchases fp ON c.customer_unique_id = fp.customer_unique_id
    WHERE o.order_status = 'delivered'
    GROUP BY 
	c.customer_unique_id, 
	fp.cohort_month, 
	DATE_TRUNC('month', o.order_purchase_timestamp)::date
)
-- cohort_index untuk setiap aktivitas => cohort_index = (ΔTahun×12) + ΔBulan
SELECT 
    customer_unique_id,
    cohort_month,
    order_month,
	(EXTRACT(YEAR FROM order_month) - EXTRACT(YEAR FROM cohort_month)) * 12
	+ 
	(EXTRACT(MONTH FROM order_month) - EXTRACT(MONTH FROM cohort_month))
	AS cohort_index
FROM customer_activities
ORDER BY customer_unique_id, cohort_index;


-- Membuat Cohort Matrix
WITH first_purchases AS (
    -- Bulan lahir/cohort (pertama belanja) per pelanggan
    SELECT 
        c.customer_unique_id,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp))::date AS cohort_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_activities AS (
    -- Semua aktivitas belanja per pelanggan
    SELECT 
        c.customer_unique_id,
        fp.cohort_month,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN first_purchases fp ON c.customer_unique_id = fp.customer_unique_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, fp.cohort_month, DATE_TRUNC('month', o.order_purchase_timestamp)::date
),
cohort_indexed AS (
    -- Menghitung selisih bulan (cohort_index)
    SELECT 
        cohort_month,
        customer_unique_id,
        (EXTRACT(YEAR FROM order_month) - EXTRACT(YEAR FROM cohort_month)) * 12 +
        (EXTRACT(MONTH FROM order_month) - EXTRACT(MONTH FROM cohort_month)) AS cohort_index
    FROM customer_activities
),
cohort_counts AS (
    -- Menghitung berapa orang unik yang aktif di setiap (cohort_month, cohort_index)
    SELECT 
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM cohort_indexed
    GROUP BY cohort_month, cohort_index
),
cohort_sizes AS (
    -- Mengambil ukuran kohor awal (ketika cohort_index = 0)
    SELECT 
        cohort_month,
        active_customers AS cohort_size
    FROM cohort_counts
    WHERE cohort_index = 0
)
-- QUERY UTAMA: Pivot ke samping dari m1 sampai m6 (atau sampai m12)
SELECT 
    TO_CHAR(c.cohort_month, 'YYYY-MM') AS cohort_month,
    s.cohort_size,
    100.00 AS m0,
    MAX(CASE WHEN c.cohort_index = 1 THEN ROUND(100.0 * c.active_customers / s.cohort_size, 2) END) AS m1,
    MAX(CASE WHEN c.cohort_index = 2 THEN ROUND(100.0 * c.active_customers / s.cohort_size, 2) END) AS m2,
    MAX(CASE WHEN c.cohort_index = 3 THEN ROUND(100.0 * c.active_customers / s.cohort_size, 2) END) AS m3,
    MAX(CASE WHEN c.cohort_index = 4 THEN ROUND(100.0 * c.active_customers / s.cohort_size, 2) END) AS m4,
    MAX(CASE WHEN c.cohort_index = 5 THEN ROUND(100.0 * c.active_customers / s.cohort_size, 2) END) AS m5,
    MAX(CASE WHEN c.cohort_index = 6 THEN ROUND(100.0 * c.active_customers / s.cohort_size, 2) END) AS m6
FROM cohort_counts c
JOIN cohort_sizes s ON c.cohort_month = s.cohort_month
WHERE c.cohort_month >= '2017-01-01'
GROUP BY c.cohort_month, s.cohort_size
ORDER BY c.cohort_month;