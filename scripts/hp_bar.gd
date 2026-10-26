class_name HpBar3D
extends MeshInstance3D
## Camera-facing health bar drawn by a tiny shader (one draw call, no textures).

const SHADER_CODE: String = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float fill = 1.0;
uniform vec4 bar_color : source_color = vec4(0.9, 0.7, 0.3, 1.0);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	float border = 0.06;
	bool edge = UV.x < 0.01 || UV.x > 0.99 || UV.y < border || UV.y > 1.0 - border;
	vec3 c = UV.x <= fill ? bar_color.rgb : vec3(0.12, 0.1, 0.1);
	ALBEDO = edge ? vec3(0.02) : c;
}
"""

static var _shader: Shader

var _mat: ShaderMaterial


func setup(size: Vector2, color: Color) -> void:
	var q: QuadMesh = QuadMesh.new()
	q.size = size
	mesh = q
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	_mat.set_shader_parameter("bar_color", color)
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func set_fill(fraction: float) -> void:
	_mat.set_shader_parameter("fill", clampf(fraction, 0.0, 1.0))
