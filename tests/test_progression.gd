extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
	print("PASS: " if ok else "FAIL: ",label)
	if not ok:
		failures += 1
func _initialize() -> void:
	call_deferred("run_tests")
func run_tests() -> void:
	var r = load("res://scripts/game_state.gd").new()
	r.act("eat")
	check(r.data.snacks == 1,"Não desperdiça lanche com energia cheia")
	r.act("work")
	r.act("eat")
	check(r.data.energy == 100 and r.data.snacks == 0 and r.data.period == 1,"Lanche recupera energia sem período")
	r.data.cash = 10
	r.act("buy_snack")
	check(r.data.cash == 10 and r.data.snacks == 0,"Compra bloqueada sem saldo")
	r.data.cash = 100
	r.data.snacks = 5
	r.act("buy_snack")
	check(r.data.cash == 100,"Capacidade não cobra compra recusada")
	for i in 3:
		r.act("chat")
		r.act("chat")
		r.next_day()
	check(r.data.friendship == 3,"Amizade cresce uma vez por dia")
	r.act("work")
	check(r.data.cash == 145,"Amizade libera trabalho de $45")
	r.data = r.defaults()
	for i in 7:
		r.act("class")
		r.act("sleep")
	check(r.data.day == 8 and r.data.exam_grade == 10 and r.data.cash == 180,"Semana completa avaliada com bolsa")
	check(r.data.grade == 0 and r.data.attendance == 0 and r.data.exams == 1,"Semana seguinte reinicia preparo e frequência")
	r.data = r.defaults()
	for i in 7:
		r.act("sleep")
	check(r.data.cash == 80 and r.data.exam_grade == 0 and r.data.scholarships == 0,"Sem frequência não recebe bolsa")
	var old: Dictionary = r.defaults()
	old.version = 1
	for key in ["snacks","friendship","last_chat","attendance","exam_grade","exams","scholarships"]:
		old.erase(key)
	var path := "user://migracao_teste.json"
	var f := FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()
	check(r.load_game(path) and r.data.version == 2 and r.data.snacks == 1,"Save v1 completo migra para v2")
	var before: Dictionary = r.data.duplicate()
	var corrupt: Dictionary = r.data.duplicate()
	corrupt.snacks = 99
	f = FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify(corrupt))
	f.close()
	check(not r.load_game(path) and r.data == before,"Save v2 fora dos limites rejeitado")
	DirAccess.remove_absolute(path)
	root.size = Vector2i(960,540)
	var g = load("res://scenes/main.tscn").instantiate()
	g.autosave_enabled = false
	root.add_child(g)
	await process_frame
	check(g.world_view.size == Vector2i(480,270),"Cenário usa superfície pixel 480x270")
	g.close_dialog()
	for key in [KEY_J,KEY_I]:
		var e := InputEventKey.new()
		e.keycode = key
		e.pressed = true
		Input.parse_input_event(e)
		await process_frame
		check(g.dialog.visible,"Abre painel pela tecla " + str(key))
		await process_frame
		check(g.dialog.get_global_rect().end.y <= 540,"Painel cabe na altura da janela")
		g.close_dialog()
	g.queue_free()
	await process_frame
	print("RESULTADO: ",failures," falhas")
	quit(1 if failures else 0)
