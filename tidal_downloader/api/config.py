from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .middleware import SessionVerificationMiddleware

def configure_app(app: FastAPI) -> None:
    """Configura la aplicación FastAPI con middleware y configuraciones necesarias."""
    
    # Configuración de CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Añadir middleware de verificación de sesión
    app.add_middleware(SessionVerificationMiddleware) 