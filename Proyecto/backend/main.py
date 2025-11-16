from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
from sqlalchemy import text

from database import get_db
from models import Usuario

app = FastAPI(title="SmartCar API", version="1.0")

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="SmartCar API", version="1.0")

# CORS para Flutter Web (localhost)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # si quieres, luego restringe a http://localhost:* y http://127.0.0.1:*
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ----------- Schemas (Pydantic) -----------
class UsuarioCreate(BaseModel):
    nombre: str
    correo: EmailStr
    contrasena: str

class UsuarioOut(BaseModel):
    id: int
    nombre: str
    correo: EmailStr
    class Config:
        orm_mode = True

# ----------- Health / Conexión -----------
@app.get("/")
def health(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))
    return {"mensaje": "Conexión OK con MySQL ✅", "bd": "smart_car"}

# ----------- CRUD mínimo Usuario -----------
@app.post("/usuarios", response_model=UsuarioOut)
def crear_usuario(payload: UsuarioCreate, db: Session = Depends(get_db)):
    # Verifica correo único (la tabla tiene UNIQUE en la práctica)
    existe = db.query(Usuario).filter(Usuario.correo == payload.correo).first()
    if existe:
        raise HTTPException(status_code=400, detail="El correo ya existe")
    user = Usuario(nombre=payload.nombre, correo=payload.correo, contrasena=payload.contrasena)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@app.get("/usuarios/{user_id}", response_model=UsuarioOut)
def obtener_usuario(user_id: int, db: Session = Depends(get_db)):
    user = db.query(Usuario).get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return user

# ----------- Hola Mundo (instanciación mínima) -----------
@app.get("/hola_mundo")
def hola_mundo(db: Session = Depends(get_db)):
    """
    Si no existe, crea un usuario 'Hola Mundo'; luego lo consulta y devuelve
    un mensaje de texto que el frontend mostrará en un botón/label.
    """
    user = db.query(Usuario).filter(Usuario.correo == "hola@smartcar.test").first()
    if not user:
        user = Usuario(nombre="Hola Mundo", correo="hola@smartcar.test", contrasena="12345")
        db.add(user)
        db.commit()
        db.refresh(user)
    return {
        "mensaje": f"Hola, {user.nombre}! (id={user.id}) desde MySQL → FastAPI → UI",
        "usuario": {"id": user.id, "nombre": user.nombre, "correo": user.correo},
    }
