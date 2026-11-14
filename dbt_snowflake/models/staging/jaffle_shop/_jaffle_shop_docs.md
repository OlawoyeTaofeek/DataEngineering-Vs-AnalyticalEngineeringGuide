{# ============================================================
   MODELS
   ============================================================ #}

{% docs stg_jaffle_shop__customers %}

Staging model for Jaffle Shop customers. **One row per customer**, cleaned
from the raw `raw.jaffle_shop.customers` table.

Columns are renamed to project conventions (`id` → `customer_id`); no rows
are filtered and no business logic is applied. Use this as the single source
of customer identity for all downstream models.

{% enddocs %}


{% docs stg_jaffle_shop__orders %}

Staging model for Jaffle Shop orders. **One row per order**, cleaned from the
raw `raw.jaffle_shop.orders` table.

Columns are renamed to project conventions:
- `id` → `order_id`
- `user_id` → `customer_id`

Contains order status and date only; payment amounts live in
`stg_stripe__payments` and are combined in `fct_orders`.

{% enddocs %}


{# ============================================================
   COLUMNS: customers
   ============================================================ #}

{% docs customers_customer_id %}
**Primary key.** Unique identifier for a customer, taken from `id` in the
source system. Joins to `stg_jaffle_shop__orders.customer_id`.
{% enddocs %}

{% docs first_name %}
Customer's first name as entered in the Jaffle Shop app.
{% enddocs %}

{% docs last_name %}
Customer's last name. In the source data this is stored as an **initial only**
(e.g. "P."), so it should not be used to uniquely identify a customer.
{% enddocs %}


{# ============================================================
   COLUMNS: orders
   ============================================================ #}

{% docs order_id %}
**Primary key.** Unique identifier for an order, taken from `id` in the
source system. Joins to `stg_stripe__payments.order_id`.
{% enddocs %}

{% docs orders_customer_id %}
**Foreign key** to `stg_jaffle_shop__customers.customer_id`. The customer who
placed the order (renamed from `user_id` in the source).
{% enddocs %}

{% docs order_date %}
Date the order was placed (no time component).
{% enddocs %}

{% docs order_status %}

Current stage of the order in its lifecycle. Status reflects the **latest
state only**; history is not kept here. One of the following values:

| status | definition |
|---|---|
| `placed` | Order placed, not yet shipped |
| `shipped` | Order has been shipped, not yet delivered |
| `completed` | Order has been received by the customer |
| `return_pending` | Customer has indicated they want to return this item |
| `returned` | Item has been returned |

{% enddocs %}


{# ============================================================
   SOURCES
   ============================================================ #}

{% docs table_customers %}

This table contains one row per customer who has signed up on the Jaffle Shop app.

Customers are created when someone places their first order or registers an
account. The data is exported from the app database and loaded into the
warehouse in a single batch. The following details are stored:
- Customer ID (unique per customer)
- First name
- Last name (initial only, e.g. "P.")

{% enddocs %}


{% docs table_orders %}

This table contains one row per order placed on the Jaffle Shop app.

Orders are recorded by the app at checkout and loaded into the warehouse in a
single batch, stamped with `_etl_loaded_at`. Each order moves through these
statuses:
- placed
- shipped
- completed
- return_pending
- returned

{% enddocs %}


{% docs table_payments %}

This table contains one row per payment attempt processed by Stripe.

Payments are captured by Stripe when a customer pays for an order, and loaded
into the warehouse in batches stamped with `_batched_at`. Amounts are stored in
**cents**. The following payment methods are used:
- credit_card
- coupon
- bank_transfer
- gift_card

{% enddocs %}