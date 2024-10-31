@tool
class_name WFCPlugin extends EditorPlugin
################################################################################
## Constants

################################################################################
## Global Pluging Scope

static func Log(p_msg : String) -> void:
	const LogHeader : String = "WFCPlugin"
	const MsgFormat : String = "[%s]: %s"
	var msg : String = MsgFormat % [LogHeader,p_msg]
	print_rich("[b][color=yellow]%s[/color][/b]" % msg)

################################################################################
## Plugin Setup/Cleanup

func _enter_tree():
	Log("Enabled")

func _exit_tree():
	Log("Disabled")

################################################################################
## Utility Methods
