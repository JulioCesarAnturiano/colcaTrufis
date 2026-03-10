# Ejemplos de Respuestas de API - ColcaTrufis

## 1. Ubicaciones por Trufi (Calles por donde pasa la ruta)

**Endpoint:** `GET /api/trufis/{idtrufi}/ubicaciones`

**Ejemplo de respuesta:**
```json
[
  {
    "idtrufi": 1,
    "orden": 1,
    "nombre_via": "Avenida Pando",
    "interseccion": null,
    "tipo_via": null,
    "latitud": -17.38956789,
    "longitud": -66.15234567
  },
  {
    "idtrufi": 1,
    "orden": 2,
    "nombre_via": "Calle Junín",
    "interseccion": "Avenida La Paz",
    "tipo_via": null,
    "latitud": -17.39045678,
    "longitud": -66.15123456
  },
  {
    "idtrufi": 1,
    "orden": 3,
    "nombre_via": "Avenida La Paz",
    "interseccion": "N° 853",
    "tipo_via": null,
    "latitud": -17.39156789,
    "longitud": -66.14987654
  }
]
```

---

## 2. Todas las Ubicaciones

**Endpoint:** `GET /api/ubicaciones`

**Ejemplo de respuesta:**
```json
[
  {
    "idtrufi": 1,
    "orden": 1,
    "nombre_via": "Avenida Pando",
    "interseccion": null,
    "tipo_via": null,
    "latitud": -17.38956789,
    "longitud": -66.15234567
  },
  {
    "idtrufi": 1,
    "orden": 2,
    "nombre_via": "Calle Junín",
    "interseccion": "Avenida La Paz",
    "tipo_via": null,
    "latitud": -17.39045678,
    "longitud": -66.15123456
  },
  {
    "idtrufi": 2,
    "orden": 1,
    "nombre_via": "Calle Sucre",
    "interseccion": "Avenida Villazón",
    "tipo_via": null,
    "latitud": -17.38234567,
    "longitud": -66.16345789
  }
]
```

---

## 3. Referencias por Trufi (Puntos de referencia manual)

**Endpoint:** `GET /api/trufis/{idtrufi}/referencias`

**Ejemplo de respuesta:**
```json
{
  "data": [
    {
      "id": 1,
      "referencia": "Parada centro buseta",
      "latitud": -17.39234567,
      "longitud": -66.15567890,
      "created_at": "2026-03-09T15:42:30.000000Z"
    },
    {
      "id": 2,
      "referencia": "Terminal buseta norte",
      "latitud": -17.38123456,
      "longitud": -66.14234567,
      "created_at": "2026-03-09T15:45:12.000000Z"
    }
  ],
  "links": {
    "first": "http://localhost:8000/api/trufis/1/referencias?page=1",
    "last": "http://localhost:8000/api/trufis/1/referencias?page=1",
    "prev": null,
    "next": null
  },
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 1,
    "path": "http://localhost:8000/api/trufis/1/referencias",
    "per_page": 50,
    "to": 2,
    "total": 2
  }
}
```

---

## 4. Todas las Referencias

**Endpoint:** `GET /api/referencias`

**Ejemplo de respuesta:**
```json
{
  "data": [
    {
      "id": 1,
      "referencia": "Parada centro buseta",
      "referenciable_type": "App\\Models\\Trufi",
      "referenciable_id": 1,
      "latitud": -17.39234567,
      "longitud": -66.15567890,
      "created_at": "2026-03-09T15:42:30.000000Z"
    },
    {
      "id": 2,
      "referencia": "Terminal buseta norte",
      "referenciable_type": "App\\Models\\Trufi",
      "referenciable_id": 1,
      "latitud": -17.38123456,
      "longitud": -66.14234567,
      "created_at": "2026-03-09T15:45:12.000000Z"
    }
  ],
  "links": {
    "first": "http://localhost:8000/api/referencias?page=1",
    "last": "http://localhost:8000/api/referencias?page=1",
    "prev": null,
    "next": null
  },
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 1,
    "path": "http://localhost:8000/api/referencias",
    "per_page": 20,
    "to": 2,
    "total": 2
  }
}
```

---

## 5. Crear Referencias Manualmente (para Admin)

**Endpoint:** `POST /api/referencias` (requiere admin)

**Ejemplo de request:**
```json
{
  "referencia": "Parada justo frente farmacia",
  "latitud": -17.39234567,
  "longitud": -66.15567890,
  "referenciable_type": "App\\Models\\Trufi",
  "referenciable_id": 1
}
```

**Ejemplo de respuesta:**
```json
{
  "id": 3,
  "referencia": "Parada justo frente farmacia",
  "referenciable_type": "App\\Models\\Trufi",
  "referenciable_id": 1,
  "latitud": -17.39234567,
  "longitud": -66.15567890,
  "created_at": "2026-03-09T16:20:45.000000Z",
  "updated_at": "2026-03-09T16:20:45.000000Z"
}
```

---

## CAMBIOS PRINCIPALES EN LOS DATOS:

### Ubicaciones (trufi_ruta_ubicaciones):
**Nuevos campos:**
- ✅ `latitud` - Lat de la ubicación (tipo decimal 10,8)
- ✅ `longitud` - Long de la ubicación (tipo decimal 11,8)
- ✅ `interseccion` - Calle transversal o número de casa (string, nullable)

**Cómo se obtienen:**
- Se obtienen **automáticamente** del servicio de geocodificación Nominatim
- Se calculan cada vez que se crea/actualiza una ruta

### Referencias (referencias):
**Nuevos campos:**
- ✅ `latitud` - Lat del punto de referencia (tipo decimal 10,8)
- ✅ `longitud` - Long del punto de referencia (tipo decimal 11,8)

**Cómo se obtienen:**
- Se colocan **manualmente** a través de un mapa en la UI del admin
- El usuario selecciona un punto en el mapa y se guardan las coordenadas

---

## NOTAS IMPORTANTES PARA FRONTEND:

1. **Latitud y Longitud**: Usa formato `decimal(10,8)` para lat y `decimal(11,8)` para long
2. **Intersección**: Puede ser `null` si Nominatim no encuentra calle transversal
3. **GeoJSON**: Las coordenadas en GeoJSON son `[longitude, latitude]` (al revés del orden normal)
4. **Mapas**: Usa `[latitude, longitude]` para Leaflet y otros mapeos (orden correcto)
5. **Precisión**: 8 decimales = precisión de ~1 metro en la ubicación

---

## Parámetros de Query Opcionales:

### Paginación (Referencias):
```
GET /api/referencias?per_page=50&page=2
GET /api/trufis/1/referencias?per_page=100&page=1
```

- **per_page**: Registros por página (default: 20 para referencias, 50 para referencias por trufi)
- **page**: Número de página

---

## Códigos de Status HTTP Esperados:

- `200 OK` - Solicitud exitosa
- `201 Created` - Recurso creado exitosamente
- `400 Bad Request` - Datos inválidos
- `404 Not Found` - Recurso no encontrado
- `422 Unprocessable Entity` - Validación fallida (en POST/PUT)
- `500 Server Error` - Error del servidor
