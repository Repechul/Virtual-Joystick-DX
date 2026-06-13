@tool
extends EditorPlugin

const JOYSTICK_CORE_SCRIPT:= preload("res://addons/virtual_joystick_DX/vjdx_core_script.gd")
const VIRT_JOY_DX_ICON:= preload("res://addons/virtual_joystick_DX/vjdx_icon.svg")


func _enter_tree():
	add_custom_type(
		"VirtualJoystickDeluxe",
		"control",
		JOYSTICK_CORE_SCRIPT,
		VIRT_JOY_DX_ICON
		)

func _exit_tree():
	remove_custom_type("VirtualJoystickDeluxe")