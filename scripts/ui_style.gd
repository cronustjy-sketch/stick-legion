class_name UiStyle
extends RefCounted
## Shared look for the menus (dark panels, gold borders). English-only text.

const GOLD: Color = Color("e8b44a")
const RED: Color = Color("de4b3f")
const TEXT: Color = Color("f1ede2")
const DIM: Color = Color("9a978d")


static func box(bg: Color, border: Color, margin: int = 10, radius: int = 10, border_w: int = 2) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


static func panel(parent: Node) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(Color(0.07, 0.08, 0.1, 0.9), GOLD.darkened(0.4), 20, 12, 2))
	parent.add_child(p)
	return p


static func label(text: String, size: int, color: Color = TEXT) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	return l


static func button(text: String, min_size: Vector2 = Vector2(260, 56), font_size: int = 24) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.name = text.replace(" ", "")
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", TEXT)
	b.pressed.connect(func() -> void: Sfx.play("click", -6.0))
	b.add_theme_stylebox_override("normal", box(Color(0.16, 0.14, 0.09, 0.95), GOLD.darkened(0.3), 8, 10))
	b.add_theme_stylebox_override("hover", box(Color(0.35, 0.28, 0.1, 1.0), GOLD, 8, 10))
	b.add_theme_stylebox_override("pressed", box(Color(0.45, 0.35, 0.12, 1.0), GOLD.lightened(0.3), 8, 10))
	b.add_theme_stylebox_override("disabled", box(Color(0.12, 0.12, 0.14, 0.9), DIM.darkened(0.4), 8, 10))
	return b
