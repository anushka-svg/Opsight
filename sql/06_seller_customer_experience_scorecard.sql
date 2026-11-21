WITH review_by_order AS (
    -- Some orders have multiple review records.
    -- This creates one review score per order.
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM public.order_reviews
    GROUP BY order_id
),

seller_orders AS (
    -- Create one record for every seller-order combination.
    SELECT
        oi.seller_id,
        o.order_id,

        SUM(
            oi.price + oi.freight_value
        ) AS seller_order_value,

        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 'Late'
            ELSE 'On time'
        END AS delivery_status,

        r.review_score

    FROM public.order_items AS oi

    JOIN public.orders AS o
        ON o.order_id = oi.order_id

    LEFT JOIN review_by_order AS r
        ON r.order_id = o.order_id

    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL

    GROUP BY
        oi.seller_id,
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        r.review_score
),

seller_metrics AS (
    SELECT
        seller_id,

        COUNT(*) AS delivered_orders,

        ROUND(
            SUM(seller_order_value)::numeric,
            2
        ) AS total_revenue,

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
            AVG(review_score)::numeric,
            2
        ) AS average_review_score,

        ROUND(
            100.0 * COUNT(*) FILTER (
                WHERE review_score <= 2
            ) / NULLIF(COUNT(review_score), 0),
            2
        ) AS low_review_rate_pct,

        ROUND(
            COALESCE(
                SUM(seller_order_value) FILTER (
                    WHERE delivery_status = 'Late'
                ),
                0
            )::numeric,
            2
        ) AS late_revenue_at_risk

    FROM seller_orders
    GROUP BY seller_id

    -- Avoid unfairly ranking sellers with only a few orders.
    HAVING COUNT(*) >= 20
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY
            late_revenue_at_risk DESC,
            late_order_rate_pct DESC
    ) AS priority_rank,

    seller_id,
    delivered_orders,
    total_revenue,
    late_orders,
    late_order_rate_pct,
    average_review_score,
    low_review_rate_pct,
    late_revenue_at_risk

FROM seller_metrics
ORDER BY priority_rank
LIMIT 15;