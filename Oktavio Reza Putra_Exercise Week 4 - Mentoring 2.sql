set search_path to exercise_pacmann_week_4;

-- Case 1
-- Show the product IDs and product names 
-- that have been ordered more than once! 
-- Sorted by  product ID
select 
	product_id,
	product_name,
	count(order_id) as count_order
from 
	sales s
join
	products p 
using
	(product_id)
group by
	product_id,
	product_name
having 
	count(distinct order_id) > 1
order by 
	product_id
;
-- Flannel, Peacoat dan Bomber adalah Top 3 Produk yang di order paling banyak


-- Case 2
-- From question number 1, How many products have been ordered more than once?
with
	total_product
as
(
	select 
		product_id,
		product_name,
		count(order_id) as count_order
	from 
		sales s
	join
		products p 
	using
		(product_id)
	group by
		product_id,
		product_name
	having 
		count(order_id) > 1
	order by 
		product_id
)
select 
	count(product_name) as total_product_ordered_more_than_once
from
	total_product;
-- Ada Total 1,145 Produk yang dipesan lebih dari 1 kali


-- Case 3
-- From question number 2, How many products have only been ordered once?
with
	total_product
as
(
	select 
		product_id,
		product_name,
		count(order_id) as count_order
	from 
		sales s
	join
		products p 
	using
		(product_id)
	group by
		product_id,
		product_name
	having 
		count(order_id) = 1
	order by 
		product_id
)
select 
	count(product_name) as total_product_have_only_been_ordered_once
from
	total_product;
-- Ada 88 Produk yang di order hanya sekali saja


-- Case 4
-- list of customers who have placed orders more than twice in a single month. 
-- Manager need customer name and their address to give the customer special discount
with 
	customer_data
as 
(
	select 
		concat(extract (year from to_date(order_date::text, 'YYYY-MM'::text)),'-',
		to_char(extract (month from to_date(order_date::text, 'YYYY-MM'::text)),'FM00')) as month,
		extract (year from to_date(order_date::text, 'YYYY-MM'::text)) as year_order,
		extract (month from to_date(order_date::text, 'YYYY-MM'::text)) as month_order,
		customer_id,
		customer_name,
		home_address,
		count(order_id) as count_cust_order
	from 
		customers c
	join
		orders o
	using 
		(customer_id)
	group by
		month,
		year_order,
		month_order,
		customer_id,
		customer_name,
		home_address
	having 
		count(order_id) > 2
	order by
		month,
		customer_id
)
select 
	customer_id,
	customer_name,
	home_address,
	year_order,
	month_order,
	count_cust_order
from
	customer_data
order by
	customer_id;
-- Gorden Seago dan Ellyn Colacombe adalah customer yang melakukan order lebih dari 2 kali pada Bulan Agustus dan April tahun 2021
-- Sehingga 2 customer ini layak mendapatkan diskon


-- Case 5
-- Find the first and last order date of each customer. 
-- Show the first 10 data, sorted by customer ID
with 
	customer_first_last_order
as 
(
	select 
		order_date,
		customer_id,
		customer_name
	from 
		customers c
	join
		orders o
	using 
		(customer_id)
	order by
		customer_id,
		order_date
)
select 
	distinct customer_id,
	customer_name,
	first_value(order_date) over(partition by customer_id, customer_name order by order_date) as first_order,
	first_value(order_date) over(partition by customer_id, customer_name order by order_date desc) as last_order
from 
	customer_first_last_order
order by
	customer_id
limit 
	10;
-- Jika nilai first order dan last order sama, maka dapat dikatakan bahwa customer tersebut melakukan order hanya 1 kali
-- Oleh karena itu, supaya customer melakukan repeat order perusahaan bisa melakukan promosi berupa: 
-- 1. Voucher jika customer sudah melakukan belanja sebanyak n kali pada tanggal yang berbeda (Voucher nya bersifat bertingkat)
-- 2. Extra Diskon bagi customer dengan Pembelian minimal sekian dollar (Extra Diskon nya bersifat bertingkat)
-- 3. Promo Product Bundling cocok juga digunakan untuk Produk Pakaian sebagai langkah tepat untuk meningkatkan repeat order customer 


