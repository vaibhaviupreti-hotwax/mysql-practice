/* ==============================================================================
   1. Completed Sales Orders (Physical Items)
   ==============================================================================
   Business Problem:
   Merchants need to track only physical items (requiring shipping and fulfillment) 
   for logistics and shipping-cost analysis.
   
   Fields to Retrieve:
   ORDER_ID, ORDER_ITEM_SEQ_ID, PRODUCT_ID, PRODUCT_TYPE_ID, SALES_CHANNEL_ENUM_ID, 
   ORDER_DATE, ENTRY_DATE, STATUS_ID, STATUS_DATETIME, ORDER_TYPE_ID, PRODUCT_STORE_ID
============================================================================== */

SELECT
    OH.ORDER_ID,
    OI.ORDER_ITEM_SEQ_ID,
    P.PRODUCT_ID,
    P.PRODUCT_TYPE_ID,
    OH.SALES_CHANNEL_ENUM_ID,
    OH.ORDER_DATE,
    OH.ENTRY_DATE,
    OS.STATUS_ID,
    OS.STATUS_DATETIME,
    OH.ORDER_TYPE_ID,
    OH.PRODUCT_STORE_ID
FROM 
    ORDER_HEADER OH
JOIN 
    ORDER_ITEM OI ON OH.ORDER_ID = OI.ORDER_ID
JOIN 
    ORDER_STATUS OS ON OH.ORDER_ID = OS.ORDER_ID 
                    AND OI.ORDER_ITEM_SEQ_ID = OS.ORDER_ITEM_SEQ_ID
JOIN 
    PRODUCT P ON OI.PRODUCT_ID = P.PRODUCT_ID
JOIN 
    PRODUCT_TYPE PT ON P.PRODUCT_TYPE_ID = PT.PRODUCT_TYPE_ID
WHERE 
    PT.IS_PHYSICAL = 'Y'
    AND OH.STATUS_ID = 'ORDER_COMPLETED'
    AND OH.ORDER_TYPE_ID = 'SALES_ORDER';


/* ==============================================================================
   2. Completed Return Items
   ==============================================================================
   Business Problem:
   Customer service and finance often need insights into returned items to manage 
   refunds, replacements, and inventory restocking.
   
   Fields to Retrieve:
   RETURN_ID, ORDER_ID, PRODUCT_STORE_ID, STATUS_DATETIME, ORDER_NAME, 
   FROM_PARTY_ID, RETURN_DATE, ENTRY_DATE, RETURN_CHANNEL_ENUM_ID
============================================================================== */

SELECT
    RH.RETURN_ID,
    RI.ORDER_ID,
    OH.PRODUCT_STORE_ID,
    RS.STATUS_DATETIME,
    OH.ORDER_NAME,
    RH.FROM_PARTY_ID,
    RH.RETURN_DATE,
    RH.ENTRY_DATE,
    RH.RETURN_CHANNEL_ENUM_ID
FROM 
    RETURN_HEADER RH
JOIN 
    RETURN_ITEM RI ON RH.RETURN_ID = RI.RETURN_ID 
                  AND RI.STATUS_ID = 'RETURN_COMPLETED'
JOIN 
    RETURN_STATUS RS ON RH.RETURN_ID = RS.RETURN_ID
JOIN 
    ORDER_HEADER OH ON RI.ORDER_ID = OH.ORDER_ID
WHERE 
    RH.RETURN_HEADER_TYPE_ID = 'CUSTOMER_RETURN';


/* ==============================================================================
   3. Single-Return Orders (Last Month)
   ==============================================================================
   Business Problem:
   The merchandising team needs a list of orders that only have one return.
   
   Fields to Retrieve:
   PARTY_ID, FIRST_NAME
============================================================================== */

WITH SINGLE_ITEM_RETURNS AS (
    SELECT 
        RI.ORDER_ID AS ORDER_ID, 
        SUM(RI.RETURN_QUANTITY) AS ITEMS_RETURNED 
    FROM
        RETURN_HEADER RH 
    JOIN 
        RETURN_ITEM RI ON RH.RETURN_ID = RI.RETURN_ID 
                       AND RI.STATUS_ID = 'RETURN_COMPLETED'
    GROUP BY 
        RI.ORDER_ID
    HAVING 
        ITEMS_RETURNED = 1
)
SELECT 
    P.PARTY_ID, 
    P.FIRST_NAME
