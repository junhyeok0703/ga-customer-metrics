# 250327 복습과제 
### CTE1. 고객별의 첫 구매와 마지막 구매 날짜 등을 메타로 만든 테이블 
### CTE2. 고객별 주문 요약한 테이블 
### CTE3. CLV, 고객 충성도, 세그먼트 관련해서 필요
### CTE4. 재구매율, 장바구니, 신규고객  등등

With first_last_orders As(
	select 
		customerNumber,
        min(orderDate) as first_order_date,
        max(orderDate) as last_order_date
	from orders
    group by 
		customerNumber
),
purchase_summary as (
	select 
		o.customerNumber,
        count(o.orderNumber) as total_orders, # 총 구매 수
        sum(od.priceEach * od.quantityOrdered) as total_sales, # 총 구매액
        avg(od.priceEach * od.quantityOrdered) as AOV, # 평균 구매액
        count(o.orderNumber) / nullif(timestampdiff(Month, Min(o.orderDate), curdate()),0) as purcahse_frequency  
        #두 날짜 간의 차이를 계산합니다. 여기서는 Min(o.orderDate)와 현재 날짜(curdate()) 간의 차이를 월 단위로 계산
	from orders as o
    join orderdetails as od on o.orderNumber = od.orderNumber
    group by o.customerNumber
),
customer_loyalty as (
select
	o.customerNumber,
    case when count(o.orderNumber) >1 then 1 else 0 end repeat_customer,## 재구매 같은 경우는 어떤 식으로 코드로 구현하면 되나~?
	sum(od.quantityOrdered * od.priceEach) * count(o.orderDate) / count(distinct year(o.orderDate)) as CLV, 
    # 실제 구매한 금액 고객별로 존재 월단위 특정 기간 단위 간단하게 나눠서 고객생애가치 활성화고객 6개월 이내 구매했는지 (활동고객 1, 아니면 0)
	case when max(o.orderDate) >= date_sub(curdate(), interval 6 month) then 1 else 0 end active_last_6_months #현재 날짜(curdate())에서 6개월을 뺀 날짜를 계산현재 날짜(curdate())에서 6개월을 뺀 날짜를 계산
    ## 이탈 여부도 동일하게 할 수 있다. 
from
	orders o 
join 
	orderdetails as od on o.orderNumber = od.orderNumber
group by o.customerNumber
),
new_customers as (
	select
    o.customerNumber,
    ## 최근 6개월 내에 첫 구매 했느냐?!
    case when min(o.orderDate) >= date_sub(curdate(), interval 6 month) then 1 else 0 end new_customer,
    count(o.orderNumber)> 1 as repeat_purchase_rate,
    sum(od.quantityOrdered) / count(o.orderNumber) as avg_basket_size
    from
		orders as o 
	join
		orderdetails as od
	group by o.customerNumber
)
select 
	c.customerNumber,
    c.customerName,
    c.country,
    flo.first_order_date,
    flo.last_order_date,
    nc.avg_basket_size
from customers c
left join first_last_orders flo on c.customerNumber = flo.customerNumber
left join purchase_summary ps on c.customerNumber = ps.customerNumber
left join customer_loyalty cl on c.customerNumber = cl.customerNumber
left join new_customers nc on c.customerNumber = nc.customerNumber;

