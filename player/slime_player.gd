class_name SlimePlayer
extends CharacterBody2D
## ============================================================
## سكربت الشخصية الرئيسية (سلّايم أزرق)
## ------------------------------------------------------------
## - حركة أفقية لليمين واليسار باستخدام لوحة المفاتيح.
## - تشغيل أنيميشن "walk" عند الحركة وأنيميشن "idle" عند التوقف.
## - قلب اتجاه الصورة تلقائياً (flip_h) حسب اتجاه الحركة.
## - نظام تدمج/حياة بتغيّر اللون: أزرق -> أخضر -> أحمر.
##
## ملاحظة: مشهد AnimatedSprite2D يحتوي بالفعل على أوراق سلّايم
## ملونة (أزرق/أخضر/أحمر)، لذا نبدّل الأنيميشن إلى الورقة الملونة
## المناسبة بدلاً من تلوينها بواسطة modulate (نتيجة أجمل وأدق).
## ============================================================

# --- إعدادات الحركة -------------------------------------------------------
@export var speed: float = 150.0            # سرعة المشي (بكسل/ثانية)

# --- نظام التدمج (الحياة) -------------------------------------------------
# الحد الأقصى للحياة = 3 أي 3 مراحل لونية.
@export var max_health: int = 3

var health: int = 3                         # الحياة الحالية

# بادئة اسم الأنيميشن حسب المرحلة: [أزرق, أخضر, أحمر]
# ملاحظة: أنيميشن السلّايم الأحمر مسمّى "psd" داخل SpriteFrames.
const COLOR_PREFIX: Array[String] = ["blue", "green", "psd"]

# مرجع لعقدة الأنيميشن (تعيين تلقائي عبر @onready).
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


# يُستدعى عند دخول العقدة إلى المشهد لأول مرة.
func _ready() -> void:
	health = max_health
	_update_animation_state()


# يُستدعى كل إطار فيزيائي (معالجة الحركة والاصطدام).
func _physics_process(_delta: float) -> void:
	# 1) قراءة اتجاه الحركة: ندمج مفاتيح A/D (move_left/right)
	#    مع مفاتيح الأسهم (ui_left/right) ثم نحوّل الناتج بين -1 و 1.
	var direction: float = Input.get_axis("move_left", "move_right")
	direction += Input.get_axis("ui_left", "ui_right")
	direction = clampf(direction, -1.0, 1.0)

	# 2) تطبيق السرعة الأفقية وتحريك العقدة مع الاصطدامات.
	velocity.x = direction * speed
	move_and_slide()

	# 3) تحديث الأنيميشن واتجاه الصورة.
	_update_animation_state()
	_flip_sprite(direction)


# يعيد بادئة اللون الحالية حسب الحياة المتبقية.
func _color_prefix() -> String:
	# الحياة 3 -> أزرق (0)، 2 -> أخضر (1)، 1 -> أحمر (2).
	var stage: int = clampi(max_health - health, 0, COLOR_PREFIX.size() - 1)
	return COLOR_PREFIX[stage]


# يختار الأنيميشن المناسب: walk إذا كان يتحرك وإلا idle.
func _update_animation_state() -> void:
	var prefix: String = _color_prefix()
	if absf(velocity.x) > 1.0:
		animated_sprite.play(prefix + " walk")
	else:
		animated_sprite.play(prefix + " idle")


# يقلب الصورة أفقياً لليمين أو اليسار حسب اتجاه الحركة.
func _flip_sprite(direction: float) -> void:
	if direction > 0.0:
		animated_sprite.flip_h = false   # ناظر لليمين
	elif direction < 0.0:
		animated_sprite.flip_h = true    # ناظر لليسار


# دالة عامة تُستدعى عند تلقي ضربة: تنقص الحياة وتحدّث اللون.
func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	_update_animation_state()
