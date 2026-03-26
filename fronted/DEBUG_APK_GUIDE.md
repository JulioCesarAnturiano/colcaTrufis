# 🔧 Guía de Debugging - APK vs Desarrollo

## Problema Resuelto: Ubicaciones no funcionan en APK

### ❌ Causa Principal
Las APIs de ubicaciones funcionaban en desarrollo pero fallaban en el APK debido a:

1. **Configuración HTTPS**: Android bloquea conexiones no seguras por defecto
2. **URLs hardcodeadas**: localhost vs producción
3. **Timeouts**: APIs pesadas necesitan más tiempo
4. **Errores enmascarados**: `.catchError((_) => [])` ocultaba problemas

### ✅ Soluciones Implementadas

#### 1. **network_security_config.xml**
- **Ubicación**: `android/app/src/main/res/xml/network_security_config.xml`
- **Propósito**: Permite HTTPS con certificados válidos + HTTP para desarrollo

#### 2. **AndroidManifest.xml actualizado**
- **Cambios**: Añadido `networkSecurityConfig` y `usesCleartextTraffic`
- **Efecto**: Permite conexiones HTTP en desarrollo y HTTPS en producción

#### 3. **AppConfig dinámico**
- **Archivo**: `lib/config/app_config.dart`
- **Beneficio**: URL automática según entorno (dev/prod)

#### 4. **ApiService mejorado**
- **Cambios**:
  - Timeouts específicos para APIs pesadas (45s ubicaciones vs 15s normales)
  - Headers adicionales `User-Agent`
  - Logging detallado para debugging
  - Re-lanza errores para mejor debugging

#### 5. **Manejo de errores mejorado**
- **Antes**: `.catchError((_) => [])`
- **Ahora**: Logs detallados + manejo específico

### 🚀 Para Testing

#### Debug/Desarrollo:
```bash
flutter run --debug
```
- Usa: `http://10.0.2.2:8000/api` (emulador)
- Logs completos visibles

#### Release/APK:
```bash
flutter build apk --release
```
- Usa: `https://moviruta.colcapirhua.gob.bo/api`
- Configuración HTTPS automática

### 📋 Checklist Futuro

Antes de generar APK, verificar:
- [ ] Backend desplegado y accesible vía HTTPS
- [ ] Certificado SSL válido
- [ ] APIs responden en < 45 segundos
- [ ] No errores 500/404 en endpoints de ubicaciones
- [ ] Logs del cliente muestran respuestas HTTP correctas

### 🔍 Debug APK Issues

Si algo falla en APK pero funciona en desarrollo:

1. **Verificar logs**: `flutter logs` o `adb logcat`
2. **Probar URLs manualmente**: `curl -v https://moviruta.colcapirhua.gob.bo/api/ubicaciones`
3. **Verificar timeout**: APIs lentas necesitan más tiempo
4. **SSL**: Certificado válido y no autofirmado

### 📞 Endpoints Críticos
- `/trufis/{id}/ubicaciones` - Pesado, necesita 45s timeout
- `/ubicaciones` - Muy pesado, necesita 45s timeout
- `/trufis/{id}/rutas/geojson` - Normal, 15s suficiente

---
**¿Problema similar?** Revisa logs y verifica configuración HTTPS primero.