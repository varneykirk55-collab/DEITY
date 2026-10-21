class_name UiKit
extends RefCounted

const GOLD := Color(0.90, 0.74, 0.32)
const GOLD_DIM := Color(0.55, 0.44, 0.18)
const NAVY := Color(0.06, 0.09, 0.16, 0.92)
const NAVY_SOLID := Color(0.07, 0.10, 0.18)
const PANEL := Color(0.08, 0.12, 0.20, 0.88)
const INK := Color(0.93, 0.94, 0.96)
const MUTED := Color(0.70, 0.74, 0.80)


static func flat(bg: Color, radius: int = 8, border: Color = Color(0, 0, 0, 0), bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.border_color = border
	sb.border_width_left = bw
	sb.border_width_right = bw
	sb.border_width_top = bw
	sb.border_width_bottom = bw
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func button(text: String, min_w: int = 220, min_h: int = 44) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, min_h)
	_style_button(b)
	return b


static func _style_button(b: Button) -> void:
	b.add_theme_stylebox_override("normal", flat(Color(0.12, 0.18, 0.30, 0.95), 10, GOLD_DIM, 2))
	b.add_theme_stylebox_override("hover", flat(Color(0.18, 0.26, 0.42, 0.98), 10, GOLD, 2))
	b.add_theme_stylebox_override("pressed", flat(Color(0.22, 0.20, 0.10, 0.98), 10, GOLD, 2))
	b.add_theme_stylebox_override("disabled", flat(Color(0.10, 0.10, 0.14, 0.8), 10, Color(0.3, 0.3, 0.3), 1))
	b.add_theme_stylebox_override("focus", flat(Color(0.18, 0.26, 0.42, 0.98), 10, GOLD, 2))
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_font_size_override("font_size", 18)


static func tool_button(text: String, tex: Texture2D) -> Button:
	var b := Button.new()
	b.text = text
	b.icon = tex
	b.custom_minimum_size = Vector2(86, 56)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 22)
	b.add_theme_font_size_override("font_size", 11)
	b.add_theme_stylebox_override("normal", flat(Color(0.10, 0.14, 0.22, 0.92), 8, Color(0.35, 0.40, 0.50), 1))
	b.add_theme_stylebox_override("hover", flat(Color(0.18, 0.24, 0.36, 0.96), 8, GOLD, 1))
	b.add_theme_stylebox_override("pressed", flat(Color(0.32, 0.26, 0.10, 0.96), 8, GOLD, 2))
	b.add_theme_color_override("font_color", INK)
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = text
	return b


static func label(text: String, size: int = 16, color: Color = Color(0.93, 0.94, 0.96, 1.0), align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


static func panel(alpha: float = 0.88) -> PanelContainer:
	var p := PanelContainer.new()
	var c := PANEL
	c.a = alpha
	p.add_theme_stylebox_override("panel", flat(c, 12, GOLD_DIM, 1))
	return p


static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v
