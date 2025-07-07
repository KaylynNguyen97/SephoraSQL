-- 1. What is the average rating and total number of reviews for each product?
SELECT 
    b.brand,
    p.product_name,
    AVG(r.rating) as avg_rating,
    r.number_of_reviews as total_reviews
FROM product_table p
JOIN brand_table b ON p.brand_id = b.brand_id
JOIN review_table r ON p.product_id = r.product_id
GROUP BY 
    p.product_name,
    b.brand,
    r.number_of_reviews;

-- 2. Which brands have the highest number of products priced above $50?
SELECT b.brand, 
       COUNT(p.product_id) as luxury_products
FROM brand_table b
JOIN product_table p ON b.brand_id = p.brand_id
JOIN price_table pr ON p.product_id = pr.product_id
WHERE pr.price > 50
GROUP BY b.brand
ORDER BY luxury_products DESC;

-- 3. List all limited edition products with their prices and ratings
SELECT p.product_name, 
       pr.price, 
       r.rating
FROM product_table p
JOIN price_table pr ON p.product_id = pr.product_id
JOIN review_table r ON p.product_id = r.product_id
JOIN marketing_table m ON p.product_id = m.product_id
WHERE m.limited_edition = 1;

-- 4. What is the total number of online only products in each category?
SELECT c.category, 
       COUNT(p.product_id) as online_only_count
FROM category_table c
JOIN product_table p ON c.category_id = p.category_id
JOIN marketing_table m ON p.product_id = m.product_id
WHERE m.online_only = 1
GROUP BY c.category;

-- 5. Identify brand performance tiers based on average product rating, review count, and price point
WITH brand_metrics AS (
    SELECT 
        b.brand_id,
        b.brand,
        AVG(r.rating) as avg_rating,
        SUM(r.number_of_reviews) as total_reviews,
        AVG(p.price) as avg_price,
        COUNT(DISTINCT pr.product_id) as product_count,
        -- Calculate percentiles for each metric
        PERCENT_RANK() OVER (ORDER BY AVG(r.rating)) as rating_percentile,
        PERCENT_RANK() OVER (ORDER BY SUM(r.number_of_reviews)) as review_percentile,
        PERCENT_RANK() OVER (ORDER BY AVG(p.price)) as price_percentile
    FROM brand_table b
    JOIN product_table pr ON b.brand_id = pr.brand_id
    JOIN review_table r ON pr.product_id = r.product_id
    JOIN price_table p ON pr.product_id = p.product_id
    GROUP BY b.brand_id, b.brand
)
SELECT 
    brand,
    avg_rating,
    total_reviews,
    avg_price,
    product_count,
    CASE 
        WHEN (rating_percentile + review_percentile + price_percentile)/3 >= 0.7 THEN 'Premium Tier'
        WHEN (rating_percentile + review_percentile + price_percentile)/3 >= 0.6 THEN 'Mid Tier'
        ELSE 'Value Tier'
    END as brand_tier,
    ROUND(rating_percentile * 100, 2) as rating_percentile_rank,
    ROUND(review_percentile * 100, 2) as review_percentile_rank,
    ROUND(price_percentile * 100, 2) as price_percentile_rank
FROM brand_metrics
ORDER BY (rating_percentile + review_percentile + price_percentile)/3 DESC;

