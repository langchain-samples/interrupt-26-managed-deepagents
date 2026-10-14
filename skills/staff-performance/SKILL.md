---
name: staff-performance
description: Review a staff member's performance, revenue processed and rentals
  handled, at their store. Use whenever someone asks for a staff or employee
  performance review.
---

# Staff performance review

Query `sakila.db`, joining `payment` and `rental` to `staff` (by `staff_id`) and
`staff` to `store`, to get, per staff member: total revenue processed
(`SUM(payment.amount)`), rentals handled (`COUNT(DISTINCT rental_id)`), and their
store. Report both staff side by side so their stores can be compared.
