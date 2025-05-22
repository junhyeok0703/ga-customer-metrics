
use classicmodels;
SELECT * from customers;
SELECT * from orders;
SELECT * from products;
SELECT * from orderdetails;
# 지표를 설계해야 한다.
# 매출
## 중요한 지표가 무엇일까?
## 크게 전사의 차원에서 지표를 본다.
## 총 매출 , 총 주문 수, 총 판매된 수량, 주문당 평균 매출(객단가랑다르다), 주문당 평균 수량, 해당 날짜의 주문한 고객수
## 데이터마트 -> 이러한 지표들을 모아두는 느낌?

## 어떤 데이터를 합치면 좋을까? 
## 항상 필요한 일자기준 yyyymmdd 날짜는 꼭필요하다. ord_ymd,ord_ym 두개의컬럼을 만든다
# 전체 주문 테이블
select
	o.orderDate,
    sum(od.quantityOrdered * od.priceEach) as total_revenue, # 총매출
    count(distinct o.orderNumber) AS total_orders,## 주문수 
    sum(od.quantityOrdered) AS total_quantity_sold, # 전체 판매된 수량
    count(distinct o.customerNumber) as ditinct_customers,
    round(sum(od.quantityOrdered * od.priceEach)/count(distinct o.orderNumber),2) AS avg_order_value, # 평균 매출액
    round(sum(od.quantityOrdered)/count(distinct o.orderNumber),2) # 주문당 평균 판매수량
from 
	orders as o
join orderdetails as od
on od.orderNumber = o.orderNumber
GROUP BY o.orderDate
order by 1;

#### 고객 (도메인에 따라 다름) - 고객테이블 - 마스터 테이블
#### 고객ID,고객명, 고객의 총 주문 횟수 , 고객의 주문금액, 고객의 평균 주문금액 , 마지막 주문 날짜, 마지막 주문 이후 경과된 일수, 고객 등급(우리가 정한 고객의등급)
#### 고객 등급 기준이 없다


select 
	c.customerNumber,
    c.customerName,
    count(distinct o.orderNumber) as total_orders, 
    coalesce(sum(od.quantityOrdered * od.priceEach),0) as total_revenue, 
    coalesce(round(sum(od.quantityOrdered * od.priceEach) / nullif(count(distinct o.orderNumber), 0),2),0) as avg_order_value,
    max(o.orderDate) as last_order_date,
    datediff(curdate(), max(o.orderDate)) as day_since_last_order,
    case
		when count(distinct o.orderNumber) > 20 and sum(od.quantityOrdered * od.priceEach) > 50000 then 'VIP 고객'
        when count(distinct o.orderNumber) between 5 and 20 then '일반 고객'
		when datediff(curdate(), max(o.orderDate)) > 365 then '휴면 고객'
	end as customer_seg
from 
    customers as c
left join orders as o on o.customerNumber = c.customerNumber
left join orderdetails as od on od.orderNumber = o.orderNumber    
group by c.customerNumber;

#### 고객 50000 vip, 주문수 10개 이상
#### 주문 5~20개 정도는 일반 고객
#### 최근 주문한 날짜와 차이를 365 이상인 경우 '휴면 고객'

#### 필수 과제 1
#### 위의 2개의 마트 쿼리를 검증해 주세요.
#### 명확한 검증 로직을 작성하고 -> 해당 값을 검증할 수 있는 코드와 함께 정리해서 주세요.
#### 둘다 모두 검증해야하고 예시는 최소 2개 이상씩 해야 합니다 -> 총 최소 4개 이상 진행
# 총 매출 검증
select
    o.orderDate,
    sum(od.quantityOrdered * od.priceEach) as total_revenue
from 
    orders as o
join orderdetails as od
    on od.orderNumber = o.orderNumber
group by o.orderDate
order by 1;
# 총 주문수 검증 - orderDate별로 주문 수가 정확히 집계되는지 확인합니다.
select
    o.orderDate,
    count(distinct o.orderNumber) AS total_orders
from 
    orders as o
join orderdetails as od
    on od.orderNumber = o.orderNumber
group by o.orderDate
order by 1;

# 고객별 총 매출 검증 - coalesce 함수가 정상적으로 작동하는지, 즉, 주문 내역이 없는 고객의 total_revenue가 0으로 계산되는지 확인합니다.

SELECT 
    c.customerNumber,
    c.customerName,
    COUNT(DISTINCT o.orderNumber) AS total_orders, 
    COALESCE(SUM(od.quantityOrdered * od.priceEach), 0) AS total_revenue, 
    COALESCE(ROUND(SUM(od.quantityOrdered * od.priceEach) / NULLIF(COUNT(DISTINCT o.orderNumber), 0), 2), 0) AS avg_order_value,
    MAX(o.orderDate) AS last_order_date,
    DATEDIFF(CURDATE(), MAX(o.orderDate)) AS day_since_last_order,
    CASE
        WHEN COUNT(DISTINCT o.orderNumber) > 20 AND SUM(od.quantityOrdered * od.priceEach) > 50000 THEN 'VIP 고객'
        WHEN COUNT(DISTINCT o.orderNumber) BETWEEN 5 AND 20 THEN '일반 고객'
        WHEN DATEDIFF(CURDATE(), MAX(o.orderDate)) > 365 THEN '휴면 고객'
        ELSE '신규 고객'
    END AS customer_seg
FROM 
    customers AS c
LEFT JOIN orders AS o ON o.customerNumber = c.customerNumber
LEFT JOIN orderdetails AS od ON od.orderNumber = o.orderNumber    
GROUP BY c.customerNumber, c.customerName;

# 고객 등급 계산 (customer_seg) 검증
select 
    c.customerNumber,
    c.customerName,
    count(distinct o.orderNumber) AS total_orders,
    coalesce(sum(od.quantityOrdered * od.priceEach), 0) as total_revenue,
    max(o.orderDate) as last_order_date,
    datediff(curdate(), max(o.orderDate)) as day_since_last_order,
    CASE 
        WHEN count(distinct o.orderNumber) > 20 and sum(od.quantityOrdered * od.priceEach) > 50000 then 'VIP 고객'
        WHEN count(distinct o.orderNumber) between 5 and 20 then '일반 고객'
        WHEN datediff(curdate(), max(o.orderDate)) > 365 then '휴면 고객'
    END as customer_seg
from 
    customers as c
left join orders as o
    on o.customerNumber = c.customerNumber
left join orderdetails as od
    on o.orderNumber = od.orderNumber
group by c.customerNumber;

#### 필수과제2
#### 고객의 세그먼트를 새롭게 나눠 주세요.
#### 5등급으로 나눠서 (직접 여러분들이 데이터를 보고 설계하시면 됩니다.) 5개의 등급의 고객 세그먼트가 나올 수 있게 만들어 주시면 됩니다.
#### 수업 때는 3개 했지만 실제 5개까지 진행하고 모두 로직상 겹치지 않게 최대한 다 세그먼트로 나뉠 수 있도록 지정해 주세요!

-- VIP 고객: 주문 수 10회 이상, 총 매출 500,000 이상
-- 우수 고객: 주문 수 7회 이상, 총 매출 300,000 이상
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