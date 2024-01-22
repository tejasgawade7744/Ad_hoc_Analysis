/*   1. Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.  */

select * from dim_customer;

select distinct(market) from dim_customer
where customer in ('Atliq Exclusive') and region in ('APAC')
order by market;

/* What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */
select * from fact_gross_price;

with cte as (
select  distinct count(product_code) unique_product_2020 from fact_gross_price
where fiscal_year in (2020)
),
cte2 as (
select  distinct count(product_code) unique_product_2021  from fact_gross_price
where fiscal_year=2021
)
SELECT
    CTE.unique_product_2020,
    CTE2.unique_product_2021,
    concat(left(concat(((CTE2.unique_product_2021-CTE.unique_product_2020)/(CTE.unique_product_2020))*100),5),"%") AS Percent_changes
FROM
    CTE
JOIN
    CTE2 ON 1=1;

WITH CombinedCTE AS (
    SELECT
        (SELECT COUNT(DISTINCT product_code) FROM fact_gross_price WHERE fiscal_year = 2020) AS up2020,
        (SELECT COUNT(DISTINCT product_code) FROM fact_gross_price WHERE fiscal_year = 2021) AS up2021
)
-- Use the results from the combined CTE
SELECT up2020,up2021,  concat(left((concat(((up2021-up2020)/(up2020))*100)),5),"%")
FROM CombinedCTE;

/* Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count */
SELECT * FROM gdb023.dim_product;

select segment,  count( distinct product_code) unique_product_count from dim_product
group by segment
order by unique_product_count desc;

/* Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields */

SELECT * FROM gdb023.dim_product;
select segment, COUNT(DISTINCT product_code) from dim_product
group by segment;

with cte as(
select d.segment,count(distinct d.product_code) up_2020
from dim_product d join fact_gross_price f 
on d.product_code=f.product_code
where f.fiscal_year in (2020)
group by d.segment, f.fiscal_year
),
cte2 as (
select d.segment,count(distinct d.product_code) up_2021
from dim_product d join fact_gross_price f 
on d.product_code=f.product_code
where f.fiscal_year in (2021)
group by d.segment, f.fiscal_year
),
cte3 as (
select cte.segment, cte.up_2020 , cte2.up_2021,
(cte2.up_2021-cte.up_2020) as Difference 
 from cte join cte2 on 
 cte.segment=cte2.segment
)
select segment , up_2020, up_2021 , Difference from cte3
where up_2021 > up_2020
;
/* Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields, */
select  m.product_code,d.product, m.manufacturing_cost from dim_product d join fact_manufacturing_cost m
on d.product_code=m.product_code
where m.manufacturing_cost in (select max(manufacturing_cost) as min_price from fact_manufacturing_cost)
union
select m.product_code, d.product,m.manufacturing_cost from dim_product d join fact_manufacturing_cost m
on d.product_code=m.product_code
where m.manufacturing_cost in (select min(manufacturing_cost) as min_price from fact_manufacturing_cost);

/* Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields */

select c.customer_code, c.customer,max(p.pre_invoice_discount_pct) as avg_discount_percentage from dim_customer c join fact_pre_invoice_deductions p 
on c.customer_code=p.customer_code
where c.market="India" and p.fiscal_year=2021
group by c.customer_code,c.customer
order by avg_discount_percentage desc
limit 5;


/*In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity */

SELECT 
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then 1  
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then 2
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then 3
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then 4
    END AS Quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY total_sold_quantity DESC;

/*
    Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
 */
 
select c.channel , round(sum(gp.gross_price*sm.sold_quantity)) as "price" from dim_customer c join
fact_sales_monthly sm
on c.customer_code= sm.customer_code
join fact_gross_price gp
on gp.product_code=sm.product_code
where sm.fiscal_year=2021
group by c.channel
order by price desc;

/* 
Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code 
product
total_sold_quantity
rank_order */

WITH cte AS (
    SELECT
        dm.division,
        dm.product_code,
        dm.product,
        SUM(sm.sold_quantity) AS total_sold_quantity
    FROM
        dim_product dm
    JOIN fact_sales_monthly sm ON dm.product_code = sm.product_code
    WHERE
        sm.fiscal_year = 2021
    GROUP BY
        dm.division,
        dm.product_code,
        dm.product  -- Include missing columns in GROUP BY
),
cte2 AS (
    SELECT
        division,
        product_code,
        product,
        total_sold_quantity,
        ROW_NUMBER() OVER (PARTITION BY division ORDER BY total_sold_quantity DESC) AS ranks
    FROM
        cte
)
SELECT
    *
FROM
    cte2
WHERE
    ranks <= 3;
