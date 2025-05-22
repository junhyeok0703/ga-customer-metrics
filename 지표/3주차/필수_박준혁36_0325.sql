#### 필수과제1 
#### 제품을 기준으로 여러분이 중요하게 생각하는 지표를 5개 이상은 만들어서 쿼리로 추출해 주세요! 
#### 본인이 생각하는 마트의 쿼리와 검증쿼리까지 비교해서 수치 검증 완료된 것도 같이 공유 주세요!!
#### 검증쿼리에 대한 설명까지도 적어주셔야 합니다!!!

-- 제품 : 총판매금액(매출),총판매량,
-- 지표1. 총 판매 금액,총 판매량
-- USE classicmodels;
WITH sales_summary AS (
    -- 제품별 총 판매 금액 & 총 판매량 계산
    SELECT 
        p.productCode, 
        p.productName, 
        SUM(od.quantityOrdered * od.priceEach) AS total_sales,
        SUM(od.quantityOrdered) AS quantity_sold
    FROM orderdetails od
    JOIN products p ON od.productCode = p.productCode
    GROUP BY p.productCode, p.productName
),
aov AS (
    -- 제품별 평균 주문 금액 (AOV) 계산
    SELECT 
        p.productCode, 
        AVG(od.quantityOrdered * od.priceEach) AS avg_order_value
    FROM orderdetails od
    JOIN products p ON od.productCode = p.productCode
    GROUP BY p.productCode
),
repurchase AS (
    -- 제품별 재구매율 계산
    WITH repurchase_count AS (
        SELECT 
            o.customerNumber, 
            od.productCode, 
            COUNT(DISTINCT o.orderNumber) AS num_orders
        FROM orders o
        JOIN orderdetails od ON o.orderNumber = od.orderNumber
        GROUP BY o.customerNumber, od.productCode
        HAVING num_orders > 1
    )
    SELECT 
        p.productCode, 
        COUNT(DISTINCT r.customerNumber) / COUNT(DISTINCT o.customerNumber) AS repurchase_rate
    FROM orderdetails od
    JOIN products p ON od.productCode = p.productCode
    JOIN orders o ON od.orderNumber = o.orderNumber
    LEFT JOIN repurchase_count r ON od.productCode = r.productCode
    GROUP BY p.productCode
),
inventory_turnover AS (
    -- 제품별 재고 회전율 계산
    SELECT 
        p.productCode, 
        SUM(od.quantityOrdered) / NULLIF(p.quantityInStock, 0) AS inventory_turnover
    FROM orderdetails od
    JOIN products p ON od.productCode = p.productCode
    GROUP BY p.productCode
)

-- 최종 데이터 마트 테이블 생성
SELECT 
    s.productCode, 
    s.productName, 
    s.total_sales, 
    s.quantity_sold, 
    a.avg_order_value, 
    r.repurchase_rate, 
    i.inventory_turnover
FROM sales_summary s
LEFT JOIN aov a ON s.productCode = a.productCode
LEFT JOIN repurchase r ON s.productCode = r.productCode
LEFT JOIN inventory_turnover i ON s.productCode = i.productCode;

# 검증쿼리
-- 1. 총 판매 금액 (Total Sales) 검증 쿼리
-- 제품별로 총 판매 금액을 계산하는 쿼리
-- 주문 세부사항에서 제품 코드별로 판매 금액을 합산한 값이 원본 쿼리에서 계산한 총 판매 금액(total_sales)과 일치하는지 확인
SELECT 
    p.productCode,  -- 제품 코드
    p.productName,  -- 제품 이름
    SUM(od.quantityOrdered * od.priceEach) AS total_sales  -- 총 판매 금액 (수량 * 단가 합산)
FROM orderdetails od
JOIN products p ON od.productCode = p.productCode  -- 주문 세부사항과 제품 정보를 연결
GROUP BY p.productCode, p.productName;  -- 제품 코드와 이름으로 그룹화하여 계산

