use classicmodels;
#### 필수 과제 1
#### 위의 2개의 마트 쿼리를 검증해 주세요.
#### 명확한 검증 로직을 작성하고 -> 해당 값을 검증할 수 있는 코드와 함께 정리해서 주세요.
#### 둘다 모두 검증해야하고 예시는 최소 2개 이상씩 해야 합니다 -> 총 최소 4개 이상 진행

# 일별 주문 데이터 마트 검증
-- 검증 1: 특정 날짜의 총 매출 계산
-- 이 값은 첫 번째 쿼리의 해당 날짜 total_revenue와 일치해야 함
SELECT 
    o.orderDate,
    SUM(od.quantityOrdered * od.priceEach) AS manual_calculated_revenue
FROM 
    orders AS o
JOIN 
    orderdetails AS od ON o.orderNumber = od.orderNumber
WHERE 
    o.orderDate = '2003-01-06'  -- 검증을 위한 특정 날짜 선택
GROUP BY 
    o.orderDate;

-- 검증 2: 특정 날짜의 주문 수 계산
-- 이 값은 첫 번째 쿼리의 해당 날짜 total_orders와 일치해야 함
SELECT 
    o.orderDate,
    COUNT(DISTINCT o.orderNumber) AS manual_order_count
FROM 
    orders AS o
WHERE 
    o.orderDate = '2003-01-06'  -- 일관된 검증을 위해 동일한 날짜 사용
GROUP BY 
    o.orderDate;

-- 두 지표를 한 번에 비교하는 쿼리
SELECT 
    mart.orderDate,
    mart.total_revenue AS mart_revenue,
    validation.manual_calculated_revenue AS validated_revenue,
    mart.total_revenue - validation.manual_calculated_revenue AS revenue_difference,
    mart.total_orders AS mart_order_count,
    validation.manual_order_count AS validated_order_count,
    mart.total_orders - validation.manual_order_count AS order_count_difference
FROM 
    (SELECT 
        o.orderDate,
        SUM(od.quantityOrdered * od.priceEach) AS total_revenue,
        COUNT(DISTINCT o.orderNumber) AS total_orders
    FROM 
        orders AS o
    JOIN 
        orderdetails AS od ON od.orderNumber = o.orderNumber
    WHERE 
        o.orderDate = '2003-01-06'
    GROUP BY 
        o.orderDate) AS mart
JOIN 
    (SELECT 
        o.orderDate,
        SUM(od.quantityOrdered * od.priceEach) AS manual_calculated_revenue,
        COUNT(DISTINCT o.orderNumber) AS manual_order_count
    FROM 
        orders AS o
    JOIN 
        orderdetails AS od ON o.orderNumber = od.orderNumber
    WHERE 
        o.orderDate = '2003-01-06'
    GROUP BY 
        o.orderDate) AS validation
ON 
    mart.orderDate = validation.orderDate;
    
    
## 고객 데이터 마트 검증
-- 검증 3: 특정 고객의 총 매출 계산
-- 이 값은 두 번째 쿼리의 해당 고객 total_revenue와 일치해야 함
SELECT 
    c.customerNumber,
    c.customerName,
    COALESCE(SUM(od.quantityOrdered * od.priceEach), 0) AS manual_calculated_revenue
FROM 
    customers AS c
LEFT JOIN 
    orders AS o ON o.customerNumber = c.customerNumber
LEFT JOIN 
    orderdetails AS od ON od.orderNumber = o.orderNumber
WHERE 
    c.customerNumber = 103  -- 검증을 위한 특정 고객 선택
GROUP BY 
    c.customerNumber, c.customerName;

-- 검증 4: 특정 고객의 주문 수 계산
-- 이 값은 두 번째 쿼리의 해당 고객 total_orders와 일치해야 함
SELECT 
    c.customerNumber,
    c.customerName,
    COUNT(DISTINCT o.orderNumber) AS manual_order_count
FROM 
    customers AS c
LEFT JOIN 
    orders AS o ON o.customerNumber = c.customerNumber
WHERE 
    c.customerNumber = 103  -- 일관된 검증을 위해 동일한 고객 사용
GROUP BY 
    c.customerNumber, c.customerName;

