# Input.gd
extends Node

@onready var cpu = $"../CPU"

# CHIP-8 keypad layout:    Keyboard mapping:
# 1 2 3 C                 1 2 3 4
# 4 5 6 D                 Q W E R
# 7 8 9 E                 A S D F
# A 0 B F                 Z X C V

const KEYMAP = {
	KEY_1: 0x1, KEY_2: 0x2, KEY_3: 0x3, KEY_4: 0xC,
	KEY_Q: 0x4, KEY_W: 0x5, KEY_E: 0x6, KEY_R: 0xD,
	KEY_A: 0x7, KEY_S: 0x8, KEY_D: 0x9, KEY_F: 0xE,
	KEY_Z: 0xA, KEY_X: 0x0, KEY_C: 0xB, KEY_V: 0xF
}

func _input(event):
	if event is InputEventKey:
		var scancode = event.physical_keycode
		if KEYMAP.has(scancode):
			var chip8_key = KEYMAP[scancode]
			cpu.keys[chip8_key] = event.pressed
