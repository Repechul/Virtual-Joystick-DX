@tool
## A fully customizable virtual joystick for touchscreen mobile games. Switch between a smooth 360° analog joystick and an 8-direction D-Pad.

@icon("res://addons/virtual_joystick_DX/vjdx_icon.svg")
extends Control
class_name VirtualJoystickDX

#region Enums & Signals
enum ControllerStyle {JOYSTICK, DPAD}
enum JoystickMode {STATIC, DYNAMIC, FOLLOWING}
enum DpadPreset {PRESET_1, PRESET_2}

## Emitted every frame the control is moved. direction is a Vector2 [-1,1] per axis.
signal joystick_moved(direction: Vector2)
## Emitted when the control is released.
signal joystick_released()
## Emitted when visibility changes automatically due to hardware detection.
signal hardware_visibility_changed(is_visible: bool)
#endregion

#region Inspector Parameters
@export_category("Controller Settings")
@export var controller_style: ControllerStyle = ControllerStyle.JOYSTICK:
	set(v):
		controller_style = v
		notify_property_list_changed()
		queue_redraw()
		update_configuration_warnings()
# Joystick (hidden for D-Pad)
@export_range(20.0, 400.0, 1.0, "suffix:px") var joystick_radius: float = 80.0:
	set(v):
		joystick_radius = maxf(v, 10.0)
		custom_minimum_size = Vector2(joystick_radius * 2.0, joystick_radius * 2.0)
		notify_property_list_changed()
		queue_redraw()
		update_configuration_warnings()
@export_range(5.0, 200.0, 1.0, "suffix:px") var thumb_radius: float = 28.0:
	set(v):
		thumb_radius = maxf(v, 5.0)
		notify_property_list_changed()
		queue_redraw()
# D-Pad (hidden for Joystick)
@export_range(20.0, 400.0, 1.0, "suffix:px") var dpad_radius: float = 80.0:
	set(v):
		dpad_radius = maxf(v, 10.0)
		notify_property_list_changed()
		queue_redraw()
		update_configuration_warnings()
# Shared
## Deadzone as a fraction of the radius.
## Max is capped at the thumb radius (JOYSTICK) so the deadzone never exceeds the thumb size.
## At 0 the speed is always constant regardless of thumb position.
@export var deadzone: float = 0.15:
	set(v):
		deadzone = clampf(v, 0.0, _max_deadzone())
		queue_redraw()
@export var debug_deadzone: bool = true:
	set(v):
		debug_deadzone = v
		notify_property_list_changed()
		queue_redraw()
@export var debug_deadzone_color: Color = Color(0.626, 0.014, 0.218, 0.702):
	set(v):
		debug_deadzone_color = v
		queue_redraw()

@export_category("Joystick Mode")
@export var joystick_mode: JoystickMode = JoystickMode.STATIC:
	set(v):
		joystick_mode = v
		notify_property_list_changed()
		update_configuration_warnings()
## [JOYSTICK + DYNAMIC only] How far (as a multiple of the radius) the finger
## can travel from the constrained base center before the control auto-releases.
@export_range(1.0, 3.0, 0.05) var clampzone_ratio: float = 1.5:
	set(v):
		clampzone_ratio = v
		queue_redraw()
## [JOYSTICK + DYNAMIC only] Shows a circle representing the auto-release distance
## (radius * clampzone_ratio) around the base, drawn on top. Editor only.
@export var debug_clampzone: bool = false:
	set(v):
		debug_clampzone = v
		notify_property_list_changed()
		queue_redraw()
@export var clampzone_color: Color = Color(0.994, 1.0, 0.0, 0.612):
	set(v):
		clampzone_color = v
		queue_redraw()

@export_category("Input Mapping")
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin, loose_mode") var action_left : StringName = "ui_left"
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin, loose_mode") var action_right : StringName = "ui_right"
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin, loose_mode") var action_up : StringName = "ui_up"
@export_custom(PROPERTY_HINT_INPUT_NAME, "show_builtin, loose_mode") var action_down : StringName = "ui_down"

