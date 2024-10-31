extends Node

var thread : Thread = Thread.new()

func _ready() -> void:
	var error : int = OK
	var result : Variant

	error = thread.start(foo1)
	print(error_string(error))
	result = thread.wait_to_finish()
	print(result)

	thread.start(foo2)
	print(error_string(error))
	result = thread.wait_to_finish()
	print(result)


func foo1() -> void:
	print("foo1")


func foo2() -> void:
	print("foo2")
