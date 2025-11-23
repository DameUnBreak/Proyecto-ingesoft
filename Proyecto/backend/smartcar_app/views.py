from rest_framework.decorators import api_view
from rest_framework.response import Response

# ✅ IMPORTS QUE FALTABAN
from django.contrib.auth.hashers import make_password, check_password
from .models import Usuario
from .serializers import UsuarioSerializer


@api_view(["GET"])
def health(request):
    return Response({
        "mensaje": "Conexión OK con SQLite ✅",
        "bd": "smartcar_sqlite"
    })


@api_view(["POST"])
def crear_usuario(request):
    data = request.data.copy()
    data["contrasena"] = make_password(data["contrasena"])  # encripta

    serializer = UsuarioSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=201)

    return Response(serializer.errors, status=400)


@api_view(["GET"])
def obtener_usuario(request, user_id):
    try:
        usuario = Usuario.objects.get(id=user_id)
    except Usuario.DoesNotExist:
        return Response({"error": "Usuario no encontrado"}, status=404)

    serializer = UsuarioSerializer(usuario)
    return Response(serializer.data)


@api_view(["POST"])
def login(request):
    correo = request.data.get("correo")
    contrasena = request.data.get("contrasena")

    try:
        usuario = Usuario.objects.get(correo=correo)
    except Usuario.DoesNotExist:
        return Response({"error": "Usuario no encontrado"}, status=404)

    if check_password(contrasena, usuario.contrasena):
        return Response({"message": "Login exitoso"})
    else:
        return Response({"error": "Contraseña incorrecta"}, status=400)


@api_view(["GET"])
def hola_mundo(request):
    correo_hola = "hola@smartcar.test"

    usuario = Usuario.objects.filter(correo=correo_hola).first()

    if not usuario:
        usuario = Usuario(
            nombre="Hola Mundo",
            correo=correo_hola,
            contrasena=make_password("12345")
        )
        usuario.save()

    return Response({
        "mensaje": f"Hola, {usuario.nombre}! (id={usuario.id}) desde SQLite → Django ✅",
        "usuario": {
            "id": usuario.id,
            "nombre": usuario.nombre,
            "correo": usuario.correo,
        }
    })
