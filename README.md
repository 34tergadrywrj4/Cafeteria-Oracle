# Cafeteria Oracle

Proyecto desarrollado con Oracle Database, Python y RabbitMQ para simular el flujo de pedidos de una cafetería escolar.

## Tecnologías utilizadas

- Oracle Database XE 21c
- Python 3.13
- RabbitMQ 4.1.8
- Erlang OTP 27.3.4.13
- Librerías Python:
  - oracledb
  - pika

## Funcionamiento general

El sistema registra pedidos en Oracle Database y utiliza RabbitMQ para enviar los pedidos al módulo de cocina mediante una cola de mensajes llamada `pedidos`.

Flujo:

1. Python crea un pedido en Oracle con estado `PENDIENTE`.
2. Python envía un mensaje JSON a RabbitMQ.
3. RabbitMQ almacena el mensaje en la cola `pedidos`.
4. El consumidor de cocina recibe el mensaje.
5. Python actualiza el estado del pedido en Oracle a `EN_PREPARACION`.

## Configuración RabbitMQ

- Host: localhost
- Puerto AMQP: 5672
- Manager: http://localhost:15672
- Usuario: guest
- Contraseña: guest
- Queue: pedidos

