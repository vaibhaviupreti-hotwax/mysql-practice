-- Q1: The marketing team ran a campaign in june 2025 and wants to see how many new customers signed up during that period.
-- PARTY_ID - party
-- FIRST_NAME - person
-- LAST_NAME-person
-- EMAIL- contact_mech - INFO_STRING
-- PHONE - contact_mech - CONTACT_MECH_TYPE_ID - TELECOM_NUMBER
-- ENTRY_DATE - PARTY CREATED_DATE
--role ROLE_TYPE_ID
 -- WHERE CREATED_DATE, ROLE_TYPE_ID,

SELECT P.PARTY_ID, PER.FIRST_NAME, PER.LAST_NAME, P.CREATED_DATE,
(
  SELECT CM.INFO_STRING
  FROM CONTACT_MECH CM JOIN party_contact_mech PCM ON CM.CONTACT_MECH_ID = PCM.CONTACT_MECH_ID AND CONTACT_MECH_TYPE_ID = 'EMAIL_ADDRESS'
  WHERE THRU_DATE IS NULL AND PCM.PARTY_ID = P.PARTY_ID
  LIMIT 1
) AS EMAIL,
(
  SELECT TN.CONTACT_NUMBER
  FROM TELECOM_NUMBER TN 
  JOIN PARTY_CONTACT_MECH CM 
  ON TN.CONTACT_MECH_ID = CM.CONTACT_MECH_ID 
  WHERE THRU_DATE IS NULL AND CM.PARTY_ID = P.PARTY_ID
  LIMIT 1
) AS PHONE
FROM PARTY P
JOIN PERSON PER ON P.PARTY_ID = PER.PARTY_ID 
JOIN PARTY_ROLE PR ON P.PARTY_ID = PR.PARTY_ID AND PR.ROLE_TYPE_ID = 'CUSTOMER' -- SINGLE CUSTOMER
WHERE P.CREATED_DATE >= '2025-06-01' AND P.CREATED_DATE <= '2025-06-30'

--Q2: List All Active Physical Products
Business Problem:
Merchandising teams often need a list of all physical products to manage logistics, warehousing, and shipping.

Fields to Retrieve:

PRODUCT_ID
PRODUCT_TYPE_ID
INTERNAL_NAME

SELECT 
  P.PRODUCT_ID, 
  P.INTERNAL_NAME, 
  PT.PRODUCT_TYPE_ID 
FROM 
  PRODUCT P 
  JOIN PRODUCT_TYPE PT ON P.PRODUCT_TYPE_ID = PT.PRODUCT_TYPE_ID 
WHERE 
  IS_PHYSICAL = 'Y' 
  AND SALES_DISCONTINUATION_DATE IS NULL 
  OR SALES_DISCONTINUATION_DATE >= NOW();

-- Q3: Products Missing NetSuite ID
-- Business Problem:
-- A product cannot sync to NetSuite unless it has a valid NetSuite ID. The OMS needs a list of all products that still need to be created or updated in NetSuite.

-- Fields to Retrieve:

-- PRODUCT_ID
-- INTERNAL_NAME
-- PRODUCT_TYPE_ID
-- NETSUITE_ID (or similar field indicating the NetSuite ID; may be NULL or empty if missing)

SELECT 
P.PRODUCT_ID,
P.INTERNAL_NAME,
P.PRODUCT_TYPE_ID,
GI.GOOD_IDENTIFICATION_TYPE_ID AS NETSUITE_ID
FROM 
PRODUCT P 
LEFT JOIN GOOD_IDENTIFICATION GI ON P.PRODUCT_ID = GI.PRODUCT_ID
AND GI.GOOD_IDENTIFICATION_TYPE_ID = 'NETSUITE_PRODUCT_ID' 
WHERE GOOD_IDENTIFICATION_TYPE_ID = '' OR GOOD_IDENTIFICATION_TYPE_ID IS NULL;

-- Note:
-- A JOIN returns only matching rows from both tables, while a LEFT JOIN returns all rows from the left table plus matching rows from the right table (filling unmatched right sides with NULL).

-- Q4 Product IDs Across Systems
-- Business Problem:
-- To sync an order or product across multiple systems (e.g., Shopify, HotWax, ERP/NetSuite), the OMS needs to know each system’s unique identifier for that product. This query retrieves the Shopify ID, HotWax ID, and ERP ID (NetSuite ID) for all products.

