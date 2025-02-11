extends Node2D

const PIXEL_COLOR = Color(1, 1, 1)  # White
const BG_COLOR = Color(0, 0, 0)  # Black
const DISPLAY_WIDTH = 64
const DISPLAY_HEIGHT = 32

@onready var cpu = $"../CPU"
var scale_factor = Vector2.ONE

func _ready():
	cpu.connect("display_updated", _on_display_updated)
	_update_scale()
	# Window resize signal
	get_tree().root.connect("size_changed", _on_window_resize)

func _update_scale():
	var viewport_size = get_viewport_rect().size
	var scale_x = viewport_size.x / DISPLAY_WIDTH
	var scale_y = viewport_size.y / DISPLAY_HEIGHT
	var final_scale = min(scale_x, scale_y)
	scale_factor = Vector2(final_scale, final_scale)

	# Center
	position = (viewport_size - Vector2(DISPLAY_WIDTH, DISPLAY_HEIGHT) * scale_factor) / 2

func _draw():
	# Draw background
	draw_rect(Rect2(0, 0, DISPLAY_WIDTH * scale_factor.x, DISPLAY_HEIGHT * scale_factor.y), BG_COLOR)
	
	# Draw pixels
	for y in range(DISPLAY_HEIGHT):
		for x in range(DISPLAY_WIDTH):
			if cpu.display[y][x]:
				draw_rect(
					Rect2(
						x * scale_factor.x, 
						y * scale_factor.y, 
						scale_factor.x, 
						scale_factor.y
					),
					PIXEL_COLOR
				)

func _on_display_updated():
	queue_redraw()

func _on_window_resize():
	_update_scale()
	queue_redraw()