@export_category("Dynamic Visibility")
@export_group("Auto-hide by Hardware")
@export var auto_hide_on_physical_input: bool = true
@export var auto_show_on_touch: bool = true

# Active Region
@export_category("Active Region")
@export var use_active_region: bool = true:
	set(v):
		use_active_region = v
		notify_property_list_changed()
		queue_redraw()
@export var debug_show_region: bool = true:
	set(v):
		debug_show_region = v
		notify_property_list_changed()
		queue_redraw()
@export var debug_region_color: Color = Color(0.1, 1.0, 0.4, 0.80):
	set(v):
		debug_region_color = v
		queue_redraw()

@export var region_x: float = 0.0:
	set(v):
		var vp: = _get_viewport_size()
		region_x = clampf(v, 0.0, vp.x)
		region_w = clampf(region_w, 0.0, vp.x - region_x)
		notify_property_list_changed()
		queue_redraw()

@export var region_y: float = 0.0:
	set(v):
		var vp: = _get_viewport_size()
		region_y = clampf(v, 0.0, vp.y)
		region_h = clampf(region_h, 0.0, vp.y - region_y)
		notify_property_list_changed()
		queue_redraw()

@export var region_w: float = 648.0:
	set(v):
		var vp: = _get_viewport_size()
		region_w = clampf(v, 0.0, vp.x - region_x)
		queue_redraw()
@export var region_h: float = 648.0:
	set(v):
		var vp: = _get_viewport_size()
		region_h = clampf(v, 0.0, vp.y - region_y)
		queue_redraw()

## Computed Rect2 from the four region components. Used internally.
var active_region: Rect2:
	get: return Rect2(region_x, region_y, region_w, region_h)

# Textures
@export_category("Textures")
@export_group("Colors - Joystick")
@export var color_js_base: Color = Color(0.12, 0.12, 0.12, 0.55)
@export var color_js_border: Color = Color(0.88, 0.88, 0.88, 0.42)
@export var color_js_thumb: Color = Color(0.90, 0.90, 0.90, 0.82)
@export var color_js_thumb_active: Color = Color(1.00, 0.55, 0.08, 0.95)

@export_group("Colors - D-Pad")
@export var color_dp_bg: Color = Color(0.08, 0.08, 0.08, 0.35)
@export var color_dp_border: Color = Color(0.88, 0.88, 0.88, 0.42)
@export var color_dp_normal: Color = Color(0.35, 0.35, 0.35, 0.72)
@export var color_dp_active: Color = Color(0.95, 0.42, 0.07, 0.97)
@export var color_dp_arrow: Color = Color(1.00, 1.00, 1.00, 0.88)

@export_group("Textures - Joystick")
@export var tex_joystick_base: Texture2D:
	set(v):
		tex_joystick_base = v
		queue_redraw()
@export var tex_joystick_thumb: Texture2D:
	set(v):
		tex_joystick_thumb = v
		queue_redraw()
@export var tex_joystick_thumb_pressed: Texture2D:
	set(v):
		tex_joystick_thumb_pressed = v
		queue_redraw()

@export_group("Textures - D-Pad")
## If enabled, the D-Pad uses a built-in preset as default.
## Custom textures assigned to the slots below always take priority over the preset.
## If disabled, always uses the code-drawn fallback regardless of any texture assignments.
@export var dpad_use_textures: bool = true:
	set(v):
		dpad_use_textures = v
		notify_property_list_changed()
		queue_redraw()
## Built-in texture preset used when no custom texture is assigned to a slot.
@export var dpad_preset: DpadPreset = DpadPreset.PRESET_1:
	set(v):
		dpad_preset = v
		_preset_cache_dirty = true
		queue_redraw()
@export var tex_dpad_idle: Texture2D:
	set(v):
		tex_dpad_idle = v
		queue_redraw()
