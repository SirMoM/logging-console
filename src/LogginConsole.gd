extends ColorRect

var _server: WS_LoggingServer

var log_buffer: Dictionary setget set_log_buffer, get_log_buffer
var db: DB = DB.new()

func set_log_buffer(_new_log_buffer: Dictionary):
	pass

func get_log_buffer():
	pass


func _ready() -> void:
	log_buffer = {
		0: [], # verbose
		1: [], # debug
		2: [], # info	
		3: [], # warn
		4: [], # error
	}
	
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
	
	var key: int = msg_data.level
	var msg_arr: Array = log_buffer.get(key)
	
	db.add(LogMsg.from_json(msg_data))
	

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
	
	func add(_log: LogMsg):
		_db[_log.u_id] = _log
		emit_signal("append", _log.u_id)
	
	func get_by_index(index):
		return _db[index]
	
	
	
	
