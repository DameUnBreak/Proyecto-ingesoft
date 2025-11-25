from django.db import models


# ===========================
# USUARIOS
# ===========================
class Usuario(models.Model):
    nombre = models.CharField(max_length=100)
    correo = models.EmailField(max_length=100, unique=True)
    contrasena = models.CharField(max_length=255)
    moneda_preferida = models.CharField(max_length=3, null=True, blank=True)
    fecha_registro = models.DateTimeField(auto_now_add=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "usuarios"

    def __str__(self):
        return f"{self.nombre} <{self.correo}>"


# ===========================
# LISTAS
# ===========================
class Lista(models.Model):
    ESTADO_CHOICES = [
        ("OK", "OK"),
        ("SOBRE_PRESUPUESTO", "SOBRE_PRESUPUESTO"),
    ]

    ALERTA_CHOICES = [
        ("NINGUNA", "NINGUNA"),
        ("AMARILLA", "AMARILLA"),
        ("ROJA", "ROJA"),
    ]

    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name="listas",
    )
    nombre = models.CharField(max_length=100)
    presupuesto = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_calculado = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    estado = models.CharField(
        max_length=20,
        choices=ESTADO_CHOICES,
        default="OK",
    )
    alerta_activa = models.CharField(
        max_length=10,
        choices=ALERTA_CHOICES,
        default="NINGUNA",
    )
    alerta_ultima_vista_at = models.DateTimeField(null=True, blank=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    version = models.IntegerField(default=1)

    class Meta:
        db_table = "listas"

    def __str__(self):
        return f"{self.nombre} (usuario_id={self.usuario_id})"


# ===========================
# ITEMS
# ===========================
class Item(models.Model):
    PRIORIDAD_CHOICES = [
        ("A", "A"),  # Alta
        ("M", "M"),  # Media
        ("B", "B"),  # Baja
    ]

    lista = models.ForeignKey(
        Lista,
        on_delete=models.CASCADE,
        related_name="items",
    )
    nombre = models.CharField(max_length=100)
    categoria = models.CharField(max_length=50, null=True, blank=True)
    cantidad = models.DecimalField(max_digits=10, decimal_places=2, default=1)
    unidad = models.CharField(max_length=30, null=True, blank=True)
    precio_unitario = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    prioridad = models.CharField(
        max_length=1,
        choices=PRIORIDAD_CHOICES,
        default="M",
    )
    nota = models.TextField(null=True, blank=True)
    comprado = models.BooleanField(default=False)
    fecha_agregado = models.DateTimeField(auto_now_add=True)

    # campos para compras rápidas / historial
    fecha_comprado = models.DateTimeField(null=True, blank=True)
    cantidad_comprada = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True
    )
    precio_pagado = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    version = models.IntegerField(default=1)

    class Meta:
        db_table = "items"
        constraints = [
            models.UniqueConstraint(
                fields=["lista", "nombre"],
                name="uq_item_nombre_por_lista",
            )
        ]

    def __str__(self):
        return f"{self.nombre} (lista_id={self.lista_id})"
    def subtotal(self):
        return self.cantidad * self.precio_unitario


