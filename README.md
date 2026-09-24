# README

# DocDigitales — Servicio de Timbrado

API Rails que simula el timbrado de un CFDI contra un PAC externo, evitando
procesar dos veces el mismo `external_id`.

## Requisitos
- Ruby `3.4.6` (ver `.ruby-version`)
- PostgreSQL
- Bundler

## Setup

- instalar gemas necesarias
```bash
bundle install
```

- Crear base de datos
```bash
rails db:setup
```
### si la DB ya existe:

- Correr migraciones
```bash
rails db:migrate
```

- Correr las semillas para generar facturas dummy
```bash
rails db:seed
```

## Para correr el servidor
```bash
rails server
```

# Manual Testing

## Request con CURL (tambien puedes usar postman)
```curl
curl -s -X POST http://localhost:3000/timbrados \
  -H "Content-Type: application/json" \
  -d '{"external_id":"req-001","invoice_id":1,"amount":777}'
```

> Usa un *invoice_id* existente (los seeds crean facturas de prueba)

## Tests
```bash
rails db:test:prepare
bundle exec rspec
```

___

# Preguntas de SQL / ActiveRecord

## Esquema de db simplificado:

```code
facturas(id, cliente_id, folio, total, estatus, fecha_emision)

clientes(id, nombre, rfc)

pagos(id, factura_id, monto, fecha_pago)
```

## Pregunta 1:
Endpoint con los resultados de la siguiente consulta: (SQL o ActiveRecord) que devuelva, por cliente, el total facturado y el total pagado, incluyendo clientes sin pagos.

```ruby
def clientes_con_totales
  Cliente.includes(facturas: :pagos).map do |cliente|
    {
      cliente_id: cliente.id,
      nombre: cliente.nombre,
      total_facturado: cliente.facturas.sum(&:total),
      total_pagado: cliente.facturas.flat_map(&:pagos).sum(&:monto)
    }
  end
end
```

### comentario:
En este caso opté por una solucion con ruby/active record, por legibilidad. se uso includes en facturas y pagos para evitar n+1, pero tenemos el detalle de que este approach carga las asociaciones en memoria y realiza las adiciones o sums, del lado de ruby, en el caso de que el dataset fuera muy grande, en ese caso si optaria por hacer la funcionalidad directamente en la base de datos con SQL.

## Pregunta 2:
Endpoint con los resultados de la siguiente consulta: (SQL o ActiveRecord) que encuentre facturas con estatus "vencida" cuyo saldo pendiente (total - suma de pagos) sea mayor
a cero.

```ruby
def facturas_vencidas_con_saldo
  Factura
    .where(estatus: "vencida")
    .left_joins(:pagos)
    .group("facturas.id")
    .having("facturas.total - COALESCE(SUM(pagos.monto), 0) > 0")
end
```

### Comentario:
En este caso opté por el SQL ya que es lo suficientemente legible para entenderlo rapidamente aqui el left join nos permite traer las facturas aun asi no tengan pagos, y COALESCE nos ayuda a parsear aquellos pagos null a cero, de esa manera podemos filtrarlos con having una vez se hizo la SUM.
___

# Pregunta corta de diseño

> Si el job que timbra una factura se ejecuta dos veces por accidente (por ejemplo, un reinicio del worker a mitad del proceso), ¿cómo evitarías que la factura se timbre dos veces? Describe tu enfoque en un párrafo

Basicamente usaria el identificador unico de la solicitud para hacer un servicio idemponente, asi como hacer uso de los UNIQUE constrains del lado de la base de datos. Antes de hacer el timbrado de una factura, se verifica si existe ya una, con el identificador unico de la solicitud, en este caso external_id, si fue procesado exitosamente simplemente se devuelve el mismo resultado sin hacer uso del servicio externo de timbrado. Para evitar race conditions entre workers, el UNIQUE constraint garantiza que no puedan existir dos registros para el mismo external_id, y podría complementarse con locking/transacciones si fuera necesario coordinar el procesamiento concurrente, igualmente se mantendrian los estados del timbrado para distinguir aquellas que pudieran repetirse o reintentarse, de aquellas que fueron completadas y finalmente el proveedor externo tambien deberia soportar un identificador idemponente (en el mejor de los casos) ya que el UNIQUE constrain evita los dobles registros de nuestro lado pero no evita, que dos request repetidos llamen al mismo servicio Pac (y que de su lado falle el doble timbrar). 

