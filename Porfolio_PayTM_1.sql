/*Mô tả: 
Paytm là một công ty công nghệ tài chính đa quốc gia của Ấn Độ. Nó chuyên về hệ thống thanh toán kỹ thuật số, thương mại điện tử và dịch vụ tài chính. Ví Paytm là một ví kỹ thuật số/di động an toàn và được RBI (Ngân hàng Dự trữ Ấn Độ) phê duyệt, cung cấp vô số tính năng tài chính để đáp ứng mọi nhu cầu thanh toán của người tiêu dùng. Ví Paytm có thể được nạp tiền thông qua UPI (Giao diện thanh toán hợp nhất), ngân hàng trực tuyến hoặc thẻ tín dụng/thẻ ghi nợ. Người dùng cũng có thể chuyển tiền từ ví Paytm sang tài khoản ngân hàng của người nhận hoặc ví Paytm của chính họ.
Dưới đây là cơ sở dữ liệu nhỏ về các giao dịch thanh toán từ năm 2019 đến 2020 của Ví Paytm. Cơ sở dữ liệu bao gồm 6 bảng:
•	fact_transaction: Lưu trữ thông tin của tất cả các loại giao dịch: Thanh toán, Nạp tiền, Chuyển khoản, Rút tiền
•	dim_scenario: Mô tả chi tiết các loại giao dịch
•	dim_payment_channel: Mô tả chi tiết phương thức thanh toán
•	dim_platform: Mô tả chi tiết về thiết bị thanh toán
•	dim_status: Mô tả chi tiết kết quả của giao dịch

1.1. Paytm có nhiều loại giao dịch trong hoạt động kinh doanh của mình. Người quản lý của bạn muốn biết mức đóng góp (theo tỷ lệ phần trăm) 
của từng loại giao dịch vào tổng số giao dịch. Truy xuất một báo cáo bao gồm các thông tin sau: 
+ Loại giao dịch (transaction type)
+ Số lượng giao dịch (number of transaction) 
+ Tỷ lệ của từng loại trong tổng số. (proportion of each type in total)
Các giao dịch này phải đáp ứng các điều kiện sau:
• Được thành lập năm 2019
• Đã thanh toán thành công
Chỉ hiển thị kết quả của 5 loại hàng đầu có tỷ lệ phần trăm cao nhất trên tổng số.*/
WITH table_A AS (SELECT fact_19.*, transaction_type
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scenario 
ON fact_19.scenario_id = scenario.scenario_id 
LEFT JOIN dim_status AS stat
ON  fact_19.status_id = stat.status_id 
WHERE status_description = 'success')
,total_table AS 
(SELECT transaction_type, 
COUNT(transaction_id) AS num_trans,
(SELECT COUNT(transaction_id) FROM table_A) AS total_trans
FROM table_A 
GROUP BY transaction_type)
SELECT TOP 5
    *
    , FORMAT (num_trans*1.0/total_trans, 'p') AS pct  
FROM total_table
ORDER BY num_trans DESC
 /*1.2. Sau khi người quản lý của bạn xem xét kết quả của 5 loại hàng đầu này, anh ấy muốn tìm hiểu sâu hơn để hiểu rõ hơn.
Truy xuất một báo cáo chi tiết hơn với các thông tin sau: 
loại giao dịch (transaction type)
danh mục (category)
số lượng giao dịch (number of transaction)
tỷ trọng của từng danh mục trong tổng số loại giao dịch đó (proportion of each category in the total of that transaction type)
Các giao dịch này phải đáp ứng các điều kiện sau:
• Được thành lập năm 2019
• Đã thanh toán thành công. */
WITH join_table AS ( 
SELECT fact_19.*, transaction_type, category
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena 
    ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS stat 
    ON fact_19.status_id = stat.status_id
WHERE status_description = 'success' 
)
, count_category AS (
SELECT transaction_type, category
    , COUNT(transaction_id) AS number_trans_category
FROM join_table 
GROUP BY transaction_type, category
) 
, count_type AS (
SELECT transaction_type
    , COUNT(transaction_id) AS number_trans_type
FROM join_table 
GROUP BY transaction_type
)
SELECT count_category.*, number_trans_type
    , FORMAT( number_trans_category*1.0/number_trans_type, 'p') AS pct 
FROM count_category 
FULL JOIN count_type 
ON count_category.transaction_type = count_type.transaction_type
WHERE number_trans_type IS NOT NULL AND number_trans_category IS NOT NULL 
ORDER BY number_trans_category*1.0/number_trans_type DESC
/* 2. Nhiệm vụ 2: Truy xuất báo cáo tổng quan về hành vi thanh toán của khách hàng
2.1. Paytm đã có được rất nhiều khách hàng. Truy xuất một báo cáo bao gồm các thông tin sau: 
số lượng giao dịch (the number of transactions) 
số lượng kịch bản thanh toán (the number of payment scenarios)
số loại thanh toán (the number of payment category )
tổng số tiền phải trả của từng khách hàng ()
• Được thành lập năm 2019
• Có mô tả trạng thái là thành công
• Có loại giao dịch là thanh toán
• Chỉ hiển thị Top 10 khách hàng cao nhất theo số lượng giao dịch*/
SELECT  top 10 customer_id
    , COUNT (transaction_id) AS number_trans 
    , COUNT ( DISTINCT dim_scenario.scenario_id ) AS number_scenarios
    , COUNT ( DISTINCT category ) AS number_categories
    , SUM ( charged_amount ) AS total_amount
