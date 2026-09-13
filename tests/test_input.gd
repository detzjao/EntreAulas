extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	print("PASS: " if ok else "FAIL: ", label)
	if not ok:
		failures += 1
func _initialize() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	root.size = Vector2i(960,540)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.autosave_enabled = false
	root.add_child(scene)
	await process_frame
	for key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
		scene.message("Teste","Continuar")
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = true
		Input.parse_input_event(event)
		await process_frame
		check(not scene.dialog.visible,"Fecha diálogo com tecla " + str(key))
		event.pressed = false
		Input.parse_input_event(event)
	var before: int = scene.state.data.cash
	scene.message("Trabalho","Confirmar","work")
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	Input.parse_input_event(enter)
	await process_frame
	check(scene.state.data.cash == before + 35,"Enter confirma uma única transação")
	enter.echo = true
	Input.parse_input_event(enter)
	await process_frame
	check(scene.state.data.cash == before + 35,"Repetição automática não duplica transação")
	enter.pressed = false
	Input.parse_input_event(enter)
	scene.message("Mouse","Continuar")
	await process_frame
	var point: Vector2 = scene.accept_button.get_global_rect().get_center()
	for pressed in [true,false]:
		var mouse := InputEventMouseButton.new()
		mouse.position = point
		mouse.global_position = point
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = pressed
		root.push_input(mouse, true)
		await process_frame
	check(not scene.dialog.visible,"Clique real no botão fecha diálogo")
	scene.queue_free()
	await process_frame
	print("RESULTADO: ",failures," falhas")
	quit(1 if failures else 0)
