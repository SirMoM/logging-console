extends Node
class_name WS_LoggingServer

signal log_received(log_msg)

const PORT: int = 6624

var wss: WebSocketServer

func _ready() -> void:
	wss = WebSocketServer.new()

	wss.connect("client_connected", self, "_on_client_connect")
	wss.connect("data_received", self, "_on_data_received")

	print("Started: %s" % start())

func _process(_delta: float) -> void:
	wss.poll()

func start()->bool:
	var is_listening = wss.listen(PORT)
	print("Server is listening on %s with protocols" % PORT)
	return is_listening

func _on_client_connect(id: int, protocol: String):
	print("Client %s connected with protocol %s" % [id, protocol])

func _on_data_received(id: int)-> void:
	print("Data recived from %s" % id)
	var peer: WebSocketPeer = wss.get_peer(id)
	var packet = peer.get_packet()
	var packet_content:String = packet.get_string_from_utf8()
	print("From %s data: %s" % [id, packet_content])
	emit_signal("log_received", packet_content)


func stop():
	wss.stop()
