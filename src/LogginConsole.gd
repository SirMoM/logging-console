extends ColorRect

var _server: WS_LoggingServer

var db: DB = DB.new()
var querry_mask = 0


func _ready() -> void:
	_server = WS_LoggingServer.new()
	get_tree().get_root().call_deferred("add_child", _server)
	_server.connect("log_received", self, "_on_log_received")
	db.connect("append", self, "_on_db_change")

func _on_db_change(u_id):
	var _log: LogMsg = db.get_by_index(u_id)
	$Messages.add_item(_log.time)
	$Messages.add_item(_log.module)
	$Messages.add_item(_log.msg)

func _on_log_received(log_msg: String):
	var msg_data
	var invalid = validate_json(log_msg)
	if not invalid:
		print("Valid JSON.")
		msg_data = parse_json(log_msg)
	else:
		push_error("Invalid JSON: " + invalid)	
	
	db.add(LogMsg.from_json(msg_data))
	
func repopulate_list(array):
	$Messages.clear()
	for entry in array:
		$Messages.add_item(entry.time)
		$Messages.add_item(entry.module)
		$Messages.add_item(entry.msg)

class LogMsg:
	
	var u_id: UUID
	var time
	var level
	var module
	var msg
	
	func _init() -> void:
		u_id = UUID.new()
	
	func _to_string() -> String:
		return "UUID: %s, msg: %s" %[u_id, msg]
	
	static func from_json(json: Dictionary) -> LogMsg:
		var result = LogMsg.new()
		
		var msg: String = json.msg
		msg = msg.replace("[", "")
		msg = msg.replace("]", "")
		var msg_tokens: Array = msg.split(" ", false, 3)
		
		var format: String = json.format
		format = format.replace("[", "")
		format = format.replace("]", "")
		
		var format_tokens: Array = format.split(" ", false, 3)
		var lvl_id = format_tokens.find(Logger.FORMAT_IDS.level)
		var time_id = format_tokens.find(Logger.FORMAT_IDS.time)
		var modul_id = format_tokens.find(Logger.FORMAT_IDS.module)
		
		result.time = msg_tokens[time_id]
		result.level = msg_tokens[lvl_id]
		result.module = msg_tokens[lvl_id]
		result.msg = msg.replace(result.time, "").replace(result.level, "").replace(result.module, "").strip_edges()
		return result

class DB:
	
	signal append(u_id)
	
	var _db = {}
	var index_verbose = []
	var index_debug = []
	var index_info = []
	var index_warn = []
	var index_error = []
	
	func add(_log: LogMsg):
		_db[_log.u_id] = _log
		match _log.level:
			"VERBOSE":
				index_verbose.append(_log.u_id)
			"DEBUG":
				index_debug.append(_log.u_id)
			"INFO":
				index_info.append(_log.u_id)
			"WARN":
				index_warn.append(_log.u_id)
			"ERROR":
				index_error.append(_log.u_id)
			_:
				push_warning("Level not known: %s" % _log.level)
		
		emit_signal("append", _log.u_id)
	
	func get_by_index(index):
		return _db[index]
	
	func querry(index)->Array:
		# Bit masks fory easy accses!
		var verbose_mask = 1
		var debug_mask = 2
		var info_mask = 3
		var warn_mask = 4
		var error_mask = 5
		
		var result = []
		if index == 0:
			return _db.values()
		
		
		
		if checkbit(index, verbose_mask):
			for index in index_verbose:
				result.append(_db[index])
		if checkbit(index, debug_mask):
			for index in index_debug:
				result.append(_db[index])
		if checkbit(index, info_mask):
			for index in index_info:
				result.append(_db[index])
		if checkbit(index, warn_mask):
			for index in index_warn:
				result.append(_db[index])
		if checkbit(index, error_mask):
			for index in index_error:
				result.append(_db[index])
		return result

	# Bit starts with 1, n is the number
	func checkbit(n, bit):
		return ((n & (1 << (bit - 1))) > 0)

func _on_Verbose_toggled(button_pressed: bool) -> void:
	print("pressed: ", button_pressed)
	if button_pressed:
		querry_mask += 1
	else:
		querry_mask -= 1
	
	print(querry_mask)
	repopulate_list(db.querry(querry_mask))
