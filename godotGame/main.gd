extends Control

signal nextDialog()

var beginnScene0 = preload("res://assets/scene0/speaker/0_BEGINN.mp3")
var storyFound = preload("res://assets/scene0/speaker/0_GESCHICHTE_FOUND.mp3")
var storyNotFound = preload("res://assets/scene0/speaker/0_GESCHICHTE_NOT_FOUND.mp3")
var startPic = preload("res://assets/scene0/pic/start.png")
var selectStorySFX = preload("res://assets/scene0/sfx/selectStory.mp3")
var startBGM = preload("res://assets/scene0/bgm/startScreenBGM.mp3")

onready var background: TextureRect = $background
onready var bgm: AudioStreamPlayer = $BGM
onready var sfx: AudioStreamPlayer = $SFX
onready var speaker: AudioStreamPlayer = $Speaker
onready var timer = $start


enum os {
	windows,
	linux
};

var underlyingOS: int = -1
var knownStories: Dictionary = {}
var storyDict: Dictionary = {}
var dialogIndex: String = "0"
var storyPath: String = ""

#var sound = load("user://storyCollection/feuerwehr/assets/scene1/1_END.mp3")
#var sound = preload("res://assets/feuerwehr/scene1/1_END.mp3")


func _ready():
	initUsrFolder()
	
	# warning-ignore:return_value_discarded
	timer.connect("timeout", self, "waitForStorySelection")
	# warning-ignore:return_value_discarded
	self.connect("nextDialog", self, "runDialog")
	
	background.texture = startPic
	
	bgm.stream = startBGM
	bgm.play()
	
	_waitForStorySelection()


#func _process(_delta):
#	if storyDict.empty():
#		waitForStorySelection()
#	yield(runDialog(), "completed")


func initUsrFolder():
	if OS.has_feature("Windows"):
		underlyingOS = os.windows
	elif OS.has_feature("X11"):
		underlyingOS = os.linux
	
	var dir: Directory = Directory.new()
	
	if not dir.dir_exists("user://pythonScript/"):
		# warning-ignore:return_value_discarded
		dir.make_dir("user://pythonScript/")
	
	if not dir.dir_exists("user://storyCollection/"):
		# warning-ignore:return_value_discarded
		dir.make_dir("user://storyCollection/")
	
	if not dir.file_exists("user://storyCollection/database"):
		var file: File = File.new()
		
		var err = file.open("user://storyCollection/database", File.WRITE)
		# var err = file.open_encrypted_with_pass("user://storyCollection/database", File.WRITE, "thisIsASecurePassword")
		
		if err != OK:
			assert(false, "there was a problem creating database file during init: " + err)
		
		file.store_string(to_json({  }))
		file.close()
		
		knownStories = {}
	else:
		var file: File = File.new()
		
		var err = file.open("user://storyCollection/database", File.READ)
		# var err = file.open_encrypted_with_pass("user://storyCollection/database", File.WRITE, "thisIsASecurePassword")
		
		if err != OK:
			assert(false, "there was a problem opening database file during init: " + str(err))
		
		var data = parse_json(file.get_as_text())
		file.close()
		
		if typeof(data) == TYPE_DICTIONARY:
			knownStories = data
		else:
			knownStories = {}
			printerr("Corrupted database data!")
	
	# warning-ignore:return_value_discarded
	dir.copy("res://pythonScript/readHat.py", "user://pythonScript/readHat.py")
	# warning-ignore:return_value_discarded
	dir.copy("res://pythonScript/readItem.py", "user://pythonScript/readItem.py")
	
	# path = ProjectSettings.globalize_path("user://pythonScript/readRfid0.py")


func _waitForStorySelection():
	# print("Hallo ihr lieben. Seit ihr bereit für eine super Geschichte? Dann setz mir doch eine Mütze auf.")
	timer.stop()
	
	speaker.stream = beginnScene0
	speaker.play()
	yield(speaker, "finished")
	timer.start(.2)


func waitForStorySelection():
	timer.stop()
	var output: Array = []
	var ret
	
	if underlyingOS == os.windows:
		ret = OS.execute("powershell.exe", ["-Command", "python", ProjectSettings.globalize_path("user://pythonScript/readHat.py")], true, output)
	elif underlyingOS == os.linux:
		ret = OS.execute("sudo", [ProjectSettings.globalize_path("user://pythonScript/runHat.sh")], true, output)
