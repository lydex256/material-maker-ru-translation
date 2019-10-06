tool
extends Control
class_name MMGradientEditor


class GradientCursor:
	extends ColorRect
	
	const WIDTH = 10
	
	func _ready():
		rect_position = Vector2(0, 15)
		rect_size = Vector2(WIDTH, 15)
	
	func _gui_input(ev):
		if ev is InputEventMouseButton:
			if ev.button_index == BUTTON_LEFT && ev.doubleclick:
				get_parent().select_color(self, ev.global_position)
			elif ev.button_index == BUTTON_RIGHT && get_parent().get_sorted_cursors().size() > 2:
				var parent = get_parent()
				parent.remove_child(self)
				parent.update_value()
				queue_free()
		elif ev is InputEventMouseMotion && (ev.button_mask & 1) != 0:
			rect_position.x += ev.relative.x
			rect_position.x = min(max(0, rect_position.x), get_parent().rect_size.x-rect_size.x)
			get_parent().update_value()
	
	func get_position():
		return rect_position.x / (get_parent().rect_size.x - WIDTH)
	
	func set_color(c):
		color = c
		get_parent().update_value()
	
	static func sort(a, b):
		if a.get_position() < b.get_position():
			return true
		return false
	
	func _draw():
		var c = color
		c.a = 1.0
		draw_rect(Rect2(0, 0, rect_size.x, rect_size.y), c, false)

var value = null setget set_value
export var embedded : bool = true

signal updated(value)

func _ready():
	$Gradient.material = $Gradient.material.duplicate(true)
	set_value(MMGradient.new())

func set_value(v):
	value = v
	for c in get_children():
		if c is GradientCursor:
			remove_child(c)
			c.free()
	for p in value.points:
		add_cursor(p.v*(rect_size.x-GradientCursor.WIDTH), p.c)
	update_shader()

func update_value():
	value.clear()
	for p in get_children():
		if p != $Gradient && p != $Background:
			value.add_point(p.rect_position.x/(rect_size.x-GradientCursor.WIDTH), p.color)
	update_shader()

func add_cursor(x, color):
	var cursor = GradientCursor.new()
	add_child(cursor)
	cursor.rect_position.x = x
	cursor.color = color

func _gui_input(ev):
	if ev is InputEventMouseButton && ev.button_index == 1 && ev.doubleclick:
		if ev.position.y > 15:
			var p = max(0, min(ev.position.x, rect_size.x-GradientCursor.WIDTH))
			add_cursor(p, get_gradient_color(p))
			update_value()
		elif embedded:
			var popup = load("res://addons/material_maker/widgets/gradient_popup.tscn").instance()
			add_child(popup)
			var popup_size = popup.rect_size
			popup.popup(Rect2(ev.global_position, Vector2(0, 0)))
			popup.set_global_position(ev.global_position-Vector2(popup_size.x / 2, popup_size.y))
			popup.init(value)
			popup.connect("updated", self, "set_value")

# Showing a color picker popup to change a cursor's color

var active_cursor

func select_color(cursor, position):
	active_cursor = cursor
	$Gradient/Popup/ColorPicker.color = cursor.color
	$Gradient/Popup/ColorPicker.connect("color_changed", cursor, "set_color")
	$Gradient/Popup.rect_position = position
	$Gradient/Popup.popup()

func _on_Popup_popup_hide():
	$Gradient/Popup/ColorPicker.disconnect("color_changed", active_cursor, "set_color")

# Calculating a color from the gradient and generating the shader

func get_sorted_cursors():
	var array = get_children()
	array.erase($Gradient)
	array.erase($Background)
	array.sort_custom(GradientCursor, "sort")
	return array

func get_gradient_color(x):
	return value.get_color(x / (rect_size.x - GradientCursor.WIDTH))

func update_shader():
	var shader
	shader  = "shader_type canvas_item;\n"
	shader += value.get_shader("gradient")
	shader += "void fragment() { COLOR = gradient(UV.x); }"
	$Gradient.material.shader.set_code(shader)
	emit_signal("updated", value)
