SELECT 
	MAX(order_purchase_timestamp) AS "Latest Transaction Date",
	DATE_TRUNC('day', MAX(order_purchase_timestamp) + INTERVAL '1 day')::timestamp AS "Snapshot Date"
FROM orders
WHERE order_status = 'delivered';

-- Raw RFM Table
-- Recency dan Frequency di dapatkan melalui customers dan orders
-- Recency di dapatkan melalui selisih antara "Snapshot Date" dan "order_purchase_timestamp" terbaru
-- Frequency di dapatkan melalui Jumlah Unique "order_id"
-- Monetary di ambil dari jumlah pembayaran di order_payments
WITH raw_rfm AS (
    SELECT 
        c.customer_unique_id AS "Customer ID",
        '2018-08-30'::date - MAX(o.order_purchase_timestamp)::date AS "Last Purchase",
        COUNT(DISTINCT o.order_id) AS "Order Frequency",
        ROUND(COALESCE(SUM(p.payment_value), 0), 2) AS "Total Purchase"
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN order_payments p ON p.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_cell AS (
    SELECT 
        "Customer ID",
        NTILE(5) OVER (ORDER BY "Last Purchase" DESC) AS "R Score",
        NTILE(5) OVER (ORDER BY "Total Purchase" ASC) AS "M Score",
        CASE
            WHEN "Order Frequency" >= 4 THEN 5
            WHEN "Order Frequency" = 3 THEN 4
            WHEN "Order Frequency" = 2 THEN 3
            ELSE 1
        END AS "F Score"
    FROM raw_rfm
),
rfm_segment AS (
    SELECT 
        raw."Customer ID",
        raw."Last Purchase",
        raw."Order Frequency",
        raw."Total Purchase",
        cell."R Score",
        cell."F Score",
        cell."M Score",
        (cell."R Score"::text || cell."F Score"::text || cell."M Score"::text) AS "RFM Cell",
        CASE 
            WHEN cell."R Score" >= 4 AND cell."F Score" >= 3 AND cell."M Score" >= 4 THEN 'Champions'
            WHEN cell."F Score" >= 3 AND cell."R Score" >= 3 THEN 'Loyal Customers'
            WHEN cell."F Score" >= 3 AND cell."R Score" <= 2 THEN 'At Risk'
            WHEN cell."R Score" >= 4 AND (cell."M Score" >= 4 OR cell."F Score" >= 3) THEN 'Potential Loyalists'
            WHEN cell."R Score" = 5 THEN 'Recent Customers'
            WHEN cell."R Score" = 4 THEN 'Promising'
            WHEN cell."R Score" = 3 THEN 'Customers Needing Attention'
            WHEN cell."R Score" = 2 THEN 'Hibernating'
            ELSE 'Lost'
        END AS "Customer Segment"
    FROM raw_rfm raw
    JOIN rfm_cell cell ON cell."Customer ID" = raw."Customer ID"
)
-- Tabel Ringkasan Eksekutif untuk Manajemen
SELECT 
    "Customer Segment",
    COUNT(*) AS "Total Customers",
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS "% Customers",
    ROUND(SUM("Total Purchase"), 2) AS "Total Revenue",
    ROUND(100.0 * SUM("Total Purchase") / SUM(SUM("Total Purchase")) OVER(), 2) AS "% Revenue",
    ROUND(AVG("Last Purchase"), 1) AS "Avg Last Purchase (Days)",
    ROUND(AVG("Order Frequency"), 2) AS "Avg Order Frequency",
    ROUND(AVG("Total Purchase"), 2) AS "Avg Spend (ARPU)"
FROM rfm_segment
GROUP BY "Customer Segment"
ORDER BY "Total Revenue" DESC;