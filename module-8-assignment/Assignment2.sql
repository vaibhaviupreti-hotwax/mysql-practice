-- SQL Assignment 2 Consolidated Queries

-- 5.1 Shipping Addresses for October 2023 Orders
SELECT
    oh.order_id, or2.party_id, CONCAT(p.first_name, ' ', p.last_name) as customer_name,
    pa.address1 as street_address, pa.city, pa.state_province_geo_id as state_province, pa.postal_code, pa.country_geo_id as country_code,
    os.status_id as order_status, oh.order_date
FROM order_header oh
JOIN order_status os ON oh.order_id = os.order_id AND (os.status_id = 'ORDER_CREATED' OR os.status_id = 'ORDER_COMPLETED')
AND os.status_datetime >= '2023-10-01' AND os.status_datetime < '2023-11-01'
JOIN order_role or2 ON oh.order_id = or2.order_id AND or2.role_type_id = 'PLACING_CUSTOMER'
JOIN person p ON or2.party_id = p.party_id
JOIN order_contact_mech ocm ON oh.order_id = ocm.order_id AND ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
JOIN postal_address pa ON ocm.contact_mech_id = pa.contact_mech_id;


-- 5.2 Orders from New York
SELECT
    oh.order_id, CONCAT(p.first_name, ' ', p.last_name) as customer_name,
    pa.address1 as street_address, pa.city, pa.state_province_geo_id as state_province, pa.postal_code, oh.grand_total as total_amount, oh.order_date, oh.status_id as order_status
FROM order_header oh
JOIN order_role or2 ON oh.order_id = or2.order_id AND or2.role_type_id = 'PLACING_CUSTOMER'
JOIN person p ON or2.party_id = p.party_id
JOIN order_contact_mech ocm ON oh.order_id = ocm.order_id AND ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
JOIN postal_address pa ON ocm.contact_mech_id = pa.contact_mech_id
LEFT JOIN geo g ON pa.state_province_geo_id = g.geo_id
WHERE pa.city = 'New York' OR g.geo_name = 'New York';


-- 5.3 Top-Selling Product in New York
WITH product_sales AS (
    SELECT p.product_id, p.internal_name, SUM(oi.quantity) as total_quantity_sold, pa.city, pa.state_province_geo_id as state, SUM(oi.unit_price * oi.quantity) as revenue
    FROM order_header oh
    JOIN order_item oi ON oh.order_id = oi.order_id
    JOIN product p ON oi.product_id = p.product_id
    JOIN order_contact_mech ocm ON oh.order_id = ocm.order_id AND ocm.contact_mech_purpose_type_id = 'SHIPPING_LOCATION'
    JOIN postal_address pa ON ocm.contact_mech_id = pa.contact_mech_id
    LEFT JOIN geo g ON pa.state_province_geo_id = g.geo_id
    WHERE oh.order_type_id = 'SALES_ORDER' AND (pa.city = 'New York' OR g.geo_name = 'New York')
    GROUP BY p.product_id, p.internal_name, pa.city, pa.state_province_geo_id
)
SELECT * FROM product_sales ORDER BY total_quantity_sold DESC LIMIT 1;


-- 7.3 Store-Specific (Facility-Wise) Revenue
SELECT f.facility_id, f.facility_name, COUNT(DISTINCT oh.order_id) as total_orders, SUM(oh.grand_total) as total_revenue,
CONCAT(MIN(oh.order_date), ' to ', MAX(oh.order_date)) as date_range
FROM order_header oh
JOIN order_item_ship_group oisg ON oh.order_id = oisg.order_id
JOIN facility f ON oisg.facility_id = f.facility_id
WHERE oh.order_type_id = 'SALES_ORDER'
GROUP BY f.facility_id, f.facility_name;


-- 8.1 Lost and Damaged Inventory
SELECT ii.inventory_item_id, ii.product_id, ii.facility_id, (iiv.quantity_on_hand_var * -1) as quantity_lost_or_damaged,
iiv.variance_reason_id as reason_code, iiv.created_tx_stamp as transaction_date
FROM inventory_item ii
JOIN inventory_item_variance iiv ON ii.inventory_item_id = iiv.inventory_item_id
WHERE iiv.variance_reason_id IN ('VAR_LOST', 'VAR_DAMAGED', 'EXPIRED');


-- 8.2 Low Stock or Out of Stock Items Report
SELECT p.product_id, p.internal_name as product_name, pf.facility_id,
ii.quantity_on_hand_total as QOH, ii.available_to_promise_total as ATP, pf.minimum_stock as reorder_threshold, CURRENT_DATE() as date_checked
FROM product p
JOIN product_facility pf ON p.product_id = pf.product_id
LEFT JOIN inventory_item ii ON p.product_id = ii.product_id AND pf.facility_id = ii.facility_id
WHERE ii.available_to_promise_total <= pf.minimum_stock OR ii.available_to_promise_total IS NULL OR ii.available_to_promise_total = 0;


-- 8.3 Retrieve the Current Facility (Physical or Virtual) of Open Orders
SELECT oh.order_id, oh.status_id as order_status, oisg.facility_id, f.facility_name, f.facility_type_id
FROM order_header oh
JOIN order_item_ship_group oisg ON oh.order_id = oisg.order_id
JOIN facility f ON oisg.facility_id = f.facility_id
WHERE oh.status_id NOT IN ('ORDER_COMPLETED', 'ORDER_CANCELLED', 'ORDER_REJECTED')
GROUP BY oh.order_id, oh.status_id, oisg.facility_id, f.facility_name, f.facility_type_id;


-- 8.4 Items Where QOH and ATP Differ
SELECT product_id, facility_id, quantity_on_hand_total as QOH, available_to_promise_total as ATP,
(quantity_on_hand_total - available_to_promise_total) as difference
FROM inventory_item
WHERE quantity_on_hand_total != available_to_promise_total;


-- 8.5 Order Item Current Status Changed Date-Time
SELECT oh.order_id, oi.order_item_seq_id, os.status_id as current_status_id,
os.status_datetime as status_change_datetime, os.status_user_login as changed_by
FROM order_header oh
JOIN order_item oi ON oh.order_id = oi.order_id
JOIN order_status os ON oh.order_id = os.order_id AND oi.order_item_seq_id = os.order_item_seq_id;


-- 8.6 Total Orders by Sales Channel
SELECT oh.sales_channel_enum_id as sales_channel, COUNT(DISTINCT oh.order_id) as total_orders,
SUM(oh.grand_total) as total_revenue, CONCAT(MIN(oh.order_date), ' to ', MAX(oh.order_date)) as reporting_period
FROM order_header oh
WHERE oh.order_type_id = 'SALES_ORDER' AND oh.sales_channel_enum_id IS NOT NULL
GROUP BY oh.sales_channel_enum_id;
