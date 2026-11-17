-- Business question:
-- Do late deliveries correspond to lower customer review scores?

WITH delivery_status AS (
    SELECT
        o.order_id,
        CASE
            WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
                THEN 'On time'
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 'Late'
            ELSE 'Not delivered'
        END AS delivery_status,
        EXTRACT(
            EPOCH FROM (
                o.order_delivered_customer_date - o.order_estimated_delivery_date
            )
        ) / 86400.0 AS delay_days
    FROM public.orders AS o
    WHERE o.order_status = 'delivered'
), review_summary AS (
    SELECT
        ds.delivery_status,
        ds.delay_days,
        r.review_score
    FROM delivery_status AS ds
    LEFT JOIN public.order_reviews AS r
        ON r.order_id = ds.order_id
)
SELECT
    delivery_status,
    COUNT(*) AS order_count,
    COUNT(review_score) AS reviewed_order_count,
    ROUND(AVG(review_score), 2) AS average_review_score,
    ROUND(AVG(delay_days)::numeric, 2) AS average_delay_days,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_score <= 2)
        / NULLIF(COUNT(review_score), 0), 2) AS low_review_rate
FROM review_summary
GROUP BY delivery_status
ORDER BY delivery_status;
