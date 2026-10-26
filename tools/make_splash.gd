extends SceneTree
## Renders the boot splash (res://ui/splash.png): the stickman art from ui/splash_art.svg plus the gold "STICK LEGION" title.
## Run (needs a window, not --headless):  godot --path . --script res://tools/make_splash.gd

func _init() -> void:
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var svg: String = FileAccess.get_file_as_string("res://ui/splash_art.svg")
	var img: Image = Image.new()
	img.load_svg_from_string(svg, 1.0)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	var art: TextureRect = TextureRect.new()
	art.texture = tex
	art.size = Vector2(1280, 720)
	vp.add_child(art)
	var title: Label = Label.new()
	title.text = "STICK LEGION"
	title.size = Vector2(1280, 150)
	title.position = Vector2(0, 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 118)
	title.add_theme_color_override("font_color", Color("e8b44a"))
	title.add_theme_color_override("font_outline_color", Color("070809"))
	title.add_theme_constant_override("outline_size", 14)
	vp.add_child(title)
	for i: int in 6:
		await process_frame
	var out: Image = vp.get_texture().get_image()
	out.save_png(ProjectSettings.globalize_path("res://ui/splash.png"))
	print("SPLASH saved ", out.get_size())
	quit()
