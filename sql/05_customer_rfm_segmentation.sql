WITH order_value AS (
    -- Calculate the value of each order.
    SELECT
        order_id,
        SUM(price + freight_value) AS order_value
    FROM public.order_items
    GROUP BY order_id
),

customer_orders AS (
    -- Connect every delivered order with the permanent customer ID.
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        ov.order_value
    FROM public.orders AS o
    JOIN public.customers AS c
        ON c.customer_id = o.customer_id
    JOIN order_value AS ov
        ON ov.order_id = o.order_id
    WHERE o.order_status = 'delivered'
),

reference_date AS (
    -- Use the final date in the dataset instead of today's date.
    SELECT
        MAX(order_purchase_timestamp)::date + 1 AS analysis_date
    FROM customer_orders
),

customer_rfm AS (
    -- Calculate recency, frequency and spending for each customer.
    SELECT
        co.customer_unique_id,

        rd.analysis_date
            - MAX(co.order_purchase_timestamp)::date AS recency_days,

        COUNT(DISTINCT co.order_id) AS frequency,

        ROUND(SUM(co.order_value)::numeric, 2) AS monetary_value

    FROM customer_orders AS co
    CROSS JOIN reference_date AS rd
    GROUP BY
        co.customer_unique_id,
        rd.analysis_date
),

customer_segments AS (
    -- Give customers understandable business labels.
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary_value,

        CASE
            WHEN frequency >= 3 AND recency_days <= 90
                THEN 'Champions'

            WHEN frequency >= 2 AND recency_days <= 180
                THEN 'Repeat customers'

            WHEN frequency >= 2 AND recency_days > 180
                THEN 'At-risk repeat customers'

            WHEN frequency = 1 AND recency_days <= 90
                THEN 'New one-time customers'

            WHEN frequency = 1 AND recency_days > 180
                THEN 'Lost one-time customers'

            ELSE 'Other one-time customers'
        END AS customer_segment

    FROM customer_rfm
)

SELECT
    customer_segment,
    COUNT(*) AS customer_count,

    ROUND(
        AVG(recency_days)::numeric,
        1
    ) AS average_recency_days,

    ROUND(
        AVG(frequency)::numeric,
        2
    ) AS average_orders,

    ROUND(
        AVG(monetary_value),
        2
    ) AS average_customer_value,

    ROUND(
        SUM(monetary_value),
        2
    ) AS total_segment_value

FROM customer_segments
GROUP BY customer_segment
ORDER BY total_segment_value DESC;