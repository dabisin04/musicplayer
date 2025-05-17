# Tidal API

API REST para streaming y descarga de música de Tidal, diseñada para ser consumida por aplicaciones Flutter.

## Requisitos

- Python 3.12 o superior
- Cuenta de Tidal Premium o HiFi
- pip (gestor de paquetes de Python)

## Instalación

1. Clonar el repositorio:
```bash
git clone <url-del-repositorio>
cd tidal-api
```

2. Crear un entorno virtual:
```bash
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
```

3. Instalar las dependencias:
```bash
pip install -r requirements.txt
```

4. Crear un archivo `.env` en la raíz del proyecto con las siguientes variables:
```
SECRET_KEY=tu_clave_secreta_muy_segura_aqui
TIDAL_USERNAME=tu_usuario_tidal
TIDAL_PASSWORD=tu_password_tidal
```

## Ejecución

Para iniciar el servidor:
```bash
uvicorn api.main:app --reload
```

El servidor estará disponible en `http://localhost:8000`

## Documentación de la API

La documentación interactiva de la API está disponible en:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Endpoints principales

### Autenticación
- `POST /token`: Obtener token de acceso
- `GET /users/me`: Obtener información del usuario actual

### Tidal
- `POST /tidal/login`: Iniciar sesión en Tidal
- `GET /tidal/track/{track_id}`: Obtener información de una pista
- `GET /tidal/stream/{track_id}`: Stream de una pista
- `GET /tidal/download/{track_id}`: Descargar una pista

## Uso con Flutter

Para consumir esta API desde una aplicación Flutter, necesitarás:

1. Implementar la autenticación JWT
2. Manejar el streaming de audio usando el paquete `just_audio` o similar
3. Implementar la descarga de archivos usando el paquete `dio` o similar

### Ejemplo de código Flutter para streaming:

```dart
import 'package:just_audio/just_audio.dart';

final player = AudioPlayer();
final trackId = '123456';

// Obtener el token de acceso
final token = await getToken();

// Configurar el stream
await player.setUrl(
  'http://tu-api.com/tidal/stream/$trackId',
  headers: {
    'Authorization': 'Bearer $token',
  },
);

// Reproducir
await player.play();
```

### Ejemplo de código Flutter para descarga:

```dart
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

final dio = Dio();
final token = await getToken();

// Obtener el directorio de descargas
final dir = await getExternalStorageDirectory();
final path = '${dir.path}/$trackId.mp3';

// Descargar el archivo
await dio.download(
  'http://tu-api.com/tidal/download/$trackId',
  path,
  options: Options(
    headers: {
      'Authorization': 'Bearer $token',
    },
  ),
);
```

## Seguridad

- La API utiliza autenticación JWT
- Las credenciales de Tidal se almacenan de forma segura en variables de entorno
- Se recomienda usar HTTPS en producción
- Implementar rate limiting para prevenir abusos

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo LICENSE para más detalles. 