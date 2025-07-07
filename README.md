# Sephora Website Product Database

This repository contains the database schema, population scripts, and analysis for a comprehensive dataset of products available on the Sephora website. The project aims to organize product data efficiently to support complex queries related to product characteristics, brand performance, customer feedback, and pricing strategies.

## Project Overview

This project focuses on creating a relational database from a Sephora product dataset. It addresses challenges encountered during data import and transformation, defines a structured database schema, and outlines key business questions that can be answered using the organized data.

## Data Source

*   The dataset was sourced from [Kaggle](https://www.kaggle.com/datasets/raghadalharbi/all-products-available-on-sephora-website).
*   It provides a comprehensive list of products available on the Sephora website, including various attributes for each product.
*   The dataset initially consists of a single CSV file.

## Database Schema

### Anticipated Tables

Based on the attributes present in the dataset, the database is anticipated to have approximately 6-7 tables for efficient organization:

*   **Product Table:** Contains primary product details (e.g., product ID, name, description, price, category).
*   **Brand Table:** Lists unique brands, linked to products by brand ID.
*   **Category Table:** Contains unique product categories, linked to products by category ID.
*   **Review Table:** Captures user reviews, ratings, and the relationship to specific products.
*   **Ingredient Table:** Contains information on product ingredients, possibly linked to products by product ID.
*   **Price Table:** Tracks price history over time, linking product ID with historical price data.
*   **Marketing Table:** Captures marketing flags, sales, and special offers (e.g., online only, limited offer, exclusive).

### Data Dictionary

The following tables and their columns are defined in the database schema:

*   **Product**
    *   `product_id` (INT): Unique identifier for each product.
    *   `brand_id` (INT): Foreign key referencing the Brand table.
    *   `category_id` (INT): Foreign key referencing the Category table.
    *   `product_name` (VARCHAR): Name of the product.
    *   `product_description` (TEXT): Description of the product.
    *   `product_size` (INT): Size of the product (e.g., volume, weight).
    *   `product_url` (VARCHAR): URL of the product.
    *   `product_instruction` (TEXT): Instructions or usage information for the product.
*   **Price**
    *   `price_id` (INT): Unique identifier for each price.
    *   `product_id` (INT): Foreign key referencing the Product table.
    *   `price` (DECIMAL): Price of the product.
    *   `price_value` (DECIMAL): Value of the price (e.g., discounted price).
*   **Review**
    *   `review_id` (INT): Unique identifier for each review.
    *   `product_id` (INT): Foreign key referencing the Product table.
    *   `review_rating` (INT): Rating of the product by the customer.
    *   `review_love` (BOOLEAN): Indication of whether the customer loved the product.
*   **Brand**
    *   `brand_id` (INT): Unique identifier for each brand.
    *   `brand_name` (VARCHAR): Name of the brand.
*   **Category**
    *   `category_id` (INT): Unique identifier for each category.
    *   `category_name` (VARCHAR): Name of the category.
*   **Size**
    *   `size_id` (INT): Unique identifier for each size.
    *   `size_options` (VARCHAR): Available size options for the product.
*   **Product_Ingredient** (Junction Table)
    *   `product_id` (INT): Foreign key referencing the Product table.
    *   `ingredient_id` (INT): Foreign key referencing the Ingredient table.
*   **Ingredient**
    *   `ingredient_id` (INT): Unique identifier for each ingredient.
    *   `ingredient_name` (VARCHAR): Name of the ingredient.
*   **Marketing**
    *   `marketing_id` (INT): Unique identifier for each marketing detail.
    *   `product_id` (INT): Foreign key referencing the Product table.
    *   `marketing_flag` (BOOLEAN): Indicates if the product is part of a marketing campaign.
    *   `marketing_content` (TEXT): Additional marketing information for the product.
    *   `marketing_online_only` (BOOLEAN): Indicates if the product is available only online.
    *   `marketing_exclusive` (BOOLEAN): Indicates if the product is exclusive.
    *   `marketing_limited_edition` (BOOLEAN): Indicates if the product is a limited edition.
    *   `marketing_limited_time_offer` (BOOLEAN): Indicates if the product is a limited time offer.
*   **Product_Size** (Junction Table)
    *   `product_id` (INT): Foreign key referencing the Product table.
    *   `size_id` (INT): Foreign key referencing the Size table.

### Entity Relationship Diagram (ERD) Business Rules

The following business rules define the relationships between tables:

*   **PRODUCT - PRICE:**
    *   Each product has one and only one price.
    *   Each price may be associated with one or many products.
*   **PRODUCT - REVIEW:**
    *   Each product can receive zero or many reviews from customers.
    *   Each review is associated with only one specific product.
*   **PRODUCT - BRAND:**
    *   Each product belongs to exactly one brand.
    *   Each brand can have at least one or many products under it.
*   **PRODUCT - CATEGORY:**
    *   Each product is assigned to exactly one category.
    *   Each category can contain one or many products.
*   **PRODUCT - PRODUCT_INGREDIENT:**
    *   Each product may contain at least one or many ingredients through a list of product-ingredient associations.
    *   Each product-ingredient association links one product to one specific ingredient.
*   **PRODUCT - MARKETING_DETAIL:**
    *   Each product may have zero or many marketing details, which provide promotional or marketing information.
    *   Each marketing detail entry is associated with exactly one specific product.
*   **PRODUCT - PRODUCT_SIZE:**
    *   Each product may be available in one or many sizes.
    *   Each product-size entry links one product to one specific size.
*   **INGREDIENT - PRODUCT_INGREDIENT:**
    *   Each ingredient can be used in one or many products through the product-ingredient association.
    *   Each product-ingredient association links one ingredient to one specific product.
*   **SIZE - PRODUCT_SIZE:**
    *   Each size can be associated with one or many products through the product-size association.
    *   Each product-size association links one size to one specific product.

## Data Preparation and Import

### Import Challenges & Solutions

*   **Challenge:** MySQL Workbench encountered issues with special characters (accented letters, symbols) in the raw CSV data, leading to import failures.
*   **Solution:** The dataset was cleaned using R.
    *   `stringr` and `gsub` functions were used to replace or remove all non-ASCII characters.
    *   A custom function was written to clean each column where special characters were found.
    *   A new, compatible CSV file was created and successfully imported into MySQL.

### Data Transformation

*   The cleaned dataset was transformed into a relational database format based on the ERD.
*   **Unique IDs:** Since the original dataset lacked unique identifier (ID) columns, these were created for `category`, `brand`, `price`, `review`, `size`, and `marketing` tables.
*   **R `dplyr` package:** Used for constructing tables and manipulating datasets.
*   **Consistency Checks:** Performed to ensure all required columns and relationships were present and ID columns were correctly assigned.
*   **Size Field Cleaning:** The `size` field, which contained multiple size options in one cell, was separated into individual size options.
*   **Ingredient Field:** Due to the messy nature and lack of clear delimiters in ingredient lists, the ingredients were kept as long text strings within the table to maintain flexibility and avoid over-complicating the data architecture.
*   **Prioritization:** Analysis focused on more structured and interpretable data such as price, review, and marketing data.
*   **Final Import:** All cleaned data tables were successfully imported into MySQL Workbench using the Table Data Import Wizard.

## Business Questions

The structured database allows for answering various business questions, including:

1.  What is the average rating and total number of reviews for each product?
2.  Which brands have the highest number of products priced above $50?
3.  List all limited edition products with their prices and ratings.
4.  What is the total number of online-only products in each category?
5.  Identify brand performance tiers based on average product rating, review count, and price point.
6.  Find products that outperform their brand's average in both ratings and price efficiency (rating-to-price ratio).
7.  Which products contribute the most to their brand's total revenue in each category?
8.  Which brands have the highest number of high-rated products (above 4.5) in at least 3 different categories?

## Visualization

*   Interactive dashboards and charts were created to visualize key insights from the data, such as product rating distributions and brand performance trends.
