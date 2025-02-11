extends Node

@onready var cpu = $CPU
@onready var rom_selector = $ROMSelector
@onready var editor_button = $MenuContainer/EditorButton

var emulation_running = false
const INSTRUCTIONS_PER_SECOND = 500  
var instruction_timer = 0.0
const INSTRUCTION_INTERVAL = 1.0 / INSTRUCTIONS_PER_SECOND

func _ready():
	# Connect ROM selector signal
	rom_selector.rom_selected.connect(_on_rom_selected)
	
	#if editor_button and not editor_button.pressed.is_connected(_on_editor_button_pressed):
	#	editor_button.pressed.connect(_on_editor_button_pressed)
	
	# Show ROM selector on startup
	rom_selector.show()
	set_process(false)  # Don't start emulation until ROM is loaded

func _on_rom_selected(path: String):
	cpu.reset()
	if cpu.load_rom(path):
		rom_selector.hide_dialog()
		emulation_running = true
		set_process(true)
		instruction_timer = 0.0
	else:
		print("Failed to load ROM")

func _on_editor_button_pressed():
	# Pause emulation while editor is open
	emulation_running = false
	set_process(false)
	
	# Instance the editor scene
	var editor = load("res://scenes/CHIP8Editor.tscn").instantiate()
	add_child(editor)
	
	# Connect close signal
	editor.closed.connect(func(): 
		emulation_running = true
		set_process(true)
	)

func _process(delta):
	if emulation_running:
		# Update timers at 60Hz
		cpu.update_timers()
		
		# Execute instructions at controlled rate
		instruction_timer += delta
		while instruction_timer >= INSTRUCTION_INTERVAL:
			cpu.execute_cycle()
			instruction_timer -= INSTRUCTION_INTERVAL


func _input(event):
	if event.is_action_pressed("pause"):
		if emulation_running:
			emulation_running = false
			set_process(false)
			rom_selector.show_dialog()
		else:
			emulation_running = true
			set_process(true)
			rom_selector.hide_dialog()
