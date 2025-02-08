extends Control

# Editor state
var current_sprite = []
var current_address = 0x200  # Starting address for programs
var memory = []
# Erm
var _on_address_changed;

@onready var sprite_grid = $EditorPanel/SpriteEditor/Grid
@onready var hex_editor = $EditorPanel/HexEditor/TextEdit
@onready var address_spin = $EditorPanel/Controls/AddressSpin

signal closed

func _ready():
	# Initialize sprite grid (8x15 for CHIP-8 sprites)
	_init_sprite_grid()
	_init_memory()
	
	# Connect signals
	address_spin.value_changed.connect(_on_address_changed)

func _init_sprite_grid():
	sprite_grid.columns = 8
	for i in range(8 * 15):
		var button = Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(30, 30)
		button.toggled.connect(_on_pixel_toggled.bind(i))
		sprite_grid.add_child(button)

func _init_memory():
	memory.resize(4096)
	memory.fill(0)

func _on_pixel_toggled(pressed: bool, index: int):
	var row = index / 8
	var col = index % 8
	
	# Update sprite data
	if pressed:
		current_sprite[row] |= (1 << (7 - col))
	else:
		current_sprite[row] &= ~(1 << (7 - col))
	
	_update_hex_display()

func _update_hex_display():
	var hex_text = ""
	for byte in current_sprite:
		hex_text += "%02X " % byte
	hex_editor.text = hex_text

func _on_save_pressed():
	# Save sprite to memory
	for i in range(current_sprite.size()):
		memory[current_address + i] = current_sprite[i]

func _on_export_pressed():
	# Export current memory as a CHIP-8 ROM
	var file = FileAccess.open("user://game.ch8", FileAccess.WRITE)
	if file:
		for byte in memory:
			file.store_8(byte)
			
			
func _on_close_button_pressed():
	emit_signal("closed")
	queue_free()  # Remove the editor scene
