---
name: qbr-report
description: Generate a Quarterly Business Review (QBR) report for the DVD rental business, covering revenue and rental volume with breakdowns by film language, category (genre), and actor. Use whenever someone asks for a QBR, a quarterly report, or a quarterly business review.
---

# QBR report

A QBR summarizes revenue and rental activity for a quarter and breaks it down by
language, category, and actor so a stakeholder can see what drove the numbers.

## Which quarter

If the user names a quarter (e.g. "Q2 2026"), use it. Otherwise use the most
recently completed calendar quarter relative to today's date.

## What to compute

Run SQL against `sakila.db` for the chosen date range (`rental.rental_date` /
`payment.payment_date`) to get:

1. **Overview** — total revenue (`SUM(payment.amount)`), total rentals
   (`COUNT(*)` on `rental`), and how both compare to the prior quarter.
2. **Revenue by language** — join `payment` → `rental` → `inventory` → `film`
   → `language`, group by `language.name`.
3. **Revenue by category (genre)** — join the same chain through
   `film_category` → `category`, group by `category.name`. A film can have
   more than one category; report each film's revenue once per category it
   belongs to.
4. **Top actors by revenue** — join through `film_actor` → `actor`, group by
   actor, and rank by revenue from films they appear in. A film can have
   multiple actors, so the same rental can contribute to several actors'
   totals.

## Report format

Write the report as markdown with these sections, in order: Overview,
Revenue by Language, Revenue by Category, Top Actors. Use a ranked list or
small table for each breakdown (top 5 is enough per section) and call out
the single biggest mover from the prior quarter in the Overview.
