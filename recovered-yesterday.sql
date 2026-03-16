---PRAGMA table_info(customers);
SELECT *
FROM customers;
SELECT COUNT(*)
FROM customers;
SELECT "Churn flag" AS churn_flag,
    COUNT(*) AS total_customers
FROM customers
GROUP BY "Churn flag";
SELECT "Churn flag" AS churn_flag,
    "Gender" AS gender,
    COUNT(*) AS total_customers
FROM customers
GROUP BY "Gender",
    "Churn flag";
SELECT ROUND(AVG("Balance"), 2) AS average_balance,
    ROUND(AVG("Income"), 2) AS average_income,
    "Customer segment" AS customer_segment
FROM customers
GROUP BY "Customer segment";
SELECT "Occupation" AS occupation,
    COUNT(*) AS total_customers
FROM customers
WHERE "Churn flag" = 1
GROUP BY "Occupation"
ORDER BY total_customers DESC;
SELECT CASE
        WHEN (
            strftime('%Y', 'now') - strftime('%Y', "Date of Birth")
        ) < 30 THEN 'Young'
        WHEN (
            strftime('%Y', 'now') - strftime('%Y', "Date of Birth")
        ) < 50 THEN 'Middle'
        ELSE 'Senior'
    END AS age_group,
    ROUND(SUM("Churn Flag") * 100.0 / COUNT(*), 2) AS churn_rate,
    COUNT(*) AS total_customers
FROM customers
GROUP BY age_group
ORDER BY total_customers DESC;
--- subquery to find customers with above average balance
SELECT `CustomerID` AS customer_id,
    `Balance` AS balance,
    `Occupation` AS occupation
FROM customers
WHERE `Balance` > (
        SELECT AVG(`Balance`)
        FROM customers
    )
ORDER BY balance DESC
LIMIT 10;
--- window function to rank customers by balance within each customer segment
WITH ranked_customers AS (
    SELECT `Customer Segment`,
        `CustomerID`,
        `Balance`,
        RANK() OVER (
            PARTITION BY `Customer Segment`
            ORDER BY `Balance` DESC
        ) AS balance_rank
    FROM customers
) --- select top 3 customers by balance for each customer segment
SELECT *
FROM ranked_customers
WHERE balance_rank <= 3
ORDER BY `Customer Segment`,
    balance_rank;
PRAGMA table_info(customers);
--- CTE to calculate average balance and income by customer segment
WITH segment_averages AS (
    SELECT `Customer Segment` AS customer_segment,
        AVG(`Balance`) AS avg_balance,
        AVG(`Income`) AS avg_income
    FROM customers
    GROUP BY `Customer Segment`
)
SELECT c.`CustomerID` AS customer_id,
    c.`Customer Segment` AS customer_segment,
    c.`Balance` AS balance,
    c.`NumComplaints` AS num_complaints,
    c.`Outstanding Loans` AS outstanding_loans,
    s.avg_balance AS segment_avg_balance,
    s.avg_income AS segment_avg_income,
    RANK() OVER (
        PARTITION BY c.`Customer Segment`
        ORDER BY c.`Balance` ASC
    ) AS balance_rank_in_segment,
    CASE
        WHEN (
            strftime('%Y', 'now') - strftime('%Y', c.`Date of Birth`)
        ) < 30 THEN 'Young'
        WHEN (
            strftime('%Y', 'now') - strftime('%Y', c.`Date of Birth`)
        ) < 50 THEN 'Middle'
        ELSE 'Senior'
    END AS age_group,
    CASE
        WHEN c.`Balance` < s.avg_balance * 0.5 THEN 'High Risk'
        WHEN c.`Balance` < s.avg_balance THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level
FROM customers c
    JOIN segment_averages s ON c.`Customer Segment` = s.customer_segment
WHERE c.`Balance` < s.avg_balance
    AND c.`NumComplaints` > 0
    AND c.`Churn Flag` = 1
    AND c.`Outstanding Loans` > 0
ORDER BY CASE
        risk_level
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        WHEN 'Low Risk' THEN 3
    END ASC,
    c.`Balance` ASC;