@export_subgroup("Cardinals")
@export var tex_dpad_up: Texture2D:
	set(v):
		tex_dpad_up = v
		queue_redraw()
@export var tex_dpad_down: Texture2D:
	set(v):
		tex_dpad_down = v
		queue_redraw()
@export var tex_dpad_left: Texture2D:
	set(v):
		tex_dpad_left = v
		queue_redraw()
@export var tex_dpad_right: Texture2D:
	set(v):
		tex_dpad_right = v
		queue_redraw()
@export_subgroup("Diagonals")
@export var tex_dpad_up_right: Texture2D:
	set(v):
		tex_dpad_up_right = v
		queue_redraw()
@export var tex_dpad_up_left: Texture2D:
	set(v):
		tex_dpad_up_left = v
		queue_redraw()
@export var tex_dpad_down_right: Texture2D:
	set(v):
		tex_dpad_down_right = v
		queue_redraw()
@export var tex_dpad_down_left: Texture2D:
	set(v):
		tex_dpad_down_left = v
		queue_redraw()
#endregion

#region Internal State
## Current direction. JOYSTICK: Vector2 [-1,1]. DPAD: components {-1,0,1}, combinable for diagonals.
var value: Vector2 = Vector2.ZERO
var is_pressed: bool = false
var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _knob_pos: Vector2 = Vector2.ZERO
var _dpad_active: Vector2 = Vector2.ZERO
var _origin_pos: Vector2 = Vector2.ZERO
var _hidden_by_hw: bool = false
var _preset_cache: Array[Texture2D] = []
var _preset_cache_dirty: bool = true
#endregion

#region Conditional Inspector Visibility
func _validate_property(property: Dictionary) -> void:
	var is_joystick: bool = (controller_style == ControllerStyle.JOYSTICK)
	var is_movable: bool = (joystick_mode == JoystickMode.DYNAMIC or joystick_mode == JoystickMode.FOLLOWING)
	var vp: Vector2 = _get_viewport_size()
	match property.name:
		"Joystick Mode":
			if not is_joystick:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"joystick_mode",\
		"joystick_radius", "thumb_radius",\
		"Colors - Joystick",\
		"color_js_base", "color_js_border", "color_js_thumb", "color_js_thumb_active",\
		"Textures - Joystick",\
		"tex_joystick_base", "tex_joystick_thumb", "tex_joystick_thumb_pressed":
			if not is_joystick:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"clampzone_ratio", "debug_clampzone":
			if not (is_joystick and is_movable):
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"clampzone_color":
			if not (is_joystick and is_movable and debug_clampzone):
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"dpad_radius",\
		"Colors - D-Pad",\
		"color_dp_bg", "color_dp_border", "color_dp_normal", "color_dp_active", "color_dp_arrow",\
		"Textures - D-Pad", "dpad_use_textures":
			if is_joystick:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"dpad_preset":
			if is_joystick or not dpad_use_textures:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"tex_dpad_idle",\
		"Cardinals", "tex_dpad_up", "tex_dpad_down", "tex_dpad_left", "tex_dpad_right",\
		"Diagonals", "tex_dpad_up_right", "tex_dpad_up_left", "tex_dpad_down_right", "tex_dpad_down_left":
			if is_joystick or not dpad_use_textures:
				property.usage = PROPERTY_USAGE_NO_EDITOR
