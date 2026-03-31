# Especificaciones Técnicas - Proyecto ColcaTrufis

## 1. Objetivo General

El objetivo general de este proyecto es desarrollar una aplicación móvil que permita a los usuarios consultar las rutas de los trufis y acceder a información de radio taxis dentro del municipio de Colcapirhua y otras zonas de la ciudad de Cochabamba.

La aplicación permitirá a los usuarios buscar cómo llegar a un lugar específico, mostrando las rutas de los trufis que pasan por ese destino o por lugares cercanos. También incluirá información de radio taxis disponibles, mostrando su ubicación aproximada donde esté ubicado el usuario y su número de contacto para que el usuario pueda comunicarse fácilmente.

Esta aplicación busca facilitar a las personas el acceso a información sobre el transporte público, mostrando las rutas, paradas y puntos de referencia cercanos, para que los usuarios puedan ubicarse mejor y saber qué trufi tomar para llegar a su destino.

## 2. Objetivos Específicos

Para poder cumplir con el objetivo general del proyecto, se plantean los siguientes objetivos específicos:

1. Analizar la situación actual del transporte público.
2. Diseñar una aplicación móvil sencilla e intuitiva con **Flutter**.
3. Mostrar las rutas de los trufis disponibles a través de una **API REST en Laravel 11**.
4. Permitir la búsqueda de rutas según el destino.
5. Mostrar las paradas y puntos de referencia georreferenciados.
6. Ofrecer información sobre radio taxis disponibles.
7. Desarrollar un panel administrativo web para gestionar la información.

## 3. Contexto del Proyecto

### 3.1 Escenario en el que se aplicará la aplicación

El proyecto se desarrolla inicialmente en el municipio de Colcapirhua, ubicado en el departamento de Cochabamba. Sin embargo, la aplicación está pensada para ser útil no solo para este municipio, sino también para otras zonas de la ciudad de Cochabamba donde circulan diferentes líneas de trufis.

Actualmente, muchas personas tienen dificultades para saber qué trufi deben tomar para llegar a un destino específico, especialmente cuando no conocen bien la zona o cuando necesitan desplazarse hacia otro municipio o barrio.

Además, cuando una persona necesita un taxi, muchas veces no sabe qué radio taxi está disponible ni cómo contactarlo rápidamente.

Debido a estos problemas, surge la idea de desarrollar una aplicación móvil que permita centralizar la información del transporte público, facilitando a los usuarios conocer las rutas disponibles y encontrar medios de transporte más fácilmente.

#### La aplicación permitirá a los usuarios:

- Consultar las rutas de los trufis que circulan en Colcapirhua y otras zonas de Cochabamba.
- Visualizar las paradas correspondientes a cada ruta.
- Buscar qué trufi tomar para llegar a un destino específico.
- Ver puntos de referencia cercanos para ubicarse mejor.
- Encontrar información sobre radio taxis disponibles.
- Obtener el número de contacto de los radio taxis para solicitar el servicio.

### 3.2 Arquitectura del Sistema

La aplicación está compuesta por tres componentes principales:

#### **1. Frontend - Aplicación Móvil (Flutter)**
- Desarrollo multiplataforma con **Flutter** (Android, iOS, Web)
- Ubicado en: `/fronted/`
- Interfaz móvil sencilla e intuitiva
- Integración con servicios de geolocalización
- Consumo de API REST desde el backend para obtener información de rutas y taxistas

#### **2. Backend - Servidor API (Laravel 11)**
- Framework: **Laravel 11** (PHP)
- Ubicado en: `/backend/`
- API REST documentada para el frontend
- Base de datos relacional para almacenar:
  - Información de trufis y sus rutas
  - Paradas y referencias geográficas
  - Datos de sindicatos y radio taxis
  - Normativas y configuración del sistema
- Autenticación y autorización para el panel administrativo
- Ubicado en el servidor del cliente que solo acepta backend **Laravel 11**

#### **3. Panel Administrativo Web**
- Interfaz web para gestionar la información del sistema
- Integrado en el mismo servidor Laravel 11
- Acceso seguro con usuario y contraseña
- Gestión de:
  - Rutas de trufis (crear, editar, eliminar)
  - Información de radio taxis
  - Paradas y puntos de referencia
  - Configuración general del sistema
  - Sindicatos y normativas

