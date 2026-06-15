-- ============================================================
--  CAFETERÍA ESCOLAR — Script Completo Oracle XE
--  Usuario   : cafeteria
--  Motor     : Oracle Database XE 21c

-- ============================================================
--  BLOQUE 1 — DDL
--  Lenguaje de Definición de Datos
-- ============================================================

-- ── 1.1 SECUENCIAS ─────────────────────────────────────────

CREATE SEQUENCE seq_categoria  START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_producto   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_alumno     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_empleado   START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_pedido     START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_detalle    START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;


-- ── 1.2 TABLAS ─────────────────────────────────────────────

-- CATEGORIA
CREATE TABLE CATEGORIA (
    ID_CATEGORIA  NUMBER(5)    NOT NULL,
    NOMBRE        VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_categoria PRIMARY KEY (ID_CATEGORIA)
);

-- PRODUCTO
CREATE TABLE PRODUCTO (
    ID_PRODUCTO   NUMBER(5)    NOT NULL,
    NOMBRE        VARCHAR2(80) NOT NULL,
    PRECIO        NUMBER(6,2)  NOT NULL,
    ID_CATEGORIA  NUMBER(5)    NOT NULL,
    CONSTRAINT pk_producto  PRIMARY KEY (ID_PRODUCTO),
    CONSTRAINT fk_prod_cat  FOREIGN KEY (ID_CATEGORIA)
                            REFERENCES CATEGORIA(ID_CATEGORIA),
    CONSTRAINT ck_precio    CHECK (PRECIO > 0)
);

-- ALUMNO
CREATE TABLE ALUMNO (
    ID_ALUMNO  NUMBER(8)    NOT NULL,
    NOMBRE     VARCHAR2(60) NOT NULL,
    APELLIDO   VARCHAR2(60) NOT NULL,
    CARRERA    VARCHAR2(80),
    TURNO      VARCHAR2(10),
    CONSTRAINT pk_alumno   PRIMARY KEY (ID_ALUMNO),
    CONSTRAINT ck_turno_al CHECK (TURNO IN ('MATUTINO','VESPERTINO'))
);

-- EMPLEADO
CREATE TABLE EMPLEADO (
    ID_EMPLEADO  NUMBER(5)    NOT NULL,
    NOMBRE       VARCHAR2(60) NOT NULL,
    TURNO        VARCHAR2(10) NOT NULL,
    ROL          VARCHAR2(30),
    CONSTRAINT pk_empleado PRIMARY KEY (ID_EMPLEADO),
    CONSTRAINT ck_turno_em CHECK (TURNO IN ('MATUTINO','VESPERTINO')),
    CONSTRAINT ck_rol      CHECK (ROL IN ('CAJERO','COCINERO','ENCARGADO'))
);

-- PEDIDO
CREATE TABLE PEDIDO (
    ID_PEDIDO    NUMBER(8)    NOT NULL,
    FECHA        DATE         DEFAULT SYSDATE NOT NULL,
    TOTAL        NUMBER(8,2)  DEFAULT 0       NOT NULL,
    ESTADO       VARCHAR2(15) DEFAULT 'PENDIENTE' NOT NULL,
    ID_ALUMNO    NUMBER(8)    NOT NULL,
    ID_EMPLEADO  NUMBER(5)    NOT NULL,
    CONSTRAINT pk_pedido  PRIMARY KEY (ID_PEDIDO),
    CONSTRAINT fk_ped_al  FOREIGN KEY (ID_ALUMNO)
                          REFERENCES ALUMNO(ID_ALUMNO),
    CONSTRAINT fk_ped_em  FOREIGN KEY (ID_EMPLEADO)
                          REFERENCES EMPLEADO(ID_EMPLEADO),
    CONSTRAINT ck_estado  CHECK (ESTADO IN ('PENDIENTE','ENTREGADO','CANCELADO'))
);

-- DETALLE_PEDIDO
CREATE TABLE DETALLE_PEDIDO (
    ID_DETALLE   NUMBER(8)   NOT NULL,
    ID_PEDIDO    NUMBER(8)   NOT NULL,
    ID_PRODUCTO  NUMBER(5)   NOT NULL,
    CANTIDAD     NUMBER(3)   NOT NULL,
    SUBTOTAL     NUMBER(8,2) NOT NULL,
    CONSTRAINT pk_detalle  PRIMARY KEY (ID_DETALLE),
    CONSTRAINT fk_det_ped  FOREIGN KEY (ID_PEDIDO)
                           REFERENCES PEDIDO(ID_PEDIDO),
    CONSTRAINT fk_det_prod FOREIGN KEY (ID_PRODUCTO)
                           REFERENCES PRODUCTO(ID_PRODUCTO),
    CONSTRAINT ck_cantidad CHECK (CANTIDAD >= 1)
);


