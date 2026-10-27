class_name StoryPlayer
extends Node3D
## Plays story cards (data/story.gd): a posed 3D scene with a slow camera pan and 1-3 lines of text at the bottom.
## Click / Space / Enter advances, Skip leaves. The cards to play come from GameState.story_queue; afterwards we go to GameState.story_next.

const TYPE_SPEED: float = 0.022  # seconds per character

var _queue: Array[String] = []
var _index: int = -1
var _card: Dictionary = {}
var _line: int = 0
var _typing: bool = false
var _busy: bool = false  # fading between cards
var _test_mode: bool = false
var _auto_ending: String = ""  # tests: "spare" or "end" - play the final choice and the ending automatically

var _stage: Node3D
var _cam: Camera3D
var _sky: ProceduralSkyMaterial
var _env: Environment
var _sun: DirectionalLight3D
var _ground: MeshInstance3D
var _ground_mat: StandardMaterial3D

var _cam_from: Vector3
var _cam_to: Vector3
var _cam_look: Vector3
var _cam_t: float = 0.0
var _cam_dur: float = 10.0

var _ui: CanvasLayer
var _fade: ColorRect
var _text_panel: PanelContainer
var _speaker: Label
var _text: Label
var _hint: Label
var _title: Label
var _subtitle: Label
var _choice_box: VBoxContainer
var _skip: Button
var _type_tween: Tween


func _ready() -> void:
	Settings.init()
	GameState.load_progress()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	_test_mode = OS.get_cmdline_user_args().has("--story-test")
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--story-ending="):
			_auto_ending = a.get_slice("=", 1)
	if _auto_ending != "":
		GameState.persist = false
		GameState.story_replay = false
		GameState.story_queue = ["final_choice"]
		GameState.seen_cards.clear()
		GameState.endings.clear()
		_run_ending_checks()
	if _test_mode:
		GameState.story_replay = true
		GameState.story_queue.clear()
		for id: String in StoryData.CARDS:
			if id != "final_choice":
				GameState.story_queue.append(id)
		GameState.story_next = "res://scenes/main_menu.tscn"
	_queue = GameState.story_queue.duplicate()
	Sfx.music("music_story")
	_build_world()
	_build_ui()
	if _queue.is_empty():
		_leave()
		return
	_next_card()


func _process(delta: float) -> void:
	if _cam == null or _card.is_empty():
		return
	_cam_t = minf(_cam_t + delta / _cam_dur, 1.0)
	var k: float = smoothstep(0.0, 1.0, _cam_t)
	_cam.position = _cam_from.lerp(_cam_to, k)
	_cam.look_at(_cam_look)


func _unhandled_input(event: InputEvent) -> void:
	var go: bool = false
	if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		go = true
	elif event is InputEventKey and event.pressed and not (event as InputEventKey).echo:
		var k: Key = (event as InputEventKey).keycode
		go = k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER
	if go:
		advance()


# --- Flow ---------------------------------------------------------------------------------------------

func advance() -> void:
	if _busy or _card.is_empty() or _choice_box.visible:
		return
	Sfx.play("page", -9.0)
	if _typing:
		_finish_typing()
		return
	var lines: Array = _card.lines
	if _line < lines.size() - 1:
		_line += 1
		_show_line()
		return
	_next_card()


func _next_card() -> void:
	_busy = true
	if _fade.color.a < 0.99:
		var out: Tween = create_tween()
		out.tween_property(_fade, "color:a", 1.0, 0.35)
		await out.finished
	_index += 1
	if _index >= _queue.size():
		_leave()
		return
	_start_card(_queue[_index])
	var inn: Tween = create_tween()
	inn.tween_property(_fade, "color:a", 0.0, 0.5)
	await inn.finished
	_busy = false


