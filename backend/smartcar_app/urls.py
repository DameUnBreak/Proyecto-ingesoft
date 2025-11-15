from django.urls import path
from . import views

urlpatterns = [
    path("", views.health),
    path("usuarios/crear/", views.crear_usuario),  # <-- aquí agregamos /crear/
    path("usuarios/<int:user_id>/", views.obtener_usuario),
    path("login/", views.login),
    path("hola_mundo/", views.hola_mundo),
]
    