-- ── 1.3 TRIGGER ────────────────────────────────────────────
-- Recalcula el TOTAL del PEDIDO automaticamente
-- Se dispara despues de cada INSERT en DETALLE_PEDIDO

CREATE OR REPLACE TRIGGER trg_actualizar_total
AFTER INSERT ON DETALLE_PEDIDO
FOR EACH ROW
BEGIN
    UPDATE PEDIDO
    SET    TOTAL = TOTAL + :NEW.SUBTOTAL
    WHERE  ID_PEDIDO = :NEW.ID_PEDIDO;
END;
/


-- ── 1.4 VISTA ──────────────────────────────────────────────
-- Reporte de ventas consolidado

CREATE OR REPLACE VIEW VW_VENTAS AS
SELECT
    P.ID_PEDIDO,
    P.FECHA,
    A.NOMBRE  || ' ' || A.APELLIDO AS CLIENTE,
    A.CARRERA,
    E.NOMBRE                        AS EMPLEADO,
    E.ROL,
    P.TOTAL,
    P.ESTADO
FROM  PEDIDO   P
JOIN  ALUMNO   A ON A.ID_ALUMNO   = P.ID_ALUMNO
JOIN  EMPLEADO E ON E.ID_EMPLEADO = P.ID_EMPLEADO
ORDER BY P.FECHA DESC;


-- ============================================================
--  BLOQUE 2 — DML
--  INSERT de datos de prueba
-- ============================================================

-- ── 2.1 INSERT — Categorías ────────────────────────────────
INSERT INTO CATEGORIA VALUES (seq_categoria.NEXTVAL, 'Bebidas');
INSERT INTO CATEGORIA VALUES (seq_categoria.NEXTVAL, 'Antojitos');
INSERT INTO CATEGORIA VALUES (seq_categoria.NEXTVAL, 'Tortas');
INSERT INTO CATEGORIA VALUES (seq_categoria.NEXTVAL, 'Postres');

-- ── 2.2 INSERT — Productos ─────────────────────────────────
INSERT INTO PRODUCTO VALUES (seq_producto.NEXTVAL, 'Agua natural',        10.00, 1);
INSERT INTO PRODUCTO VALUES (seq_producto.NEXTVAL, 'Refresco',            15.00, 1);
INSERT INTO PRODUCTO VALUES (seq_producto.NEXTVAL, 'Cafe',                18.00, 1);
INSERT INTO PRODUCTO VALUES (seq_producto.NEXTVAL, 'Taco de guisado',     14.00, 2);
INSERT INTO PRODUCTO VALUES (seq_producto.NEXTVAL, 'Quesadilla',          20.00, 2);
INSERT INTO PRODUCTO VALUES (seq_producto.NEXTVAL, 'Torta de jamon',      35.00, 3);
INSERT INTO PRODUCTO VALUES (seq_producto.NEXTVAL, 'Torta de milanesa',   45.00, 3);
INSERT INTO PRODUCTO VALUES (seq_producto.NEXTVAL, 'Pastel de chocolate', 22.00, 4);

-- ── 2.3 INSERT — Alumnos ───────────────────────────────────
INSERT INTO ALUMNO VALUES (seq_alumno.NEXTVAL, 'Carlos',  'Ramirez', 'Ing. Sistemas',  'MATUTINO');
INSERT INTO ALUMNO VALUES (seq_alumno.NEXTVAL, 'Sofia',   'Lopez',   'Ing. Civil',     'VESPERTINO');
INSERT INTO ALUMNO VALUES (seq_alumno.NEXTVAL, 'Miguel',  'Torres',  'Ing. Electrica', 'MATUTINO');
INSERT INTO ALUMNO VALUES (seq_alumno.NEXTVAL, 'Valeria', 'Mendoza', 'Administracion', 'VESPERTINO');

-- ── 2.4 INSERT — Empleados ─────────────────────────────────
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Rosa Martinez', 'MATUTINO',   'CAJERO');
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Juan Perez',    'MATUTINO',   'COCINERO');
INSERT INTO EMPLEADO VALUES (seq_empleado.NEXTVAL, 'Ana Flores',    'VESPERTINO', 'CAJERO');