-- Fields to Retrieve:

-- PRODUCT_ID (internal OMS ID) --prod
-- SHOPIFY_ID --sh_prod
-- HOTWAX_ID prod
-- ERP_ID or NETSUITE_ID (depending on naming)

SELECT 
  P.PRODUCT_ID, 
  P.INTERNAL_NAME, 
  SHP.SHOP_ID, 
  SHP.SHOPIFY_PRODUCT_ID, 
  GID.ID_VALUE AS NETSUITE_ID 
FROM 
  PRODUCT P 
  LEFT JOIN SHOPIFY_SHOP_PRODUCT SHP ON P.PRODUCT_ID = SHP.PRODUCT_ID 
  LEFT JOIN GOOD_IDENTIFICATION GID ON P.PRODUCT_ID = GID.PRODUCT_ID 
  AND GID.GOOD_IDENTIFICATION_TYPE_ID = 'NETSUITE_ID';

-- Q5 Completed Orders in August 2025
-- Business Problem:
-- After running similar reports for a previous month, you now need all 
--completed orders in March 2026 for analysis.

-- Fields to Retrieve:

-- PRODUCT_ID --OI
-- PRODUCT_TYPE_ID --
-- PRODUCT_STORE_ID --
-- TOTAL_QUANTITY --ORDER_ITEM
-- INTERNAL_NAME --PROD
-- FACILITY_ID -- 
-- EXTERNAL_ID --ORDER_HEADER
-- FACILITY_TYPE_ID 
-- ORDER_ID -- OH
-- ORDER_ITEM_SEQ_ID --oi
-- SHIP_GROUP_SEQ_ID -- OISG

SELECT 
  OH.ORDER_ID,
  OH.EXTERNAL_ID,
  OI.ORDER_ITEM_SEQ_ID, 
  OI.PRODUCT_ID, 
  OI.QUANTITY, 
  P.PRODUCT_TYPE_ID, 
  P.INTERNAL_NAME,
  FAC.FACILITY_ID,
  FAC.FACILITY_TYPE_ID
FROM 
  ORDER_HEADER OH 
  JOIN ORDER_STATUS OS ON OH.ORDER_ID = OS.ORDER_ID 
  AND OS.STATUS_ID = 'ORDER_COMPLETED' 
  JOIN ORDER_ITEM OI ON OH.ORDER_ID = OI.ORDER_ID 
  JOIN PRODUCT P ON OI.PRODUCT_ID = P.PRODUCT_ID 
  JOIN ORDER_ITEM_SHIP_GROUP OISG ON OISG.ORDER_ID = OI.ORDER_ID AND OISG.SHIP_GROUP_SEQ_ID = OI.SHIP_GROUP_SEQ_ID
  JOIN FACILITY FAC ON OISG.FACILITY_ID = FAC.FACILITY_ID
WHERE 
  STATUS_DATETIME <= '2026-03-31' 
  AND STATUS_DATETIME >= '2026-03-01' 
  AND OI.STATUS_ID = 'ITEM_COMPLETED'
--------------------------------------------------------------------------------------------------------

-- 6 Newly Created Sales Orders and Payment Methods
-- Business Problem:
-- Finance teams need to see new orders and their payment methods for reconciliation and fraud checks.

-- Fields to Retrieve:

-- ORDER_ID --OPP
-- TOTAL_AMOUNT --OH
-- PAYMENT_METHOD --OPP
-- Shopify Order ID (if applicable) --SSO

SELECT 
  OPP.ORDER_ID, 
  SSO.SHOPIFY_ORDER_ID, 
  OH.GRAND_TOTAL, 
  OPP.PAYMENT_METHOD_ID 
FROM 
  ORDER_HEADER OH 
  JOIN SHOPIFY_SHOP_ORDER SSO ON OH.ORDER_ID = SSO.ORDER_ID 
  JOIN order_payment_preference OPP ON OH.ORDER_ID = OPP.ORDER_ID

-- 8 Payment Captured but Not Shipped
-- Business Problem:
-- Finance teams want to ensure revenue is recognized properly. If payment is captured but no shipment has occurred, it warrants further review.

-- Fields to Retrieve:

