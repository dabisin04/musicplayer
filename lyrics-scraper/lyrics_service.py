import lyricsgenius

_genius_instance = None

def inicializar_genius(token):
    global _genius_instance
    _genius_instance = lyricsgenius.Genius(token)

def obtener_letra(titulo, artista=None):
    if not _genius_instance:
        raise RuntimeError("Genius no ha sido inicializado. Usa /set-genius-token para establecer el token.")
    cancion = _genius_instance.search_song(titulo, artista) if artista else _genius_instance.search_song(titulo)
    if cancion:
        return {
            "track_name": cancion.title,
            "artist": cancion.artist,
            "lyrics": cancion.lyrics
        }
    return None