FROM 
    ORDER_ROLE OR_ROLE 
JOIN 
    SINGLE_ITEM_RETURNS SIR ON OR_ROLE.ORDER_ID = SIR.ORDER_ID
JOIN 
    PERSON P ON P.PARTY_ID = OR_ROLE.PARTY_ID 
             AND OR_ROLE.ROLE_TYPE_ID = 'PLACING_CUSTOMER';


/* ==============================================================================
   4. Returns and Appeasements
   ==============================================================================
   Business Problem:
   The retailer needs the total amount of items that were returned as well as 
   how many appeasements were issued.
   
   Fields to Retrieve:
   TOTAL RETURNS, RETURN $ TOTAL, TOTAL APPEASEMENTS, APPEASEMENTS $ TOTAL
============================================================================== */

SELECT 
    R.TOTAL_RETURNS AS `TOTAL RETURNS`,
    R.RETURN_TOTAL AS `RETURN $ TOTAL`,
    A.APPEASEMENT_COUNT AS `TOTAL APPEASEMENTS`,
    A.TOTAL_APPEASEMENT_AMOUNT AS `APPEASEMENTS $ TOTAL`
FROM 
    (SELECT 
        SUM(RI.RETURN_QUANTITY) AS TOTAL_RETURNS,
        SUM(RI.RETURN_PRICE) AS RETURN_TOTAL
     FROM 
        RETURN_HEADER RH
     JOIN 
        RETURN_ITEM RI ON RH.RETURN_ID = RI.RETURN_ID
     WHERE 
        RI.STATUS_ID = 'RETURN_COMPLETED'
    ) R
CROSS JOIN 
    (SELECT 
        COUNT(RA.RETURN_ADJUSTMENT_ID) AS APPEASEMENT_COUNT, 
        SUM(RA.AMOUNT) AS TOTAL_APPEASEMENT_AMOUNT 
     FROM 
        RETURN_ADJUSTMENT RA 
     WHERE 
        RA.RETURN_ADJUSTMENT_TYPE_ID = 'APPEASEMENT'
    ) A;


/* ==============================================================================
   5. Detailed Return Information
   ==============================================================================
   Business Problem:
   Certain teams need granular return data (reason, date, refund amount) for 
   analyzing return rates, identifying recurring issues, or updating policies.
   
   Fields to Retrieve:
   RETURN_ID, ENTRY_DATE, RETURN_ADJUSTMENT_TYPE_ID, AMOUNT, COMMENTS, 
   ORDER_ID, ORDER_DATE, RETURN_DATE, PRODUCT_STORE_ID
============================================================================== */

SELECT
    RH.RETURN_ID,
    RH.ENTRY_DATE,
    RA.RETURN_ADJUSTMENT_TYPE_ID,
    RA.AMOUNT,
    RA.COMMENTS,
    RI.ORDER_ID,
    OH.ORDER_DATE,
    RH.RETURN_DATE,
    OH.PRODUCT_STORE_ID
FROM 
    RETURN_HEADER RH
JOIN 
    RETURN_ITEM RI ON RI.RETURN_ID = RH.RETURN_ID
JOIN 
    RETURN_ADJUSTMENT RA ON RH.RETURN_ID = RA.RETURN_ID 
                         AND RA.RETURN_ITEM_SEQ_ID = RI.RETURN_ITEM_SEQ_ID
JOIN 
    ORDER_HEADER OH ON RA.ORDER_ID = OH.ORDER_ID;


/* ==============================================================================
   6. Orders with Multiple Returns
   ==============================================================================
   Business Problem:
   Analyzing orders with multiple returns can identify potential fraud, chronic 
   issues with certain items, or inconsistent shipping processes.
   
   Fields to Retrieve:
   ORDER_ID, RETURN_ID, RETURN_DATE, RETURN_REASON, RETURN_QUANTITY
============================================================================== */