# Active Region sub-properties
# Hidden when use_active_region is disabled.
# When visible, set dynamic ranges based on current viewport size.
		"region_x":
			if not use_active_region:
				property.usage = PROPERTY_USAGE_NO_EDITOR
			else:
				property.hint = PROPERTY_HINT_RANGE
				property.hint_string = "0.0,%.0f,1.0,suffix:px" % vp.x
		"region_y":
			if not use_active_region:
				property.usage = PROPERTY_USAGE_NO_EDITOR
			else:
				property.hint = PROPERTY_HINT_RANGE
				property.hint_string = "0.0,%.0f,1.0,suffix:px" % vp.y
		"region_w":
			if not use_active_region:
				property.usage = PROPERTY_USAGE_NO_EDITOR
			else:
				property.hint = PROPERTY_HINT_RANGE
				property.hint_string = "0.0,%.0f,1.0,suffix:px" % maxf(0.0, vp.x - region_x)
		"region_h":
			if not use_active_region:
				property.usage = PROPERTY_USAGE_NO_EDITOR
			else:
				property.hint = PROPERTY_HINT_RANGE
				property.hint_string = "0.0,%.0f,1.0,suffix:px" % maxf(0.0, vp.y - region_y)
		"debug_show_region":
			if not use_active_region:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"debug_region_color":
			if not (use_active_region and debug_show_region):
				property.usage = PROPERTY_USAGE_NO_EDITOR
		"debug_deadzone_color":
			if not debug_deadzone:
				property.usage = PROPERTY_USAGE_NO_EDITOR
# Deadzone: dynamic max = thumb_radius / joystick_radius
		"deadzone":
			property.hint = PROPERTY_HINT_RANGE
			property.hint_string = "0.0,%.3f,0.001" % _max_deadzone()
#endregion

#region Lifecycle
func _ready() -> void:
	_origin_pos = position
	_center = size / 2.0
	_knob_pos = _center
	mouse_filter = MOUSE_FILTER_IGNORE
	if not Engine.is_editor_hint():
		set_process_input(true)
		if auto_hide_on_physical_input:
			Input.joy_connection_changed.connect(_on_joy_connection_changed)
			_check_hardware_state()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_center = size / 2.0
			_knob_pos = _center if not is_pressed else _knob_pos
			queue_redraw()
		NOTIFICATION_ENTER_TREE:
			if not Engine.is_editor_hint():
				_origin_pos = position

func _active_radius() -> float:
	return joystick_radius if controller_style == ControllerStyle.JOYSTICK else dpad_radius

## Returns the max allowed deadzone fraction based on thumb and radius sizes.
## For JOYSTICK: caps deadzone so it never visually exceeds the thumb.
## For DPAD: caps at 0.9 (no thumb reference).
func _max_deadzone() -> float:
	if controller_style == ControllerStyle.JOYSTICK and joystick_radius > 0.0:
		return minf(thumb_radius / joystick_radius, 0.999)
	return 0.9

## Returns the viewport size configured in Project Settings → Display → Window → Size.
func _get_viewport_size() -> Vector2:
	var w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 1920)
	var h: float = ProjectSettings.get_setting("display/window/size/viewport_height", 1080)
	return Vector2(w, h)
#endregion

#region Hardware Detection
func _check_hardware_state() -> void:
	if Input.get_connected_joypads().size() > 0:
		_apply_hw_visibility(false)

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	if auto_hide_on_physical_input:
		_apply_hw_visibility(Input.get_connected_joypads().size() == 0)

func _apply_hw_visibility(show: bool) -> void:
	_hidden_by_hw = not show
	visible= show
	hardware_visibility_changed.emit(show)
	if not show:
		_do_release()
#endregion