-- 6. Find products that outperform their brand's average in both ratings and price efficiency (rating-to-price ratio)
WITH brand_averages AS (
    SELECT 
        b.brand_id,
        b.brand,
        AVG(r.rating) as brand_avg_rating,
        AVG(r.rating / pr.price) as brand_avg_price_efficiency
    FROM brand_table b
    JOIN product_table p ON b.brand_id = p.brand_id
    JOIN review_table r ON p.product_id = r.product_id
    JOIN price_table pr ON p.product_id = pr.product_id
    GROUP BY b.brand_id, b.brand
),
product_metrics AS (
    SELECT 
        p.product_id,
        p.product_name,
        b.brand_id,
        b.brand,
        c.category,
        r.rating,
        pr.price,
        r.rating / pr.price as price_efficiency,
        r.number_of_reviews,
        PERCENT_RANK() OVER (PARTITION BY c.category_id ORDER BY r.rating) as rating_percentile,
        PERCENT_RANK() OVER (PARTITION BY c.category_id ORDER BY r.rating / pr.price) as efficiency_percentile
    FROM product_table p
    JOIN brand_table b ON p.brand_id = b.brand_id
    JOIN category_table c ON p.category_id = c.category_id
    JOIN review_table r ON p.product_id = r.product_id
    JOIN price_table pr ON p.product_id = pr.product_id
)
SELECT 
    pm.product_name,
    pm.brand,
    pm.category,
    pm.rating,
    ba.brand_avg_rating,
    ROUND(((pm.rating - ba.brand_avg_rating) / ba.brand_avg_rating * 100), 2) as rating_diff_percentage,
    ROUND(pm.price, 2) as price,
    ROUND(pm.price_efficiency * 100, 2) as rating_per_dollar,
    ROUND(ba.brand_avg_price_efficiency * 100, 2) as brand_avg_rating_per_dollar,
    ROUND(pm.rating_percentile * 100, 2) as category_rating_percentile,
    ROUND(pm.efficiency_percentile * 100, 2) as category_efficiency_percentile,
    pm.number_of_reviews
FROM product_metrics pm
JOIN brand_averages ba ON pm.brand_id = ba.brand_id
WHERE pm.rating > ba.brand_avg_rating
    AND pm.price_efficiency > ba.brand_avg_price_efficiency
    AND pm.number_of_reviews >= (
        SELECT AVG(number_of_reviews) 
        FROM review_table
    )
ORDER BY 
    (pm.rating_percentile + pm.efficiency_percentile) DESC;
    
-- 7. Which products contribute the most to their brand's total revenue in each category?
WITH product_revenues AS (
    SELECT 
        p.product_id,
        p.product_name,
        b.brand,
        c.category,
        (pr.price * r.number_of_reviews) as product_revenue
    FROM product_table p
    JOIN brand_table b ON p.brand_id = b.brand_id
    JOIN category_table c ON p.category_id = c.category_id
    JOIN review_table r ON p.product_id = r.product_id
    JOIN price_table pr ON p.product_id = pr.product_id
),
brand_total_revenues AS (
    SELECT 
        b.brand,
        SUM(pr.price * r.number_of_reviews) as brand_revenue
    FROM product_table p
    JOIN brand_table b ON p.brand_id = b.brand_id
    JOIN review_table r ON p.product_id = r.product_id
    JOIN price_table pr ON p.product_id = pr.product_id
    GROUP BY b.brand
)
SELECT 
    pr.product_name,
    pr.brand,
    pr.category,
    ROUND(pr.product_revenue, 2) as product_revenue,
    ROUND((pr.product_revenue / btr.brand_revenue) * 100, 2) as contribution_percentage
FROM product_revenues pr
JOIN brand_total_revenues btr ON pr.brand = btr.brand
ORDER BY contribution_percentage DESC;

-- 8. Which brands have the highest number of high-rated products (above 4.5) in at least 3 different categories?
WITH high_rated_products AS (
    SELECT 
        b.brand,
        c.category,
        COUNT(*) as high_rated_count
    FROM product_table p
    JOIN brand_table b ON p.brand_id = b.brand_id
    JOIN category_table c ON p.category_id = c.category_id
    JOIN review_table r ON p.product_id = r.product_id
    WHERE r.rating > 4.5
    GROUP BY b.brand, c.category
),
brand_category_count AS (
    SELECT 
        brand,
        COUNT(category) as categories_with_high_rated
    FROM high_rated_products
    WHERE high_rated_count > 0
    GROUP BY brand
)
SELECT 
    brand,
    categories_with_high_rated
FROM brand_category_count
WHERE categories_with_high_rated >= 3
ORDER BY categories_with_high_rated DESC;

-- 
SELECT 
    t.TABLE_NAME AS tables_in_sephora_data,
    t.TABLE_ROWS AS row_count,
    COUNT(c.COLUMN_NAME) AS column_count
FROM 
    INFORMATION_SCHEMA.TABLES t
JOIN 
    INFORMATION_SCHEMA.COLUMNS c 
    ON t.TABLE_NAME = c.TABLE_NAME
WHERE 
    t.TABLE_SCHEMA = 'sephora_data'
    AND c.TABLE_SCHEMA = 'sephora_data'
GROUP BY 
    t.TABLE_NAME, t.TABLE_ROWS;
    
SHOW TABLES;

