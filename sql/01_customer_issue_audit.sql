-- Business question:
-- Which customer-impacting issues are most common, and what review score
-- is associated with each issue?
--
-- This first audit assigns one primary issue per order so the categories
-- are easy to compare. Later analysis should also allow multiple issues.

WITH order_issue AS (
    SELECT
        o.order_id,
        o.order_status,
        r.review_score,
        CASE
            WHEN o.order_status = 'canceled' THEN 'Cancelled order'
            WHEN o.order_status NOT IN ('canceled', 'unavailable')
                 AND o.order_delivered_customer_date IS NULL
                THEN 'Not delivered'
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 'Late delivery'
            WHEN r.review_score <= 2 THEN 'Very low review'
            ELSE 'No flagged issue'
        END AS customer_issue
    FROM public.orders AS o
    LEFT JOIN public.order_reviews AS r
        ON r.order_id = o.order_id
)
SELECT
    customer_issue,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_of_orders,
    ROUND(AVG(review_score), 2) AS average_review_score
FROM order_issue
GROUP BY customer_issue
ORDER BY order_count DESC;
