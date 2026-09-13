extends RefCounted
## Regras do protótipo. Valores abstratos, sem logística real.
var data: Dictionary = defaults()

func defaults() -> Dictionary:
	return {"version": 2, "day": 1, "period": 0, "cash": 80, "energy": 100, "heat": 0, "grade": 0, "quest": false, "deliveries": 0, "business": false, "last_class": 0, "snacks": 1, "friendship": 0, "last_chat": 0, "attendance": 0, "exam_grade": -1, "exams": 0, "scholarships": 0}

func next_day() -> void:
	if data.day % 7 == 0:
		data.exam_grade = mini(10, data.grade)
		data.exams += 1
		if data.exam_grade >= 6 and data.attendance >= 4:
			data.cash += 100
			data.scholarships += 1
		data.grade = 0
		data.attendance = 0
	data.day += 1
	data.period = 0
	data.energy = 100
	data.heat = maxi(0, data.heat - 15)
	if data.business:
		data.cash += 25

func spend_time(energy: int) -> void:
	data.energy -= energy
	data.period += 1
	if data.period > 2:
		next_day()

func act(action: String) -> String:
	var costs := {"class": 20, "study": 15, "work": 20, "deliver": 20}
	if data.energy < costs.get(action, 0):
		return "Sem energia. Volte à república para descansar."
	match action:
		"buy_snack":
			if data.cash < 15:
				return "Você precisa de $15."
			if data.snacks >= 5:
				return "Sua mochila comporta até 5 lanches."
			data.cash -= 15
			data.snacks += 1
			return "Lanche guardado. Use I para abrir a mochila."
		"eat":
			if data.snacks == 0:
				return "Você não tem lanches. Compre na cantina do campus."
			if data.energy == 100:
				return "Sua energia já está cheia. O lanche foi preservado."
			data.snacks -= 1
			data.energy = mini(100, data.energy + 25)
			return "Lanche consumido. Energia +25; nenhum período gasto."
		"chat":
			if data.last_chat == data.day:
				return "Lia: Vamos conversar mais amanhã! Boa sorte hoje."
			data.last_chat = data.day
			data.friendship = mini(10, data.friendship + 1)
			return "Lia gostou da conversa. Amizade +1. Ao chegar a 3, ela indica um trabalho melhor."
		"sleep":
			next_day()
			return "Você descansou. Um novo dia começou!"
		"class":
			if data.period != 0 or data.last_class == data.day:
				return "A aula acontece uma vez por dia, pela manhã."
			data.last_class = data.day
			data.grade += 2
			data.attendance += 1
			spend_time(20)
		"study":
			data.grade += 1
			spend_time(15)
		"work":
			data.cash += 45 if data.friendship >= 3 else 35
			spend_time(20)
		"accept":
			if data.quest:
				return "Você já tem um pacote para Rafa, no campus."
			if data.period == 0:
				return "Nico recebe pedidos à tarde e à noite."
			data.quest = true
			return "Pacote recebido. Encontre Rafa no campus."
		"deliver":
			if not data.quest:
				return "Você não tem um pacote para entregar."
			data.quest = false
			data.deliveries += 1
			data.cash += 90
			data.heat = mini(100, data.heat + 25)
			spend_time(20)
		"business":
			if data.business:
				return "Seu food truck rende $40 por dia, menos $15 de manutenção."
			if data.cash < 250:
				return "Você precisa de $250 para abrir o food truck."
			data.cash -= 250
			data.business = true
			data.heat = maxi(0, data.heat - 10)
			return "Food truck aberto! Renda líquida: $25 por dia."
		"party":
			if data.cash < 10:
				return "Você precisa de $10 para socializar no bar."
			data.cash -= 10
			data.energy = mini(100, data.energy + 15)
			data.heat = maxi(0, data.heat - 5)
			spend_time(0)
		"police":
			data.heat = maxi(0, data.heat - 20)
			if data.quest:
				data.quest = false
				data.cash = maxi(0, data.cash - 30)
				return "Pacote apreendido. A missão falhou. Multa de até $30 aplicada."
			return "Você recebeu uma advertência e foi liberado."
		_:
			return "Ação desconhecida."
	return "Atividade concluída."

func save_game(path: String = "user://progresso.json") -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	return file.get_error() == OK

func load_game(path: String = "user://progresso.json") -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return false
	# Migra somente um save antigo completo; arquivos incompletos continuam inválidos.
	if parsed.get("version") == 1:
		var old_keys := ["day","period","cash","energy","heat","grade","quest","deliveries","business","last_class"]
		for key in old_keys:
			if not parsed.has(key):
				return false
		for key in ["snacks","friendship","last_chat","attendance","exam_grade","exams","scholarships"]:
			parsed[key] = defaults()[key]
		parsed.version = 2
	var schema := defaults()
	for key in schema:
		if not parsed.has(key):
			return false
		if schema[key] is bool:
			if not parsed[key] is bool:
				return false
		else:
			if not (parsed[key] is int or parsed[key] is float):
				return false
			if not is_finite(float(parsed[key])) or float(parsed[key]) != floor(float(parsed[key])):
				return false
			parsed[key] = int(parsed[key])
	var ranges := {"version": Vector2(2,2), "snacks": Vector2(0,5), "friendship": Vector2(0,10), "last_chat": Vector2(0,parsed.day), "attendance": Vector2(0,7), "exam_grade": Vector2(-1,10), "exams": Vector2(0,1000000), "scholarships": Vector2(0,1000000), "day": Vector2(1,1000000), "period": Vector2(0,2), "cash": Vector2(0,1000000000), "energy": Vector2(0,100), "heat": Vector2(0,100), "grade": Vector2(0,1000000), "deliveries": Vector2(0,1000000), "last_class": Vector2(0,parsed.day)}
	for key in ranges:
		if parsed[key] < ranges[key].x or parsed[key] > ranges[key].y:
			return false
	data = parsed
	return true

func objective() -> String:
	if data.quest:
		return "Entregue o pacote a Rafa no campus."
	if data.energy < 20:
		return "Recupere energia: lanche na mochila (I) ou cama."
	if data.period == 0 and data.last_class != data.day:
		return "Aula no campus: preserve sua bolsa semanal."
	if data.deliveries == 0:
		return "Encontre Nico no Bar Aurora à tarde ou à noite."
	if not data.business:
		return "Junte $250 e abra o food truck na cidade."
	return "Prepare a avaliação semanal e cuide da sua rotina."

func journal() -> String:
	return "AGORA: %s\n\nSEMANA %d • DIA %d/7\nAo encerrar o dia 7: nota = estudo acumulado (máx. 10).\nBolsa de $100: nota 6+ e pelo menos 4 aulas na semana.\nAulas: %d/4 • Preparo: %d/6\n\nÚLTIMA AVALIAÇÃO: %s\nEntregas: %d • Bolsas recebidas: %d" % [objective(), int((data.day-1)/7)+1, ((data.day-1)%7)+1, data.attendance, data.grade, "ainda não realizada" if data.exam_grade < 0 else str(data.exam_grade)+"/10", data.deliveries, data.scholarships]