-- ── 2.5 INSERT — Pedidos ───────────────────────────────────
-- El TOTAL inicia en 0, el trigger lo actualiza automaticamente

INSERT INTO PEDIDO (ID_PEDIDO, ID_ALUMNO, ID_EMPLEADO)
    VALUES (seq_pedido.NEXTVAL, 1, 1);

INSERT INTO PEDIDO (ID_PEDIDO, ID_ALUMNO, ID_EMPLEADO)
    VALUES (seq_pedido.NEXTVAL, 2, 3);

INSERT INTO PEDIDO (ID_PEDIDO, ID_ALUMNO, ID_EMPLEADO)
    VALUES (seq_pedido.NEXTVAL, 3, 1);

INSERT INTO PEDIDO (ID_PEDIDO, ID_ALUMNO, ID_EMPLEADO)
    VALUES (seq_pedido.NEXTVAL, 4, 3);

-- ── 2.6 INSERT — Detalles ──────────────────────────────────
-- Cada INSERT dispara el trigger que suma al TOTAL del pedido

-- Pedido 1: Carlos — 2 tacos + 1 refresco = 43.00
INSERT INTO DETALLE_PEDIDO VALUES (seq_detalle.NEXTVAL, 1, 4, 2, 2*14.00);
INSERT INTO DETALLE_PEDIDO VALUES (seq_detalle.NEXTVAL, 1, 2, 1, 1*15.00);

-- Pedido 2: Sofia — torta milanesa + cafe = 63.00
INSERT INTO DETALLE_PEDIDO VALUES (seq_detalle.NEXTVAL, 2, 7, 1, 1*45.00);
INSERT INTO DETALLE_PEDIDO VALUES (seq_detalle.NEXTVAL, 2, 3, 1, 1*18.00);

-- Pedido 3: Miguel — 2 quesadillas + pastel + agua = 72.00
INSERT INTO DETALLE_PEDIDO VALUES (seq_detalle.NEXTVAL, 3, 5, 2, 2*20.00);
INSERT INTO DETALLE_PEDIDO VALUES (seq_detalle.NEXTVAL, 3, 8, 1, 1*22.00);
INSERT INTO DETALLE_PEDIDO VALUES (seq_detalle.NEXTVAL, 3, 1, 1, 1*10.00);

-- Pedido 4: Valeria — torta jamon + refresco = 50.00
INSERT INTO DETALLE_PEDIDO VALUES (seq_detalle.NEXTVAL, 4, 6, 1, 1*35.00);
INSERT INTO DETALLE_PEDIDO VALUES (seq_detalle.NEXTVAL, 4, 2, 1, 1*15.00);

-- ── 2.7 UPDATE — Cambiar estado de pedidos ─────────────────
UPDATE PEDIDO SET ESTADO = 'ENTREGADO'  WHERE ID_PEDIDO = 1;
UPDATE PEDIDO SET ESTADO = 'ENTREGADO'  WHERE ID_PEDIDO = 2;
UPDATE PEDIDO SET ESTADO = 'CANCELADO'  WHERE ID_PEDIDO = 4;


-- ============================================================
--  BLOQUE 3 — TCL
--  Control de Transacciones
-- ============================================================

-- Confirmar todos los cambios anteriores
COMMIT;

-- Si algo falla antes del COMMIT puedes deshacer con:
-- ROLLBACK;

-- Punto de recuperacion parcial:
-- SAVEPOINT sp_despues_inserts;
-- ROLLBACK TO sp_despues_inserts;


-- ============================================================
--  BLOQUE 4 — DCL
--  Control de Datos / Permisos
-- ============================================================

-- Dar permiso de solo lectura a un usuario reportes
-- (descomenta si tienes ese usuario creado)

-- GRANT SELECT ON CATEGORIA      TO reportes;
-- GRANT SELECT ON PRODUCTO       TO reportes;
-- GRANT SELECT ON ALUMNO         TO reportes;
-- GRANT SELECT ON EMPLEADO       TO reportes;
-- GRANT SELECT ON PEDIDO         TO reportes;
-- GRANT SELECT ON DETALLE_PEDIDO TO reportes;
-- GRANT SELECT ON VW_VENTAS      TO reportes;

-- Quitar permisos:
-- REVOKE SELECT ON VW_VENTAS FROM reportes;


-- ============================================================
--  BLOQUE 5 — CONSULTAS DE VERIFICACION
--  Ejecutar despues del COMMIT para verificar que todo este bien
-- ============================================================

