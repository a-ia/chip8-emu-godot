extends Control

signal rom_selected(path: String)

@onready var file_dialog = $FileDialog

var current_rom_path: String = ""

func _ready():
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.ch8, *.8o, *.txt ; CHIP-8 ROM"]
	
	file_dialog.current_dir = "res://roms"
	
	file_dialog.file_selected.connect(_on_file_selected)

func _on_file_selected(path):
	current_rom_path = path
	emit_signal("rom_selected", path)
	
func show_dialog():
	file_dialog.show()
	super.show()
	
	
func hide_dialog():
	file_dialog.hide()
	super.show()
