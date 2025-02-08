extends AudioStreamPlayer

@onready var cpu = $"../CPU"

func _ready():
	# Create the audio stream
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100  # Hz
	stream.buffer_length = 0.1  # 100ms buffer
	
	# Set the stream
	self.stream = stream
	
	# Set initial volume
	volume_db = -10
	
func _process(_delta):
	if cpu.sound_timer > 0:
		if not playing:
			# Start playing the beep
			play()
			
			# Get the playback after starting playback
			var playback = get_stream_playback()
			if playback:
				var sample_hz = 44100.0  # Same as mix_rate
				var frequency = 440.0  # Frequency of 440Hz = A4 note
				
				# Fill the buffer with a sine wave
				var increment = frequency / sample_hz
				var phase = 0.0
				
				# Write samples to the buffer
				for i in range(int(sample_hz * 0.1)):  # 0.1 seconds of audio
					var sample = sin(phase * TAU)  # TAU is 2*PI
					playback.push_frame(Vector2.ONE * sample * 0.5)  # Stereo audio, 0.5 = volume
					phase = fmod(phase + increment, 1.0)
	else:
		if playing:
			stop()
