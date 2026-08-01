### Query all orders belonging to the Lovers Product Store, excluding DoorDash(Sales channel enum id) orders. 
```sql
SELECT 
  OH.ORDER_ID,
  OH.STATUS_ID, 
  OH.ORDER_TYPE_ID,
  OH.SALES_CHANNEL_ENUM_ID, 
  OH.product_store_id
from order_header OH 
where product_store_id='LOVERS_STORE' --ORDERS PLACED AT LOVERS_STORE 
and SALES_CHANNEL_ENUM_ID <> 'UNKNWN_SALES_CHANNEL' --EXCLUDING DOORDASH ORDERS
```
### products ordered from lovers store
```SQL
SELECT
DISTINCT OI.PRODUCT_ID 
FROM ORDER_HEADER OH
JOIN ORDER_ITEM OI ON OH.ORDER_ID = OI.ORDER_ID 
WHERE OH.PRODUCT_STORE_ID='LOVERS_STORE';
```
### ORDER_PAYMENT_PREFERENCE ENTITY is linked with:
- ORDER_HEADER          [ORDER_ID]
- ORDER_ITEM            [ORDER_ID, ORDER_ITEM_SEQ_ID]  
- ORDER_ITEM_SHIP_GROUP [ORDER_ID, SHIP_GROUP_DEQ_ID]
  