-- 2. 총 판매량 (Total Quantity Sold) 검증 쿼리
-- 제품별로 총 판매 수량을 계산하는 쿼리
-- 주문 세부사항에서 제품 코드별로 판매된 수량을 합산한 값이 원본 쿼리에서 계산한 총 판매량(quantity_sold)과 일치하는지 확인
SELECT 
    p.productCode,  -- 제품 코드
    p.productName,  -- 제품 이름
    SUM(od.quantityOrdered) AS total_quantity_sold  -- 총 판매 수량 (수량 합산)
FROM orderdetails od
JOIN products p ON od.productCode = p.productCode  -- 주문 세부사항과 제품 정보를 연결
GROUP BY p.productCode, p.productName;  -- 제품 코드와 이름으로 그룹화하여 계산
-- 3.  평균 주문 금액 (AOV, Average Order Value) 검증 쿼리
-- 제품별 평균 주문 금액(AOV)을 계산하는 쿼리
-- 각 제품에 대해 주문 세부사항에서 `quantityOrdered * priceEach`의 평균값을 구한 것이 원본 쿼리에서 계산한 `avg_order_value`와 일치하는지 확인
SELECT 
    p.productCode,  -- 제품 코드
    AVG(od.quantityOrdered * od.priceEach) AS avg_order_value  -- 평균 주문 금액 (수량 * 단가 평균)
FROM orderdetails od
JOIN products p ON od.productCode = p.productCode  -- 주문 세부사항과 제품 정보를 연결
GROUP BY p.productCode;  -- 제품 코드별로 그룹화하여 계산
-- 4.재구매율 (Repurchase Rate) 검증 쿼리
-- 재구매율을 계산하는 쿼리
-- 재구매를 한 고객들의 비율을 계산
-- 먼저 각 제품에 대해 고객이 두 번 이상 주문한 횟수를 세고, 그 고객들의 비율을 계산하여 원본 쿼리에서 계산한 `repurchase_rate`와 비교
WITH repurchase_count AS (
    SELECT 
        o.customerNumber,  -- 고객 번호
        od.productCode,  -- 제품 코드
        COUNT(DISTINCT o.orderNumber) AS num_orders  -- 고객이 주문한 횟수
    FROM orders o
    JOIN orderdetails od ON o.orderNumber = od.orderNumber  -- 주문과 주문 세부사항을 연결
    GROUP BY o.customerNumber, od.productCode  -- 고객 번호와 제품 코드별로 그룹화
    HAVING num_orders > 1  -- 2회 이상 주문한 고객만 필터링
)
SELECT 
    p.productCode,  -- 제품 코드
    COUNT(DISTINCT r.customerNumber) / COUNT(DISTINCT o.customerNumber) AS repurchase_rate  -- 재구매율 (재구매한 고객 수 / 전체 고객 수)
FROM orderdetails od
JOIN products p ON od.productCode = p.productCode  -- 주문 세부사항과 제품 정보를 연결
JOIN orders o ON od.orderNumber = o.orderNumber  -- 주문과 주문 세부사항을 연결
LEFT JOIN repurchase_count r ON od.productCode = r.productCode  -- 재구매한 고객들을 LEFT JOIN으로 연결
GROUP BY p.productCode;  -- 제품 코드별로 그룹화하여 계산
-- 5. 재고 회전율 (Inventory Turnover) 검증 쿼리
-- 제품별 재고 회전율을 계산하는 쿼리
-- 재고 회전율은 제품의 총 판매량을 제품의 재고 수량으로 나누어 계산
-- 원본 쿼리에서 계산한 `inventory_turnover`와 일치하는지 확인
SELECT 
    p.productCode,  -- 제품 코드
    SUM(od.quantityOrdered) / NULLIF(p.quantityInStock, 0) AS inventory_turnover  -- 재고 회전율 (판매된 수량 / 재고 수량)
FROM orderdetails od
JOIN products p ON od.productCode = p.productCode  -- 주문 세부사항과 제품 정보를 연결
GROUP BY p.productCode;  -- 제품 코드별로 그룹화하여 계산