FROM fact_transaction_2019
LEFT JOIN dim_scenario 
ON fact_transaction_2019.scenario_id = dim_scenario.scenario_id
WHERE fact_transaction_2019.status_id = 1 
AND transaction_type = 'Payment'
GROUP BY customer_id 
ORDER BY number_trans DESC
/*2.2. Sau khi xem xét các số liệu về hành vi thanh toán của khách hàng ở trên, chúng tôi muốn phân tích sự phân bổ của từng số liệu. Trước khi tính toán và vẽ biểu đồ phân phối để kiểm tra tần suất của các giá trị trong mỗi chỉ số, chúng ta cần nhóm các quan sát thành phạm vi.
2.2.1.
Dựa trên kết quả của 2.1, hãy truy xuất báo cáo bao gồm các cột sau: chỉ số, giá trị tối thiểu, giá trị tối đa và giá trị trung bình của các chỉ số này: (Khó)
• Tổng số tiền đã tính phí (The total charged amount)
• Số lượng giao dịch (The number of transactions)
• Số lượng kịch bản thanh toán (The number of payment scenarios)
• Số lượng danh mục thanh toán (The number of payment categories)*/
WITH summary_table AS (
SELECT customer_id
    , COUNT(transaction_id) AS number_trans
    , COUNT(DISTINCT fact_19.scenario_id) AS number_scenarios
    , COUNT(DISTINCT scena.category) AS number_categories
    , SUM(charged_amount) AS total_amount
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena 
        ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS sta 
        ON fact_19.status_id = sta.status_id 
WHERE status_description = 'success'
    AND transaction_type = 'payment'
GROUP BY customer_id
)
SELECT 'The number of transaction' AS metric 
    , MIN(number_trans) AS min_value
    , MAX(number_trans) AS max_value
    , AVG(number_trans) AS avg_value
FROM summary_table
UNION 
SELECT 'The number of scenarios' AS metric
    , MIN(number_scenarios) AS min_value
    , MAX(number_scenarios) AS max_value
    , AVG(number_scenarios) AS avg_value
FROM summary_table
UNION 
SELECT 'The number of categories' AS metric
    , MIN(number_categories) AS min_value
    , MAX(number_categories) AS max_value
    , AVG(number_categories) AS avg_value
FROM summary_table
UNION 
SELECT 'The total charged amount' AS metric
    , MIN(total_amount) AS min_value
    , MAX(total_amount) AS max_value
    , AVG(1.0*total_amount) AS avg_value
FROM summary_table
/*2.2.2. Tính tần suất của từng trường trong mỗi số liệu (từ kết quả 2.1)
Số liệu 1: Số lượng kịch bản thanh toán*/
WITH summary_table AS (
SELECT customer_id
    , COUNT(DISTINCT scena.scenario_id) AS number_scenario
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena 
        ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS sta 
        ON fact_19.status_id = sta.status_id 
WHERE status_description = 'success'
    AND transaction_type = 'payment'
GROUP BY customer_id -- 
)
SELECT number_scenario
    , COUNT(customer_id) AS number_customers
FROM summary_table
GROUP BY number_scenario
ORDER BY number_scenario

--2.2.3. Tổng số tiền đã tính
WITH summary_table AS (
SELECT customer_id
    , SUM(charged_amount) AS total_amount
    , CASE
        WHEN SUM(charged_amount) < 1000000 THEN '0-01M'
        WHEN SUM(charged_amount) >= 1000000 AND SUM(charged_amount) < 2000000 THEN '01M-02M'
        WHEN SUM(charged_amount) >= 2000000 AND SUM(charged_amount) < 3000000 THEN '02M-03M'
        WHEN SUM(charged_amount) >= 3000000 AND SUM(charged_amount) < 4000000 THEN '03M-04M'
        WHEN SUM(charged_amount) >= 4000000 AND SUM(charged_amount) < 5000000 THEN '04M-05M'
        WHEN SUM(charged_amount) >= 5000000 AND SUM(charged_amount) < 6000000 THEN '05M-06M'
        WHEN SUM(charged_amount) >= 6000000 AND SUM(charged_amount) < 7000000 THEN '06M-07M'
        WHEN SUM(charged_amount) >= 7000000 AND SUM(charged_amount) < 8000000 THEN '07M-08M'
        WHEN SUM(charged_amount) >= 8000000 AND SUM(charged_amount) < 9000000 THEN '08M-09M'
        WHEN SUM(charged_amount) >= 9000000 AND SUM(charged_amount) < 10000000 THEN '09M-10M'
        WHEN SUM(charged_amount) >= 10000000 THEN 'more > 10M'
        END AS charged_amount_range
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS scena 
        ON fact_19.scenario_id = scena.scenario_id
LEFT JOIN dim_status AS sta 
        ON fact_19.status_id = sta.status_id 
WHERE status_description = 'success'
    AND transaction_type = 'payment'
GROUP BY customer_id
)
SELECT charged_amount_range
    , COUNT(customer_id) AS number_customers
FROM summary_table
GROUP BY charged_amount_range 
ORDER BY charged_amount_range
