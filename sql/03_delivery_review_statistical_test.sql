WITH order_reviews AS (
    SELECT
        o.order_id,
        AVG(r.review_score)::numeric AS review_score,
        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 'Late'
            ELSE 'On time'
        END AS delivery_status
    FROM public.orders AS o
    JOIN public.order_reviews AS r
        ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
),

group_stats AS (
    SELECT
        delivery_status,
        COUNT(*) AS order_count,
        AVG(review_score) AS average_review_score,
        STDDEV_SAMP(review_score) AS review_stddev
    FROM order_reviews
    GROUP BY delivery_status
),

comparison AS (
    SELECT
        late.order_count AS late_count,
        ontime.order_count AS on_time_count,
        late.average_review_score AS late_average_score,
        ontime.average_review_score AS on_time_average_score,
        ontime.average_review_score
            - late.average_review_score AS score_difference,

        SQRT(
            POWER(late.review_stddev, 2) / late.order_count
            + POWER(ontime.review_stddev, 2) / ontime.order_count
        ) AS standard_error
    FROM group_stats AS late
    CROSS JOIN group_stats AS ontime
    WHERE late.delivery_status = 'Late'
      AND ontime.delivery_status = 'On time'
)

SELECT
    late_count,
    on_time_count,
    ROUND(late_average_score, 2) AS late_average_score,
    ROUND(on_time_average_score, 2) AS on_time_average_score,
    ROUND(score_difference, 2) AS score_difference,

    ROUND(
        score_difference - 1.96 * standard_error,
        2
    ) AS confidence_interval_lower,

    ROUND(
        score_difference + 1.96 * standard_error,
        2
    ) AS confidence_interval_upper
FROM comparison;