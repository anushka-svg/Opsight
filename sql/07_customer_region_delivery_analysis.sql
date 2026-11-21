-- Purpose: identify customer regions where delivery problems have the greatest impact.
-- Currency: monetary values are in Brazilian reais (R$) for the original Olist dataset.

WITH order_value AS (
    -- Calculate one total value for each order to prevent duplicated revenue.
    SELECT
        order_id,
        SUM(price + freight_value) AS order_value
    FROM public.order_items
    GROUP BY order_id
),

review_by_order AS (
    -- Create one review score per order because an order can have multiple review rows.
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM public.order_reviews
    GROUP BY order_id
),

order_details AS (
    SELECT
        o.order_id,
        c.customer_state,
        ov.order_value,
        r.review_score,

        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 'Late'
            ELSE 'On time'
        END AS delivery_status,

        o.order_delivered_customer_date::date
            - o.order_estimated_delivery_date::date AS delay_days

    FROM public.orders AS o
    JOIN public.customers AS c
        ON c.customer_id = o.customer_id
    JOIN order_value AS ov
        ON ov.order_id = o.order_id
    LEFT JOIN review_by_order AS r
        ON r.order_id = o.order_id

    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)

SELECT
    customer_state,
    COUNT(*) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE delivery_status = 'Late'
    ) AS late_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE delivery_status = 'Late'
        ) / COUNT(*),
        2
    ) AS late_order_rate_pct,

    ROUND(
        (
            AVG(delay_days) FILTER (
                WHERE delivery_status = 'Late'
            )
        )::numeric,
        2
    ) AS average_late_days,

    ROUND(
        AVG(review_score)::numeric,
        2
    ) AS average_review_score,

    ROUND(
        COALESCE(
            SUM(order_value) FILTER (
                WHERE delivery_status = 'Late'
            ),
            0
        )::numeric,
        2
    ) AS late_revenue_at_risk

FROM order_details
GROUP BY customer_state

-- Avoid judging a region using a very small number of orders.
HAVING COUNT(*) >= 100

ORDER BY late_revenue_at_risk DESC;
