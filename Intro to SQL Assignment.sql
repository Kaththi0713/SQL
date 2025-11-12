-- Question 6 : Create the database
CREATE DATABASE ECommerceDB;

-- Switch to the database
USE ECommerceDB;

-- 1. Create Tables with Data Types and Constraints

-- Categories Table
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL UNIQUE
);

-- Products Table
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL UNIQUE,
    CategoryID INT,
    Price DECIMAL(10,2) NOT NULL,
    StockQuantity INT,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);

-- Customers Table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    JoinDate DATE
);

-- Orders Table
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE NOT NULL,
    TotalAmount DECIMAL(10,2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- 2. Insert Records

-- Insert Categories
INSERT INTO Categories VALUES
(1, 'Electronics'),
(2, 'Books'),
(3, 'Home Goods'),
(4, 'Apparel');

-- Insert Products
INSERT INTO Products VALUES
(101, 'Laptop Pro', 1, 1200.00, 50),
(102, 'SQL Handbook', 2, 45.50, 200),
(103, 'Smart Speaker', 1, 99.99, 150),
(104, 'Coffee Maker', 3, 75.00, 80),
(105, 'Novel : The Great SQL', 2, 25.00, 120),
(106, 'Wireless Earbuds', 1, 150.00, 100),
(107, 'Blender X', 3, 120.00, 60),
(108, 'T-Shirt Casual', 4, 20.00, 300);

-- Insert Customers
INSERT INTO Customers VALUES
(1, 'Alice Wonderland', 'alice@example.com', '2023-01-10'),
(2, 'Bob the Builder', 'bob@example.com', '2022-11-25'),
(3, 'Charlie Chaplin', 'charlie@example.com', '2023-03-01'),
(4, 'Diana Prince', 'diana@example.com', '2021-04-26');

-- Insert Orders
INSERT INTO Orders VALUES
(1001, 1, '2023-04-26', 1245.50),
(1002, 2, '2023-10-12', 99.99),
(1003, 1, '2023-07-01', 145.00),
(1004, 3, '2023-01-14', 150.00),
(1005, 2, '2023-09-24', 120.00),
(1006, 1, '2023-06-19', 20.00);

-- Question 7 : Generate a report showing CustomerName, Email, and the
-- TotalNumberofOrders for each customer. Include customers who have not placed
-- any orders, in which case their TotalNumberofOrders should be 0. Order the results
-- by CustomerName.##

SELECT 
    c.CustomerName,
    c.Email,
    COUNT(o.OrderID) AS TotalNumberOfOrders
FROM Customers c
LEFT JOIN Orders o 
    ON c.CustomerID = o.CustomerID
GROUP BY 
    c.CustomerName,
    c.Email
ORDER BY 
    c.CustomerName;
    
-- Question 8 : Retrieve Product Information with Category: Write a SQL query to
-- display the ProductName, Price, StockQuantity, and CategoryName for all
-- products. Order the results by CategoryName and then ProductName alphabetically.

SELECT 
    p.ProductName,
    p.Price,
    p.StockQuantity,
    c.CategoryName
FROM Products p
JOIN Categories c 
    ON p.CategoryID = c.CategoryID
ORDER BY 
    c.CategoryName,
    p.ProductName;


-- Question 9 : Write a SQL query that uses a Common Table Expression (CTE) and a
-- Window Function (specifically ROW_NUMBER() or RANK()) to display the
-- CategoryName, ProductName, and Price for the top 2 most expensive products in
-- each CategoryName.

WITH RankedProducts AS (
    SELECT 
        c.CategoryName,
        p.ProductName,
        p.Price,
        ROW_NUMBER() OVER (
            PARTITION BY c.CategoryName 
            ORDER BY p.Price DESC
        ) AS RankPosition
    FROM Products p
    JOIN Categories c 
        ON p.CategoryID = c.CategoryID
)
SELECT 
    CategoryName,
    ProductName,
    Price
FROM RankedProducts
WHERE RankPosition <= 2
ORDER BY 
    CategoryName,
    Price DESC;

-- Question 10 : You are hired as a data analyst by Sakila Video Rentals, a global movie
-- rental company. The management team is looking to improve decision-making by
-- analyzing existing customer, rental, and inventory data.

use sakila;

# 1. Top 5 customers by total amount spent
SELECT
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.email,
  ROUND(SUM(p.amount), 2) AS total_spent
FROM payment AS p
JOIN customer AS c
  ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
ORDER BY total_spent DESC
LIMIT 5;

# 2. Top 3 movie categories by rental count
SELECT
  cat.name AS category,
  COUNT(r.rental_id) AS rental_count
FROM category AS cat
JOIN film_category AS fc
  ON fc.category_id = cat.category_id
JOIN inventory AS i
  ON i.film_id = fc.film_id
JOIN rental AS r
  ON r.inventory_id = i.inventory_id
GROUP BY cat.category_id, cat.name
ORDER BY rental_count DESC
LIMIT 3;
# 3. Films available at each store and how many have never been rented
#(Counts distinct films per store; “never rented” = no rentals for any copy in that store.)
SELECT
  fs.store_id,
  COUNT(*) AS distinct_films_available,
  SUM(CASE WHEN fsr.film_id IS NULL THEN 1 ELSE 0 END) AS distinct_films_never_rented
FROM (
  SELECT store_id, film_id
  FROM inventory
  GROUP BY store_id, film_id
) AS fs
LEFT JOIN (
  SELECT i.store_id, i.film_id
  FROM inventory AS i
  JOIN rental AS r
    ON r.inventory_id = i.inventory_id
  GROUP BY i.store_id, i.film_id
) AS fsr
  ON fs.store_id = fsr.store_id
 AND fs.film_id = fsr.film_id
GROUP BY fs.store_id
ORDER BY fs.store_id;

# 4. Total revenue per month for the year 2023
SELECT
  DATE_FORMAT(p.payment_date, '%Y-%m') AS yearmonth,
  ROUND(SUM(p.amount), 2) AS total_revenue
FROM payment AS p
WHERE YEAR(p.payment_date) = 2023
GROUP BY YEAR(p.payment_date), MONTH(p.payment_date)
ORDER BY YEAR(p.payment_date), MONTH(p.payment_date);

# 5. Customers with more than 10 rentals in the last 6 months
SELECT
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.email,
  COUNT(r.rental_id) AS rentals_last_6_months
FROM customer AS c
JOIN rental AS r
  ON r.customer_id = c.customer_id
WHERE r.rental_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
HAVING rentals_last_6_months > 10
ORDER BY rentals_last_6_months DESC;
