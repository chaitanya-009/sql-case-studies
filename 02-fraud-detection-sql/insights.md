1. Quick Summary

I worked with three tables — customers, cards, and transactions. After joining them and running a few SQL queries, I tried to understand what kind of patterns show up around fraud, spending behaviour, and card usage.

This is a small dataset (around 500 transactions), but it still shows some interesting things.

2. Fraud Patterns I Noticed

A lot of the fraud-tagged transactions are linked to foreign countries/IPs, even though most normal activity is domestic.

When a card has many transactions in a very short time, the chances of fraud go up.

Transactions that are way above the usual spend on that card also seem risky — basically spikes compared to the card’s normal behaviour.

3. Customer-Level Observations

Most customers don’t have much activity, but the ones who do often have 1–2 cards and a bunch of small transactions.

Customers with higher “risk_score” in the customer table tend to show up more often in fraud cases (not perfect, but the pattern is there).

4. Card-Level Notes

A few cards have a surprising number of transactions in a 24-hour window (5–10+). Some of those ended up being fraud.

Some cards have chargebacks, and those cards almost always have at least one fraud case.

One or two cards have transactions before the card’s issued_date — small data quality issue.

5. Merchant-Related Stuff

Some merchants have mostly normal transactions, but a few (especially in Electronics / Travel) show unusually high fraud percentages.

Merchants with a lot of foreign transactions also have more fraud cases.

6. Time-Based Observations

A chunk of the fraud attempts seem to happen late night or very early morning.

There are a few hourly windows where fraud_rate jumps up even with a small number of transactions.

7. Features That Look Useful for a Model

Just noting what actually changed between fraud vs non-fraud rows:

mins_since_prev_card — very low for many fraud cases

txns_last_24h_card — spikes often correlated

is_foreign — pretty strong indicator

amount_over_card_mean — very large deviations look suspicious

chargeback status also lines up with fraud in many cases