#		ret = OS.execute("python", [ProjectSettings.globalize_path("user://pythonScript/readHat.py")], true, output)
	
	if ret != 0:
		assert(false, "there was a problem during reading python hat: " + str(ret))
	
	var value: String = output[0]
	
	value = value.strip_edges()
	
#	match underlyingOS:
#		os.windows:
#			value.erase(value.length() - 2, 2)
#		os.linux:
#			value.erase(value.length() - 6, 6)
	
	sfx.stream = selectStorySFX
	sfx.play()
	
	if knownStories.has(value):
		speaker.stream = storyFound
		speaker.play()
		yield(speaker, "finished")
		
		loadStory("user://storyCollection/" + knownStories.get(value) + "/")
		return
	else:
		speaker.stream = storyNotFound
		speaker.play()
		yield(speaker, "finished")
		timer.start(.2)


func loadStory(path: String):
	var file = File.new()
	if file.file_exists(path + "story"):
		storyPath = path
		file.open(path + "story", File.READ)
		
		var data = parse_json(file.get_as_text())
		file.close()
		
		if typeof(data) == TYPE_DICTIONARY:
			storyDict = data
			emit_signal("nextDialog")
			return
		else:
			printerr("Corrupted story data!")
	else:
		printerr("No saved story data dict!")
	
	timer.start(1)


func runDialog():
	if dialogIndex == "-1":
#		dialogIndex = "0"
		storyDict = {}
		get_tree().reload_current_scene()
		return
	
	var dict: Dictionary = storyDict.get(dialogIndex)
	
	if dict.get("typ") == "story":
		yield(tellStory(dict), "completed")
	elif dict.get("typ") == "decision":
		yield(makeDecision(dict), "completed")
	
	emit_signal("nextDialog")


func tellStory(dict: Dictionary):
	yield(get_tree(), "idle_frame")
	
	if not dict.get("next").empty():
		dialogIndex = dict.get("next")
	
	if not dict.get("picture").empty():
		var img = Image.new()
		img.load(storyPath + dict.get("picture"))
		var pic = ImageTexture.new()
		pic.create_from_image(img)
		background.texture = pic
	
	if not dict.get("bgm").empty():
		var bgmSound = AudioStreamMP3.new()
		var file = File.new()
		if file.file_exists(storyPath + dict.get("bgm")):
			file.open(storyPath + dict.get("bgm"), File.READ)
			var buffer = file.get_buffer(file.get_len())
			bgmSound.data = buffer
			file.close()
			bgmSound.loop = true
		bgm.stream = bgmSound
		bgm.play()
	
	if not dict.get("sfx").empty():
		var sfxSound = AudioStreamMP3.new()
		var file = File.new()
		if file.file_exists(storyPath + dict.get("sfx")):
			file.open(storyPath + dict.get("sfx"), File.READ)
			var buffer = file.get_buffer(file.get_len())
			sfxSound.data = buffer
			file.close()
			sfxSound.loop = false
		sfx.stream = sfxSound
		sfx.play()
	
	if not dict.get("speaker").empty():
		var speakerSound = AudioStreamMP3.new()
		var file = File.new()
		if file.file_exists(storyPath + dict.get("speaker")):
			file.open(storyPath + dict.get("speaker"), File.READ)
			var buffer = file.get_buffer(file.get_len())
			speakerSound.data = buffer
			file.close()
			speakerSound.loop = false
		speaker.stream = speakerSound
		speaker.play()
		yield(speaker, "finished")


func makeDecision(dict: Dictionary):
	yield(get_tree(), "idle_frame")
	var choice: Dictionary = dict.get("choice")
	var output: Array = []
	var ret
	
	if underlyingOS == os.windows:
		ret = OS.execute("powershell.exe", ["-Command", "python", ProjectSettings.globalize_path("user://pythonScript/readItem.py")], true, output)
	elif underlyingOS == os.linux:
		ret = OS.execute("sudo", [ProjectSettings.globalize_path("user://pythonScript/runItem.sh")], true, output)
	
	if ret != 0:
		assert(false, "there was a problem during reading python item: " + str(ret))
	
	var value: String = output[0]
	value = value.strip_edges()
	
	if choice.has(value):
		dialogIndex = choice.get(value)
	else:
		dialogIndex = choice.get("else")