# ===========================
# PRECIOS ONLINE
# ===========================
class PrecioOnline(models.Model):
    item = models.ForeignKey(
        Item,
        on_delete=models.CASCADE,
        related_name="precios_online",
    )
    fuente = models.CharField(max_length=100)
    precio_consultado = models.DecimalField(max_digits=10, decimal_places=2)
    fecha_consulta = models.DateTimeField(auto_now_add=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "precios_online"

    def __str__(self):
        return f"{self.fuente} - {self.precio_consultado} (item_id={self.item_id})"


# ===========================
# ALERTAS (LOG)
# ===========================
class Alerta(models.Model):
    TIPO_CHOICES = [
        ("AMARILLA", "AMARILLA"),
        ("ROJA", "ROJA"),
    ]

    lista = models.ForeignKey(
        Lista,
        on_delete=models.CASCADE,
        related_name="alertas",
    )
    tipo = models.CharField(max_length=10, choices=TIPO_CHOICES)
    mensaje = models.CharField(max_length=255)
    fecha_hora = models.DateTimeField(auto_now_add=True)
    total_al_momento = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        db_table = "alertas"

    def __str__(self):
        return f"{self.tipo} - {self.mensaje[:20]}..."


# ===========================
# PREFERENCIAS ALERTAS (1:1 USUARIO)
# ===========================
class PreferenciasAlertas(models.Model):
    usuario = models.OneToOneField(
        Usuario,
        on_delete=models.CASCADE,
        related_name="preferencias_alertas",
    )
    in_app = models.BooleanField(default=True)
    push = models.BooleanField(default=False)
    badge = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "preferencias_alertas"

    def __str__(self):
        return f"Preferencias alertas de {self.usuario_id}"


# ===========================
# HISTORIAL (AGREGADO MENSUAL)
# ===========================
class Historial(models.Model):
    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name="historial",
    )
    mes = models.CharField(max_length=20)  # p.ej. '2025-10'
    total = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    numero_items = models.IntegerField(default=0)
    promedio_por_categoria = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True
    )
    fecha_registro = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "historial"

    def __str__(self):
        return f"Historial {self.mes} (usuario_id={self.usuario_id})"


# ===========================
# COMPRAS (OPCIONAL)
# ===========================
class Compra(models.Model):
    item = models.ForeignKey(
        Item,
        on_delete=models.CASCADE,
        related_name="compras",
    )
    fecha = models.DateTimeField(auto_now_add=True)
    cantidad = models.DecimalField(max_digits=10, decimal_places=2)
    precio_unitario = models.DecimalField(max_digits=10, decimal_places=2)
    tienda = models.CharField(max_length=100, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "compras"

    def __str__(self):
        return f"Compra item {self.item_id} - {self.cantidad} x {self.precio_unitario}"


# ===========================
# RECOMENDACIONES
# ===========================
class Recomendacion(models.Model):
    lista = models.ForeignKey(
        Lista,
        on_delete=models.CASCADE,
        related_name="recomendaciones",
    )
    # importante: TextField, NO JSONField
    criterios_json = models.TextField(null=True, blank=True)
    total_usado = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True
    )
    presupuesto_no_usado = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "recomendaciones"



class RecomendacionItem(models.Model):
    recomendacion = models.ForeignKey(
        Recomendacion,
        on_delete=models.CASCADE,
        related_name="items_recomendados",
    )
    item = models.ForeignKey(
        Item,
        on_delete=models.CASCADE,
        related_name="en_recomendaciones",
    )
    orden = models.IntegerField()

    class Meta:
        db_table = "recomendacion_items"
        unique_together = ("recomendacion", "item")

    def __str__(self):
        return f"Recom {self.recomendacion_id} - Item {self.item_id} (orden={self.orden})"


# ===========================
# DISPOSITIVOS (PUSH)
# ===========================
class Dispositivo(models.Model):
    PLATAFORMA_CHOICES = [
        ("ANDROID", "ANDROID"),
        ("IOS", "IOS"),
        ("WEB", "WEB"),
    ]

    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name="dispositivos",
    )
    push_token = models.CharField(max_length=255)
    plataforma = models.CharField(max_length=10, choices=PLATAFORMA_CHOICES)
    activo = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "dispositivos"

    def __str__(self):
        return f"{self.plataforma} - {self.usuario_id}"


# ===========================
# EVENTOS (KPIs)
# ===========================
class Evento(models.Model):
    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name="eventos",
    )
    tipo = models.CharField(max_length=40)      # 'ABRE_APP', 'CREA_LISTA', etc.
    entidad = models.CharField(max_length=40, null=True, blank=True)  # 'listas', 'items', etc.
    entidad_id = models.IntegerField(null=True, blank=True)
    ts = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "eventos"

    def __str__(self):
        return f"{self.tipo} (usuario_id={self.usuario_id})"
