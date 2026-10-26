class_name DebugShot
extends RefCounted
## Saves the current viewport to res://screenshots/<name>.png (debug builds only). Await a frame first.


static func save(vp: Viewport, shot_name: String) -> String:
	var img: Image = vp.get_texture().get_image()
	var dir: String = ProjectSettings.globalize_path("res://screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var path: String = dir.path_join(shot_name + ".png")
	img.save_png(path)
	print("Screenshot saved: ", path)
	return path
