from django.urls import path
from . import views

urlpatterns = [
    path("health/", views.health, name="health"),
    path("usuarios/crear/", views.crear_usuario, name="crear_usuario"),
    path("usuarios/<int:user_id>/", views.obtener_usuario, name="obtener_usuario"),
    path("login/", views.login, name="login"),
    path("hola/", views.hola_mundo, name="hola_mundo"),

    # ✅ LISTAS (listar y crear)
    path("listas/", views.listas, name="listas"),

    # ✅ NUEVO: detalle de una lista específica
    path("listas/<int:lista_id>/", views.lista_detalle, name="lista_detalle"),

    # ✅ Items (obtener y crear)
    path("items/", views.items, name="items"),

    # ✅ NUEVO: detalle de un item específico
    path("items/<int:item_id>/", views.item_detalle, name="item_detalle"),
    
    #Resumen
    path("resumen_lista/<int:lista_id>/", views.resumen_lista, name="resumen_lista"),

    #Recomendaciones
    path("recomendaciones/<int:lista_id>/", views.recomendaciones, name="recomendaciones"),

]