-- Case 6
-- Retrieve the top 5 customers who have spent the most amount of money on products within the “Trousers” category, 
-- including the customer's name, the quantity and total amount spent in this category. 
-- Additionally, find the total number of products sold in this category and calculate the average total price spent in this category, 
-- compare with the top 5 customers who have spent the most amount of money on products within the “Trousers” category . 
-- Finally, sort the results by the total amount spent in descending order.
with 
	trousers_transaction
as
(
	with 
		customer_order
	as 
	(
		select 
			customer_id,
			customer_name,
			order_id
		from 
			customers c
		join
			orders o
		using 
			(customer_id)
		order by
			customer_id,
			order_id
	)
	select 
		customer_id,
		customer_name,
		total_all_qty,
		avg_total_amount_spend,
		sum(t2.quantity) as quantity_order,
		sum(t2.total_price) as total_amount_spend
	from 
		customer_order t1	
	join
		(
			select
				order_id,
				product_type,
				product_name,
				s.price_per_unit,
				s.quantity,
				sum(s.quantity) over() as total_all_qty,
				avg(s.total_price) over() as avg_total_amount_spend,
				total_price
			from 
				sales s
			join
				products p
			using
				(product_id)
			where 
				product_type = 'Trousers'
		) as t2
	using
		(order_id)
	group by 
		customer_id,
		customer_name,
		total_all_qty,
		avg_total_amount_spend
	order by 
		total_amount_spend desc
)
select 
	customer_name,
	quantity_order,
	total_all_qty,
	total_amount_spend,
	avg_total_amount_spend
from 
	trousers_transaction
limit
	5;
-- Rata-Rata Total Spending Customer untuk Trousers sebesar 202.71 dan 
-- Top 5 Spender Customer untuk Trousers berada di atas rata-rata tersebut.
-- Selain itu, total Quantity Order dari Top 5 Customer tersebut berkontribusi 3.66% dari keseluruhan penjualan (3,360)


-- Case 7
-- Find the top-selling (Top 1) product for each month. 
-- You want to know the product with the highest total quantity sold in each month. 
-- If there are products that have the same total quantity sold, choose the smallest product ID. 
-- Return the product name, the corresponding month, and the total quantity sold for each month's top-selling product. 
-- Sorted by month
with 
	highest_qty
as 
(
	with 
		product_rank
	as 
	(
		with 
			table_product
		as 
		(
			select 
				extract(year from to_date(order_date::text, 'YYYY-MM'::text)) as year_order,
				extract(month from to_date(order_date::text, 'YYYY-MM'::text)) as month_order,
				product_id,
				product_type,
				product_name,
				sum(quantity) as total_quantity_sold
			from
				orders o
			join
				(
					select
						product_id,
						order_id,
						product_type,
						product_name,
						s.quantity
					from 
						sales s
					join
						products p
					using
						(product_id)
				) s
			using
				(order_id)
			group by
				year_order,
				month_order,
				product_id,
				product_name,
				product_type,
				product_name
			order by 
				year_order,
				month_order,
				total_quantity_sold desc
		)
		select 
			*,
			dense_rank() over(partition by year_order, month_order order by total_quantity_sold desc) as rank_qty_sold
		from 
			table_product
	)
	select
		*,
		min(product_id) over(partition by year_order, month_order) as product_id_min
	from 
		product_rank
	where 
		rank_qty_sold = 1
)
select 
	month_order,
	year_order,
	product_id,
	product_name,
	total_quantity_sold
from 
	highest_qty
where 
	product_id = product_id_min
order by 
	year_order,
	month_order;
-- Penjualan terbesar terjadi di bulan Mei 2021 untuk Produk Coach (ID 650) sebanyak 11 Produk
-- jika dibandingkan dengan Penjualan Produk terbanyak setiap bulannya

-- Case 8
-- Create a view to store a query for calculating monthly total payment.
create view 
 	monthly_total_payment
 as
 select 
  	 extract(month from to_date((o.order_date)::text, 'yyyy-mm'::text)) as sale_month,
     extract(year from to_date((o.order_date)::text, 'yyyy-mm'::text)) as sale_year,
     sum(o.payment) as total_transaction_amount
 from 
 	orders o
 group by 
 	(extract(month from to_date((o.order_date)::text, 'yyyy-mm'::text))), 
 	(extract(year from to_date((o.order_date)::text, 'yyyy-mm'::text)))
 order by 
 	(extract(month from to_date((o.order_date)::text, 'yyyy-mm'::text))), 
 	(extract(year from to_date((o.order_date)::text, 'yyyy-mm'::text)));

