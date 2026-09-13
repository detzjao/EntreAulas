extends Node2D

const Rules = preload("res://scripts/game_state.gd")
const PixelWorld = preload("res://scripts/pixel_world.gd")
const World = preload("res://scripts/world_data.gd")
const TITLES := {"home":"REPÚBLICA / CASA 04", "campus":"CAMPUS / BLOCO B", "street":"CIDADE / PRAÇA CENTRAL", "bar":"BAR AURORA"}
const OFFERS := {
	"sleep":["Descansar", "Encerrar o dia? Recupera toda a energia e reduz 15 de calor."],
	"study":["Estudar", "Um período, -15 energia, +1 desempenho acadêmico."],
	"class":["Assistir à aula", "Disponível pela manhã. Um período, -20 energia, +2 desempenho acadêmico."],
	"work":["Trabalho legal", "Um período, -20 energia e +$35."],
	"accept":["Uma entrega", "Nico oferece um pacote para Rafa, no campus. Recompensa: $90. A entrega usa um período e 20 de energia, e aumenta o calor em 25. Aceitar?"],
	"deliver":["Entregar a Rafa", "Entregar o pacote agora? +$90, +25 calor, -20 energia e um período."],
	"business":["Food truck", "Investir $250? Renda diária $40, manutenção $15. Redução única de 10 de calor."],
	"party":["Socializar", "Custa $10 e um período. Recupera 15 energia e reduz 5 de calor."]}
var state = Rules.new()
var area := "home"
var props: Array = []
var player := Vector2(480,405)
var nearest := -1
var patrol_handled := false
var dialog: PanelContainer
var heading: Label
var body: Label
var accept_button: Button
var cancel_button: Button
var pending := ""
var paused := false
var walk_clock := 0.0
var walking := false
var facing := Vector2.DOWN
var autosave_enabled := true
var world_view: SubViewport
var pixel_world: Node2D
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	setup_pixel_world()
	setup_dialog()
	enter_area("home")
	message("Entre Aulas", "Você é um universitário adulto da casa 04. Assista à aula no campus pela manhã; encontre Nico no bar à tarde e entregue o pacote a Rafa.\n\nWASD / setas: mover. E: interagir. J: diário e bolsa semanal. I: mochila. Enter: continuar. F5 / F9: salvar e carregar. F8: restaurar autosave.")

