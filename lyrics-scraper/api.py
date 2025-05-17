from fastapi import FastAPI, Query, HTTPException
from pydantic import BaseModel
from lyrics_service import obtener_letra, inicializar_genius

app = FastAPI()

class GeniusTokenRequest(BaseModel):
    token: str

@app.post("/set-genius-token")
def set_genius_token(request: GeniusTokenRequest):
    try:
        inicializar_genius(request.token)
        return {"status": "success", "message": "Token de Genius configurado correctamente."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error al configurar el token: {str(e)}")

@app.get("/lyrics")
def get_lyrics(title: str = Query(...), artist: str = Query(None)):
    try:
        result = obtener_letra(title, artist)
        return result if result else {"error": "No se encontró la letra"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