-- Ver todas las tablas
SELECT * FROM CATEGORIA;
SELECT * FROM PRODUCTO;
SELECT * FROM ALUMNO;
SELECT * FROM EMPLEADO;

-- Ver pedidos con su total (calculado por el trigger)
SELECT * FROM PEDIDO;

-- Ver reporte completo de ventas
SELECT * FROM VW_VENTAS;

-- Ver detalle de un pedido especifico
SELECT
    PR.NOMBRE   AS PRODUCTO,
    D.CANTIDAD,
    PR.PRECIO,
    D.SUBTOTAL
FROM  DETALLE_PEDIDO D
JOIN  PRODUCTO PR ON PR.ID_PRODUCTO = D.ID_PRODUCTO
WHERE D.ID_PEDIDO = 1;

-- Producto mas vendido
SELECT
    PR.NOMBRE,
    SUM(D.CANTIDAD) AS TOTAL_VENDIDO,
    SUM(D.SUBTOTAL) AS INGRESOS
FROM  DETALLE_PEDIDO D
JOIN  PRODUCTO PR ON PR.ID_PRODUCTO = D.ID_PRODUCTO
GROUP BY PR.NOMBRE
ORDER BY TOTAL_VENDIDO DESC;

-- Ventas por empleado
SELECT
    E.NOMBRE            AS EMPLEADO,
    COUNT(P.ID_PEDIDO)  AS NUM_PEDIDOS,
    SUM(P.TOTAL)        AS TOTAL_VENTAS
FROM  PEDIDO P
JOIN  EMPLEADO E ON E.ID_EMPLEADO = P.ID_EMPLEADO
WHERE P.ESTADO = 'ENTREGADO'
GROUP BY E.NOMBRE
ORDER BY TOTAL_VENTAS DESC;

-- Pedidos por alumno
SELECT
    A.NOMBRE || ' ' || A.APELLIDO AS ALUMNO,
    COUNT(P.ID_PEDIDO)             AS NUM_PEDIDOS,
    SUM(P.TOTAL)                   AS TOTAL_GASTADO
FROM  PEDIDO P
JOIN  ALUMNO A ON A.ID_ALUMNO = P.ID_ALUMNO
GROUP BY A.NOMBRE, A.APELLIDO
ORDER BY TOTAL_GASTADO DESC;

-- ============================================================
--  FIN DEL SCRIPT
-- ============================================================

CREATE TABLE HISTORIAL_PEDIDO (
    ID_HISTORIAL NUMBER(8),
    ID_PEDIDO NUMBER(8),
    ESTADO VARCHAR2(20),
    FECHA_CAMBIO DATE DEFAULT SYSDATE
);

ALTER TABLE PEDIDO ADD CONSTRAINT ck_estado
CHECK (ESTADO IN ('PENDIENTE','EN_PREPARACION','LISTO','ENTREGADO','CANCELADO'));

SELECT table_name
FROM user_tables
ORDER BY table_name;

SELECT 'ALUMNO' AS TABLA, COUNT(*) AS REGISTROS FROM ALUMNO
UNION ALL
SELECT 'CATEGORIA', COUNT(*) FROM CATEGORIA
UNION ALL
SELECT 'PRODUCTO', COUNT(*) FROM PRODUCTO
UNION ALL
SELECT 'EMPLEADO', COUNT(*) FROM EMPLEADO
UNION ALL
SELECT 'PEDIDO', COUNT(*) FROM PEDIDO
UNION ALL
SELECT 'DETALLE_PEDIDO', COUNT(*) FROM DETALLE_PEDIDO
UNION ALL
SELECT 'HISTORIAL_PEDIDO', COUNT(*) FROM HISTORIAL_PEDIDO;

SELECT constraint_name, search_condition
FROM user_constraints
WHERE table_name = 'PEDIDO'
AND constraint_type = 'C';


SELECT 
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS USUARIO,
    SYS_CONTEXT('USERENV', 'SERVICE_NAME') AS SERVICE_NAME,
    SYS_CONTEXT('USERENV', 'SERVER_HOST') AS HOST
FROM dual;

SELECT ID_PEDIDO, TOTAL, ESTADO
FROM PEDIDO
WHERE ID_PEDIDO = 5;

SELECT ID_PEDIDO, FECHA, TOTAL, ESTADO
FROM PEDIDO
ORDER BY ID_PEDIDO DESC;