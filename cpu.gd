extends Node

# Signal emitted when the display needs updating
signal display_updated

# Font set representing the hexadecimal digits 0-9 and A-F as 4x5 sprites
const FONT_SET = [
	0xF0, 0x90, 0x90, 0x90, 0xF0, # 0
	0x20, 0x60, 0x20, 0x20, 0x70, # 1
	0xF0, 0x10, 0xF0, 0x80, 0xF0, # 2
	0xF0, 0x10, 0xF0, 0x10, 0xF0, # 3
	0x90, 0x90, 0xF0, 0x10, 0x10, # 4
	0xF0, 0x80, 0xF0, 0x10, 0xF0, # 5
	0xF0, 0x80, 0xF0, 0x90, 0xF0, # 6
	0xF0, 0x10, 0x20, 0x40, 0x40, # 7
	0xF0, 0x90, 0xF0, 0x90, 0xF0, # 8
	0xF0, 0x90, 0xF0, 0x10, 0xF0, # 9
	0xF0, 0x90, 0xF0, 0x90, 0x90, # A
	0xE0, 0x90, 0xE0, 0x90, 0xE0, # B
	0xF0, 0x80, 0x80, 0x80, 0xF0, # C
	0xE0, 0x90, 0x90, 0x90, 0xE0, # D
	0xF0, 0x80, 0xF0, 0x80, 0xF0, # E
	0xF0, 0x80, 0xF0, 0x80, 0x80  # F
]
"""
func load_fontset():
	for i in range(FONT_SET.size()):
		memory[0x50 + i] = FONT_SET[i]  # Load font set starting at 0x50
"""
# Memory (4KB)
var memory: Array = []

# CPU registers (V0-VF)
var V: Array = []

# Index register (I)
var I: int = 0

# Program counter (PC), starts at 0x200 where programs are loaded
var pc: int = 0x200

# Stack (used for CALL and RET instructions)
var stack: Array = []
var sp: int = 0  # Stack pointer

# Timers (delay and sound timers, which decrement at 60Hz)
var delay_timer: int = 0
var sound_timer: int = 0

# Display (64x32 pixels, each pixel is either on or off)
var display: Array = []

# Key state (16 keys)
var keys: Array = []

# Random number generator
var rng = RandomNumberGenerator.new()


func _init():
	"""
	Initializes the CHIP-8 CPU:
	- Resets memory, registers, and stack
	- Clears the display and input keys
	- Loads the font set into memory
	"""
	memory.resize(4096)
	memory.fill(0)
	V.resize(16)
	V.fill(0)
	stack.resize(16)
	stack.fill(0)
	# load_fontset()

	# Initialize display (32 rows of 64 pixels)
	display.resize(32)
	for i in range(32):
		display[i] = []
		display[i].resize(64)
		display[i].fill(false)

	keys.resize(16)
	keys.fill(false)

	# Load font set into memory at 0x50 (80 bytes)
	#for i in range(FONT_SET.size()):
	#	memory[0x50 + i] = FONT_SET[i]

	rng.randomize()

func load_rom(rom_path: String) -> bool:
	"""
	Loads a CHIP-8 ROM into memory starting at address 0x200.
	:param rom_path: The file path of the ROM.
	:return: True if ROM is loaded successfully, False otherwise.
	"""
	var file = FileAccess.open(rom_path, FileAccess.READ)
	if not file:
		return false

	var pos = 0x200  # Start loading program at address 0x200
	while not file.eof_reached():
		memory[pos] = file.get_8()
		pos += 1

	return true

func reset():
	memory.fill(0)
	V.fill(0)
	stack.fill(0)
	delay_timer = 0
	sound_timer = 0
	pc = 0x200  # Start of ROM
	keys.fill(false)

	# Reload font set
	# load_fontset()
	
	# Clear display
	emit_signal("display_updated")

