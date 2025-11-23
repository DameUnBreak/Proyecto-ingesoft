from rest_framework import serializers
from .models import Usuario


class UsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        # puedes ajustar los campos, por ahora dejamos todos
        fields = ['id', 'nombre', 'correo', 'contrasena']
        # si no quieres devolver la contraseña al frontend, usa:
        # fields = ['id', 'nombre', 'correo']