#region Input
func _input(event: InputEvent) -> void:
	if auto_hide_on_physical_input and event is InputEventKey and event.pressed:
		_apply_hw_visibility(false)
		return

	if auto_show_on_touch and not _hidden_by_hw and auto_hide_on_physical_input:
		if event is InputEventJoypadButton and event.pressed:
			_apply_hw_visibility(false)
			return
		if event is InputEventJoypadMotion and absf(event.axis_value) > 0.2:
			_apply_hw_visibility(false)
			return

	if _hidden_by_hw and auto_show_on_touch:
		if event is InputEventScreenTouch or event is InputEventScreenDrag:
			_apply_hw_visibility(true)

	if not visible:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_touch(event.index, event.position)
		elif event.index == _touch_index:
			_do_release()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_stick(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_touch(0, event.position)
			elif _touch_index == 0:
				_do_release()
	elif event is InputEventMouseMotion:
		if _touch_index == 0 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_update_stick(event.position)
#endregion

#region Core Logic
func _to_local(screen_pos: Vector2) -> Vector2:
	return (screen_pos - global_position) / scale
func _in_start_region(screen_pos: Vector2) -> bool:
	if use_active_region:
		return active_region.has_point(screen_pos)
	return get_global_rect().has_point(screen_pos)
func _begin_touch(index: int, screen_pos: Vector2) -> void:
	if _touch_index != -1:
		return
# FOLLOWING: must touch the joystick's own current rect directly.
# active_region is ignored for this gate — it only constrains the slide once active.
	if controller_style == ControllerStyle.JOYSTICK and joystick_mode == JoystickMode.FOLLOWING:
		if not get_global_rect().has_point(screen_pos):
			return
	elif not _in_start_region(screen_pos):
		return
	_touch_index = index
	is_pressed = true
	if controller_style == ControllerStyle.JOYSTICK and joystick_mode == JoystickMode.DYNAMIC:
		_reposition_base(screen_pos)
		_center = size / 2.0
		_knob_pos = _center
	_update_stick(screen_pos)

func _reposition_base(screen_pos: Vector2) -> void:
	# Clamp the initial spawn position so the base center stays inside the active region.
	var spawn: Vector2 = screen_pos
	if use_active_region:
		spawn.x = clampf(spawn.x, active_region.position.x, active_region.end.x)
		spawn.y = clampf(spawn.y, active_region.position.y, active_region.end.y)
	var parent := get_parent()
	var new_pos: Vector2
	if parent is CanvasItem:
		new_pos = (parent as CanvasItem).get_global_transform().affine_inverse() * spawn
	else:
		new_pos = spawn
	position = new_pos - size / 2.0
func _update_stick(screen_pos: Vector2) -> void:
	var radius: float = _active_radius()
	var is_movable_js: bool = (controller_style == ControllerStyle.JOYSTICK and
								(joystick_mode == JoystickMode.DYNAMIC or joystick_mode == JoystickMode.FOLLOWING))
	var is_static_mode: bool = not is_movable_js
# Active region enforcement
	if use_active_region and is_static_mode:
# STATIC joystick and D-Pad: finger leaving the active region = release.
		if not active_region.has_point(screen_pos):
			_do_release()
			return

	var local_pos: Vector2 = _to_local(screen_pos)
	var offset: Vector2 = local_pos - _center
	var dist: float = offset.length()

# DYNAMIC + FOLLOWING: slide base, clamped to active region.
# Both modes share the exact same follow mechanic from here on —
# they only differ in how the control gets activated (see _begin_touch).
	if is_movable_js:
		if dist > radius * clampzone_ratio:
			_do_release()
			return

		if dist > radius:
			var dir: Vector2 = offset / dist
# Ideal new base center in screen/viewport coordinates.
			var target_center: Vector2 = (global_position + _center) + offset - dir * radius
# Clamp base center so it never exits the active region.
			if use_active_region:
				target_center.x = clampf(target_center.x, active_region.position.x, active_region.end.x)
				target_center.y = clampf(target_center.y, active_region.position.y, active_region.end.y)
			var parent := get_parent()
			var new_pos: Vector2
			if parent is CanvasItem:
				new_pos = (parent as CanvasItem).get_global_transform().affine_inverse() * target_center
			else:
				new_pos = target_center
			position = new_pos - size / 2.0
# Recalculate offset after the base moved.
			local_pos = _to_local(screen_pos)
			offset = local_pos - _center
			dist = offset.length()
# Knob always follows the finger, clamped to the radius.
# The deadzone never affects the knob's visual position.
	_knob_pos = _center + offset.limit_length(radius)
	match controller_style:
		ControllerStyle.JOYSTICK: _calc_joystick(offset, dist)
		ControllerStyle.DPAD: _calc_dpad(offset, dist)
	_trigger_actions()
	joystick_moved.emit(value)
	queue_redraw()

func _do_release() -> void:
	if _touch_index == -1:
		return
	_touch_index = -1
	is_pressed = false
	value = Vector2.ZERO
	_dpad_active = Vector2.ZERO
	_knob_pos = _center
	if controller_style == ControllerStyle.JOYSTICK and (joystick_mode == JoystickMode.DYNAMIC or joystick_mode == JoystickMode.FOLLOWING):
		position = _origin_pos
		_center = size / 2.0
		_knob_pos = _center
	_reset_actions()
	joystick_released.emit()
	queue_redraw()
#endregion

#region Value Calculation
func _calc_joystick(offset: Vector2, dist: float) -> void:
	var dz_px: float = deadzone * joystick_radius
	if dist < 0.001 or dist <= dz_px:
		value = Vector2.ZERO
		return

	var direction: Vector2 = offset / dist

	if is_zero_approx(deadzone):
# deadzone = 0 → constant speed, value is always a unit vector.
		value = direction
	else:
# deadzone > 0 → proportional speed: 0 at the deadzone edge, 1.0 at the radius.
		var t: float = clampf((dist - dz_px) / (joystick_radius - dz_px), 0.0, 1.0)
		value = direction * t

func _calc_dpad(offset: Vector2, dist: float) -> void:
	var dz_px: float = deadzone * dpad_radius
	if dist < 0.001 or dist <= dz_px:
		value = Vector2.ZERO
		_dpad_active = Vector2.ZERO
		return

	var nx: float = offset.x / dist
	var ny: float = offset.y / dist

# sin(22.5°) ≈ 0.3827 → divides the circle into 8 octants of 45°.
# Each axis is evaluated independently, allowing simultaneous diagonal inputs.
	const DIAG_T: float = 0.3827

	var dir: Vector2 = Vector2.ZERO
	if nx > DIAG_T: dir.x = 1.0
	elif nx < -DIAG_T: dir.x = -1.0
	if ny > DIAG_T: dir.y = 1.0
	elif ny < -DIAG_T: dir.y = -1.0

	if dir == Vector2.ZERO:
		dir.x = signf(nx)
		dir.y = signf(ny)

	_dpad_active = dir
	value = dir
#endregion

#region Input Actions
# Actual value components are passed as strength to Input.action_press().
# This enables 360° movement via Input.get_axis():
# Input.get_axis("move_left", "move_right") -> returns exactly value.x
# Input.get_axis("move_up", "move_down") -> returns exactly value.y
# Use get_axis, NOT get_vector.
# get_vector applies its own internal deadzone and may truncate values < 0.5.

func _trigger_actions() -> void:
	if value.x < 0.0:
		if Input.is_action_pressed(action_right): Input.action_release(action_right)
		Input.action_press(action_left, absf(value.x))
	elif value.x > 0.0:
		if Input.is_action_pressed(action_left): Input.action_release(action_left)
		Input.action_press(action_right, value.x)
	else:
		Input.action_release(action_left)
		Input.action_release(action_right)
	if value.y < 0.0:
		if Input.is_action_pressed(action_down): Input.action_release(action_down)
		Input.action_press(action_up, absf(value.y))
	elif value.y > 0.0:
		if Input.is_action_pressed(action_up): Input.action_release(action_up)
		Input.action_press(action_down, value.y)
	else:
		Input.action_release(action_up)
		Input.action_release(action_down)

func _reset_actions() -> void:
	Input.action_release(action_left)
	Input.action_release(action_right)
	Input.action_release(action_up)
	Input.action_release(action_down)
#endregion

#region Drawing
func _draw() -> void:
	if Engine.is_editor_hint() and use_active_region and debug_show_region:
		_draw_debug_region()
	match controller_style:
		ControllerStyle.JOYSTICK: _draw_joystick()
		ControllerStyle.DPAD: _draw_dpad()
	if Engine.is_editor_hint() and controller_style == ControllerStyle.JOYSTICK \
			and (joystick_mode == JoystickMode.DYNAMIC or joystick_mode == JoystickMode.FOLLOWING) and debug_clampzone:
		_draw_debug_clampzone()
	if Engine.is_editor_hint() and debug_deadzone:
		_draw_debug_deadzone()

func _draw_joystick() -> void:
	var c: Vector2 = _center
	var r: float = joystick_radius

	if tex_joystick_base:
		draw_texture_rect(tex_joystick_base, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false)
	else:
		draw_circle(c, r, color_js_base)
		draw_arc(c, r, 0.0, TAU, 64, color_js_border, 2.0)

	var tr: float = thumb_radius
	var tp: Vector2 = _knob_pos
	var tex: Texture2D = tex_joystick_thumb_pressed if (is_pressed and tex_joystick_thumb_pressed) else tex_joystick_thumb

	if tex:
		draw_texture_rect(tex, Rect2(tp - Vector2(tr, tr), Vector2(tr, tr) * 2.0), false)
	else:
		draw_circle(tp + Vector2(1.5, 2.5), tr, Color(0.0, 0.0, 0.0, 0.22))
		draw_circle(tp, tr, color_js_thumb_active if is_pressed else color_js_thumb)

const _PRESET_FILES: Array[String] = [
	"idle", "up", "down", "left", "right", "up_right", "up_left", "down_right", "down_left"
]

func _load_preset_cache() -> void:
	_preset_cache.clear()
	var folder: String
	if dpad_preset == DpadPreset.PRESET_1:
		folder = "res://addons/virtual_joystick_DX/Dpad textures/preset 1/"
	else:
		folder = "res://addons/virtual_joystick_DX/Dpad textures/preset 2/"
	for f in _PRESET_FILES:
		var path: String = folder + f + ".svg"
		if ResourceLoader.exists(path):
			_preset_cache.append(load(path) as Texture2D)
		else:
			_preset_cache.append(null)
	_preset_cache_dirty = false

func _preset_state_index() -> int:
	var x: = _dpad_active.x
	var y: = _dpad_active.y
	if y < 0 and x > 0: return 5
	if y < 0 and x < 0: return 6
	if y > 0 and x > 0: return 7
	if y > 0 and x < 0: return 8
	if y < 0: return 1
	if y > 0: return 2
	if x < 0: return 3
	if x > 0: return 4
	return 0

func _get_dpad_texture() -> Texture2D:
	if not dpad_use_textures:
		return null

	# Custom slot always overrides the preset
	var x: = _dpad_active.x
	var y: = _dpad_active.y
	var custom: Texture2D
	if y < 0 and x > 0: custom = tex_dpad_up_right
	elif y < 0 and x < 0: custom = tex_dpad_up_left
	elif y > 0 and x > 0: custom = tex_dpad_down_right
	elif y > 0 and x < 0: custom = tex_dpad_down_left
	elif y < 0: custom = tex_dpad_up
	elif y > 0: custom = tex_dpad_down
	elif x < 0: custom = tex_dpad_left
	elif x > 0: custom = tex_dpad_right
	else: custom = tex_dpad_idle
	if custom:
		return custom

	# Preset fallback (lazy-loaded and cached)
	if _preset_cache_dirty:
		_load_preset_cache()
	var idx: int = _preset_state_index()
	if idx < _preset_cache.size():
		return _preset_cache[idx]
	return null

func _draw_dpad() -> void:
	var c: Vector2 = _center
	var r: float = dpad_radius
	var arm: float = r * 0.54
	var hw: float = r * 0.38
	var rect_full := Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
	var tex: = _get_dpad_texture()
	if tex:
		draw_texture_rect(tex, rect_full, false)
		return

	draw_circle(c, r, color_dp_bg)
	var cross_color: = Color(color_dp_bg.r * 0.6, color_dp_bg.g * 0.6, color_dp_bg.b * 0.6, color_dp_bg.a)
	draw_rect(Rect2(c + Vector2(-hw, -r * 0.94), Vector2(hw * 2.0, r * 1.88)), cross_color, true)
	draw_rect(Rect2(c + Vector2(-r * 0.94, -hw), Vector2(r * 1.88, hw * 2.0)), cross_color, true)
	draw_arc(c, r * 0.98, 0.0, TAU, 64, color_dp_border, 1.5)

	var dirs: Array = [
		{&"v": Vector2.UP, "off": Vector2(0.0, -arm)},
		{&"v": Vector2.DOWN, "off": Vector2(0.0, arm)},
		{&"v": Vector2.LEFT, "off": Vector2(-arm, 0.0)},
		{&"v": Vector2.RIGHT, "off": Vector2(arm, 0.0)},
	]
	for d in dirs:
		var active: bool = d[&"v"].dot(_dpad_active) > 0.0
		var bp: Vector2 = c + d.off
		var rect: Rect2 = Rect2(bp - Vector2(hw, hw), Vector2(hw, hw) * 2.0)
		draw_rect(rect, color_dp_active if active else color_dp_normal, true)
		draw_rect(rect, color_dp_border, false, 1.4)
		_draw_arrow(bp, d[&"v"], hw * 0.52)

func _draw_arrow(pos: Vector2, dir: Vector2, size: float) -> void:
	var perp: Vector2 = Vector2(-dir.y, dir.x) * size * 0.62
	draw_colored_polygon(PackedVector2Array([
		pos + dir * size,
		pos - dir * size * 0.48 + perp,
		pos - dir * size * 0.48 - perp,
	]), color_dp_arrow)

func _draw_debug_region() -> void:
	# active_region is in viewport/screen coordinates; convert to node local space.
	var xf: Transform2D = get_global_transform().affine_inverse()
	var tl: Vector2 = xf * active_region.position
	var br: Vector2 = xf * active_region.end
	var fill: Color = Color(debug_region_color.r, debug_region_color.g,
								debug_region_color.b, debug_region_color.a * 0.18)
	draw_rect(Rect2(tl, br - tl), fill, true)
	draw_rect(Rect2(tl, br - tl), debug_region_color, false, 2.0)

func _draw_debug_deadzone() -> void:
	var r: float = deadzone * _active_radius()
	if r < 0.5:
		return
	var fill: Color = Color(debug_deadzone_color.r, debug_deadzone_color.g,
							debug_deadzone_color.b, debug_deadzone_color.a * 0.45)
	draw_circle(_center, r, fill)
	draw_arc(_center, r, 0.0, TAU, 64, debug_deadzone_color, 2.0)

func _draw_debug_clampzone() -> void:
	# Shows the auto-release boundary: radius * clampzone_ratio
	# around the base's current center (the base itself may have slid already).
	var r: float = joystick_radius * clampzone_ratio
	var fill: Color = Color(clampzone_color.r, clampzone_color.g,
							clampzone_color.b, clampzone_color.a * 0.12)
	draw_circle(_center, r, fill)
	draw_arc(_center, r, 0.0, TAU, 64, clampzone_color, 2.0)
#endregion

func release() -> void: _do_release()
func is_active() -> bool: return _touch_index != -1
func get_value() -> Vector2: return value

func _get_configuration_warnings() -> PackedStringArray:
	var w: PackedStringArray = []
	var r: float = _active_radius()
	if joystick_mode == JoystickMode.DYNAMIC and controller_style == ControllerStyle.DPAD:
		w.append("DYNAMIC only works with JOYSTICK. The D-Pad always uses STATIC.")
	if joystick_mode == JoystickMode.FOLLOWING and controller_style == ControllerStyle.DPAD:
		w.append("FOLLOWING only works with JOYSTICK. The D-Pad always uses STATIC.")
	if size.x < r * 2.0 or size.y < r * 2.0:
		w.append("The node is smaller than the control diameter (%dpx). Adjust the size." % int(r * 2.0))
	if use_active_region and active_region.size == Vector2.ZERO:
		w.append("The active region has zero size. Define a valid Rect2.")
	return w
