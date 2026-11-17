# Customer analysis plan

## Decision question

Which customer problems have the greatest impact, where are they concentrated, and what should the marketplace fix first?

## Issue definitions

- **Late delivery:** delivered after the estimated delivery date.
- **Cancelled order:** `order_status = 'canceled'`.
- **Not delivered:** no customer delivery date for an order that is not cancelled or unavailable.
- **Very low review:** review score of 1 or 2.

## Planned decision output

The final Power BI report will rank customer problems and connect each problem to an action, such as seller intervention, delivery SLA review, or customer recovery messaging.

Results must be calculated from PostgreSQL. No headline number should be invented before the queries are run.
