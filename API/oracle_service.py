from decimal import Decimal
from typing import Any
import oracledb
from .config import ORACLE_USER, ORACLE_PASSWORD, ORACLE_DSN

def _value(value: Any):
    return float(value) if isinstance(value, Decimal) else value

def get_connection():
    return oracledb.connect(user=ORACLE_USER, password=ORACLE_PASSWORD, dsn=ORACLE_DSN)

def rows_to_dicts(cursor):
    columns = [col[0].lower() for col in cursor.description]
    return [{columns[i]: _value(value) for i, value in enumerate(row)} for row in cursor.fetchall()]

def get_alumnos():
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT ID_ALUMNO, NOMBRE, APELLIDO, CARRERA, TURNO
            FROM ALUMNO ORDER BY ID_ALUMNO
        """)
        return rows_to_dicts(cur)

def get_empleados():
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT ID_EMPLEADO, NOMBRE, TURNO, ROL
            FROM EMPLEADO ORDER BY ID_EMPLEADO
        """)
        return rows_to_dicts(cur)

def get_productos():
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT P.ID_PRODUCTO, P.NOMBRE, P.PRECIO, P.ID_CATEGORIA, C.NOMBRE AS CATEGORIA
            FROM PRODUCTO P
            LEFT JOIN CATEGORIA C ON C.ID_CATEGORIA = P.ID_CATEGORIA
            ORDER BY P.ID_PRODUCTO
        """)
        return rows_to_dicts(cur)

def create_pedido(id_alumno: int, id_empleado: int, productos: list[dict]):
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute("SELECT seq_pedido.NEXTVAL FROM dual")
        id_pedido = cur.fetchone()[0]
        cur.execute("""
            INSERT INTO PEDIDO (ID_PEDIDO, ID_ALUMNO, ID_EMPLEADO, ESTADO)
            VALUES (:id_pedido, :id_alumno, :id_empleado, 'PENDIENTE')
        """, {"id_pedido": id_pedido, "id_alumno": id_alumno, "id_empleado": id_empleado})

        productos_mensaje = []
        for item in productos:
            id_producto = int(item["id_producto"])
            cantidad = int(item["cantidad"])
            if cantidad < 1:
                raise ValueError("La cantidad debe ser mayor o igual a 1")
            cur.execute("SELECT NOMBRE, PRECIO FROM PRODUCTO WHERE ID_PRODUCTO = :id_producto", {"id_producto": id_producto})
            producto = cur.fetchone()
            if producto is None:
                raise ValueError(f"Producto con ID {id_producto} no existe")
            nombre = producto[0]
            precio = float(producto[1])
            subtotal = precio * cantidad
            cur.execute("SELECT seq_detalle.NEXTVAL FROM dual")
            id_detalle = cur.fetchone()[0]
            cur.execute("""
                INSERT INTO DETALLE_PEDIDO (ID_DETALLE, ID_PEDIDO, ID_PRODUCTO, CANTIDAD, SUBTOTAL)
                VALUES (:id_detalle, :id_pedido, :id_producto, :cantidad, :subtotal)
            """, {"id_detalle": id_detalle, "id_pedido": id_pedido, "id_producto": id_producto, "cantidad": cantidad, "subtotal": subtotal})
            productos_mensaje.append({"id_producto": id_producto, "producto": nombre, "cantidad": cantidad, "precio": precio, "subtotal": subtotal})

        cur.execute("SELECT TOTAL FROM PEDIDO WHERE ID_PEDIDO = :id_pedido", {"id_pedido": id_pedido})
        total = float(cur.fetchone()[0])
        conn.commit()
        return {"id_pedido": int(id_pedido), "estado": "PENDIENTE", "total": total, "productos": productos_mensaje}
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()

def update_estado_pedido(id_pedido: int, estado: str):
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("UPDATE PEDIDO SET ESTADO = :estado WHERE ID_PEDIDO = :id_pedido", {"estado": estado, "id_pedido": id_pedido})
        if cur.rowcount == 0:
            raise ValueError(f"No existe el pedido {id_pedido}")
        conn.commit()

def get_pedidos_recientes():
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT P.ID_PEDIDO, P.TOTAL, P.ESTADO,
                   A.NOMBRE || ' ' || A.APELLIDO AS ALUMNO,
                   E.NOMBRE AS EMPLEADO
            FROM PEDIDO P
            LEFT JOIN ALUMNO A ON A.ID_ALUMNO = P.ID_ALUMNO
            LEFT JOIN EMPLEADO E ON E.ID_EMPLEADO = P.ID_EMPLEADO
            ORDER BY P.ID_PEDIDO DESC
            FETCH FIRST 20 ROWS ONLY
        """)
        pedidos = rows_to_dicts(cur)
        for pedido in pedidos:
            cur.execute("""
                SELECT DP.CANTIDAD || ' x ' || PR.NOMBRE AS PRODUCTO
                FROM DETALLE_PEDIDO DP
                JOIN PRODUCTO PR ON PR.ID_PRODUCTO = DP.ID_PRODUCTO
                WHERE DP.ID_PEDIDO = :id_pedido
                ORDER BY DP.ID_DETALLE
            """, {"id_pedido": pedido["id_pedido"]})
            pedido["productos"] = [row[0] for row in cur.fetchall()]
        return pedidos
