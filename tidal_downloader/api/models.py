from enum import Enum
from pydantic import BaseModel

class OutputFormat(str, Enum):
    flac = "flac"
    mp3 = "mp3"
    m4a = "m4a"
    wav = "wav"

class VerificationUri(BaseModel):
    verification_uri: str | None = None
    verification_url: str | None = None

    def get_uri(self) -> str:
        if self.verification_uri:
            return self.verification_uri
        if self.verification_url:
            return self.verification_url
        raise ValueError("No se proporcionó ni verification_uri ni verification_url") 