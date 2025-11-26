from rest_framework import serializers
from .models import (
    Usuario,
    Lista,
    Item,
    PrecioOnline,
    Alerta,
    PreferenciasAlertas,
    Historial,
    Compra,
    Recomendacion,
    RecomendacionItem,
    Dispositivo,
    Evento,
)


# ===========================
# USUARIO
# ===========================
class UsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = [
            "id",
            "nombre",
            "correo",
            "contrasena",         # ojo: en un proyecto real se encripta y no se expone
            "moneda_preferida",
            "fecha_registro",
        ]
        read_only_fields = ["id", "fecha_registro"]


# ===========================
# LISTA
# ===========================
class ListaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Lista
        fields = [
            "id",
            "usuario",
            "nombre",
            "presupuesto",
            "total_calculado",
            "estado",
            "alerta_activa",
            "alerta_ultima_vista_at",
            "fecha_creacion",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "total_calculado",
            "estado",
            "alerta_activa",
            "alerta_ultima_vista_at",
            "fecha_creacion",
            "updated_at",
        ]


# ===========================
# ITEM
# ===========================
class ItemSerializer(serializers.ModelSerializer):
    subtotal = serializers.SerializerMethodField()
    class Meta:
        model = Item
        fields = [
            "id",
            "lista",
            "nombre",
            "categoria",
            "cantidad",
            "unidad",
            "precio_unitario",
            "prioridad",
            "nota",
            "comprado",
            "fecha_agregado",
            "fecha_comprado",
            "cantidad_comprada",
            "precio_pagado",
            "subtotal",
        ]
        read_only_fields = [
            "id",
            "fecha_agregado",
            "fecha_comprado",
            "subtotal",
        ]
    def get_subtotal(self, obj):
        try:
            return obj.cantidad * obj.precio_unitario
        except:
            return 0


# ===========================
# ALERTA
# ===========================
class AlertaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alerta
        fields = [
            "id",
            "lista",
            "tipo",
            "mensaje",
            "fecha_hora",
            "total_al_momento",
        ]
        read_only_fields = ["id", "fecha_hora"]


# ===========================
# PREFERENCIAS ALERTAS
# ===========================
class PreferenciasAlertasSerializer(serializers.ModelSerializer):
    class Meta:
        model = PreferenciasAlertas
        fields = [
            "id",
            "usuario",
            "in_app",
            "push",
            "badge",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


# ===========================
# HISTORIAL
# ===========================
class HistorialSerializer(serializers.ModelSerializer):
    class Meta:
        model = Historial
        fields = [
            "id",
            "usuario",
            "mes",
            "total",
            "numero_items",
            "promedio_por_categoria",
            "fecha_registro",
        ]
        read_only_fields = ["id", "fecha_registro"]


# ===========================
# COMPRA
# ===========================
class CompraSerializer(serializers.ModelSerializer):
    class Meta:
        model = Compra
        fields = [
            "id",
            "item",
            "fecha",
            "cantidad",
            "precio_unitario",
            "tienda",
            "created_at",
        ]
        read_only_fields = ["id", "fecha", "created_at"]


# ===========================
# RECOMENDACION
# ===========================
class RecomendacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recomendacion
        fields = [
            "id",
            "lista",
            "criterios_json",
            "total_usado",
            "presupuesto_no_usado",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class RecomendacionItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = RecomendacionItem
        fields = [
            "id",
            "recomendacion",
            "item",
            "orden",
        ]
        read_only_fields = ["id"]


# ===========================
# DISPOSITIVO
# ===========================
class DispositivoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Dispositivo
        fields = [
            "id",
            "usuario",
            "push_token",
            "plataforma",
            "activo",
            "updated_at",
        ]
        read_only_fields = ["id", "updated_at"]


# ===========================
# EVENTO
# ===========================
class EventoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Evento
        fields = [
            "id",
            "usuario",
            "tipo",
            "entidad",
            "entidad_id",
            "ts",
        ]
        read_only_fields = ["id", "ts"]