-- ORDER_ID
-- ORDER_STATUS
-- PAYMENT_STATUS
-- SHIPMENT_STATUS

SELECT 
  SS.STATUS_ID, 
  OH.ORDER_ID, 
  OH.STATUS_ID, 
  -- OPP.STATUS_ID
  -- DISTINCT OH.STATUS_ID
FROM 
  ORDER_HEADER OH 
  JOIN ORDER_SHIPMENT OS ON OH.ORDER_ID = OS.ORDER_ID 
  JOIN SHIPMENT_STATUS SS ON OS.SHIPMENT_ID = SS.SHIPMENT_ID 
  AND SS.STATUS_ID <> 'SHIPMENT_SHIPPED' 
  JOIN ORDER_PAYMENT_PREFERENCE OPP ON OPP.ORDER_ID = OH.ORDER_ID 
  AND OPP.STATUS_ID = 'PAYMENT_SETTLED'

-- 9 Orders Completed Hourly
-- Business Problem:
-- Operations teams want to see the volume of completed orders by hour to manage staffing and logistics.

-- Fields to Retrieve:
-- TOTAL ORDERS
-- HOUR

SELECT HOUR(STATUS_DATETIME) AS GRP_HOURS, COUNT(DISTINCT ORDER_ID) AS ORDERS
from order_status  
WHERE STATUS_ID='ORDER_COMPLETED'
GROUP BY HOUR(STATUS_DATETIME)
ORDER BY GRP_HOURS

-- 10 BOPIS Orders Revenue (Last Year)
-- Business Problem:
-- BOPIS (Buy Online, Pickup In Store) is a key retail strategy. Finance wants to know the revenue from BOPIS orders for the previous year.

-- Fields to Retrieve:

-- TOTAL ORDERS
-- TOTAL REVENUE

select 
  OISG.SHIPMENT_METHOD_TYPE_ID AS BOPIS_orders, 
  SUM(OH.GRAND_TOTAL) AS TOT_REVENUE 
from 
  order_header OH 
  JOIN order_item_ship_group OISG ON OH.ORDER_ID = OISG.ORDER_ID 
  AND OH.ORDER_TYPE_ID = 'SALES_ORDER' 
  --BUY ONLINE_(BOPIS-1)
WHERE 
  OISG.SHIPMENT_METHOD_TYPE_ID = 'STOREPICKUP' AND   YEAR(OH.ORDER_DATE)= YEAR(NOW())-1
  --PICKUP IN STORE_(BOPIS-2)
GROUP BY 
  OISG.SHIPMENT_METHOD_TYPE_ID 

--11 Canceled Orders (Last Month)
-- Business Problem:
-- The merchandising team needs to know how many orders were canceled in the previous month and their reasons.

-- Fields to Retrieve:

-- TOTAL ORDERS
-- CANCELATION REASON

SELECT * 
-- COUNT(OS.ORDER_ID)
-- OS.ORDER_ID,OS.STATUS_ID,OS.CHANGE_REASON, OS.CHANGE_REASON_ENUM_ID 
FROM 
ORDER_STATUS OS 
WHERE OS.STATUS_ID = 'ORDER_CANCELLED' AND MONTH(STATUS_DATETIME)=MONTH(NOW())-1
----------------------------------------------------
SELECT 
  COUNT(OS.ORDER_ID), 
  OS.ORDER_ID, 
  OS.STATUS_ID, 
  OS.CHANGE_REASON, 
  OS.CHANGE_REASON_ENUM_ID 
FROM 
  ORDER_STATUS OS 
WHERE 
  OS.STATUS_ID = 'ORDER_CANCELLED' 
  AND MONTH(STATUS_DATETIME) = INTERVAL 1 MONTH;

-- 12 Product Threshold Value
-- Business Problem The retailer has set a threshild value for products that are sold online, in order to avoid over selling.

-- Fields to Retrieve:

-- PRODUCT ID
-- THRESHOLD

SELECT * from product_facility where MINIMUM_STOCK > 0 ;

SELECT PF.PRODUCT_ID,
PF.MINIMUM_STOCK
FROM product_facility PF --CHECK ONLINE SELLABLE
JOIN INVENTORY_ITEM INI
WHERE
INI.AVAILABLE_TO_PROMISE > 0
-- INVENTORY_ITEM_TYPE_ID=""










