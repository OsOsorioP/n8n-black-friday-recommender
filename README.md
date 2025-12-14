# Black Friday Recommender

![alt text](https://img.shields.io/badge/n8n-313131?style=flat&logo=n8n)
![alt text](https://img.shields.io/badge/Supabase-313131?style=flat&logo=supabase)
![alt text](https://img.shields.io/badge/Postman-313131?style=flat&logo=postman)
![alt text](https://img.shields.io/badge/Status-Production-success)

Una API basada en n8n, diseñada para servir recomendaciones de productos en tiempo real bajo escenarios de alta concurrencia como el **Black Friday**.

El sistema ingesta el ID de un usuario, analiza su histórico transaccional en **PostgreSQL** mediante consultas optimizadas y retorna la mejor oferta en milisegundos, implementando estrategias de Graceful Degradation para asegurar un 100% de disponibilidad.

![Vista previa del Workflow](https://github.com/OsOsorioP/n8n-black-friday-recommender/blob/main/workflow.png)

## Tabla de Contenidos
- [Contexto del Proyecto](#contexto-del-proyecto)
- [Lógica de Recomendación](#lógica-de-recomendación)
- [Documentación API](#documentación-api)
- [Optimización SQL](#optimización-sql)
- [Instalación y Uso](#instalación-y-uso)
- [Roadmap](#roadmap)

## Contexto del Proyecto

El objetivo es maximizar la conversión de ventas mostrando un banner personalizado a cada usuario. El sistema debe:
1.  Recibir el ID de usuario vía HTTP.
2.  Consultar su historial de compras en una base de datos masiva.
3.  Determinar su categoría preferida.
4.  Devolver el producto ideal instantáneamente.

**Desafío Técnico:** Evitar cuellos de botella en la base de datos y memoria RAM al procesar miles de peticiones por minuto.


### Flujo de Datos
1.  **Ingesta:** Webhook recibe `user_id`.
2.  **Procesamiento de Datos:** Ejecución de SQL optimizado (Server-side filtering).
3.  **Lógica de Negocio:** Un nodo JavaScript evalúa la categoría ganadora.
4.  **Resiliencia:** Si la DB falla o el usuario no existe, se aplica una estrategia de *Graceful Degradation*.

## Lógica de Recomendación

El sistema mapea la categoría de compra más frecuente del usuario en los últimos 12 meses hacia una oferta específica.

| Categoría Histórica | Recomendación Generada |
|---------------------|------------------------|
| `tecnologia`        | Accesorios PC          |
| `moda`              | Nueva Colección Invierno|
| `hogar`             | Decoración Navideña    |
| *Sin datos / Error* | **Top Ventas General** |

## Documentación API

### Endpoint Principal

`GET` `/webhook/recommend`

#### Parámetros (Query String)

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `user_id` | Int  | Sí        | ID único del usuario a consultar |

#### Ejemplo de Respuesta (Éxito - 200 OK)

```json
{
  "recommendation": "Accesorios PC",
  "context": {
    "categoria_preferida": "tecnologia",
    "has_purchase_history": true,
    "system_status": "ok"
  },
  "timestamp": "2025-11-24T10:00:00.000Z"
}
```

#### Ejemplo de Respuesta (Error - 400 Bad Request)

```json
{
  "error": "user_id is required",
  "recommendation": "Top Ventas General"
}
```

## Optimización SQL

### 1. Server-Side Aggregation
Para manejar tablas con millones de registros sin saturar la memoria de n8n, la lógica de conteo y ordenamiento se delega al motor de base de datos.

```sql
SELECT categoria, COUNT(*) as total_compras
FROM ventas
WHERE user_id = $1::integer AND fecha >= NOW() - INTERVAL '12 months'
GROUP BY categoria
ORDER BY total_compras DESC
LIMIT 1;
```
*   **Eficiencia:** Solo viaja 1 fila por la red hacia n8n, reduciendo latencia I/O.
*   **Escalabilidad:** El uso de índices en `user_id` permite búsquedas O(log n).

### 2. Graceful Degradation (Manejo de Errores)
Implementación del patrón *Circuit Breaker*.
*   **Problema:** Si la base de datos tarda demasiado (timeout) o cae.
*   **Solución:** El flujo captura el error, evita el código HTTP 500 y devuelve la recomendación por defecto ("Top Ventas General"). El usuario final nunca percibe el fallo.

## Instalación y Uso

### Requisitos
*   [n8n](https://n8n.io/)
*   PostgreSQL o Supabase
*   Postman o usar el navegador

### Configuración Rápida
1.  **Base de Datos:**
    Asegúrate de tener una tabla `ventas` con las columnas `user_id`, `categoria` y `fecha`.
2.  **Importar Workflow:**
    Importa el archivo `.json` de este repositorio en tu instancia de n8n.
3.  **Credenciales:**
    Configura tus credenciales de Postgres en el nodo SQL.
4.  **Despliegue:**
    Activa el workflow y utiliza la URL de producción del Webhook.

## Roadmap

Mejoras planificadas para futuras versiones:

- [ ] **Caché (Redis):** Almacenar la recomendación por 24h para reducir hits a la base de datos.
- [ ] **Autenticación:** Añadir validación de API Key en los headers.
- [ ] **Tests Unitarios:** Implementar nodos de prueba para validar la lógica automáticamente.