-- Calculate Transaction Amount Growth MoM (%)
with
	trx_amount_growth
as
(
	select 
		concat(sale_year,'-',sale_month) as year_month,
		sale_year,
		sale_month,
		total_transaction_amount
	from 
		monthly_total_payment
	order by
		sale_year,
		sale_month
)
select 
	year_month,
	total_transaction_amount,
	case 
		when 
			lag(total_transaction_amount) over(order by sale_year, sale_month) is null 
			then
				0 
			else 
				round(((total_transaction_amount - lag(total_transaction_amount) over(order by year_month)) / 
				lag(total_transaction_amount) over(order by year_month)::numeric) * 100, 2)  
	end as transaction_amount_growth	
from 
	trx_amount_growth;
-- Case 9
-- As a warehouse manager responsible for stock management in your company's warehouse, 
-- oversee a warehouse with a total area of 600,000 sq ft. 
-- There are two types of items: prime items and non-prime items. 
-- These items come in various sizes, with priority given to prime items. 

-- Your task is to determine the maximum number of prime and non-prime items that can be stored in the warehouse
-- Prime and non-prime items are stored in their respective containers. 

-- For example, In the database, there are 15 non-prime items and 35 prime items. 
-- Each prime container must contain 35 prime items, and each non-prime container must contain 15 non-prime items
-- Non-prime items must always be available in stock to meet customer demand, so the non-prime item count should never be zero.
-- Define the total warehouse area and container capacities
with
	max_item_stored
as
(
	select
		count(case 
				when
					is_prime=true
					then
						item_name
				end) as total_prime_item,
		count(case
				when
					is_prime = false
					then
						item_name
				end) as total_non_prime_item,
		sum(case
				when
					is_prime=true
					then
						item_size_sqft
				end) as total_prime_size_area,
		sum(case
				when
					is_prime = false
					then
						item_size_sqft
				end) as total_non_prime_size_area
	from
		item
)
	select
		'prime' as item_type,
		floor(600000/total_prime_size_area) * total_prime_item as count_item  
	from
		max_item_stored
union all
	select
		'non-prime' as item_type,
		floor((600000 - ((600000/total_prime_size_area) * total_prime_size_area))/total_non_prime_size_area) * total_non_prime_item as count_item
	from
		max_item_stored;
-- Total Item Prime yang dapat disimpan ada 735 item (21 Kontainer dengan Luas 28,040 sqft per Kontainer) 
-- Total Item Non-Prime yang dapat disimpan ada 30 item (2 Kontainer dengan Luas 5,500 sqft per Kontainer)
-- Sehingga untuk menyimpan seluruh Jumlah Item minimum Item Prime dan Non-Prime membutuhkan 23 Kontainer untuk Luas Warehouse 600,000 sqft (588,840 sqft untuk Prime Item dan 11,160 sqft untuk Non-Prime Item)


-- Case 10
-- The warehouse manager is planning to find a new warehouse to store their products. 
-- The warehouse is expected to accommodate 20 containers for each prime and non-prime item. 
-- What is the minimum required size for the warehouse?
with 
	minimum_size_area_required
as 
(
	with 
	 	total_size_item_category
	 as 
	 (
		select 
			item_id,
			item_name,
			item_size_sqft,
			sum(item_size_sqft) over(partition by is_prime order by is_prime desc) as total_item_size_sqft,
			case
				when 
					is_prime = true 
					then
						'prime'
					else 
						'non-prime'
			end as 
				item_category	
			from 
				item
	 )
	 select
	 	distinct item_category,
	 	total_item_size_sqft,
	 	20 as expected_container,
	 	total_item_size_sqft * 20 as expected_minimum_size_area
	 from
	 	total_size_item_category
)
select
	sum(expected_minimum_size_area) as total_warehouse_area
from
	minimum_size_area_required;
-- Luas Area Warehouse minimum sekitar 670,800 sqft untuk menyimpan item prime dan non-prime 
-- dengan 20 kontainer untuk Prime Item (Dengan Luas Total 28,040 sqft per kontainer) dengan Luas Minimum Warehouse 560,800 sqft
-- dan 20 kontainer untuk Non-Prime Item (Dengan Luas Total 5,550 sqft per kontainer) dengan Luas Minimum Warehouse 110,000 sqft