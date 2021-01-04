extends ColorRect

var _server#: WS_LoggingServer

var log_buffer: Dictionary setget set_log_buffer, get_log_buffer


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
	msg_arr.append(msg_data.msg)
	$RichTextLabel.text+= msg_data.msg + "\n"

class ObservableDictionary:
	var _dict: Dictionary
	
	func clear()->void:
		_dict.clear()
	
	func duplicate(deep: bool = false)->Dictionary:
		return _dict.duplicate()
	
	func empty()->bool:
		return _dict.empty()
		
	func erase(key)->bool:
		return _dict.erase(key)
		
	func get(key, default = null)->Object:
		return _dict.get(key, default)
		
	func has(key)->bool:
		return _dict.has(key)
	
	func has_all(keys: Array)->bool:
		return _dict.has_all(keys)
	
	func hash()->int:
		return _dict.hash()
		
	func keys()->Array:
		return _dict.keys()
		
	func size()-> int:
		return _dict.size()
		
	func values()->Array:
		return _dict.values()
