# Manual de Usuario — ColcaTrufis
### Aplicación Móvil de Transporte Público de Colcapirhua

---

**Versión:** 1.0.0  
**Fecha:** Abril 2026  
**Plataforma:** Android / iOS  
**Desarrollado para:** Gobierno Autónomo Municipal de Colcapirhua (GAM Colcapirhua)

---

## Tabla de Contenido

1. [Introducción](#1-introducción)
2. [Requisitos del Dispositivo](#2-requisitos-del-dispositivo)
3. [Instalación de la Aplicación](#3-instalación-de-la-aplicación)
4. [Pantalla de Inicio (Splash)](#4-pantalla-de-inicio-splash)
5. [Pantalla Principal — Mapa Interactivo](#5-pantalla-principal--mapa-interactivo)
   - 5.1 [Barra Superior (AppBar)](#51-barra-superior-appbar)
   - 5.2 [El Mapa](#52-el-mapa)
   - 5.3 [Botones Flotantes](#53-botones-flotantes)
   - 5.4 [Indicador de Filtro de Rutas](#54-indicador-de-filtro-de-rutas)
6. [Consultar Rutas de Trufis](#6-consultar-rutas-de-trufis)
   - 6.1 [Ver Lista de Trufis](#61-ver-lista-de-trufis)
   - 6.2 [Seleccionar un Trufi](#62-seleccionar-un-trufi)
   - 6.3 [Ver Recorrido de la Ruta](#63-ver-recorrido-de-la-ruta)
   - 6.4 [Marcadores de Inicio y Fin](#64-marcadores-de-inicio-y-fin)
   - 6.5 [Tocar Rutas en el Mapa](#65-tocar-rutas-en-el-mapa)
   - 6.6 [Horario de Atención](#66-horario-de-atención)
   - 6.7 [Referencias de Ubicación (Trufi)](#67-referencias-de-ubicación-trufi)
7. [Consultar Radiotaxis](#7-consultar-radiotaxis)
   - 7.1 [Ver Lista de Radiotaxis](#71-ver-lista-de-radiotaxis)
   - 7.2 [Seleccionar un Radiotaxi](#72-seleccionar-un-radiotaxi)
   - 7.3 [Ver Ubicación del Radiotaxi](#73-ver-ubicación-del-radiotaxi)
   - 7.4 [Llamar al Radiotaxi](#74-llamar-al-radiotaxi)
   - 7.5 [Paradas de Radiotaxis en el Mapa](#75-paradas-de-radiotaxis-en-el-mapa)
   - 7.6 [Referencias de Ubicación (Radiotaxi)](#76-referencias-de-ubicación-radiotaxi)
8. [Menú Lateral (Drawer)](#8-menú-lateral-drawer)
   - 8.1 [Sección Transporte](#81-sección-transporte)
   - 8.2 [Sección Información y Servicios](#82-sección-información-y-servicios)
   - 8.3 [Sección Municipio de Colcapirhua](#83-sección-municipio-de-colcapirhua)
   - 8.4 [Sección Configuración](#84-sección-configuración)
   - 8.5 [Sección Acerca de](#85-sección-acerca-de)
9. [Filtro de Rutas — Cercanas vs. Todas](#9-filtro-de-rutas--cercanas-vs-todas)
   - 9.1 [Modo "Cerca"](#91-modo-cerca)
   - 9.2 [Modo "Todas"](#92-modo-todas)
10. [Historial de Uso](#10-historial-de-uso)
    - 10.1 [Ver Historial](#101-ver-historial)
    - 10.2 [Reusar desde Historial](#102-reusar-desde-historial)
    - 10.3 [Limpiar Historial](#103-limpiar-historial)
11. [Normativas](#11-normativas)
12. [Números de Reclamos](#12-números-de-reclamos)
13. [Configuración de la Aplicación](#13-configuración-de-la-aplicación)
    - 13.1 [Cambiar Idioma](#131-cambiar-idioma)
    - 13.2 [Modo Oscuro](#132-modo-oscuro)
    - 13.3 [Radio de Búsqueda](#133-radio-de-búsqueda)
    - 13.4 [Modo de Centrado](#134-modo-de-centrado)
14. [Ubicación y GPS](#14-ubicación-y-gps)
    - 14.1 [Activar la Ubicación](#141-activar-la-ubicación)
    - 14.2 [Notificación de "GPS Apagado"](#142-notificación-de-gps-apagado)
    - 14.3 [Notificación de "Fuera de Colcapirhua"](#143-notificación-de-fuera-de-colcapirhua)
15. [Redes Sociales y Página Oficial](#15-redes-sociales-y-página-oficial)
16. [Preguntas Frecuentes (FAQ)](#16-preguntas-frecuentes-faq)
17. [Solución de Problemas](#17-solución-de-problemas)
18. [Contacto y Soporte](#18-contacto-y-soporte)

---

## 1. Introducción

**ColcaTrufis** es una aplicación móvil desarrollada para el Gobierno Autónomo Municipal de Colcapirhua que permite a los habitantes y visitantes del municipio:

- **Visualizar rutas de trufis** que circulan por Colcapirhua y zonas de Cochabamba.
- **Consultar información de radiotaxis** disponibles, incluyendo ubicación y número de contacto.
- **Buscar transporte** según su ubicación actual, mostrando rutas cercanas.
- **Ver el recorrido completo** de cada línea de trufi con puntos de inicio y fin.
- **Contactar radiotaxis** directamente desde la aplicación con un toque.

La aplicación cuenta con un mapa interactivo que muestra los límites del municipio de Colcapirhua, las rutas de los trufis disponibles y las paradas de radiotaxis.

---

## 2. Requisitos del Dispositivo

| Requisito | Especificación |
|---|---|
| **Sistema Operativo** | Android 8.0 (Oreo) o superior / iOS 12.0 o superior |
| **Conexión a Internet** | Requerida (Wi-Fi o datos móviles) |
| **GPS / Ubicación** | Recomendado (para funciones de cercanía) |
| **Espacio de Almacenamiento** | Mínimo 50 MB disponibles |
| **Permisos Requeridos** | Ubicación, Teléfono (para llamadas) |

---

## 3. Instalación de la Aplicación

### En Android:
1. Descargue el archivo APK proporcionado o acceda a la tienda de aplicaciones.
2. Si descarga el APK directamente, habilite la instalación de fuentes desconocidas:
   - Vaya a **Configuración → Seguridad → Fuentes desconocidas** y active la opción.
3. Abra el archivo APK descargado y toque **Instalar**.
4. Una vez instalada, el ícono de **ColcaTrufis** aparecerá en su menú de aplicaciones.

### En iOS:
1. Descargue la aplicación desde la App Store (cuando esté disponible).
2. La instalación se realizará automáticamente.

---

## 4. Pantalla de Inicio (Splash)

Al abrir la aplicación, verá una **pantalla de bienvenida** con las siguientes características:

- **Fondo oscuro** con gradiente radial en tonos teal/verde azulado.
- **Logo de ColcaTrufis** en el centro con una animación elegante de entrada (zoom suave).
- **Indicador de versión** ("v 1.0.0") en la parte inferior.
- **Patrón de puntos sutil** en el fondo que le da un aspecto profesional.

Esta pantalla dura aproximadamente **2.8 segundos** y luego navega automáticamente a la pantalla principal del mapa.

> **Nota:** No es necesario tocar nada durante la pantalla de inicio, la transición es automática.

---

## 5. Pantalla Principal — Mapa Interactivo

La pantalla principal es donde pasará la mayor parte del tiempo. Contiene un **mapa interactivo** que ocupa toda la pantalla.

### 5.1 Barra Superior (AppBar)

En la parte superior encontrará:

- **Ícono de menú** (☰) — A la izquierda, abre el menú lateral.
- **Logo del Municipio de Colcapirhua** — A la izquierda del título.
- **Logo de ColcaTrufis** — A la derecha del título.

La barra tiene un degradado transparente que se funde con el mapa para una experiencia visual fluida.

### 5.2 El Mapa

El mapa muestra:

- **Mapa base de OpenStreetMap** con calles y puntos de interés.
- **Límites de Colcapirhua** — Un polígono/contorno que delimita el municipio.
- **Rutas de trufis** — Líneas de colores mostrando los recorridos.
- **Paradas de radiotaxis** — Marcadores con íconos de taxi.
- **Su ubicación actual** — Un marcador azul con forma de persona (si activó el GPS).
- **Círculo de radio** — Muestra el radio de búsqueda de rutas cercanas (en tono anaranjado).

**Interacciones con el mapa:**
- **Arrastrar** — Mover el mapa en cualquier dirección.
- **Pellizcar** (pinch) — Hacer zoom in/out.
- **Tocar una ruta** — Ver información de esa línea de trufi.

### 5.3 Botones Flotantes

En la esquina inferior derecha encontrará tres botones:

| Botón | Ícono | Función |
|---|---|---|
| **Trufi** | 🚌 (bus) | Abre la lista de trufis disponibles. Se resalta en color cuando está activo. |
| **Radiotaxi** | 🚕 (taxi) | Abre la lista de radiotaxis disponibles. Se resalta en color cuando está activo. |
| **Centrar** | 📍 (ubicación) | Centra el mapa en su ubicación actual o en Colcapirhua (según la configuración). |

### 5.4 Indicador de Filtro de Rutas

En la esquina inferior izquierda verá un indicador que muestra:
- **"Cerca (250 m)"** — Si está mostrando rutas cercanas con el radio indicado.
- **"Todas"** — Si está mostrando todas las rutas disponibles.

Toque este indicador para cambiar el modo de filtro.

---

## 6. Consultar Rutas de Trufis

### 6.1 Ver Lista de Trufis

1. Toque el **botón de trufi** (🚌) en la esquina inferior derecha.
2. Se abrirá un panel deslizable desde abajo que muestra:
   - **Título**: "Trufi de Colcapirhua"
   - **Cantidad disponible**: Número de trufis registrados.
   - **Lista de trufis**: Cada tarjeta muestra el nombre de la línea.
3. Desplácese por la lista para ver todas las líneas disponibles.

### 6.2 Seleccionar un Trufi

1. Toque el nombre de la línea de trufi que desea consultar.
2. La aplicación:
   - Cierra el panel de lista.
   - Carga la ruta del trufi seleccionado en el mapa.
   - Centra el mapa en el inicio de la ruta.
   - Muestra marcadores de inicio (🟢 verde) y fin (🔴 rojo).
   - Muestra flechas de dirección a lo largo de la ruta.
   - Abre automáticamente la ventana de recorrido con las vías.

### 6.3 Ver Recorrido de la Ruta

Cuando selecciona un trufi, se abre automáticamente un panel inferior que muestra:

- **Título**: "Recorrido de la ruta"
- **Nombre de la línea**: La línea seleccionada.
- **Lista de vías/calles**: Cada calle por donde pasa la ruta, numeradas en orden.
- **Botón de Referencias**: Si hay referencias disponibles, aparece un botón para verlas.

**Para navegar a un punto del recorrido:**
- Toque cualquier calle de la lista.
- El mapa se centrará en ese punto y mostrará un marcador temporal con el nombre de la calle.

### 6.4 Marcadores de Inicio y Fin

Cuando una ruta está seleccionada en el mapa:
- **Marcador verde** (🟢 bandera) — Indica el punto de **inicio** de la ruta.
- **Marcador rojo** (🔴 bandera) — Indica el punto de **fin** de la ruta.
- **Flechas de dirección** — A lo largo de la ruta, indican el sentido de circulación del trufi.

### 6.5 Tocar Rutas en el Mapa

Cuando hay varias rutas visibles en el mapa:

1. Toque sobre cualquier parte de una ruta dibujada.
2. Se abrirá un panel con:
   - **Nombre de la línea**.
   - **Sindicato** al que pertenece (si aplica).
   - **Botón "Cerrar"** — Para cerrar el panel.
   - **Botón "Recorrido de la ruta"** — Para ver el recorrido completo y centrar la ruta en el mapa.

### 6.6 Horario de Atención

Si el trufi seleccionado tiene horario registrado, aparecerá una tarjeta debajo de la tarjeta de selección:

- Muestra **"Horario de atención"** con el rango horario (ejemplo: "06:00–21:00").
- Si no hay horario registrado, muestra "Sin horario registrado".

### 6.7 Referencias de Ubicación (Trufi)

Si la ruta tiene referencias de ubicación asociadas:

1. En el panel de recorrido, verá un botón **"Referencias (N)"** donde N es la cantidad.
2. Toque el botón para ver la lista de referencias.
3. Cada referencia muestra su nombre y puede tocarse para centrar el mapa en esa ubicación.

---

## 7. Consultar Radiotaxis

### 7.1 Ver Lista de Radiotaxis

1. Toque el **botón de radiotaxi** (🚕) en la esquina inferior derecha.
2. Se abrirá un panel con:
   - **Título**: "Radiotaxi de Colcapirhua"
   - **Cantidad disponible**.
   - **Lista de radiotaxis**: Cada tarjeta muestra el nombre comercial.

### 7.2 Seleccionar un Radiotaxi

1. Toque el nombre del radiotaxi que desea consultar.
2. La aplicación:
   - Cierra el panel de lista.
   - Centra el mapa en la ubicación del radiotaxi (si tiene coordenadas registradas).
   - Abre una ventana de información del radiotaxi.
   - Guarda la selección en el historial.

### 7.3 Ver Ubicación del Radiotaxi

Cuando selecciona un radiotaxi, se abre un panel inferior con:

- **Título**: "Ubicación"
- **Nombre del radiotaxi**.
- **Tarjeta de ubicación** — Con la dirección registrada. Toque para centrar el mapa en esa ubicación.
- **Botón de llamada** — Si tiene teléfono registrado, aparece un botón para llamar directamente.
- **Botón de Referencias** — Si hay referencias disponibles.

### 7.4 Llamar al Radiotaxi

Para llamar a un radiotaxi:

1. Seleccione un radiotaxi de la lista.
2. En la ventana de información, toque el **botón de llamada** con el número de teléfono.
3. Se abrirá un **diálogo de confirmación**: "¿Deseas llamar a este radiotaxi?"
4. Toque **"Llamar"** para iniciar la llamada o **"Cancelar"** para cerrar.

> **Nota:** Se necesita el permiso de teléfono activo para realizar llamadas.

### 7.5 Paradas de Radiotaxis en el Mapa

Cuando está en modo **Radiotaxi**:
- El mapa muestra marcadores en las ubicaciones de paradas de radiotaxis.
- Cada marcador incluye una etiqueta con el nombre del radiotaxi.
- Los marcadores se filtran según el radio de búsqueda configurado (igual que las rutas).

### 7.6 Referencias de Ubicación (Radiotaxi)

Si el radiotaxi tiene referencias de ubicación:
1. En la ventana de información, verá un botón **"Referencias (N)"**.
2. Toque para ver la lista de referencias geográficas.
3. Toque cualquier referencia para navegar a su ubicación en el mapa.

---

## 8. Menú Lateral (Drawer)

Acceda al menú lateral tocando el **ícono de menú** (☰) en la esquina superior izquierda, o deslizando desde el borde izquierdo de la pantalla.

### 8.1 Sección Transporte

#### Sindicatos
- Muestra una **lista expandible** de sindicatos de transporte.
- Cada sindicato se puede expandir para ver los trufis que pertenecen a él.
- Toque un trufi del sindicato para ver su ruta directamente.

#### Radiotaxis
- Muestra una **lista expandible** de radiotaxis registrados.
- Toque cualquier radiotaxi para ver su información y ubicación.

### 8.2 Sección Información y Servicios

#### Historial
- Muestra la cantidad de registros guardados.
- Toque para abrir el historial completo con pestañas (Trufis / Radiotaxis).

#### Números de Reclamos
- Acceso a los números de teléfono y WhatsApp para reclamos de transporte.

#### Normativas
- Acceso a las normativas y regulaciones de transporte vigentes.

### 8.3 Sección Municipio de Colcapirhua

#### Redes Sociales
- Lista expandible con enlaces directos a:
  - **TikTok** — @gamdecolcapirhua
  - **YouTube** — @gamdecolcapirhua
  - **Facebook** — municipiodecolcapirhua
  - **Instagram** — alcaldiadecolcapirhua
  - **X (Twitter)** — @GAMColcapirhua

#### Página Oficial
- Enlace directo a **www.colcapirhua.gob.bo**

### 8.4 Sección Configuración

#### Idioma
- Selector de idioma con tres opciones:
  - **Español** (predeterminado)
  - **English** (Inglés)
  - **Quechua**

#### Modo Oscuro
- Interruptor para activar/desactivar el tema oscuro de la aplicación.

#### Radio de Búsqueda
- Deslizador para ajustar el radio de búsqueda de rutas cercanas.
- Rango: **50 metros** a **2000 metros**.
- El valor actual se muestra en metros junto al deslizador.

#### Centrar
- Permite elegir el comportamiento del botón de centrado:
  - **Centrar Colcapirhua** — Siempre centra en el municipio.
  - **Centrar ubicación** — Centra en su posición actual (requiere GPS).

### 8.5 Sección Acerca de

- Muestra información sobre la aplicación ColcaTrufis:
  - Descripción del propósito de la aplicación.
  - Funcionalidades principales.

---

## 9. Filtro de Rutas — Cercanas vs. Todas

La aplicación ofrece dos modos de visualización de rutas:

### 9.1 Modo "Cerca"

- **Requiere GPS activado.**
- Muestra un **círculo anaranjado** alrededor de su ubicación.
- Solo muestra las rutas que **pasan dentro del radio** configurado.
- Ideal para encontrar trufis que pasan cerca de donde usted se encuentra.
- El radio se puede ajustar desde **50 m hasta 2000 m** en la configuración.

### 9.2 Modo "Todas"

- **No requiere GPS** (aunque es recomendable).
- Muestra **todas las rutas** disponibles en el mapa.
- Ideal para explorar todas las opciones de transporte disponibles.

**Para cambiar entre modos:**
1. Toque el indicador de filtro en la esquina inferior izquierda.
2. Seleccione **"Cerca"** o **"Todas"** en el panel que aparece.

---

## 10. Historial de Uso

La aplicación guarda automáticamente un historial de los trufis y radiotaxis que ha consultado.

### 10.1 Ver Historial

1. Abra el **menú lateral** (☰).
2. Toque **"Historial"** en la sección de Información y Servicios.
3. Se abrirá un panel con dos pestañas:
   - **Trufis recientes** — Lista de trufis consultados.
   - **Radiotaxis recientes** — Lista de radiotaxis consultados.

### 10.2 Reusar desde Historial

- **Para trufis:** Toque un trufi del historial para ver su ruta nuevamente.
- **Para radiotaxis:** Toque un radiotaxi del historial para llamar directamente (si tiene teléfono registrado).

Cada elemento muestra:
- Nombre del trufi/radiotaxi.
- Tiempo transcurrido desde la última consulta ("Hace 5 min", "Hace 2h", etc.).

### 10.3 Limpiar Historial

1. En la pantalla de historial, toque **"Limpiar historial"** (botón rojo).
2. Confirme la acción en el diálogo que aparece.
3. El historial se borrará permanentemente (por pestaña: trufis o radiotaxis).

> **Nota:** Se guardan hasta **20 registros** por categoría. Los más antiguos se eliminan automáticamente.

---

## 11. Normativas

Para consultar las normativas de transporte:

1. Abra el **menú lateral** (☰).
2. Toque **"Normativas"**.
3. Se mostrará una lista de normativas vigentes con:
   - Categoría.
   - Título.
   - Descripción.
   - Enlace al documento PDF (si disponible).

---

## 12. Números de Reclamos

Para acceder a los números de reclamos:

1. Abra el **menú lateral** (☰).
2. Toque **"Números de Reclamos"**.
3. Se mostrará la información de contacto para reclamos:
   - **Teléfono de reclamos** — Con opción de llamar directamente.
   - **WhatsApp de reclamos** — Con opción de abrir la conversación.

---

## 13. Configuración de la Aplicación

### 13.1 Cambiar Idioma

1. Abra el **menú lateral** (☰).
2. En la sección **Configuración**, busque **"Idioma"**.
3. Toque el selector desplegable y elija:
   - **Español** — Idioma predeterminado.
   - **English** — Interfaz en inglés.
   - **Quechua** — Interfaz en quechua.
4. El cambio se aplica **inmediatamente** sin necesidad de reiniciar.

### 13.2 Modo Oscuro

1. Abra el **menú lateral** (☰).
2. En la sección **Configuración**, active o desactive el interruptor de **"Modo oscuro"**.
3. El tema cambia inmediatamente:
   - **Modo claro** — Fondos blancos, texto oscuro.
   - **Modo oscuro** — Fondos oscuros (azul marino), texto claro.

### 13.3 Radio de Búsqueda

1. Abra el **menú lateral** (☰).
2. En la sección **Configuración**, encuentre **"Distancia de rutas"**.
3. Deslice el control para ajustar el radio:
   - **Mínimo:** 50 metros.
   - **Máximo:** 2000 metros (2 km).
   - **Predeterminado:** 250 metros.
4. El valor actual se muestra a la derecha del título.
5. Las rutas en el mapa se actualizan automáticamente al cambiar el radio.

### 13.4 Modo de Centrado

1. Abra el **menú lateral** (☰).
2. En la sección **Configuración**, toque **"Centrar"**.
3. Elija una opción:
   - **Centrar Colcapirhua** — El botón de centrar siempre lleva al centro del municipio.
   - **Centrar ubicación** — El botón de centrar lleva a su posición GPS actual.

---

## 14. Ubicación y GPS

### 14.1 Activar la Ubicación

Para aprovechar al máximo la aplicación, active la ubicación de su dispositivo:

1. La primera vez que abra la aplicación, se le solicitará **permiso de ubicación**.
2. Toque **"Permitir"** o **"Permitir mientras se usa la aplicación"**.
3. Asegúrese de que el **GPS esté encendido** en la configuración de su dispositivo.

### 14.2 Notificación de "GPS Apagado"

Si la ubicación no está disponible, aparecerá un banner en la parte inferior del mapa:

- **"GPS apagado"** — Le indica que active la ubicación.
- **"Activar ubicación"** — Botón para intentar solicitar el permiso nuevamente.
- **"Cancelar"** — Cierra el banner sin activar la ubicación.

> Sin GPS activo, las rutas se muestran en modo **"Todas"** automáticamente.

### 14.3 Notificación de "Fuera de Colcapirhua"

Si se detecta que su ubicación está fuera de los límites del municipio:

- Aparece un banner informativo: **"Estás fuera de Colcapirhua"**.
- Le informa que la aplicación muestra información de Colcapirhua.
- Puede seguir usando la aplicación normalmente.
- Toque **"Entendido"** para cerrar el mensaje.

---

## 15. Redes Sociales y Página Oficial

Desde el menú lateral puede acceder a las redes sociales oficiales del municipio:

| Red Social | Enlace |
|---|---|
| **TikTok** | @gamdecolcapirhua |
| **YouTube** | @gamdecolcapirhua |
| **Facebook** | municipiodecolcapirhua |
| **Instagram** | alcaldiadecolcapirhua |
| **X (Twitter)** | @GAMColcapirhua |
| **Página Oficial** | www.colcapirhua.gob.bo |

Al tocar cualquier enlace, se abrirá en su navegador o aplicación correspondiente.

---

## 16. Preguntas Frecuentes (FAQ)

### ¿Necesito Internet para usar la aplicación?
**Sí.** La aplicación requiere conexión a Internet para cargar las rutas, información de radiotaxis y el mapa base desde el servidor.

### ¿Necesito GPS para usar la aplicación?
**No es obligatorio**, pero es recomendable. Sin GPS, la aplicación muestra todas las rutas disponibles en lugar de filtrar por cercanía.

### ¿Puedo usar la aplicación fuera de Colcapirhua?
**Sí.** La aplicación funciona en cualquier lugar, pero la información mostrada corresponde específicamente a Colcapirhua y zonas de Cochabamba.

### ¿Las rutas se actualizan?
**Sí.** Las rutas se obtienen del servidor cada vez que abre la aplicación, por lo que siempre verá información actualizada sin necesidad de actualizar la aplicación.

### ¿Puedo cambiar el idioma en cualquier momento?
**Sí.** Vaya al menú lateral → Configuración → Idioma. El cambio es inmediato.

### ¿Se guardan mis datos personales?
**No.** La aplicación no recopila ni almacena datos personales. El historial se guarda únicamente en su dispositivo.

### ¿Cómo puedo ajustar el radio de búsqueda?
Abra el menú lateral → Configuración → Distancia de rutas → Deslice el control entre 50 y 2000 metros.

### ¿Qué significan los colores de los marcadores en el mapa?
- **Verde (🟢)** — Punto de inicio de la ruta.
- **Rojo (🔴)** — Punto de fin de la ruta.
- **Azul (🔵)** — Su ubicación actual.
- **Anaranjado (círculo)** — Radio de búsqueda de rutas cercanas.

---

## 17. Solución de Problemas

| Problema | Solución |
|---|---|
| **El mapa no carga** | Verifique su conexión a Internet. El mapa requiere datos o Wi-Fi. |
| **No aparecen rutas** | Asegúrese de estar en modo "Todas" o active el GPS para modo "Cerca". |
| **El GPS no funciona** | Active la ubicación en la configuración de su dispositivo. Asegúrese de haber otorgado permiso. |
| **No puedo llamar a un radiotaxi** | Verifique que la aplicación tenga permiso para realizar llamadas telefónicas. |
| **La aplicación se cierra inesperadamente** | Cierre la aplicación completamente y vuelva a abrirla. Si persiste, reinstale la aplicación. |
| **La lista de trufis está vacía** | Espere a que termine de cargar los datos. Si el problema persiste, verifique su conexión a Internet. |
| **El modo oscuro no se aplica** | El modo oscuro se activa desde el menú lateral → Configuración → Modo oscuro. |

---

## 18. Contacto y Soporte

Para soporte técnico o reportar problemas con la aplicación:

- **Página web:** [www.colcapirhua.gob.bo](https://www.colcapirhua.gob.bo/)
- **Facebook:** [municipiodecolcapirhua](https://www.facebook.com/municipiodecolcapirhua)
- **Reclamos de transporte:** Disponibles desde el menú lateral → "Números de Reclamos"

---

*Manual de Usuario — ColcaTrufis v1.0.0*  
*Gobierno Autónomo Municipal de Colcapirhua*  
*Última actualización: Abril 2026*
