from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

from .models import Usuario, Lista, Item
from .serializers import UsuarioSerializer, ListaSerializer, ItemSerializer


# ===========================
# Helper: usuario demo
# ===========================
def get_demo_user():
    """
    Mientras no tenemos autenticación real integrada con Flutter,
    si no nos mandan usuario usamos siempre un usuario 'demo'.
    """
    usuario = Usuario.objects.first()
    if not usuario:
        usuario = Usuario.objects.create(
            nombre="Demo",
            correo="demo@smartcar.test",
            contrasena="1234",
        )
    return usuario


# ===========================
# ENDPOINT DE SALUD
# ===========================
@api_view(["GET"])
def health(request):
    """
    Endpoint simple para probar que el backend está vivo.
    GET /api/health/
    """
    return Response({"status": "ok"})


# ===========================
# HOLA MUNDO (PRUEBA)
# ===========================
@api_view(["GET"])
def hola_mundo(request):
    """
    GET /api/hola/
    """
    return Response({"message": "Hola desde SmartCar API"})


# ===========================
# USUARIOS
# ===========================
@api_view(["POST"])
def crear_usuario(request):
    """
    Crea un usuario nuevo.
    POST /api/usuarios/crear/
    Body JSON:
    {
        "nombre": "Lina",
        "correo": "lina@example.com",
        "contrasena": "1234"
    }
    """
    data = {
        "nombre": request.data.get("nombre"),
        "correo": request.data.get("correo"),
        "contrasena": request.data.get("contrasena"),
    }

    serializer = UsuarioSerializer(data=data)
    if serializer.is_valid():
        usuario = serializer.save()
        return Response(
            UsuarioSerializer(usuario).data,
            status=status.HTTP_201_CREATED,
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET"])
def obtener_usuario(request, user_id):
    """
    Obtiene la info de un usuario por id.
    GET /api/usuarios/<user_id>/
    """
    try:
        usuario = Usuario.objects.get(pk=user_id)
    except Usuario.DoesNotExist:
        return Response(
            {"detail": "Usuario no encontrado"},
            status=status.HTTP_404_NOT_FOUND,
        )

    serializer = UsuarioSerializer(usuario)
    return Response(serializer.data)


@api_view(["POST"])
def login(request):
    """
    Login muy sencillo (NO para producción).
    POST /api/login/
    Body JSON:
    {
        "correo": "lina@example.com",
        "contrasena": "1234"
    }
    """
    correo = request.data.get("correo")
    contrasena = request.data.get("contrasena")

    if not correo or not contrasena:
        return Response(
            {"detail": "Faltan correo o contraseña"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        # OJO: esto compara la contraseña en texto plano.
        usuario = Usuario.objects.get(correo=correo, contrasena=contrasena)
    except Usuario.DoesNotExist:
        return Response(
            {"detail": "Credenciales inválidas"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Lo que le vamos a devolver al frontend
    data = {
        "id": usuario.id,
        "nombre": usuario.nombre,
        "correo": usuario.correo,
    }
    return Response(data, status=status.HTTP_200_OK)


# ===========================
# LISTAS
# ===========================
@api_view(["GET", "POST"])
def listas(request):
    """
    GET /api/listas/?usuario_id=1   -> devuelve listas del usuario
    POST /api/listas/              -> crea una lista nueva

    Body POST que espera Flutter ahora mismo:
    {
        "nombre": "Lista mercado",
    OPTIONAL "presupuesto": 150000
    }
    (sin campo 'usuario'; lo completamos aquí)
    """

    # ---------- GET ----------
    if request.method == "GET":
        usuario_id = request.query_params.get("usuario_id")

        if usuario_id:
            qs = Lista.objects.filter(usuario_id=usuario_id)
        else:
            # si no nos mandan usuario_id, usamos el usuario demo
            usuario = get_demo_user()
            qs = Lista.objects.filter(usuario=usuario)

        serializer = ListaSerializer(qs, many=True)
        # Para que cuadre con ApiService: envolvemos en {"listas": [...]}
        return Response({"listas": serializer.data}, status=status.HTTP_200_OK)

    # ---------- POST ----------
    # Aquí adaptamos para que, si Flutter NO manda 'usuario',
    # usemos el usuario demo automáticamente.
    data = dict(request.data)

    usuario_id = data.get("usuario")
    if not usuario_id:
        usuario = get_demo_user()
        data["usuario"] = usuario.id

    serializer = ListaSerializer(data=data)
    if serializer.is_valid():
        lista = serializer.save()
        return Response(
            ListaSerializer(lista).data,
            status=status.HTTP_201_CREATED,
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(["GET", "PUT", "DELETE"])
def lista_detalle(request, lista_id):
    """
    GET    /api/listas/<lista_id>/   -> detalle de una lista
    PUT    /api/listas/<lista_id>/   -> actualizar una lista
    DELETE /api/listas/<lista_id>/   -> borrar una lista
    """
    try:
        lista = Lista.objects.get(pk=lista_id)
    except Lista.DoesNotExist:
        return Response(
            {"detail": "Lista no encontrada"},
            status=status.HTTP_404_NOT_FOUND,
        )

    if request.method == "GET":
        serializer = ListaSerializer(lista)
        return Response(serializer.data, status=status.HTTP_200_OK)

    if request.method == "PUT":
        serializer = ListaSerializer(lista, data=request.data, partial=True)
        if serializer.is_valid():
            lista = serializer.save()
            return Response(
                ListaSerializer(lista).data,
                status=status.HTTP_200_OK,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    if request.method == "DELETE":
        lista.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