func _start_card(id: String) -> void:
	_card = StoryData.CARDS[id]
	_card = _card.duplicate()
	_card["id"] = id
	GameState.mark_seen(id)
	if _card.has("ending") and not GameState.story_replay:
		GameState.endings[String(_card.ending)] = true
		GameState.save()
	_build_scene(_card)
	_line = 0
	_title.visible = _card.has("title")
	_subtitle.visible = _card.has("title")
	if _card.has("title"):
		_title.text = Loc.t(String(_card.title))
		var sub: String = Loc.t(String(_card.subtitle))
		if bool(_card.get("credits", false)) and GameState.story_replay:
			sub = ""
		_subtitle.text = sub
	_choice_box.visible = false
	_text_panel.visible = not (_card.lines as Array).is_empty()
	_hint.visible = true
	_skip.visible = not bool(_card.get("choice", false))
	if bool(_card.get("choice", false)):
		_show_choice()
	elif _text_panel.visible:
		_show_line()
	if _test_mode:
		_run_test_step(id)
	if _auto_ending != "":
		_auto_step(id)


func _leave() -> void:
	if _auto_ending != "":
		print("ENDING-TEST (", _auto_ending, ") finished: endings seen=", GameState.endings.keys(), " endless unlocked=", GameState.endless_unlocked(), " cards seen=", GameState.seen_cards.keys())
		get_tree().quit()
		return
	var next_scene: String = GameState.story_next
	GameState.story_queue.clear()
	GameState.story_replay = false
	get_tree().change_scene_to_file(next_scene)


func _on_skip() -> void:
	if _busy:
		return
	# Skipping jumps to the final choice card if there is one ahead (a choice can not be skipped), otherwise leaves.
	for i: int in range(_index + 1, _queue.size()):
		if bool(StoryData.CARDS[_queue[i]].get("choice", false)):
			for j: int in range(_index, i):
				GameState.mark_seen(_queue[j])
			_index = i - 1
			_next_card()
			return
	for j: int in range(_index, _queue.size()):
		GameState.mark_seen(_queue[j])
	_busy = true
	_leave()


func _show_line() -> void:
	var l: Array = (_card.lines as Array)[_line]
	var who: String = String(l[0])
	_speaker.text = Loc.t(who)
	_speaker.visible = who != ""
	_speaker.add_theme_color_override("font_color", UiStyle.RED if who == "Corvin" or who == "Sera and Kade" else UiStyle.GOLD)
	_text.text = Loc.t(String(l[1]))
	_text.visible_ratio = 0.0
	_typing = true
	if _type_tween != null:
		_type_tween.kill()
	_type_tween = create_tween()
	_type_tween.tween_property(_text, "visible_ratio", 1.0, maxf(0.4, float(_text.text.length()) * TYPE_SPEED))
	_type_tween.tween_callback(func() -> void: _typing = false)
	_cam_dur = maxf(9.0, float(_text.text.length()) * 0.11)


func _finish_typing() -> void:
	if _type_tween != null:
		_type_tween.kill()
	_text.visible_ratio = 1.0
	_typing = false


func _show_choice() -> void:
	_choice_box.visible = true
	_hint.visible = false
	_text_panel.visible = false


func _choose(spare: bool) -> void:
	if GameState.story_replay:
		_choice_box.visible = false
		_next_card()
		return
	var extra: Array[String] = StoryData.SPARE_ENDING if spare else StoryData.END_ENDING
	_queue.append_array(extra)
	_choice_box.visible = false
	_next_card()


# --- Scene building -----------------------------------------------------------------------------------

func _build_world() -> void:
	_sky = ProceduralSkyMaterial.new()
	var sky: Sky = Sky.new()
	sky.sky_material = _sky
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.fog_enabled = true
	_env.fog_density = 0.012
	_env.fog_sky_affect = 0.2
	var we: WorldEnvironment = WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-40.0, 35.0, 0.0)
	_sun.shadow_enabled = false
	add_child(_sun)
	_ground = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(240.0, 240.0)
	_ground.mesh = plane
	_ground_mat = StandardMaterial3D.new()
	_ground_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	_ground_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_ground.material_override = _ground_mat
	add_child(_ground)
	_stage = Node3D.new()
	_stage.name = "Stage"
	add_child(_stage)
	_cam = Camera3D.new()
	_cam.fov = 55.0
	_cam.far = 400.0
	add_child(_cam)
	_cam.current = true


