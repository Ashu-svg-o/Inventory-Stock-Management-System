SET SERVEROUTPUT ON; 

CREATE TABLE suppliers (

    supplier_id NUMBER PRIMARY KEY,
    supplier_name VARCHAR2(50) NOT NULL,
    phone VARCHAR2(15),
    city VARCHAR2(30)
);

CREATE TABLE products (
    product_id NUMBER PRIMARY KEY,
    product_name VARCHAR2(50) NOT NULL,
    supplier_id NUMBER,
    price NUMBER(10,2),
    stock_qty NUMBER DEFAULT 0 CHECK (stock_qty >= 0),
    reorder_level NUMBER DEFAULT 10,

    CONSTRAINT fk_supplier
    FOREIGN KEY (supplier_id)
    REFERENCES suppliers(supplier_id)
);

CREATE TABLE stock_transactions (
    txn_id NUMBER PRIMARY KEY,
    product_id NUMBER,
    txn_type VARCHAR2(10),     -- IN / OUT
    quantity NUMBER,
    txn_date DATE DEFAULT SYSDATE,

    CONSTRAINT fk_product
    FOREIGN KEY (product_id)
    REFERENCES products(product_id)
);

CREATE SEQUENCE seq_supplier START WITH 1;
CREATE SEQUENCE seq_product START WITH 101;
CREATE SEQUENCE seq_stock_txn START WITH 1;

INSERT INTO suppliers VALUES (
    seq_supplier.NEXTVAL,
    'ABC Traders',
    '9876543210',
    'Indore'
);

INSERT INTO products VALUES (
    seq_product.NEXTVAL,
    'Laptop',
    1,
    50000,
    20,
    5
);

COMMIT;

CREATE OR REPLACE FUNCTION get_available_stock (
    p_product_id NUMBER
) RETURN NUMBER IS
    v_stock NUMBER;
BEGIN
    SELECT stock_qty INTO v_stock
    FROM products
    WHERE product_id = p_product_id;

    RETURN v_stock;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1;
END;
/

SELECT get_available_stock(101) FROM dual;

CREATE OR REPLACE PROCEDURE stock_in (
    p_product_id NUMBER,
    p_qty NUMBER
) IS
BEGIN
    UPDATE products
    SET stock_qty = stock_qty + p_qty
    WHERE product_id = p_product_id;

    INSERT INTO stock_transactions VALUES (
        seq_stock_txn.NEXTVAL,
        p_product_id,
        'IN',
        p_qty,
        SYSDATE
    );

    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE stock_out (
    p_product_id NUMBER,
    p_qty NUMBER
) IS
    v_stock NUMBER;
BEGIN
    SELECT stock_qty INTO v_stock
    FROM products
    WHERE product_id = p_product_id;

    IF v_stock < p_qty THEN
        RAISE_APPLICATION_ERROR(-20001, 'Insufficient Stock');
    END IF;

    UPDATE products
    SET stock_qty = stock_qty - p_qty
    WHERE product_id = p_product_id;

    INSERT INTO stock_transactions VALUES (
        seq_stock_txn.NEXTVAL,
        p_product_id,
        'OUT',
        p_qty,
        SYSDATE
    );

    COMMIT;
END;
/

CREATE OR REPLACE TRIGGER prevent_negative_stock
BEFORE UPDATE OF stock_qty ON products
FOR EACH ROW
BEGIN
    IF :NEW.stock_qty < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Stock cannot be negative');
    END IF;
END;
/

DECLARE
    CURSOR low_stock_cursor IS
        SELECT product_name, stock_qty
        FROM products
        WHERE stock_qty <= reorder_level;

BEGIN
    FOR rec IN low_stock_cursor LOOP
        DBMS_OUTPUT.PUT_LINE(
            rec.product_name || ' | Stock: ' || rec.stock_qty
        );
    END LOOP;
END;
/

SELECT s.supplier_name, p.product_name, p.stock_qty
FROM suppliers s
JOIN products p
ON s.supplier_id = p.supplier_id;

SELECT p.product_name, t.quantity, t.txn_date
FROM stock_transactions t
JOIN products p
ON t.product_id = p.product_id
WHERE t.txn_type = 'OUT';



BEGIN
    stock_in(101, 10);
END;
/

BEGIN
    stock_out(101, 19);
END;
/






