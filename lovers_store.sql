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
