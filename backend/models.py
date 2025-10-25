from sqlalchemy import Column, Integer, String, DateTime, func
from database import Base

# Mapea la tabla existente 'usuarios' (no necesitas todas las columnas)
class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    correo = Column(String(100), nullable=False)
    contrasena = Column(String(255), nullable=False)
    fecha_registro = Column(DateTime, server_default=func.now())
