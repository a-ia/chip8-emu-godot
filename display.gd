extends Node2D

const SCALE = 20  # Size of each pixel
const PIXEL_COLOR = Color(1, 1, 1)  # White
const BG_COLOR = Color(0, 0, 0)  # Black

@onready var cpu = $"../CPU"

func _ready():
	cpu.connect("display_updated", _on_display_updated)

func _draw():
	# Draw background
	draw_rect(Rect2(0, 0, 64 * SCALE, 32 * SCALE), BG_COLOR)
	
	# Draw pixels
	for y in range(32):
		for x in range(64):
			if cpu.display[y][x]:
				draw_rect(
					Rect2(x * SCALE, y * SCALE, SCALE, SCALE),
					PIXEL_COLOR
				)

func _on_display_updated():
	queue_redraw()
