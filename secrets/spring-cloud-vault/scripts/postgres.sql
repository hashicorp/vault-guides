CREATE TABLE orders (
    id bigserial primary key,
    customer_name varchar(60) NOT NULL,
    product_name varchar(20) NOT NULL,
    order_date timestamp NOT NULL
);