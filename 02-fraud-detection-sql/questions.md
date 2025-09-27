1.For each customer, compute total number of cards, total transactions, total spend, number of frauds, and fraud_rate (frauds/transactions). Return top 20 customers by fraud_rate (only include customers with ≥5 transactions).


2.Find the top 10 cards by total transaction amount and show for each: card_id, customer_id, issuer_bank (from cards), is_active, total_txn_count, total_amount, fraud_count, last_txn_date.


3.Calculate hourly and daily fraud spikes: for each day and hour (YYYY-MM-DD, hour), report total_txns, fraud_txns, fraud_rate. Return the top 20 hour-slots with highest fraud_rate (only consider slots with ≥10 txns).


4.Identify suspicious merchants: for each merchant, compute total_txns, total_revenue, fraud_txns, fraud_rate, and %txns_from_foreign_countries. List merchants with fraud_rate > 5% and at least 50 transactions, ordered by fraud_rate desc.


5.Session/velocity anomaly: find transactions where mins_since_prev_card < 2 AND txns_last_24h_card >= 5. Join with cards and customers to return txn_id, txn_date, card_id, customer_id, issuer_bank, amount, mins_since_prev_card, txns_last_24h_card, is_fraud. Order by txn_date desc.


6.Build a card-level risk table: for each card compute avg_amount, median_amount, stddev_amount, txns_last_30d (count of txns in last 30 days relative to max txn_date), proportion_foreign, proportion_chargebacks, and a simple risk_flag = 1 if (proportion_chargebacks>0.02 OR proportion_foreign>0.1 OR txns_last_30d>20). Return cards flagged as risky with their customer info.


7.Feature correlation check for modelling: compute, grouped by is_fraud, the average and stddev for amount, mins_since_prev_card, txns_last_24h_card, amount_over_card_mean, and customer risk_score (joined). Present the results side-by-side to show which features differ most between fraud and non-fraud.


8.Backfill and enrichment check: find cards with issued_date after their first transaction (data quality issue). Return card_id, customer_id, issued_date, first_txn_date, count_of_txns and flag these records for investigation.