func _build_scene(card: Dictionary) -> void:
	for c: Node in _stage.get_children():
		c.queue_free()
	var set_def: Dictionary = StorySets.SETS.get(String(card.set), StorySets.SETS.dawn)
	_sky.sky_top_color = Color(String(set_def.sky[0]))
	_sky.sky_horizon_color = Color(String(set_def.sky[1]))
	_sky.ground_horizon_color = Color(String(set_def.sky[1])).darkened(0.1)
	_sky.ground_bottom_color = Color(String(set_def.ground)).darkened(0.2)
	_ground_mat.albedo_color = Color(String(set_def.ground))
	_sun.light_color = Color(String(set_def.sun[0]))
	_sun.light_energy = float(set_def.sun[1])
	_env.ambient_light_color = Color(String(set_def.ambient))
	_env.ambient_light_energy = 0.7
	_env.fog_light_color = Color(String(set_def.fog))
	StorySets.build_props(_stage, String(card.set), card.props as Array)
	for a: Array in (card.actors as Array):
		var s: Stickman = Stickman.new()
		s.setup(String(a[0]), int(a[1]))
		s.position = Vector3(float(a[2]), float(a[6]) if a.size() > 6 else 0.0, float(a[3]))
		s.rotation_degrees.y = float(a[4])
		_stage.add_child(s)
		var anim: String = String(a[5])
		s.play(anim, 1.0, true)
		if anim in ["attack", "attack3", "block"]:  # fight poses keep swinging; the others hold their last frame
			var sid: int = s.get_instance_id()
			s.animation_done.connect(func(_n: StringName) -> void: _replay_later(sid, anim))
	var cam: Array = card.cam
	_cam_from = _v3(cam[0])
	_cam_to = _v3(cam[1])
	_cam_look = _v3(cam[2])
	_cam_t = 0.0
	_cam_dur = 11.0
	_cam.position = _cam_from
	_cam.look_at(_cam_look)


func _replay_later(actor_id: int, anim: String) -> void:
	await get_tree().create_timer(0.7).timeout
	var s: Stickman = instance_from_id(actor_id) as Stickman
	if s != null and is_instance_valid(s):
		s.play(anim, 1.0, true)


func _v3(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


# --- UI -----------------------------------------------------------------------------------------------

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	var root: Control = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Letterbox bars give the cards a cinematic frame.
	for top: bool in [true, false]:
		var bar: ColorRect = ColorRect.new()
		bar.color = Color(0, 0, 0, 0.85)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bar)
		bar.anchor_left = 0.0
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 1.0
		bar.anchor_bottom = 0.0 if top else 1.0
		bar.offset_left = 0.0
		bar.offset_right = 0.0
		bar.offset_top = 0.0 if top else -46.0
		bar.offset_bottom = 46.0 if top else 0.0
	_text_panel = UiStyle.panel(root)
	_text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_panel.anchor_left = 0.5
	_text_panel.anchor_right = 0.5
	_text_panel.anchor_top = 1.0
	_text_panel.anchor_bottom = 1.0
	_text_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_text_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_text_panel.offset_top = -66.0
	_text_panel.offset_bottom = -66.0
	var v: VBoxContainer = VBoxContainer.new()
	_text_panel.add_child(v)
	_speaker = UiStyle.label("", 22, UiStyle.GOLD)
	v.add_child(_speaker)
	_text = UiStyle.label("", 28)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(860, 0)
	v.add_child(_text)
	_hint = UiStyle.label("Click to continue", 14, UiStyle.DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(_hint)
	_title = UiStyle.label("", 80, UiStyle.GOLD)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_constant_override("outline_size", 10)
	root.add_child(_title)
	_title.anchor_right = 1.0
	_title.offset_top = 230.0
	_title.offset_bottom = 330.0
	_subtitle = UiStyle.label("", 34, UiStyle.TEXT)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_subtitle)
	_subtitle.anchor_right = 1.0
	_subtitle.offset_top = 340.0
	_subtitle.offset_bottom = 400.0
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 14)
	_choice_box.visible = false
	root.add_child(_choice_box)
	_choice_box.anchor_left = 0.5
	_choice_box.anchor_right = 0.5
	_choice_box.anchor_top = 1.0
	_choice_box.anchor_bottom = 1.0
	_choice_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_choice_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_choice_box.offset_top = -70.0
	_choice_box.offset_bottom = -70.0
	var prompt: Label = UiStyle.label("Corvin kneels. The choice is yours.", 26, UiStyle.TEXT)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_box.add_child(prompt)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	_choice_box.add_child(row)
	var spare: Button = UiStyle.button("Spare him", Vector2(280, 64), 28)
	spare.pressed.connect(func() -> void: _choose(true))
	row.add_child(spare)
	var end_it: Button = UiStyle.button("End it", Vector2(280, 64), 28)
	end_it.pressed.connect(func() -> void: _choose(false))
	row.add_child(end_it)
	_skip = UiStyle.button("Skip", Vector2(110, 40), 18)
	_skip.pressed.connect(_on_skip)
	root.add_child(_skip)
	_skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 56)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# --- Scripted check (godot --path . res://scenes/story.tscn -- --story-test) ----------------------------------

