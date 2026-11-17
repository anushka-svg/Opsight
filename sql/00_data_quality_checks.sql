-- Purpose: validate the source data before making customer claims.
-- Run this in pgAdmin against the ecommerce_ops database.

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_ids,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_ids,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS missing_purchase_dates,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS missing_estimated_dates
FROM public.orders;

SELECT
    COUNT(*) AS total_reviews,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_review_order_ids,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS missing_review_scores,
    MIN(review_score) AS minimum_review_score,
    MAX(review_score) AS maximum_review_score
FROM public.order_reviews;

SELECT
    order_status,
    COUNT(*) AS order_count
FROM public.orders
GROUP BY order_status
ORDER BY order_count DESC;
