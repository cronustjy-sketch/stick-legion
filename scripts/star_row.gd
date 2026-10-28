class_name StarRow
extends Control
## A row of drawn stars (the UI font has no star glyph). `filled` of `total` are gold, the rest are dark outlines.
## Also has a static helper to draw one star on any CanvasItem (used on the campaign map).

const GOLD: Color = Color("ffd24a")
const EDGE: Color = Color("8a6522")
const EMPTY: Color = Color(0.2, 0.2, 0.24, 0.9)

var filled: int = 0
var total: int = 3
var star_radius: float = 16.0


static func create(filled_count: int, radius: float = 16.0, total_count: int = 3) -> StarRow:
	var row: StarRow = StarRow.new()
	row.filled = filled_count
	row.total = total_count
	row.star_radius = radius
	row.custom_minimum_size = Vector2((radius * 2.2) * float(total_count), radius * 2.1)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row


func _draw() -> void:
	for i: int in total:
		draw_star(self, Vector2(star_radius * 1.1 + float(i) * star_radius * 2.2, size.y * 0.5), star_radius, i < filled)


static func draw_star(canvas: CanvasItem, centre: Vector2, radius: float, on: bool) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 10:
		var r: float = radius if i % 2 == 0 else radius * 0.46
		var a: float = -PI * 0.5 + float(i) * PI / 5.0
		pts.append(centre + Vector2(cos(a), sin(a)) * r)
	canvas.draw_colored_polygon(pts, GOLD if on else EMPTY)
	pts.append(pts[0])
	canvas.draw_polyline(pts, EDGE if on else Color(0.45, 0.45, 0.5, 0.9), maxf(1.5, radius * 0.1), true)
