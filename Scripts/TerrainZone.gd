extends Area2D

# ─────────────────────────────────────────────────────────────────────────────
# TerrainZone.gd
# Attach ke Area2D di level. Saat player masuk zone ini, terrain audio berubah.
#
# CARA PAKAI:
# 1. Di Level_01.tscn, buat node Area2D baru
# 2. Attach script ini
# 3. Set terrain_type di Inspector
# 4. Buat CollisionShape2D sebagai child, cover area tanah biasa
# 5. Default terrain = snow, jadi HANYA taruh zone untuk "dirt"
# ─────────────────────────────────────────────────────────────────────────────

@export_enum("snow", "dirt") var terrain_type: String = "dirt"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		body.on_snow = (terrain_type == "snow")

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		# Saat keluar zone, kembali ke terrain default (snow)
		body.on_snow = true
