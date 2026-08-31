#!/usr/bin/env bash
set -euo pipefail

pip install --quiet --break-system-packages pandas matplotlib

curl -s -o /tmp/sakila-schema.sql https://raw.githubusercontent.com/jOOQ/sakila/main/sqlite-sakila-db/sqlite-sakila-schema.sql
curl -s -o /tmp/sakila-data.sql https://raw.githubusercontent.com/jOOQ/sakila/main/sqlite-sakila-db/sqlite-sakila-insert-data.sql
sqlite3 sakila.db < /tmp/sakila-schema.sql
sqlite3 sakila.db < /tmp/sakila-data.sql
rm -f /tmp/sakila-schema.sql /tmp/sakila-data.sql

# The public Sakila sample only has English films and dates from 2005-2006.
# Diversify some films into other languages, and shift dates into a recent
# window so "this quarter"/"last quarter" resolve sensibly in a live demo.
sqlite3 sakila.db <<'SQL'
UPDATE film SET language_id = 5 WHERE film_id BETWEEN 1 AND 120;   -- French
UPDATE film SET language_id = 2 WHERE film_id BETWEEN 121 AND 200; -- Italian
UPDATE film SET language_id = 3 WHERE film_id BETWEEN 201 AND 250; -- Japanese

UPDATE rental SET
  rental_date = datetime(rental_date, '+7595 days'),
  return_date = datetime(return_date, '+7595 days');
UPDATE payment SET payment_date = datetime(payment_date, '+7595 days');

-- customer.create_date is a record-creation stamp, not a real signup date, and
-- sits after the rental window in the source data. Pin it before all shifted
-- rental activity so customers don't appear to rent before they existed.
UPDATE customer SET create_date = '2026-01-01 00:00:00';

-- The source data also stamps a batch of still-checked-out rentals with its
-- generation timestamp instead of a real date; after the shift that lands in
-- the future, so pull those back to a recent, still-open-looking date.
UPDATE rental SET rental_date = '2026-08-10 15:16:03' WHERE rental_date > '2026-08-15';
UPDATE payment SET payment_date = '2026-08-10 15:16:03' WHERE payment_date > '2026-08-15';

-- A handful of source payments are recorded at $0.00 (comped rentals), which
-- reads like a data error to anyone doing quick revenue math. Bump them to a
-- nominal amount so every payment is a real transaction.
UPDATE payment SET amount = 0.99 WHERE amount <= 0;
SQL

mkdir -p artifacts