func setup_dialog() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	dialog = PanelContainer.new()
	dialog.position = Vector2(150,100)
	dialog.size = Vector2(660,300)
	layer.add_child(dialog)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202e40")
	style.border_color = Color("eac77d")
	style.set_border_width_all(2)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 22
	style.content_margin_bottom = 20
	dialog.add_theme_stylebox_override("panel",style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",18)
	dialog.add_child(box)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size",24)
	heading.add_theme_color_override("font_color",Color("eac77d"))
	box.add_child(heading)
	body = Label.new()
	body.custom_minimum_size = Vector2(610,105)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size",18)
	box.add_child(body)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation",16)
	box.add_child(buttons)
	accept_button = Button.new()
	accept_button.custom_minimum_size = Vector2(280,42)
	accept_button.focus_mode = Control.FOCUS_NONE
	accept_button.pressed.connect(confirm)
	buttons.add_child(accept_button)
	cancel_button = Button.new()
	cancel_button.text = "Esc • cancelar"
	cancel_button.custom_minimum_size = Vector2(280,42)
	cancel_button.focus_mode = Control.FOCUS_NONE
	cancel_button.pressed.connect(close_dialog)
	buttons.add_child(cancel_button)

func setup_pixel_world() -> void:
	world_view = SubViewport.new()
	world_view.size = Vector2i(480,270)
	world_view.transparent_bg = true
	world_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(world_view)
	pixel_world = PixelWorld.new()
	pixel_world.game = self
	world_view.add_child(pixel_world)
	var screen := Sprite2D.new()
	screen.texture = world_view.get_texture()
	screen.centered = false
	screen.scale = Vector2(2,2)
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.show_behind_parent = true
	add_child(screen)

func autosave() -> String:
	if autosave_enabled and not state.save_game("user://automatico.json"):
		return "\nNão foi possível gravar o autosave. Use F5 para tentar salvar."
	return ""

func message(title: String, text: String, action: String = "") -> void:
	heading.text = title
	body.text = text
	pending = action
	accept_button.text = "Confirmar • Enter" if action != "" else "Continuar • Enter / Espaço"
	cancel_button.visible = action != ""
	dialog.size = Vector2(660,300)
	dialog.show()
	queue_redraw()

func close_dialog() -> void:
	dialog.hide()
	pending = ""
	paused = false
	queue_redraw()

func confirm() -> void:
	var action := pending
	close_dialog()
	if action.begins_with("go:"):
		enter_area(action.trim_prefix("go:"))
	elif action != "":
		var old_day: int = state.data.day
		var result: String = state.act(action)
		if state.data.day != old_day:
			enter_area("home")
			result += "\nVocê voltou à república para começar o dia."
		result += autosave()
		message("Seu dia",result)

func enter_area(target: String) -> void:
	if not TITLES.has(target):
		return
	area = target
	props = World.get_area(area)
	player = Vector2(480,405)
	nearest = -1
	patrol_handled = false
	queue_redraw()

func free_at(pos: Vector2) -> bool:
	if not Rect2(28,127,904,324).has_point(pos):
		return false
	var feet := Rect2(pos-Vector2(11,7),Vector2(22,14))
	for prop in props:
		if feet.intersects(prop.rect):
			return false
	return true

func move_player(direction: Vector2, delta: float) -> void:
	walking = direction.length_squared() > 0
	if walking:
		facing = direction.normalized()
		walk_clock += delta
	var movement := direction.limit_length() * 170.0 * minf(delta,0.05)
	var steps := maxi(1,ceili(movement.length()/3.0))
	for i in steps:
		var part := movement/steps
		if free_at(player+Vector2(part.x,0)):
			player.x += part.x
		if free_at(player+Vector2(0,part.y)):
			player.y += part.y

func _physics_process(delta: float) -> void:
	if dialog.visible:
		walking = false
		pixel_world.queue_redraw()
		return
	var direction := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	move_player(direction,delta)
	nearest = -1
	var best := 50.0
	for i in props.size():
		var rect: Rect2 = props[i].rect
		var point := player.clamp(rect.position,rect.end)
		var distance := player.distance_to(point)
		if distance < best:
			best = distance
			nearest = i
	if area == "street" and state.data.heat >= 40 and not patrol_handled and player.distance_to(Vector2(480,290)) < 60.0:
		patrol_handled = true
		var result: String = state.act("police")
		message("Abordagem",result + autosave())
	pixel_world.queue_redraw()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if dialog.visible:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			get_viewport().set_input_as_handled()
			confirm()
		elif event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close_dialog()
		return
	match event.keycode:
		KEY_J:
			message("Diário acadêmico",state.journal())
		KEY_I:
			message("Mochila", "Lanches: %d/5 • recuperam 25 energia.\nPacote: %s\nAmizade com Lia: %d/10\n\nConsumir um lanche agora?" % [state.data.snacks, "destino Rafa" if state.data.quest else "nenhum", state.data.friendship], "eat")
		KEY_F8:
			if state.load_game("user://automatico.json"):
				enter_area("home")
				message("Autosave", "Progresso automático restaurado.")
			else:
				message("Autosave", "Não há autosave válido. Seu progresso foi preservado.")
		KEY_ESCAPE:
			paused = true
			message("Pausado","Pressione Enter ou Esc para voltar ao jogo.")
		KEY_F5:
			message("Progresso","Jogo salvo." if state.save_game() else "Não foi possível salvar.")
		KEY_F9:
			if state.load_game():
				enter_area("home")
				message("Progresso","Jogo carregado. Você está na república.")
			else:
				message("Progresso","Save ausente ou inválido. O estado atual foi preservado.")
		KEY_E:
			if nearest >= 0:
				interact(props[nearest].action)

func interact(action: String) -> void:
	if action == "go:street" and state.data.heat >= 40:
		message("Fiscalização na praça","Há uma patrulha no círculo vermelho. Entrar nele causa uma abordagem e pode levar à perda do pacote e multa. Entrar na cidade?",action)
	elif action.begins_with("go:"):
		enter_area(action.trim_prefix("go:"))
	elif action == "lia":
		message("Lia", "Conversar e fortalecer a amizade? Uma vez por dia, sem gastar período. Com 3 pontos, ela indica um trabalho de $45 por turno.","chat")
	elif action == "buy_snack":
		message("Cantina", "Comprar um lanche por $15? Cabe até 5 na mochila. Use I para consumir.", "buy_snack")
	elif action == "work":
		message("Trabalho legal", "Um período e 20 energia. Pagamento: $%d." % (45 if state.data.friendship >= 3 else 35), "work")
	elif OFFERS.has(action):
		message(OFFERS[action][0],OFFERS[action][1],action)

func text(at: Vector2, value: String, size: int = 18, color: Color = Color("e6e9ed")) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _draw() -> void:
	draw_rect(Rect2(0,0,960,116),Color("111c28"))
	draw_rect(Rect2(0,462,960,78),Color("111c28"))
	for p in props:
		text(p.rect.position + Vector2(0,-12),p.title,14,Color("f0dfba"))
	text(Vector2(25,29),"ENTRE AULAS",23,Color("eac77d"))
	text(Vector2(25,57),TITLES.get(area,""),16)
	text(Vector2(660,30),"DIA %d  /  %s" % [state.data.day,["MANHÃ","TARDE","NOITE"][state.data.period]],20)
	text(Vector2(25,91),"$ %d     ENERGIA %d     CALOR %d / 100     ACADÊMICO %d" % [state.data.cash,state.data.energy,state.data.heat,state.data.grade],18)
	text(Vector2(25,487),state.objective(),15,Color("eac77d"))
	text(Vector2(25,522),"WASD / setas • E ação • J diário • I mochila • F5 salva • F9 carrega • F8 auto",16)
	if nearest >= 0 and not dialog.visible:
		text(Vector2(650,487),"E  •  " + props[nearest].title,14)
	if is_instance_valid(dialog) and dialog.visible:
		draw_rect(Rect2(0,0,960,540),Color(0,0,0,0.55))
