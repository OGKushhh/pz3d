## This is a central system for receiving player input, and ensuring
## only one Node receives it. Set this as a global script.
## Anything that needs input should register a custom
## input(event: InputEvent) method here instead of using the
## built-in _input(event: InputEvent) method!
extends Node
signal on_input(event: InputEvent)

## Holds all subscribed input methods. The last method in this list
## is what is given input events.
var input_stack: Array[Callable]

#region Node Methods
func _init() -> void: process_mode = Node.PROCESS_MODE_ALWAYS
func _input(event: InputEvent) -> void: on_input.emit(event)
#endregion

#region Input Methods
## Register the given input method and immediately put it at the top of the queue.
func push(method: Callable) -> void:
	if method == null:
		printerr("InputRouter / Cannot push null method!")
		return
		
	CogitoGlobals.debug_log(true, "InputRouter", "Pushing new method")
	
	if input_stack.has(method):
		CogitoGlobals.debug_log(true, "InputRouter", "  - Method is already in the stack")
		if input_stack.back() == method:
			CogitoGlobals.debug_log(true, "InputRouter", "  - And method is already the priority. Doing nothing.")
			return
			
		CogitoGlobals.debug_log(true, "InputRouter", "  - Removing method to push to front")
		input_stack.erase(method)

	if !input_stack.is_empty():
		CogitoGlobals.debug_log(true, "InputRouter", "  - Disconnecting existing connection")
		if input_stack.back().is_null() or !input_stack.back().is_valid():
			input_stack.pop_back()
		else:
			on_input.disconnect(input_stack.back())
	
	CogitoGlobals.debug_log(true, "InputRouter", "  - Inserting method to top of stack")
	Input.flush_buffered_events()
	input_stack.push_back(method)
	on_input.connect(method)

## Remove the method at the top of the stack and return it. The next top
## method becomes the one that's in control.
func pop() -> Callable:
	if input_stack.is_empty():
		CogitoGlobals.debug_log(true, "InputRouter", "Nothing to pop!")
		return Callable.create(null, "")
	
	CogitoGlobals.debug_log(true, "InputRouter", "Popping current method")
	var callable = input_stack.pop_back()
	if on_input.is_connected(callable): on_input.disconnect(callable)
	Input.flush_buffered_events()
	
	if !input_stack.is_empty():
		CogitoGlobals.debug_log(true, "InputRouter", "  - Connecting to previous object on stack")
		on_input.connect(input_stack.back())
		
	return callable
	
## Remove the given method, no matter where it is in the queue.
func remove(method: Callable) -> void:
	if input_stack.is_empty(): return
	if input_stack.has(method):
		if on_input.is_connected(method):
			on_input.disconnect(method)
		input_stack.erase(method)

## Get whether the given node owns the input method that's currently
## on the top of the method stack.
func is_input_active(node: Node) -> bool:
	if input_stack.is_empty(): return false
	var id = input_stack.back().get_object_id()
	return id == node.get_instance_id()
#endregion
