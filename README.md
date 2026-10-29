# Retail Sales Database Design and SQL Analytics

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Advanced%20Analytics-orange?style=for-the-badge&logo=database)
![JSON](https://img.shields.io/badge/Data-JSON-yellow?style=for-the-badge&logo=json)

## Project Overview

This project presents the design and analytical implementation of a relational retail e-commerce database. The database is built from six structured JSON datasets representing core entities in an online retail system: customers, orders, order line items, products, suppliers, and product-supplier mappings.

The analytical layer consists of 10 advanced SQL queries addressing business intelligence use cases such as customer spending segmentation, product category performance, supplier contribution analysis, and cross-entity aggregation using subqueries and Common Table Expressions (CTEs).

---

## Database Schema

The relational model consists of 6 interconnected tables reconstructed from structured JSON source files:

| Table | Records | Description | Key Columns |
| :--- | :---: | :--- | :--- |
| `customers` | 50 | Retail customer directory | `customer_id` (PK), `customer_name`, `email`, `phone`, `address` |
| `orders` | 50 | Purchase orders per customer | `order_id` (PK), `order_date`, `customer_id` (FK) |
| `order_items` | 100 | Line items within each order | `order_item_id` (PK), `order_id` (FK), `product_id` (FK), `quantity`, `subtotal` |
| `products` | 50 | Product catalog with categories | `product_id` (PK), `product_name`, `price`, `category` |
| `suppliers` | 10 | Supplier directory | `supplier_id` (PK), `supplier_name`, `contact_name`, `phone` |
| `product_suppliers` | 50 | Product-supplier mapping (many-to-many) | `product_supplier_id` (PK), `product_id` (FK), `supplier_id` (FK) |

### Relational Connections

- `orders.customer_id` → `customers.customer_id`
- `order_items.order_id` → `orders.order_id`
- `order_items.product_id` → `products.product_id`
- `product_suppliers.product_id` → `products.product_id`
- `product_suppliers.supplier_id` → `suppliers.supplier_id`

---

## Advanced SQL Analytics

10 business intelligence queries were developed against the retail schema, covering multi-table joins, subqueries, conditional aggregation, and CTEs:

### Query 1: Total Spending per Customer
- **Objective:** Calculate the cumulative total spending of each customer across all their orders.
- **SQL Technique:** `SUM(subtotal)` with 3-table `JOIN` across `customers`, `orders`, and `order_items`.

```sql
SELECT c.customer_name, SUM(oi.subtotal) AS total_belanja
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY customer_name;
```

---

### Query 2: Products Sold by Each Supplier
- **Objective:** List all products together with the supplier(s) providing them.
- **SQL Technique:** 3-table `JOIN` linking `suppliers`, `product_suppliers` (bridge), and `products`.

```sql
SELECT p.product_name, s.supplier_name
FROM suppliers s
JOIN product_suppliers ps ON s.supplier_id = ps.supplier_id
JOIN products p ON ps.product_id = p.product_id;
```

---

### Query 3: Products Never Ordered
- **Objective:** Identify products that have no purchase history in the order system.
- **SQL Technique:** `LEFT JOIN order_items ... WHERE oi.product_id IS NULL` anti-join pattern.

```sql
SELECT p.product_name
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;
```

---

### Query 4: Average Product Price per Category
- **Objective:** Compute the average selling price for each product category.
- **SQL Technique:** `AVG(price)` with `GROUP BY category`.

```sql
SELECT p.category, AVG(p.price) AS rata_rata
FROM products p
GROUP BY p.category;
```

---

### Query 5: Customers Spending Above Average
- **Objective:** Filter customers whose total spending exceeds the average total spending across all customers.
- **SQL Technique:** `HAVING SUM(...) > (SELECT AVG(...) FROM subquery)` — nested subquery with derived table.

```sql
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
```

---

### Query 6: Product Categories with Above-Average Total Sales
- **Objective:** Identify which product categories generate total sales revenue above the average across all categories.
- **SQL Technique:** CTE (`WITH tab_totalcat AS ...`) with self-referencing subquery for average comparison.

```sql
WITH tab_totalcat AS (
    SELECT p.category, SUM(oi.subtotal) AS total_penjualan
    FROM products p
    JOIN order_items oi ON oi.product_id = p.product_id
    GROUP BY p.category
)
SELECT category, total_penjualan
FROM tab_totalcat
WHERE total_penjualan > (SELECT AVG(total_penjualan) FROM tab_totalcat);
```

---

### Query 7: Products Supplied by More Than One Supplier
- **Objective:** Detect products that have multiple supplier sources and count the number of suppliers per product.
- **SQL Technique:** `COUNT(supplier_id)` with `HAVING COUNT(...) > 1` filtering.

```sql
SELECT p.product_name, COUNT(ps.supplier_id) AS jumlah_pemasok
FROM products p
JOIN product_suppliers ps ON p.product_id = ps.product_id
GROUP BY p.product_name
HAVING COUNT(ps.supplier_id) > 1;
```

---

### Query 8: Orders with High-Volume Product Purchase
- **Objective:** Retrieve customer names, product names, and order dates for transactions where more than 2 units of a product were ordered.
- **SQL Technique:** 4-table `JOIN` with `WHERE quantity > 2` filter.

```sql
SELECT c.customer_name, p.product_name, o.order_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE quantity > 2;
```

---

### Query 9: Total Units Ordered per Supplier-Product Pair
- **Objective:** For each supplier, summarize the total number of units ordered for each product they supply.
- **SQL Technique:** 4-table `JOIN` chain from `suppliers` to `order_items` with `SUM(quantity) GROUP BY supplier, product`.

```sql
SELECT s.supplier_name, p.product_name, SUM(oi.quantity) AS jumlah_unit
FROM suppliers s
JOIN product_suppliers ps ON s.supplier_id = ps.supplier_id
JOIN products p ON ps.product_id = p.product_id
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY s.supplier_name, p.product_name
ORDER BY s.supplier_name;
```

---

### Query 10: Product Breakdown for High-Value Customers
- **Objective:** For customers whose total spending exceeds the average, display the per-product spending breakdown.
- **SQL Technique:** Chained CTEs — first CTE identifies above-average customers, second CTE re-joins to produce product-level granularity.

```sql
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
```

---

## Project Structure

```
.
├── data/
│   ├── Customers.json
│   ├── Orders.json
│   ├── Order_Items.json
│   ├── Products.json
│   ├── Product_Suppliers.json
│   └── Suppliers.json
├── sql/
│   └── retail_analytical_queries.sql
├── Retail_eCommerce_Database_SQL_Problem_Set.pdf
├── Retail_eCommerce_Database_SQL_Solutions.pdf
└── README.md
```

---

## Getting Started

### Prerequisites
- PostgreSQL 14+ or any ANSI SQL-compliant RDBMS
- A tool to import JSON data: DBeaver, pgAdmin, or a custom ETL script

### Loading the Data
Import each JSON file into its respective table in your PostgreSQL database before running the queries. Each file maps directly to a table with the same name (lowercase, underscored).

### Running the Queries
Execute the analytical queries via `psql`:
```bash
psql -U postgres -d your_database_name -f sql/retail_analytical_queries.sql
```