-- 검증 5: 고객 세분화 로직
-- VIP 고객 세분화 로직을 검증합니다
SELECT 
    c.customerNumber,
    c.customerName,
    COUNT(DISTINCT o.orderNumber) AS total_orders,
    SUM(od.quantityOrdered * od.priceEach) AS total_revenue,
    CASE
        WHEN COUNT(DISTINCT o.orderNumber) > 20 AND SUM(od.quantityOrdered * od.priceEach) > 50000 THEN 'VIP 고객'
        WHEN COUNT(DISTINCT o.orderNumber) BETWEEN 5 AND 20 THEN '일반 고객'
        WHEN DATEDIFF(CURDATE(), MAX(o.orderDate)) > 365 THEN '휴면 고객'
        ELSE '미분류 고객'
    END AS calculated_segment
FROM 
    customers AS c
LEFT JOIN 
    orders AS o ON o.customerNumber = c.customerNumber
LEFT JOIN 
    orderdetails AS od ON od.orderNumber = o.orderNumber
WHERE 
    c.customerNumber = 141  -- VIP 고객일 가능성이 높은 고객 선택
GROUP BY 
    c.customerNumber, c.customerName;

-- 검증 6: 두 데이터 마트 결과 비교 (고객 세분화)
SELECT 
    mart.customerNumber,
    mart.customerName,
    mart.total_orders AS mart_order_count,
    validation.manual_order_count AS validated_order_count,
    mart.total_revenue AS mart_revenue,
    validation.manual_calculated_revenue AS validated_revenue,
    mart.customer_seg AS mart_segment,
    validation.calculated_segment AS validated_segment,
    CASE WHEN mart.customer_seg = validation.calculated_segment THEN '일치' ELSE '불일치' END AS segment_match
FROM 
    (SELECT 
        c.customerNumber,
        c.customerName,
        COUNT(DISTINCT o.orderNumber) AS total_orders,
        COALESCE(SUM(od.quantityOrdered * od.priceEach), 0) AS total_revenue,
        CASE
            WHEN COUNT(DISTINCT o.orderNumber) > 20 AND SUM(od.quantityOrdered * od.priceEach) > 50000 THEN 'VIP 고객'
            WHEN COUNT(DISTINCT o.orderNumber) BETWEEN 5 AND 20 THEN '일반 고객'
            WHEN DATEDIFF(CURDATE(), MAX(o.orderDate)) > 365 THEN '휴면 고객'
            ELSE '미분류 고객'
        END AS customer_seg
    FROM 
        customers AS c
    LEFT JOIN 
        orders AS o ON o.customerNumber = c.customerNumber
    LEFT JOIN 
        orderdetails AS od ON od.orderNumber = o.orderNumber
    WHERE 
        c.customerNumber IN (103, 141, 151, 161)  -- 다양한 고객 세그먼트를 포함하는 고객 선택
    GROUP BY 
        c.customerNumber, c.customerName) AS mart
JOIN 
    (SELECT 
        c.customerNumber,
        c.customerName,
        COUNT(DISTINCT o.orderNumber) AS manual_order_count,
        COALESCE(SUM(od.quantityOrdered * od.priceEach), 0) AS manual_calculated_revenue,
        CASE
            WHEN COUNT(DISTINCT o.orderNumber) > 20 AND SUM(od.quantityOrdered * od.priceEach) > 50000 THEN 'VIP 고객'
            WHEN COUNT(DISTINCT o.orderNumber) BETWEEN 5 AND 20 THEN '일반 고객'
            WHEN DATEDIFF(CURDATE(), MAX(o.orderDate)) > 365 THEN '휴면 고객'
            ELSE '미분류 고객'
        END AS calculated_segment
    FROM 
        customers AS c
    LEFT JOIN 
        orders AS o ON o.customerNumber = c.customerNumber
    LEFT JOIN 
        orderdetails AS od ON od.orderNumber = o.orderNumber
    WHERE 
        c.customerNumber IN (103, 141, 151, 161)  -- 동일한 고객 세트 사용
    GROUP BY 
        c.customerNumber, c.customerName) AS validation
ON 
    mart.customerNumber = validation.customerNumber;