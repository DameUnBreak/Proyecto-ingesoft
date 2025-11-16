from django.urls import path
from . import views

urlpatterns = [
    path("health/", views.health, name="health"),
    path("usuarios/crear/", views.crear_usuario, name="crear_usuario"),
    path("usuarios/<int:user_id>/", views.obtener_usuario, name="obtener_usuario"),
    path("login/", views.login, name="login"),
    path("hola/", views.hola_mundo, name="hola_mundo"),
]

    
