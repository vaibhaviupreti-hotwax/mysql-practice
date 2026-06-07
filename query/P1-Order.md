# Question 1
## Objective
Calculate the average number of items and distinct products per order grouped by order type.

## SQL Query
```sql
SELECT TEMP.ORDER_TYPE_ID,
       ROUND(AVG(ITEMS)),
       ROUND(AVG(PRODUCTS))
FROM (
    SELECT OH.ORDER_TYPE_ID,
           OI.ORDER_ID,
           COUNT(OI.ORDER_ITEM_SEQ_ID) AS ITEMS,
           COUNT(DISTINCT OI.PRODUCT_ID) AS PRODUCTS
    FROM ORDER_ITEM OI
    JOIN ORDER_HEADER OH ON OH.ORDER_ID = OI.ORDER_ID
    GROUP BY OI.ORDER_ID
    ORDER BY OI.ORDER_ID
) AS TEMP
GROUP BY ORDER_TYPE_ID;
```

## Output
* <a href="https://github.com/vaibhaviupreti-hotwax/mysql-practice/blob/main/resources/P1-Order-output.png" target="_blank" rel="noopener">Output Screenshot</a>

## Resources
* <a href="https://github.com/vaibhaviupreti-hotwax/mysql-practice/blob/main/resources/P1-order-mindmap.jpg" target="_blank" rel="noopener">Mind Map</a>
