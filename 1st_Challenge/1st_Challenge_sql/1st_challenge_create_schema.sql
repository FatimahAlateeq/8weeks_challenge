-- MySQL Workbench version 8.0.30
-- Creating the schema
-- SET FOREIGN_KEY_CHECKS=0; #ERROR 1452: Cannot add or update a child row: a foreign key constraint fails: https://stackoverflow.com/questions/21659691/error-1452-cannot-add-or-update-a-child-row-a-foreign-key-constraint-fails
DROP DATABASE IF EXISTS dannys_diner;
CREATE DATABASE IF NOT EXISTS dannys_diner; 
USE dannys_diner;

SELECT 'CREATING DATABASE STRUCTURE' as 'INFO';

DROP TABLE IF EXISTS menu,
                     members,
                     sales;

CREATE TABLE menu (
  product_id INTEGER NOT NULL,
  product_name VARCHAR(5) NOT NULL,
  price INTEGER NOT NULL,
  PRIMARY KEY (product_id),
  UNIQUE  KEY (product_name)
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
CREATE TABLE members (
  customer_id VARCHAR(1) NOT NULL,
  join_date DATE NOT NULL,
  PRIMARY KEY (customer_id)
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

CREATE TABLE sales (
  customer_id VARCHAR(1) NOT NULL,
  order_date DATE,
  product_id INTEGER NOT NULL,
  FOREIGN KEY (customer_id)  REFERENCES members (customer_id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES menu (product_id) ON DELETE CASCADE 
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');