SELECT 
    RI.ORDER_ID, 
    RI.RETURN_ID,
    RH.RETURN_DATE,
    RI.RETURN_REASON_ID AS RETURN_REASON,
    RI.RETURN_QUANTITY
FROM 
    RETURN_HEADER RH 
JOIN 
    RETURN_ITEM RI ON RH.RETURN_ID = RI.RETURN_ID 
                  AND RI.STATUS_ID = 'RETURN_COMPLETED'
WHERE
    RI.ORDER_ID IN (
        SELECT RI2.ORDER_ID 
        FROM RETURN_ITEM RI2 
        GROUP BY RI2.ORDER_ID 
        HAVING SUM(RI2.RETURN_QUANTITY) > 1
    );


/* ==============================================================================
   7. Store with Most One-Day Shipped Orders (Last Month)
   ==============================================================================
   Business Problem:
   Identify which facility (store) handled the highest volume of “one-day shipping” 
   orders in the previous month, useful for operational benchmarking.
   
   Fields to Retrieve:
   FACILITY_ID, FACILITY_NAME, TOTAL_ONE_DAY_SHIP_ORDERS, REPORTING_PERIOD
============================================================================== */

SELECT 
    S.ORIGIN_FACILITY_ID AS FACILITY_ID, 
    F.FACILITY_NAME AS FACILITY_NAME,
    COUNT(DISTINCT S.PRIMARY_ORDER_ID) AS TOTAL_ONE_DAY_SHIP_ORDERS,
    CONCAT(DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m-01'), ' TO ',
           LAST_DAY(NOW() - INTERVAL 1 MONTH)) AS REPORTING_PERIOD
FROM 
    SHIPMENT S
JOIN 
    SHIPMENT_METHOD_TYPE SMT ON S.SHIPMENT_METHOD_TYPE_ID = SMT.SHIPMENT_METHOD_TYPE_ID
                             AND S.STATUS_ID = 'SHIPMENT_SHIPPED'
JOIN 
    FACILITY F ON F.FACILITY_ID = S.ORIGIN_FACILITY_ID 
WHERE 
    (SMT.PARENT_TYPE_ID = 'NEXT_DAY' OR S.SHIPMENT_METHOD_TYPE_ID = 'NEXT_DAY')
    AND S.LAST_MODIFIED_DATE >= DATE_FORMAT(NOW() - INTERVAL 1 MONTH, '%Y-%m-01')
    AND S.LAST_MODIFIED_DATE <= LAST_DAY(NOW() - INTERVAL 1 MONTH)
GROUP BY 
    S.ORIGIN_FACILITY_ID, 
    F.FACILITY_NAME
ORDER BY 
    TOTAL_ONE_DAY_SHIP_ORDERS DESC
LIMIT 1;


/* ==============================================================================
   8. List of Warehouse Pickers
   ==============================================================================
   Business Problem:
   Warehouse managers need a list of employees responsible for picking and packing 
   orders to manage shifts, productivity, and training needs.
   
   Fields to Retrieve:
   PARTY_ID (or Employee ID), NAME (First/Last), ROLE_TYPE_ID, FACILITY_ID, STATUS
============================================================================== */

SELECT 
    P.PARTY_ID,
    CONCAT(P.FIRST_NAME, ' ', P.LAST_NAME) AS NAME,
    PR.ROLE_TYPE_ID,
    PL.FACILITY_ID,
    CASE
        WHEN PR.THRU_DATE IS NULL OR PR.THRU_DATE > DATE_FORMAT(NOW(), '%Y-%m-%d')
        THEN 'ACTIVE'
        ELSE 'INACTIVE'
    END AS STATUS
FROM 
    PICKLIST_ROLE PR 
JOIN 
    PERSON P ON PR.PARTY_ID = P.PARTY_ID
JOIN 
    PICKLIST PL ON PR.PICKLIST_ID = PL.PICKLIST_ID;