func _run_test_step(id: String) -> void:
	await get_tree().create_timer(1.6).timeout
	if _index >= _queue.size() or _queue[_index] != id:
		return
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "story_card_%s" % id)
	if _index == _queue.size() - 1:
		print("STORY-TEST showed ", _queue.size(), " cards without errors")
		get_tree().quit()
		return
	_finish_typing()
	var lines: Array = _card.lines
	_line = maxi(lines.size() - 1, 0)
	_next_card()


# --- Scripted check of the final choice and both endings (godot ... story.tscn -- --story-ending=spare|end) ------

func _auto_step(id: String) -> void:
	await get_tree().create_timer(1.2).timeout
	if _index >= _queue.size() or _queue[_index] != id:
		return
	if bool(_card.get("choice", false)):
		print("ENDING-TEST final choice card shown with buttons: ", _choice_box.visible, " -> choosing ", _auto_ending)
		await RenderingServer.frame_post_draw
		DebugShot.save(get_viewport(), "story_choice")
		_choose(_auto_ending == "spare")
		return
	await RenderingServer.frame_post_draw
	DebugShot.save(get_viewport(), "story_ending_%s_%s" % [_auto_ending, id])
	_finish_typing()
	_line = maxi((_card.lines as Array).size() - 1, 0)
	_next_card()


func _run_ending_checks() -> void:
	# Pure logic checks of which cards play when (nothing is loaded).
	GameState.seen_cards.clear()
	print("FLOW-CHECK prologue cards on first Play: ", StoryFlow.unseen(StoryData.PROLOGUE).size(), " (expect 4)")
	print("FLOW-CHECK before level 1: ", StoryData.BEFORE_LEVEL.get(1), "  level 6: ", StoryData.BEFORE_LEVEL.get(6), "  level 7: ", StoryData.BEFORE_LEVEL.get(7), "  level 18: ", StoryData.BEFORE_LEVEL.get(18))
	print("FLOW-CHECK after boss 5/10/15/20: ", StoryData.AFTER_BOSS[5].size(), "/", StoryData.AFTER_BOSS[10].size(), "/", StoryData.AFTER_BOSS[15].size(), "/", StoryData.AFTER_BOSS[20].size(), " cards (expect 1/1/4/1)")
	GameState.mark_all_seen_for_test()
	print("FLOW-CHECK after everything is seen, cards left to show on Play: ", StoryFlow.unseen(StoryData.PROLOGUE).size(), " (expect 0)")
	GameState.seen_cards.clear()
