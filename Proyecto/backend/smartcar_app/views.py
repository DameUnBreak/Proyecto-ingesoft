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



@api_view(["GET"])
def resumen_lista(request, lista_id):
    lista = Lista.objects.get(id=lista_id)
    total = sum(item.cantidad * item.precio_unitario for item in lista.items.all())
    data = {
        "presupuesto": lista.presupuesto,
        "total": total,
        "supera_presupuesto": total > lista.presupuesto
    }
    return Response(data)


@api_view(["GET"])
def recomendaciones(request, lista_id):

    lista = Lista.objects.get(id=lista_id)
    items = lista.items.all()

    recomendaciones = []

    # 1. Si supera presupuesto
    total = sum(i.cantidad * i.precio_unitario for i in items)
    if total > lista.presupuesto:
        recomendaciones.append("Has superado el presupuesto, considera reducir gastos.")

    # 2. Categorías con más gasto
    categorias = {}
    for i in items:
        subtotal = i.cantidad * i.precio_unitario
        categorias[i.categoria] = categorias.get(i.categoria, 0) + subtotal
    if categorias:
        cat_mayor = max(categorias, key=categorias.get)
        recomendaciones.append(f"Estás gastando mucho en '{cat_mayor}'.")


    # 3. Cantidades demasiado grandes
    for i in items:
        if i.cantidad >= 10:
            recomendaciones.append(
                f"La cantidad del ítem '{i.nombre}' es bastante alta. Revisa si realmente necesitas tanto."
            )
            break
    
    # 4. Ítems de precio elevado
    for i in items:
        if i.precio_unitario > 30000:
            recomendaciones.append(
                f"El ítem '{i.nombre}' tiene un precio elevado. Considera buscar alternativas más económicas."
            )
            break
        
    # 5. Ítems duplicados
    nombres = {}
    for i in items:
        nombres[i.nombre] = nombres.get(i.nombre, 0) + 1
    
    duplicados = [n for n, count in nombres.items() if count > 1]
    if duplicados:
        recomendaciones.append(
            f"Tienes ítems duplicados en la lista: {', '.join(duplicados)}. "
            "Elimina uno de ellos para evitar compras innecesarias."
        )
        
    # 6. Lista con pocos ítems
    if len(items) <= 2:
        recomendaciones.append(
            "Tu lista tiene pocos ítems. ¿Seguro que no olvidaste agregar algo importante?"
        )
 
    # 7) Valores mal formateados (cantidad o precio 0 o negativo)
    for i in items:
        if i.cantidad <= 0:
            recomendaciones.append(
                f"El ítem '{i.nombre or '(sin nombre)'}' tiene una cantidad inválida (debe ser mayor a 0)."
            )
            break

        if i.precio_unitario < 0:
            recomendaciones.append(
                f"El ítem '{i.nombre or '(sin nombre)'}' tiene un precio negativo, revisa su valor."
            )
            break
        
    print("RECOMENDACIONES FINALES:", recomendaciones)
    return Response(recomendaciones)



# ===========================
# ITEMS
# ===========================


" Funcion para actualizar el total de una lista"
def recalcular_total(lista):
    total = sum(item.cantidad * item.precio_unitario for item in lista.items.all())
    lista.total_calculado = total
    lista.save()



@api_view(["GET", "POST"])
def items(request):
    
    " GET <-- Para obtener los items de una lista"


    if request.method == "GET":
        lista_id = request.query_params.get("lista_id")
        if lista_id:
            qs = Item.objects.filter(lista_id=lista_id) 
        else:
            qs = Item.objects.all()
        serializer = ItemSerializer(qs, many=True)
        return Response({"items": serializer.data}, status=200)
    

    " POST <-- Para crear un item nuevo"

    if request.method == "POST":
        serializer = ItemSerializer(data=request.data)
        if serializer.is_valid():
            item = serializer.save()
            recalcular_total(item.lista)
            return Response(ItemSerializer(item).data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(["GET", "PUT", "DELETE"])
def item_detalle(request, item_id):

    try:
        item = Item.objects.get(pk=item_id)
    except Item.DoesNotExist:
        return Response(
            {"detail": "Item no encontrado"},
            status=status.HTTP_404_NOT_FOUND,
        )


    "GET <-- Obtener informacion de un item"
    if request.method == "GET":
        serializer = ItemSerializer(item)
        return Response(serializer.data, status=200)

    "PUT <-- Editar informacion de un item"
    if request.method == "PUT":
        serializer = ItemSerializer(item, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            recalcular_total(item.lista)
            return Response(serializer.data, status=200)
        return Response(serializer.errors, status=400)

    "DELETE <-- Eliminar un item "
    if request.method == "DELETE":
        item.delete()
        recalcular_total(item.lista)
        return Response({"message": "Item eliminado"}, status=200)


        
