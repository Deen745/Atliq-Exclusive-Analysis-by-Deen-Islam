use gdb023;

-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.

select market 
from dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC';




-- 2. What is the percentage of unique product increase in 2021 vs. 2020? 
-- The final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg


with FY_2020 as (select fiscal_year,
		count(DISTINCT product_code) as unique_products_2020
from fact_sales_monthly
where fiscal_year = 2020),

FY_2021 as(
select fiscal_year,
		count(DISTINCT product_code) as unique_products_2021
from fact_sales_monthly
where fiscal_year = 2021
)
select unique_products_2020, unique_products_2021,
((unique_products_2021 - unique_products_2020)/ (unique_products_2020) * 100) as PCT_change
from FY_2020
cross join FY_2021;


-- 3. Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

select * from dim_product
limit 10;

select segment, count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;

-- Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference


select a.segment,
count(distinct case when b.fiscal_year = 2020 then a.product_code end) as product_count_2020,
count(distinct case when b.fiscal_year = 2021 then a.product_code end) as product_count_2021,
(count(distinct case when b.fiscal_year = 2021 then a.product_code end) -
count(distinct case when b.fiscal_year = 2020 then a.product_code end)) as difference

from dim_product as a
join fact_sales_monthly as b on a.product_code = b.product_code
group by a.segment
order by difference desc;

-- 5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost

select a.product_code, b.product, a.manufacturing_cost
from fact_manufacturing_cost as a
join dim_product as b on a.product_code = b.product_code
where a.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)
UNION -- FULL JOIN
select a.product_code, b.product, a.manufacturing_cost
from fact_manufacturing_cost as a
join dim_product as b on a.product_code = b.product_code
where a.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost);


-- 6. Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

with cte1 as (
select a.customer_code, 
		a.customer, 
		a.market, 
		b.fiscal_year, 
        b.pre_invoice_discount_pct
from dim_customer as a
join fact_pre_invoice_deductions as b on a.customer_code = b.customer_code
),
cte2 as (
select customer_code, customer, market, 
		avg(pre_invoice_discount_pct) as average_discount
        from cte1
        where fiscal_year = 2021 and market = 'India'
        group by customer_code, customer, market
)
select customer_code, customer, round(average_discount*100, 2) as average_discount
from cte2
order by average_discount desc
limit 5;


-- 7. Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

-- gross sales = gross price * sold quantity


with cte1 as (
select a.customer_code, a.customer, 
		b.date, b.product_code, b.fiscal_year, b.sold_quantity
from dim_customer as a
join fact_sales_monthly as b on a.customer_code = b.customer_code
where customer = 'Atliq Exclusive'
),
cte2 as (
select a.customer_code, a.customer, a.date, a.product_code, a.fiscal_year, a.sold_quantity,
		b.gross_price
        from cte1 as a
        join fact_gross_price as b on a.product_code = b.product_code)
        
select monthname(date) as Month,
		fiscal_year,
        sum(gross_price * sold_quantity) as total_gross_sales
from cte2
group by Month, fiscal_year;


-- 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity

-- sept - nov = 1st
-- dec - feb = 2nd
-- mar - may = 3rd
-- jun - aug = 4th

select case 
	when date between '2019-09-01' and '2019-12-01' then 1
    when date between '2019-12-01' and '2020-3-01' then 2
    when date between '2020-03-01' and '2020-06-01' then 3
    when date between '2020-06-01' and '2020-09-01' then 4
    end as Quarters,
    
    sum(sold_quantity) as total_sold_quantity
    from fact_sales_monthly
    where fiscal_year = 2020
    group by quarters
    order by total_sold_quantity desc;
    






