## 4. Requisitos Funcionales

### Para la Aplicación Móvil (Flutter):

- RF1: La aplicación debe permitir visualizar rutas de trufis en Colcapirhua y otras zonas de Cochabamba.
- RF2: El usuario debe poder buscar rutas según el destino al que desea ir.
- RF3: La aplicación debe permitir seleccionar una ruta para ver su recorrido completo.
- RF4: El sistema debe mostrar las paradas correspondientes a cada ruta.
- RF5: La aplicación debe mostrar puntos de referencia cercanos a las paradas.
- RF6: El sistema debe permitir visualizar información de radio taxis disponibles.
- RF7: La aplicación debe mostrar el número de contacto de los radio taxis registrados.
- RF8: La aplicación debe obtener la información desde el backend mediante conexión HTTPS.
- RF9: La aplicación debe mostrar la ubicación aproximada del usuario (con permiso).
- RF10: La aplicación debe permitir filtrar rutas por sindicato o línea de trufi.

### Para el Backend (Laravel 11):

- RF11: El backend debe proporcionar una API REST documentada para el frontend.
- RF12: El backend debe validar y autenticar las solicitudes del panel administrativo.
- RF13: El backend debe gestionar la persistencia de datos en base de datos relacional.
- RF14: El backend debe permitir operaciones CRUD (Crear, Leer, Actualizar, Eliminar) para:
  - Rutas de trufis
  - Paradas
  - Sindicatos y radio taxis
  - Normativas
  - Puntos de referencia

### Para el Panel Administrativo Web:

- RF15: El panel administrativo debe permitir registrar nuevas rutas de trufis.
- RF16: El panel administrativo debe permitir registrar, editar o eliminar información de radio taxis.
- RF17: El panel administrativo debe permitir gestionar paradas y puntos de referencia.
- RF18: El panel administrativo debe generar reportes sobre uso de rutas.
- RF19: El panel administrativo debe permitir configurar normativas del sistema.

## 5. Requisitos No Funcionales

### Seguridad:

- RNF1: El panel administrativo debe tener acceso seguro mediante usuario y contraseña.
- RNF2: El backend debe implementar autenticación con tokens JWT o similares.
- RNF3: Las comunicaciones entre frontend y backend deben ser mediante HTTPS.
- RNF4: Las credenciales no deben ser almacenadas en el frontend de forma insegura.

### Rendimiento:

- RNF5: El sistema debe tener tiempos de respuesta inferiores a 2 segundos para consultas de rutas.
- RNF6: El backend debe soportar al menos 100 usuarios concurrentes.
- RNF7: La carga inicial de la aplicación móvil no debe exceder 3 segundos.
- RNF8: Las consultas a la API REST deben incluir paginación cuando sea necesario.

### Compatibilidad:

- RNF9: La aplicación móvil debe funcionar correctamente en dispositivos Android con versión 8.0 o superior.
- RNF10: La aplicación móvil debe funcionar correctamente en dispositivos iOS con versión 12.0 o superior.
- RNF11: El backend debe ejecutarse en servidor con PHP 8.1+ compatible con Laravel 11.
- RNF12: El backend debe ser compatible con bases de datos MySQL 8.0 o superior.

### Confiabilidad y Estabilidad:

- RNF13: El sistema debe ser estable y confiable, con un tiempo de funcionamiento del 99% en condiciones normales.
- RNF14: Los datos deben ser respaldados regularmente.
- RNF15: El sistema debe incluir manejo de errores robusto y recuperación de fallos.
- RNF16: La información debe poder actualizarse fácilmente desde el panel administrativo sin requerir redeploy de la aplicación móvil.

### Escalabilidad y Mantenibilidad:

- RNF17: El sistema debe permitir ampliar en el futuro más rutas de transporte en Cochabamba.
- RNF18: El código debe seguir los patrones y convenciones de Laravel 11.
- RNF19: La documentación del API debe estar disponible para facilitar el mantenimiento y extensión futura.
- RNF20: El sistema debe permitir agregar nuevas funcionalidades sin afectar la versión actual.

### Interfaz de Usuario:

