extends SceneTree
var failures := 0

func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)
	else:
		print("PASS: ",description)

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var rules = load("res://scripts/game_state.gd").new()
	rules.act("class")
	check(rules.data.period == 1 and rules.data.grade == 2 and rules.data.energy == 80,"Aula avança manhã e aplica custo")
	var before: Dictionary = rules.data.duplicate()
	rules.act("class")
	check(before == rules.data,"Aula repetida bloqueada")
	rules.act("accept")
	check(rules.data.quest,"Pacote aceito à tarde")
	rules.act("deliver")
	check(not rules.data.quest and rules.data.cash == 170 and rules.data.heat == 25 and rules.data.deliveries == 1,"Entrega paga uma vez e remove pacote")
	before = rules.data.duplicate()
	rules.act("deliver")
	check(before == rules.data,"Sem duplicação de recompensa")
	rules.act("study")
	check(rules.data.day == 2 and rules.data.energy == 100 and rules.data.period == 0,"Atividade noturna inicia próximo dia")
	rules.data.cash = 250
	rules.act("business")
	rules.act("sleep")
	check(rules.data.cash == 25 and rules.data.business,"Negócio cobra investimento e paga renda líquida")
	rules.data.energy = 0
	before = rules.data.duplicate()
	rules.act("work")
	check(before == rules.data,"Energia insuficiente impede transação")
	rules.data.quest = true
	rules.data.heat = 70
	rules.act("police")
	check(not rules.data.quest and rules.data.cash == 0 and rules.data.heat == 50,"Apreensão e multa sem saldo negativo")
	var save := "user://teste_temporario.json"
	check(rules.save_game(save),"Save gravado")
	before = rules.data.duplicate()
	rules.data.cash = 999
	check(rules.load_game(save) and rules.data == before,"Save restaurado")
	var file := FileAccess.open(save,FileAccess.WRITE)
	file.store_string('{"version":1}')
	file.close()
	check(not rules.load_game(save) and rules.data == before,"Save inválido preserva estado")
	DirAccess.remove_absolute(save)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.autosave_enabled = false
	root.add_child(scene)
	await process_frame
	check(scene.dialog.visible,"Cena inicial e diálogo instanciados")
	var pos: Vector2 = scene.player
	scene._physics_process(0.02)
	check(scene.player == pos,"Diálogo bloqueia movimento")
	scene.close_dialog()
	for area in ["home","campus","street","bar"]:
		scene.enter_area(area)
		check(scene.free_at(scene.player),"Spawn livre: " + area)
	scene.enter_area("home")
	scene.move_player(Vector2(1,1),0.02)
	check(is_equal_approx(scene.player.distance_to(Vector2(480,405)),3.4),"Diagonal normalizada")
	check(not scene.free_at(Vector2(80,170)),"Cama bloqueia passagem")
	check(not scene.free_at(Vector2(10,400)),"Limite de mapa bloqueia passagem")
	scene.state.data.period = 2
	scene.enter_area("bar")
	scene.pending = "study"
	scene.confirm()
	check(scene.area == "home" and scene.state.data.day == 2,"Fim do dia retorna à república")
	scene.close_dialog()
	scene.enter_area("street")
	scene.state.data.heat = 80
	scene.state.data.quest = true
	scene.player = Vector2(480,290)
	scene._physics_process(0)
	check(not scene.state.data.quest and scene.state.data.cash == 50,"Zona de patrulha aplica consequência")
	scene.close_dialog()
	scene._physics_process(0)
	check(scene.state.data.cash == 50 and scene.state.data.heat == 60,"Patrulha não repete abordagem na mesma visita")
	scene.queue_free()
	await process_frame
	print("RESULTADO: ",failures," falhas")
	quit(1 if failures else 0)
