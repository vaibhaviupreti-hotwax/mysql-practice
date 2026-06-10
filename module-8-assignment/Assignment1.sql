-- SQL Assignment 1 Consolidated Queries

-- 1 New Customers Acquired in June 2023
SELECT
    p.party_id,
    p.first_name,
    p.last_name,
    email.info_string AS email,
    tn.contact_number AS phone,
    p.CREATED_STAMP as entry_date
FROM person p
JOIN party_role pr ON p.party_id = pr.party_id AND pr.role_type_id = 'CUSTOMER'
LEFT JOIN party_contact_mech pcm_email ON p.party_id = pcm_email.party_id
LEFT JOIN contact_mech email ON pcm_email.contact_mech_id = email.contact_mech_id AND email.contact_mech_type_id = 'EMAIL_ADDRESS'
LEFT JOIN party_contact_mech pcm_phone ON p.party_id = pcm_phone.party_id
LEFT JOIN telecom_number tn ON pcm_phone.contact_mech_id = tn.contact_mech_id
WHERE p.created_stamp >= '2023-06-01' AND p.created_stamp < '2023-07-01'
GROUP BY p.party_id, p.first_name, p.last_name, email.info_string, tn.contact_number, p.CREATED_STAMP;


-- 2 List All Active Physical Products
SELECT p.product_id, p.product_type_id, p.internal_name
FROM product p
JOIN product_type pt ON p.product_type_id = pt.product_type_id
WHERE pt.is_physical = 'Y';


-- 3 Products Missing NetSuite ID
SELECT p.product_id, p.internal_name, p.product_type_id, gi.id_value as netsuite_id
FROM product p
LEFT JOIN good_identification gi ON p.product_id = gi.product_id AND gi.good_identification_type_id = 'ERP_ID'
WHERE gi.id_value IS NULL;


-- 4 Product IDs Across Systems
SELECT
    p.product_id,
    shopify.id_value as shopify_id,
    hotwax.id_value as hotwax_id,
    ns.id_value as netsuite_id
FROM product p
LEFT JOIN good_identification shopify ON p.product_id = shopify.product_id AND shopify.good_identification_type_id = 'SHOPIFY_PROD_ID'
LEFT JOIN good_identification hotwax ON p.product_id = hotwax.product_id AND hotwax.good_identification_type_id = 'HC_code'
LEFT JOIN good_identification ns ON p.product_id = ns.product_id AND ns.good_identification_type_id = 'ERP_ID';


-- 5 Completed Orders in August 2023
SELECT oi.product_id, p.product_type_id, oh.product_store_id, oi.quantity as total_quantity,
p.internal_name, oisg.facility_id, oi.external_id, f.facility_type_id, ohs.order_history_id,
oi.order_id, oi.order_item_seq_id, oisg.ship_group_seq_id
FROM order_header oh
JOIN order_status os ON oh.order_id = os.order_id AND os.status_id = 'ORDER_COMPLETED' AND os.status_datetime >= '2023-08-01' AND os.status_datetime < '2023-09-01'
JOIN order_item oi ON oh.order_id = oi.order_id
JOIN order_item_ship_group oisg ON oi.order_id = oisg.order_id AND oi.ship_group_seq_id = oisg.ship_group_seq_id
LEFT JOIN facility f ON oisg.facility_id = f.facility_id
JOIN product p ON oi.product_id = p.product_id
LEFT JOIN order_history ohs ON oi.order_id = ohs.order_id AND oi.order_item_seq_id = ohs.order_item_seq_id AND ohs.ship_group_seq_id = oisg.ship_group_seq_id;


-- 7 Newly Created Sales Orders and Payment Methods
SELECT oh.order_id, oh.grand_total as total_amount, opp.payment_method_id, oh.external_id as shopify_order_id
FROM order_header oh
LEFT JOIN order_payment_preference opp ON oh.order_id = opp.order_id
WHERE oh.order_type_id = 'SALES_ORDER';


-- 8 Payment Captured but Not Shipped
SELECT oh.order_id, oh.status_id as order_status, opp.status_id as payment_status, s.status_id as shipping_status
FROM order_header oh
JOIN order_payment_preference opp ON oh.order_id = opp.order_id
LEFT JOIN shipment s ON oh.order_id = s.primary_order_id
WHERE (opp.status_id = 'PAYMENT_SETTLED' OR opp.status_id = 'PAYMENT_RECEIVED')
AND (s.status_id != 'SHIPMENT_SHIPPED' OR s.status_id IS NULL);


-- 9 Orders Completed Hourly
SELECT HOUR(os.status_datetime) as hour, COUNT(DISTINCT os.order_id) as total_orders
FROM order_status os
WHERE os.status_id = 'ORDER_COMPLETED'
GROUP BY HOUR(os.status_datetime)
ORDER BY hour;


-- 10 BOPIS Orders Revenue (Last Year)
SELECT COUNT(DISTINCT oh.order_id) as total_orders, SUM(oh.grand_total) as total_revenue
FROM order_header oh
JOIN shipment s ON oh.order_id = s.primary_order_id AND s.shipment_method_type_id = 'STOREPICKUP'
WHERE oh.sales_channel_enum_id = 'WEB_SALES_CHANNEL'
AND oh.order_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR);


-- 11 Canceled Orders (Last Month)
SELECT COUNT(DISTINCT oh.order_id) AS total_orders, os.change_reason AS cancellation_reason
FROM order_header oh
JOIN order_status os ON oh.order_id = os.order_id
WHERE oh.status_id = 'ORDER_CANCELLED' AND os.change_reason IS NOT NULL
GROUP BY os.change_reason;


-- 12 Product Threshold Value
SELECT product_id, minimum_stock as threshold FROM product_facility;