- RNF21: La aplicación debe tener una interfaz sencilla y fácil de usar.
- RNF22: La navegación debe ser intuitiva y consistente.
- RNF23: Los tiempos de carga de pantallas no deben exceder 2 segundos.

## 6. Especificaciones Técnicas

### Stack Tecnológico:

| Componente | Tecnología | Versión |
|---|---|---|
| **Frontend Móvil** | Flutter | Última versión estable |
| **Backend** | Laravel | 11 |
| **Lenguaje Backend** | PHP | 8.1+ |
| **Base de Datos** | MySQL | 8.0+ |
| **API** | REST | - |
| **Panel Administrativo** | Laravel Blade / Livewire | - |
| **Control de Versiones** | Git | - |

### Endpoints Principales de la API:

```
GET    /api/trufis              - Listar todos los trufis
GET    /api/trufis/{id}         - Obtener detalles de un trufi
GET    /api/rutas               - Listar rutas disponibles
GET    /api/rutas/{id}          - Obtener detalles de una ruta
GET    /api/paradas             - Listar paradas
GET    /api/radio-taxis         - Listar radio taxis disponibles
GET    /api/radio-taxis/{id}    - Obtener detalles de un radio taxi
GET    /api/referencias         - Listar puntos de referencia
POST   /admin/login             - Autenticación del panel administrativo
```

### Requisitos de Servidor:

- **SO**: Linux (CentOS, Ubuntu) o Windows Server
- **PHP**: 8.1 o superior con extensiones: bcmath, ctype, json, mbstring, openssl, pdo, tokenizer, xml
- **Servidor Web**: Apache con mod_rewrite o Nginx
- **Composer**: Para gestión de dependencias PHP
- **Node.js** (opcional): Para compilación de assets con Vite

## 7. Plan de Implementación

### Fase 1: Configuración Inicial
- Configuración del entorno de desarrollo
- Creación de modelos Eloquent en Laravel
- Diseño del esquema de base de datos
- Creación de migraciones

### Fase 2: Desarrollo del Backend (Laravel 11)
- Implementación de Controllers y Routes
- Desarrollo de la API REST
- Implementación de autenticación
- Validación de datos y manejo de errores

### Fase 3: Desarrollo del Frontend (Flutter)
- Diseño de interfaz de usuario
- Integración con API REST
- Implementación de servicios de geolocalización
- Gestión de estado de la aplicación

### Fase 4: Panel Administrativo
- Diseño de vistas administrativas
- Gestión de usuarios administradores
- Funcionalidades CRUD
- Reportes y análisis

### Fase 5: Testing y Deployment
- Pruebas unitarias y de integración
- Pruebas de aplicación en diferentes dispositivos
- Deployment en servidor de producción
- Monitoreo y mantenimiento

## 8. Consideraciones Importantes

- **Servidor Único**: El servidor del cliente solo acepta backend Laravel, por lo que todos los componentes de backend están integrados en Laravel 11.
- **API REST**: La comunicación entre Flutter y Laravel se realiza exclusivamente mediante API REST.
- **Base de Datos**: Proporciona persistencia centralizada para todos los datos del sistema.
- **Mantenibilidad**: El código sigue las convenciones y patrones recomendados por Laravel 11.
- **Escalabilidad**: El sistema está diseñado para permitir expansión a otras zonas de Cochabamba sin cambios mayores en la arquitectura.

## 9. Equipo de Desarrollo

- **Backend Developer**: Responsable de la API REST en Laravel 11
- **Mobile Developer**: Responsable de la aplicación Flutter
- **Admin Panel Developer**: Responsable del panel administrativo web
- **DevOps / DBA**: Responsable de infraestructura y base de datos
- **QA**: Responsable de pruebas y control de calidad

## 10. Cronograma Estimado

| Fase | Duración Estimada |
|---|---|
| Fase 1: Configuración Inicial | 2 semanas |
| Fase 2: Desarrollo Backend | 4 semanas |
| Fase 3: Desarrollo Frontend | 4 semanas |
| Fase 4: Panel Administrativo | 2 semanas |
| Fase 5: Testing y Deployment | 2 semanas |
| **Total** | **14 semanas** |

---

*Última actualización: Marzo 2026*
*Versión: 1.0*
