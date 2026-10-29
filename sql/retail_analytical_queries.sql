-- Retail E-Commerce Database: 10 Advanced SQL Analytical Queries
-- Author: Ahmad Fauzan
-- Database: PostgreSQL
-- Tables: customers, orders, order_items, products, product_suppliers, suppliers
-- ============================================================================

-- Query 1: Total spending per customer across all orders
SELECT c.customer_name, SUM(oi.subtotal) AS total_belanja
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY customer_name;

-- Query 2: Products sold by each supplier
SELECT p.product_name, s.supplier_name
FROM suppliers s
JOIN product_suppliers ps ON s.supplier_id = ps.supplier_id
JOIN products p ON ps.product_id = p.product_id;

-- Query 3: Products that have never been ordered (anti-join)
SELECT p.product_name
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- Query 4: Average product price per category
SELECT p.category, AVG(p.price) AS rata_rata
FROM products p
GROUP BY p.category;

-- Query 5: Customers whose total spending exceeds the average spending of all customers
SELECT c.customer_name, SUM(oi.subtotal) AS tot_lebih_ratarata
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_name
HAVING SUM(oi.subtotal) > (
    SELECT AVG(tot_lebih_ratarata)
    FROM (
        SELECT SUM(oi.subtotal) AS tot_lebih_ratarata
        FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        JOIN order_items oi ON o.order_id = oi.order_id
        GROUP BY c.customer_id
    ) sub
);

-- Query 6: Product categories with total sales above the average category total (CTE)
WITH tab_totalcat AS (
    SELECT p.category, SUM(oi.subtotal) AS total_penjualan
    FROM products p
    JOIN order_items oi ON oi.product_id = p.product_id
    GROUP BY p.category
)
SELECT category, total_penjualan
FROM tab_totalcat
WHERE total_penjualan > (SELECT AVG(total_penjualan) FROM tab_totalcat);

-- Query 7: Products supplied by more than one supplier
SELECT p.product_name, COUNT(ps.supplier_id) AS jumlah_pemasok
FROM products p
JOIN product_suppliers ps ON p.product_id = ps.product_id
GROUP BY p.product_name
HAVING COUNT(ps.supplier_id) > 1;

-- Query 8: Orders where a customer purchased more than 2 units of a product
SELECT c.customer_name, p.product_name, o.order_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE quantity > 2;

-- Query 9: Total units ordered per supplier-product pair
SELECT s.supplier_name, p.product_name, SUM(oi.quantity) AS jumlah_unit
FROM suppliers s
JOIN product_suppliers ps ON s.supplier_id = ps.supplier_id
JOIN products p ON ps.product_id = p.product_id
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY s.supplier_name, p.product_name
ORDER BY s.supplier_name;

-- Query 10: Per-product spending breakdown for customers whose total exceeds the average (chained CTEs)
WITH tabell AS (
    SELECT c.customer_id, c.customer_name, SUM(oi.subtotal) AS total_pembelian
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.customer_name
),
diatas_rata2 AS (
    SELECT customer_id, customer_name, total_pembelian
    FROM tabell
    WHERE total_pembelian > (SELECT AVG(total_pembelian) FROM tabell)
)
SELECT dt.customer_name, p.product_name, SUM(oi.subtotal) AS total_per_produk
FROM diatas_rata2 dt
JOIN orders o ON dt.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY dt.customer_name, p.product_name
ORDER BY dt.customer_name, p.product_name;
