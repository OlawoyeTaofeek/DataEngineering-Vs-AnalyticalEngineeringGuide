# practice_data.py
from datetime import date
from decimal import Decimal

TABLES = {
    "customers_dedup": {
        "types": {"customer_id": "INT", "email": "STRING", "name": "STRING",
                  "phone": "STRING", "updated_at": "DATE"},
        "rows": [
            (3,  "bob@example.com",   "Bob Brown",   "555-2002", "2024-01-05"),
            (5,  "bob@example.com",   "Bob B",       "555-2002", "2024-01-25"),
            (6,  "david@example.com", "David D",     "555-4004", "2024-01-12"),
            (8,  "eve@example.com",   "Eve E",       "555-5005", "2024-01-08"),
            (11, "bob@example.com",   "Bob Beta",    "555-2002", "2024-01-28"),
            (16, "david@example.com", "David Davis", "555-4004", "2024-01-22"),
            (21, None,                "Unknown",     "555-0012", "2024-01-17"),
            (1,  "henry@example.com", "Henry H",     "555-1001", "2024-02-14"),
            (4,  "ivy@example.com",   "Ivy I",       "555-9009", "2024-03-01"),
            (2,  "frank@example.com", "Frank F",     "555-6006", "2024-01-10"),
            (9,  "frank@example.com", "Frank Fox",   "555-6006", "2024-02-01"),
            (14, "frank@example.com", "Franklin",    "555-6006", "2024-02-01"),
            (7,  "jack@example.com",  "Jack J",      "555-1010", "2024-01-03"),
            (10, "jack@example.com",  "Jack Jones",  "555-1010", "2024-01-20"),
            (12, "jack@example.com",  "Jackson",     "555-1010", "2024-02-11"),
            (18, "jack@example.com",  "Jack Jr",     "555-1010", "2024-02-20"),
            (20, "grace@example.com", "Grace G",     "555-7007", "2024-03-10"),
            (22, "grace@example.com", "Grace Green", "555-7007", "2024-02-01"),
            (23, "grace@example.com", "Grace",       "555-7007", "2024-01-15"),
            (25, None,                "Unknown",     "555-0013", "2024-01-30"),
            (26, None,                "Unknown",     "555-0014", "2024-02-05"),
        ],
    },
    # input_order is an extra column: Spark and Snowflake don't guarantee row order,
    # so "preserve input order" needs an explicit column
    "scores": {
        "types": {"day": "INT", "gender": "STRING", "player_name": "STRING",
                  "score_points": "INT", "input_order": "INT"},
        "rows": [
            (1, "F", "Alice",   10, 1),  (1, "M", "Bob",   15, 2),
            (1, "M", "Charlie", 12, 3),  (2, "F", "Diana", 20, 4),
            (3, "F", "Eve",     15, 5),  (2, "M", "Frank", 18, 6),
            (4, "F", "Grace",   25, 7),  (3, "M", "Henry", 22, 8),
            (5, "X", "Ivy",     30, 9),  (2, "X", "Jon",   10, 10),
            (5, "X", "Kai",      0, 11), (5, "X", "Lee",   20, 12),
            (2, "X", "Ned",      8, 13), (9, "X", "Mia",    5, 14),
            (3, "U", "Omar",    40, 15),
        ],
    },
    "rt_orders": {
        "types": {"order_id": "INT", "customer_id": "INT",
                  "order_date": "DATE", "status": "STRING"},
        "rows": [
            (101, 1, "2023-12-15", "completed"), (102, 1, "2024-01-10", "completed"),
            (103, 1, "2024-01-10", "completed"), (104, 1, "2024-03-05", "cancelled"),
            (105, 1, "2024-03-20", "completed"), (106, 2, "2024-01-25", "completed"),
            (107, 2, "2024-02-14", "completed"), (108, 2, "2024-02-14", "pending"),
            (109, 2, "2024-05-02", "completed"), (110, 3, "2024-02-28", "completed"),
            (111, 3, "2024-04-01", "cancelled"), (112, 4, "2024-06-15", "completed"),
            (113, 4, "2024-06-30", "completed"), (114, 4, "2024-09-10", "completed"),
            (115, 4, "2024-12-31", "completed"), (116, 4, "2025-01-01", "completed"),
            (117, 5, "2024-07-04", "completed"), (118, 5, "2025-02-10", "completed"),
        ],
    },
    "rt_order_items": {
        "types": {"order_item_id": "INT", "order_id": "INT", "product_id": "INT",
                  "quantity": "INT", "unit_price": "DECIMAL(10,2)"},
        "rows": [
            (1, 101, 1, 2, 50.00),  (2, 102, 1, 4, 25.00),  (3, 102, 2, 1, 100.00),
            (4, 103, 1, 1, 50.00),  (5, 104, 3, 5, 100.00), (6, 105, 2, 3, 50.00),
            (7, 106, 1, 2, 100.00), (8, 106, 2, 4, 25.00),  (9, 107, 3, 6, 20.00),
            (10, 108, 1, 2, 40.00), (11, 109, 3, 4, 100.00),(12, 110, 2, 3, 30.00),
            (13, 111, 1, 2, 30.00), (14, 112, 2, 5, 50.00), (15, 113, 1, 10, 25.00),
            (16, 114, 3, 1, 100.00),(17, 115, 2, 7, 25.00), (18, 116, 1, 3, 333.00),
            (19, 117, 3, 4, 20.00), (20, 118, 2, 6, 20.00),
        ],
    },
}
# Add the bank tables the same way if you want them.

EXPECTED_COUNTS = {"customers_dedup": 21, "scores": 15, "rt_orders": 18, "rt_order_items": 20}


def typed_rows(name):
    """Rows with real date / Decimal objects, so every engine gets proper types."""
    kinds = list(TABLES[name]["types"].values())
    out = []
    for row in TABLES[name]["rows"]:
        conv = []
        for v, k in zip(row, kinds):
            if v is None:
                conv.append(None)
            elif k == "DATE":
                conv.append(date.fromisoformat(v))
            elif k.startswith("DECIMAL"):
                conv.append(Decimal(str(v)))
            else:
                conv.append(v)
        out.append(tuple(conv))
    return out


def snowflake_inserts():
    """Returns INSERT statements you can paste into a Snowflake worksheet."""
    blocks = []
    for name, t in TABLES.items():
        cols = ", ".join(t["types"])
        vals = [
            "(" + ", ".join("NULL" if v is None
                            else f"'{v}'" if isinstance(v, str) else str(v)
                            for v in row) + ")"
            for row in t["rows"]
        ]
        blocks.append(f"INSERT INTO {name} ({cols}) VALUES\n" + ",\n".join(vals) + ";")
    return "\n\n".join(blocks)