/* ==============================================================================
   9. Total Facilities That Sell the Product
   ==============================================================================
   Business Problem:
   Retailers want to see how many (and which) facilities (stores, warehouses, 
   virtual sites) currently offer a product for sale.
   
   Fields to Retrieve:
   PRODUCT_ID, PRODUCT_NAME (or INTERNAL_NAME), FACILITY_COUNT
============================================================================== */

WITH PRODUCT_KEPT_BY_FACILITY AS (
    SELECT 
        PF.PRODUCT_ID, 
        COUNT(*) AS FACILITY_COUNT 
    FROM 
        PRODUCT_FACILITY PF 
    GROUP BY 
        PF.PRODUCT_ID
) 
SELECT 
    P.PRODUCT_ID, 
    P.INTERNAL_NAME AS PRODUCT_NAME,
    PKF.FACILITY_COUNT 
FROM
    PRODUCT P 
JOIN
    PRODUCT_KEPT_BY_FACILITY PKF ON P.PRODUCT_ID = PKF.PRODUCT_ID;


/* ==============================================================================
   10. Total Items in Various Virtual Facilities
   ==============================================================================
   Business Problem:
   Retailers need to study the relation of inventory levels of products to the 
   type of facility it's stored at. Retrieve all inventory levels for products 
   at locations and include the facility type Id. Do not retrieve facilities 
   that are of type Virtual.
   
   Fields to Retrieve:
   PRODUCT_ID, FACILITY_ID, FACILITY_TYPE_ID, QOH, ATP
============================================================================== */

SELECT
    II.PRODUCT_ID,
    II.FACILITY_ID,
    F.FACILITY_TYPE_ID,
    II.QUANTITY_ON_HAND_TOTAL AS QOH,
    II.AVAILABLE_TO_PROMISE_TOTAL AS ATP
FROM 
    INVENTORY_ITEM II
JOIN 
    FACILITY F ON II.FACILITY_ID = F.FACILITY_ID
WHERE 
    F.FACILITY_TYPE_ID != 'VIRTUAL_FACILITY';


/* ==============================================================================
   11. Transfer Orders Without Inventory Reservation
   ==============================================================================
   Business Problem:
   When transferring stock between facilities, the system should reserve inventory. 
   If it isn’t reserved, the transfer may fail or oversell.
   
   Fields to Retrieve:
   TRANSFER_ORDER_ID, FROM_FACILITY_ID, TO_FACILITY_ID, PRODUCT_ID, 
   REQUESTED_QUANTITY, RESERVED_QUANTITY, TRANSFER_DATE, STATUS
============================================================================== */

-- QUERY TO BE IMPLEMENTED HERE


/* ==============================================================================
   12. Orders Without Picklist
   ==============================================================================
   Business Problem:
   A picklist is necessary for warehouse staff to gather items. Orders missing a 
   picklist might be delayed and need attention.
   
   Fields to Retrieve:
   ORDER_ID, ORDER_DATE, ORDER_STATUS, FACILITY_ID, DURATION
============================================================================== */

SELECT 
    OISG.ORDER_ID, 
    OH.ORDER_DATE, 
    OH.STATUS_ID AS ORDER_STATUS,
    OISG.FACILITY_ID,
    DATEDIFF(NOW(), OISG.LAST_UPDATED_STAMP) AS DURATION
FROM
    ORDER_HEADER OH 
JOIN 
    ORDER_ITEM OI ON OH.ORDER_ID = OI.ORDER_ID AND OH.STATUS_ID = 'ORDER_APPROVED'
JOIN 
    ORDER_ITEM_SHIP_GROUP OISG ON OI.ORDER_ID = OISG.ORDER_ID
                               AND OI.SHIP_GROUP_SEQ_ID = OISG.SHIP_GROUP_SEQ_ID
LEFT JOIN 
    PICKLIST_BIN PB ON PB.PRIMARY_ORDER_ID = OISG.ORDER_ID 
                   AND PB.PRIMARY_SHIP_GROUP_SEQ_ID = OISG.SHIP_GROUP_SEQ_ID
WHERE 
    PB.PRIMARY_ORDER_ID IS NULL 
    AND PB.PRIMARY_SHIP_GROUP_SEQ_ID IS NULL;
