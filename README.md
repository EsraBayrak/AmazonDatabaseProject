# Amazon Database Project

A relational SQL Server database design modeling an Amazon-like e-commerce platform.

This project demonstrates database design, normalization, constraints, triggers, and analytical SQL queries.

---

## 📌 Project Overview

The database models the core components of an e-commerce system including:

- Accounts (Buyer / Seller specialization)
- Products and Categories
- Orders and Order Items
- Cart and Cart Items
- Payments and Shipments
- Reviews
- Discounts
- Wishlist

The schema enforces referential integrity using primary keys, foreign keys, constraints, and triggers.

---

## 🗂 Database Structure

All SQL files are located inside the `database/` folder:

- `01_create_tables.sql` – Table definitions and constraints  
- `02_triggers.sql` – Trigger implementations  
- `03_seed.sql` – Sample data  
- `04_queries.sql` – Analytical and reporting queries  

---

## 🧠 Concepts Demonstrated

- Entity-Relationship Modeling (EER)
- Normalization principles
- Primary & Foreign Key constraints
- Check constraints
- Triggers
- Aggregate queries
- JOIN operations
- Transaction-related logic

---

## ▶ How to Run

1. Create a new database in SQL Server named:

   ```sql
   CREATE DATABASE Amazon;
