extends SceneTree
## Lists characters used by data/translations.gd that the bundled CJK subset font cannot draw.
##   godot --headless --path . --script tools/check_font.gd
func _init() -> void:
	var font: FontFile = FontFile.new()
	font.load_dynamic_font("res://ui/fonts/cjk_subset.ttf")
	var missing: Dictionary = {}
	for k: String in Translations.ZH:
		for ch: String in String(Translations.ZH[k]):
			if ch.unicode_at(0) > 0x2E80 and not font.has_char(ch.unicode_at(0)):
				missing[ch] = String(k)
	print("FONT-CHECK missing characters: ", missing.size())
	for ch: String in missing:
		print("  ", ch, "  in: ", missing[ch])
	quit()
