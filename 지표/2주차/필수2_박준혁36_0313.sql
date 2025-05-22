#### 필수과제2
#### 고객의 세그먼트를 새롭게 나눠 주세요.
#### 5등급으로 나눠서 (직접 여러분들이 데이터를 보고 설계하시면 됩니다.) 5개의 등급의 고객 세그먼트가 나올 수 있게 만들어 주시면 됩니다.
#### 수업 때는 3개 했지만 실제 5개까지 진행하고 모두 로직상 겹치지 않게 최대한 다 세그먼트로 나뉠 수 있도록 지정해 주세요!

-- VIP 고객: 주문 수 10회 이상, 총 매출 500,000 이상
-- 우수 고객: 주문 수 7회 이상, 총 매출 300,000 이상
use classicmodels;

-- 일반 고객: 주문 수 4회 이상, 총 매출 100,000 이상
-- 잠재 고객: 최소 1회 이상 주문하고 최근 1년 내 활동 있음
-- 휴면 고객: 최소 1회 이상 주문했지만 1년 이상 활동 없음
-- 신규 고객: 주문 기록이 없는 고객

SELECT 
    c.customerNumber,
    c.customerName,
    COUNT(DISTINCT o.orderNumber) AS total_orders,
    COALESCE(SUM(od.quantityOrdered * od.priceEach), 0) AS total_revenue,
    MAX(o.orderDate) AS last_order_date,
    DATEDIFF(CURDATE(), MAX(o.orderDate)) AS days_since_last_order,
    CASE 
        WHEN COUNT(DISTINCT o.orderNumber) >= 10 AND SUM(od.quantityOrdered * od.priceEach) >= 500000 THEN 'VIP 고객'
        WHEN COUNT(DISTINCT o.orderNumber) >= 7 AND SUM(od.quantityOrdered * od.priceEach) >= 300000 THEN '우수 고객'
        WHEN COUNT(DISTINCT o.orderNumber) >= 4 AND SUM(od.quantityOrdered * od.priceEach) >= 100000 THEN '일반 고객'
        WHEN COUNT(DISTINCT o.orderNumber) >= 1 AND DATEDIFF(CURDATE(), MAX(o.orderDate)) <= 365 THEN '잠재 고객'
        WHEN COUNT(DISTINCT o.orderNumber) >= 1 AND DATEDIFF(CURDATE(), MAX(o.orderDate)) > 365 THEN '휴면 고객'
        ELSE '신규 고객'
    END AS customer_seg
FROM 
    customers AS c
LEFT JOIN orders AS o
    ON o.customerNumber = c.customerNumber
LEFT JOIN orderdetails AS od
    ON o.orderNumber = od.orderNumber
GROUP BY c.customerNumber, c.customerName;