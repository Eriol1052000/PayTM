--1.1
SELECT customer_id, 
transaction_id, 
fact_20.scenario_id, 
transaction_type, 
sub_category, 
category,
status_description
INTO #t20
FROM fact_transaction_2020 AS fact_20
JOIN dim_scenario AS sce 
ON fact_20.scenario_id = sce.scenario_id
JOIN dim_status 
ON fact_20.status_id = dim_status.status_id
WHERE MONTH (transaction_time) = 1 AND dim_status.status_id = 1
--1.2
WITH table_1 AS
(SELECT transaction_type,COUNT(transaction_type) as nb_trans
    FROM fact_transaction_2020 AS fact_20
    JOIN dim_scenario sce 
    ON fact_20.scenario_id = sce.scenario_id
    JOIN dim_status
    ON fact_20.status_id = dim_status.status_id
    WHERE MONTH(transaction_time) = 1
    GROUP BY transaction_type)
,
table_2 AS (SELECT COUNT(transaction_type) as nb_success_trans, 
transaction_type
--INTO #t20
FROM fact_transaction_2020 AS fact_20
JOIN dim_scenario AS sce 
ON fact_20.scenario_id = sce.scenario_id
JOIN dim_status 
ON fact_20.status_id = dim_status.status_id
WHERE MONTH (transaction_time) = 1 AND dim_status.status_id = 1
GROUP BY transaction_type)
SELECT table_2.transaction_type, nb_trans,nb_success_trans,
CAST( nb_success_trans AS float)/CAST(nb_trans AS float)  AS  success_rate
FROM table_2
JOIN table_1
ON table_2.transaction_type = table_1.transaction_type
--2.1
WITH fact_table AS ( 
SELECT TOP 5000 transaction_id, customer_id, scenario_id, charged_amount, transaction_time, status_id
FROM fact_transaction_2019
UNION 
SELECT TOP 5000 transaction_id, customer_id, scenario_id, charged_amount, transaction_time, status_id
FROM fact_transaction_2020
) 
SELECT customer_id 
    , DATEDIFF (day, MAX (transaction_time), '2020-12-31') AS recency 
    , COUNT ( DISTINCT CONVERT (varchar, transaction_time, 102) )  AS frequency 
    , SUM (1.0*charged_amount) AS monetary 
FROM fact_table 
LEFT JOIN dim_scenario scena 
    ON fact_table.scenario_id = scena.scenario_id
WHERE category = 'Billing' AND status_id = 1
GROUP BY customer_id
--2.2
WITH fact_table AS ( 
    SELECT  fact_19.*
    FROM fact_transaction_2019 fact_19 
    JOIN dim_scenario sce ON fact_19.scenario_id = sce.scenario_id
    WHERE category = 'Billing' AND status_id = 1 
UNION
    SELECT  fact_20.*
    FROM fact_transaction_2020 fact_20 
    JOIN dim_scenario sce ON fact_20.scenario_id = sce.scenario_id
    WHERE category = 'Billing' AND status_id = 1 
)
, rfm_metric AS (
SELECT customer_id
    , DATEDIFF(day, MAX(transaction_time), '2020-12-31') AS recency 
    , COUNT( DISTINCT CONCAT( DAY(transaction_time), MONTH(transaction_time))) AS frequency
    , SUM(charged_amount) AS monetary 
FROM fact_table
GROUP BY customer_id 
)
, rfm_rank AS (
SELECT *
    , PERCENT_RANK() OVER ( ORDER BY recency ASC ) AS r_percent_rank
    , PERCENT_RANK() OVER ( ORDER BY frequency DESC ) AS f_percent_rank
    , PERCENT_RANK() OVER ( ORDER BY monetary DESC ) AS m_percent_rank
FROM rfm_metric
)
, rfm_tier AS ( 
SELECT *
    , CASE WHEN r_percent_rank > 0.75 THEN 4
        WHEN r_percent_rank > 0.5 THEN 3
        WHEN r_percent_rank > 0.25 THEN 2
        ELSE 1 END AS r_tier
    , CASE WHEN f_percent_rank > 0.75 THEN 4
        WHEN f_percent_rank > 0.5 THEN 3
        WHEN f_percent_rank > 0.25 THEN 2
        ELSE 1 END AS f_tier
    , CASE WHEN m_percent_rank > 0.75 THEN 4
        WHEN m_percent_rank > 0.5 THEN 3
        WHEN m_percent_rank > 0.25 THEN 2
        ELSE 1 END AS m_tier
FROM rfm_rank
)
, rfm_group AS ( 
SELECT * 
    , CONCAT(r_tier, f_tier, m_tier) AS rfm_score 
FROM rfm_tier
) 
, segment_table AS (
SELECT *
    , CASE 
        WHEN rfm_score  =  111 THEN 'Best Customers'
        WHEN rfm_score LIKE '[3-4][3-4][1-4]' THEN 'Lost Bad Customer'
        WHEN rfm_score LIKE '[3-4]2[1-4]' THEN 'Lost Customers'
        WHEN rfm_score LIKE  '21[1-4]' THEN 'Almost Lost' 
        WHEN rfm_score LIKE  '11[2-4]' THEN 'Loyal Customers'
        WHEN rfm_score LIKE  '[1-2][1-3]1' THEN 'Big Spenders'
        WHEN rfm_score LIKE  '[1-2]4[1-4]' THEN 'New Customers'  
        WHEN rfm_score LIKE  '[3-4]1[1-4]' THEN 'Hibernating' 
        WHEN rfm_score LIKE  '[1-2][2-3][2-4]' THEN 'Potential Loyalists' -- 
    ELSE 'unknown'
    END AS segment 
FROM rfm_group
)
SELECT
    segment
    , COUNT( customer_id) AS number_users 
    , SUM( COUNT( customer_id)) OVER() AS total_users
    , FORMAT( 1.0*COUNT( customer_id) / SUM( COUNT( customer_id)) OVER(), 'p') AS pct
FROM segment_table
GROUP BY segment
ORDER BY number_users DESC