from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

from .models import Usuario, Lista, Item, Historial
from .serializers import UsuarioSerializer, ListaSerializer, ItemSerializer, HistorialSerializer


# ===========================
# Helper: usuario demo (solo para pruebas)
# ===========================
def get_demo_user():
    """
    Mientras no tenemos autenticación real integrada con Flutter,
    se puede usar en pruebas, pero YA NO se usa por defecto en los endpoints
    de listas, para evitar que todos vean las mismas listas.
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


@api_view(["POST"])
def guardar_historial(request):
    """
    Crea un registro de historial.

    POST /api/historial/

    Body JSON esperado:
    {
        "usuario_id": 3,
        "mes": "2025-10",
        "total": 250000,
        "numero_items": 12,
        "promedio_por_categoria": 35000
    }
    """

    data = request.data.copy()

    # Aceptamos tanto "usuario" como "usuario_id"
    usuario_id = data.get("usuario") or data.get("usuario_id")

    if not usuario_id:
        return Response(
            {"detail": "Debes enviar 'usuario_id' (o 'usuario') en el body."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        usuario = Usuario.objects.get(pk=usuario_id)
    except Usuario.DoesNotExist:
        return Response(
            {"detail": f"Usuario con id={usuario_id} no existe."},
            status=status.HTTP_404_NOT_FOUND,
        )

    # Lo que espera el serializer
    data["usuario"] = usuario.id

    serializer = HistorialSerializer(data=data)
    if serializer.is_valid():
        registro = serializer.save()
        return Response(
            HistorialSerializer(registro).data,
            status=status.HTTP_201_CREATED,
        )

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(["GET"])
def historial_usuario(request, usuario_id):
    """
    GET /api/historial/3/
    Devuelve historial completo del usuario con id=3
    """
    qs = Historial.objects.filter(usuario_id=usuario_id).order_by("-fecha_registro")
    serializer = HistorialSerializer(qs, many=True)
    return Response({"historial": serializer.data}, status=status.HTTP_200_OK)



# ===========================
# LISTAS
# ===========================
@api_view(["GET", "POST"])
def listas(request):
    """
    GET /api/listas/?usuario_id=1   -> devuelve listas del usuario
    POST /api/listas/              -> crea una lista nueva

    Body POST esperado desde Flutter ahora:
    {
        "nombre": "Lista mercado",
        "presupuesto": 150000,   (opcional)
        "usuario_id": 3          (obligatorio ahora para multiusuario)
    }

    También aceptamos "usuario" en lugar de "usuario_id".
    """

    # ---------- GET ----------
    if request.method == "GET":
        usuario_id = request.query_params.get("usuario_id")

        if not usuario_id:
            return Response(
                {"detail": "Parametro 'usuario_id' es requerido en la URL."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        qs = Lista.objects.filter(usuario_id=usuario_id).order_by("-fecha_creacion")
        serializer = ListaSerializer(qs, many=True)
        # Para que cuadre con ApiService: envolvemos en {"listas": [...]}
        return Response({"listas": serializer.data}, status=status.HTTP_200_OK)

    # ---------- POST ----------
    # Aquí YA NO usamos get_demo_user por defecto;
    # exigimos que nos digan para qué usuario es la lista.
    data = request.data.copy()

    # Aceptamos tanto "usuario" como "usuario_id" desde el frontend
    usuario_id = data.get("usuario") or data.get("usuario_id")

    if not usuario_id:
        return Response(
            {
                "detail": "Debes enviar 'usuario_id' (o 'usuario') en el body para crear una lista."
            },
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        usuario = Usuario.objects.get(pk=usuario_id)
    except Usuario.DoesNotExist:
        return Response(
            {"detail": f"Usuario con id={usuario_id} no existe."},
            status=status.HTTP_404_NOT_FOUND,
        )

    # El serializer espera el campo 'usuario' (FK)
    data["usuario"] = usuario.id

    serializer = ListaSerializer(data=data)
    if serializer.is_valid():
        lista = serializer.save()
        Historial.objects.create(
            usuario=usuario,
            mes=lista.fecha_creacion.strftime("%Y-%m"),
            total=lista.presupuesto or 0,
            numero_items=lista.items.count(),
            promedio_por_categoria=0  # o algún cálculo si quieres
        )
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
        data = request.data.copy()

        # Si quisieran cambiar el usuario de la lista, controlamos igual:
        if "usuario_id" in data and "usuario" not in data:
            data["usuario"] = data["usuario_id"]

        serializer = ListaSerializer(lista, data=data, partial=True)
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
    try:
        lista = Lista.objects.get(id=lista_id)
    except Lista.DoesNotExist:
        return Response(
            {"detail": "Lista no encontrada"},
            status=status.HTTP_404_NOT_FOUND,
        )

    total = sum(item.cantidad * item.precio_unitario for item in lista.items.all())
    data = {
        "presupuesto": lista.presupuesto,
        "total": total,
        "supera_presupuesto": total > lista.presupuesto,
    }
    return Response(data)


@api_view(["GET"])
def recomendaciones(request, lista_id):
    try:
        lista = Lista.objects.get(id=lista_id)
    except Lista.DoesNotExist:
        return Response(
            {"detail": "Lista no encontrada"},
            status=status.HTTP_404_NOT_FOUND,
        )

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
        if i.categoria:
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

    # 7. Valores mal formateados (cantidad o precio 0 o negativo)
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

# Función para actualizar el total de una lista
def recalcular_total(lista):
    total = sum(item.cantidad * item.precio_unitario for item in lista.items.all())
    lista.total_calculado = total
    lista.save()
    usuario = lista.usuario
    mes = lista.fecha_creacion.strftime("%Y-%m")
    historial, created = Historial.objects.get_or_create(usuario=usuario, mes=mes)
    historial.total = total
    historial.numero_items = lista.items.count()
    # promedio_por_categoria: calcula si quieres
    historial.save()



@api_view(["GET", "POST"])
def items(request):
    """
    GET  /api/items/?lista_id=10  -> items de una lista
    POST /api/items/              -> crea un item nuevo
    """

    # ---------- GET ----------
    if request.method == "GET":
        lista_id = request.query_params.get("lista_id")
        if not lista_id:
            return Response(
                {"detail": "Parametro 'lista_id' es requerido para listar items."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        qs = Item.objects.filter(lista_id=lista_id)
        serializer = ItemSerializer(qs, many=True)
        return Response({"items": serializer.data}, status=status.HTTP_200_OK)

    # ---------- POST ----------
    if request.method == "POST":
        data = request.data.copy()

        # Aceptamos tanto 'lista' como 'lista_id'
        lista_id = data.get("lista") or data.get("lista_id")
        if not lista_id:
            return Response(
                {"detail": "Debes enviar 'lista_id' (o 'lista') en el body para crear un item."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        data["lista"] = lista_id

        serializer = ItemSerializer(data=data)
        if serializer.is_valid():
            item = serializer.save()
            recalcular_total(item.lista)
            return Response(
                ItemSerializer(item).data,
                status=status.HTTP_201_CREATED,
            )
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

    # GET <-- Obtener informacion de un item
    if request.method == "GET":
        serializer = ItemSerializer(item)
        return Response(serializer.data, status=status.HTTP_200_OK)

    # PUT <-- Editar informacion de un item
    if request.method == "PUT":
        data = request.data.copy()
        # Igual que antes, aceptamos 'lista_id'
        if "lista_id" in data and "lista" not in data:
            data["lista"] = data["lista_id"]

        serializer = ItemSerializer(item, data=data, partial=True)
        if serializer.is_valid():
            item = serializer.save()
            recalcular_total(item.lista)
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    # DELETE <-- Eliminar un item
    if request.method == "DELETE":
        lista = item.lista
        item.delete()
        recalcular_total(lista)
        return Response({"message": "Item eliminado"}, status=status.HTTP_200_OK)
