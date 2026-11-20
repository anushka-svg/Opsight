WITH delivered_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 'Late'
            ELSE 'On time'
        END AS delivery_status,

        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS order_number

    FROM public.orders AS o
    JOIN public.customers AS c
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),

first_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        delivery_status
    FROM delivered_orders
    WHERE order_number = 1
),

customer_retention AS (
    SELECT
        f.customer_unique_id,
        f.delivery_status,
        COUNT(later.order_id) AS later_order_count
    FROM first_orders AS f
    LEFT JOIN delivered_orders AS later
        ON later.customer_unique_id = f.customer_unique_id
       AND later.order_purchase_timestamp > f.order_purchase_timestamp
    GROUP BY
        f.customer_unique_id,
        f.delivery_status
)

SELECT
    delivery_status,
    COUNT(*) AS first_time_customers,
    COUNT(*) FILTER (
        WHERE later_order_count > 0
    ) AS repeat_customers,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE later_order_count > 0
        ) / COUNT(*),
        2
    ) AS repeat_rate_pct
FROM customer_retention
GROUP BY delivery_status
ORDER BY delivery_status;