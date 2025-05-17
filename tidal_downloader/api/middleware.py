from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
import json

class SessionVerificationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        try:
            # Verificar si la ruta requiere autenticación
            if not self._requires_auth(request.url.path):
                return await call_next(request)

            # Por ahora, permitimos todas las peticiones
            # La verificación real de sesión se hará en los endpoints
            return await call_next(request)
        except Exception as e:
            print(f"Error en middleware: {str(e)}")
            return await call_next(request)

    def _requires_auth(self, path: str) -> bool:
        # Rutas que no requieren autenticación
        public_paths = [
            "/login",
            "/login/",
            "/tidal/login",
            "/tidal/login/",
            "/tidal/login/verify",
            "/tidal/login/verify/",
        ]
        return not any(path.startswith(p) for p in public_paths)

# Crear instancia del middleware
verify_session_middleware = SessionVerificationMiddleware 