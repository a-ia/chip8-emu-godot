extends Control

signal rom_selected(path: String)

@onready var file_dialog = $FileDialog

var current_rom_path: String = ""

func _ready():
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.ch8 ; CHIP-8 ROM"]
	
	file_dialog.current_dir = "res://roms"
	
	file_dialog.file_selected.connect(_on_file_selected)

func _on_file_selected(path):
	current_rom_path = path
	emit_signal("rom_selected", path)