func execute_cycle():
	"""
	Executes a single CPU cycle:
	- Fetches the current opcode
	- Decodes and executes the instruction
	- Updates the program counter (PC)
	- Updates the display if needed
	"""
	var should_update = false

	# Fetch opcode (two bytes)
	var opcode = (memory[pc] << 8) | memory[pc + 1]
	pc += 2  # Move to next instruction

	print("Opcode: 0x%04X | PC: 0x%03X" % [opcode, pc])

	# Decode opcode
	var x = (opcode & 0x0F00) >> 8
	var y = (opcode & 0x00F0) >> 4
	var n = opcode & 0x000F
	var nn = opcode & 0x00FF
	var nnn = opcode & 0x0FFF

	match opcode & 0xF000:
		0x0000:
			match opcode & 0x00FF:
				0x00E0:  # CLS (Clear the screen)
					for row in display:
						row.fill(false)
					emit_signal("display_updated")
				0x00EE:  # RET (Return from subroutine)
					pc = stack[sp - 1]
					sp -= 1

		0x1000:  # JP addr (Jump to address)
			pc = nnn

		0x2000:  # CALL addr (Call subroutine)
			stack[sp] = pc
			sp += 1
			pc = nnn

		0x3000:  # SE Vx, byte (Skip next instruction if Vx == nn)
			if V[x] == nn:
				pc += 2


		0x4000:  # SNE Vx, byte
			if V[x] != nn:
				pc += 2
		
		0x5000:  # SE Vx, Vy
			if V[x] == V[y]:
				pc += 2
		
		0x6000:  # LD Vx, byte
			V[x] = nn
		
		0x7000:  # ADD Vx, byte
			V[x] = (V[x] + nn) & 0xFF
		
		0x8000:
			match n:
				0x0:  # LD Vx, Vy
					V[x] = V[y]
				0x1:  # OR Vx, Vy
					V[x] |= V[y]
				0x2:  # AND Vx, Vy
					V[x] &= V[y]
				0x3:  # XOR Vx, Vy
					V[x] ^= V[y]
				0x4:  # ADD Vx, Vy
					var sum = V[x] + V[y]
					V[0xF] = 1 if sum > 0xFF else 0
					V[x] = sum & 0xFF
				0x5:  # SUB Vx, Vy
					V[0xF] = 1 if V[x] >= V[y] else 0
					V[x] = (V[x] - V[y]) & 0xFF
				0x6:  # SHR Vx
					V[0xF] = V[x] & 0x1
					V[x] >>= 1
				0x7:  # SUBN Vx, Vy
					V[0xF] = 1 if V[y] >= V[x] else 0
					V[x] = (V[y] - V[x]) & 0xFF
				0xE:  # SHL Vx
					V[0xF] = (V[x] & 0x80) >> 7
					V[x] = (V[x] << 1) & 0xFF
		
		0x9000:  # SNE Vx, Vy
			if V[x] != V[y]:
				pc += 2
		
		0xA000:  # LD I, addr
			I = nnn
		
		0xB000:  # JP V0, addr
			pc = nnn + V[0]
		
		0xC000:  # RND Vx, byte
			V[x] = rng.randi() & nn
		
		0xD000:  # DRW Vx, Vy, n (Draw sprite)
			V[0xF] = 0  # Reset collision flag
			for yline in range(n):
				var pixel = memory[I + yline]
				for xline in range(8):
					if (pixel & (0x80 >> xline)) != 0:
						var xcoord = (V[x] + xline) % 64
						var ycoord = (V[y] + yline) % 32
						if display[ycoord][xcoord]:
							V[0xF] = 1  # Collision detected
						display[ycoord][xcoord] = !display[ycoord][xcoord]
			emit_signal("display_updated")
		
		0xE000:
			match nn:
				0x9E:  # SKP Vx
					if keys[V[x]]:
						pc += 2
				0xA1:  # SKNP Vx
					if not keys[V[x]]:
						pc += 2
		
		0xF000:
			match nn:
				0x07:  # LD Vx, DT
					V[x] = delay_timer
				0x0A:  # LD Vx, K
					var key_pressed = false
					for i in range(16):
						if keys[i]:
							V[x] = i
							key_pressed = true
							break
					if not key_pressed:
						pc -= 2
				0x15:  # LD DT, Vx
					delay_timer = V[x]
				0x18:  # LD ST, Vx
					sound_timer = V[x]
				0x1E:  # ADD I, Vx
					I = (I + V[x]) & 0xFFF
				0x29:  # LD F, Vx
					I = 0x50 + (V[x] * 5)
				0x33:  # LD B, Vx
					memory[I] = V[x] / 100
					memory[I + 1] = (V[x] / 10) % 10
					memory[I + 2] = V[x] % 10
				0x55:  # LD [I], Vx
					for i in range(x + 1):
						memory[I + i] = V[i]
				0x65:  # LD Vx, [I]
					for i in range(x + 1):
						V[i] = memory[I + i]
						
	if should_update:
		emit_signal("display_updated")

func update_timers():
	if delay_timer > 0:
		delay_timer -= 1
	if sound_timer > 0:
		sound_timer -= 1
