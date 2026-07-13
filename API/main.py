from typing import List
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from . import oracle_service
from . import rabbit_service

app = FastAPI(title="API Cafetería Oracle + RabbitMQ")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

class ProductoPedido(BaseModel):
    id_producto: int
    cantidad: int = Field(ge=1)

class PedidoRequest(BaseModel):
    id_alumno: int
    id_empleado: int
    productos: List[ProductoPedido]

@app.get("/api/health")
def health():
    return {"status": "conectada"}

@app.get("/api/catalogo")
def catalogo():
    try:
        return {"alumnos": oracle_service.get_alumnos(), "empleados": oracle_service.get_empleados(), "productos": oracle_service.get_productos()}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Error al consultar Oracle: {exc}")

@app.get("/api/pedidos")
def pedidos():
    try:
        return oracle_service.get_pedidos_recientes()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Error al consultar pedidos: {exc}")

@app.post("/api/pedidos")
def crear_pedido(payload: PedidoRequest):
    try:
        pedido = oracle_service.create_pedido(
            id_alumno=payload.id_alumno,
            id_empleado=payload.id_empleado,
            productos=[item.model_dump() for item in payload.productos]
        )
        rabbit_service.publish_pedido(pedido)
        return {"ok": True, "message": "Pedido creado en Oracle y enviado a RabbitMQ", **pedido}
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Error al crear pedido: {exc}")
