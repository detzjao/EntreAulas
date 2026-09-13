extends Node2D
## Arte original desenhada em uma superfície 480x270; ampliada em nearest.
var game: Node2D
const INK := Color("243044")
const WOOD := Color("705040")
const CREAM := Color("e6cd9e")
const HAIR := Color("393044")
const SKIN := Color("dbaa86")

func box(x: float,y: float,w: float,h: float,c: Color) -> void:
	draw_rect(Rect2(floorf(x),floorf(y),w,h),c)

func person(pos: Vector2, shirt: Color, step: int = 0, back: bool = false) -> void:
	var x := floorf(pos.x)
	var y := floorf(pos.y)
	box(x-6,y-1,13,3,Color("343944"))
	box(x-4,y-6,3,6+step,INK)
	box(x+1,y-6,3,6-step,INK)
	box(x-5,y-14,10,9,shirt)
	box(x-7,y-13,2,7,SKIN)
	box(x+5,y-13,2,7,SKIN)
	box(x-4,y-22,8,8,SKIN)
	box(x-5,y-24,10,4,HAIR)
	box(x-5,y-21,2,5,HAIR)
	if back:
		box(x-3,y-20,7,6,HAIR)
	else:
		box(x+1,y-19,1,1,INK)
		box(x+3,y-19,1,1,INK)
	box(x-3,y-12,6,2,shirt.lightened(0.15))

func plant(x: int,y: int) -> void:
	box(x-4,y,8,6,Color("a3674a"))
	box(x-6,y-7,12,8,Color("315c4e"))
	box(x-3,y-10,8,7,Color("518366"))
	box(x,y-8,3,3,Color("83a375"))

func building(r: Rect2, tint: Color) -> void:
	box(r.position.x,r.position.y,r.size.x,r.size.y,tint.darkened(0.25))
	box(r.position.x-2,r.position.y-3,r.size.x+4,11,tint.darkened(0.5))
	box(r.position.x,r.position.y-2,r.size.x,2,tint.lightened(0.18))
	box(r.position.x+8,r.position.y+14,14,10,Color("96bdc0"))
	box(r.position.x+14,r.position.y+14,2,10,INK)
	box(r.end.x-22,r.position.y+14,14,10,Color("96bdc0"))
	box(r.end.x-16,r.position.y+14,2,10,INK)
	box(r.get_center().x-7,r.end.y-15,14,15,INK)
	box(r.get_center().x+3,r.end.y-8,2,2,CREAM)

func _draw() -> void:
	if not is_instance_valid(game):
		return
	var outdoors: bool = game.area in ["street","campus"]
	var ground := Color("608568") if outdoors else Color("967455")
	box(0,0,480,270,Color("111c28"))
	box(11,58,458,173,ground)
	if outdoors:
		for x in range(15,468,13):
			for y in range(66,230,17):
				box(x,y,2,1,Color("789775"))
		box(134,60,197,169,Color("a3a18d"))
		for y in range(65,230,16):
			box(135,y,194,1,Color("929384"))
		for x in range(145,325,24):
			box(x,60,1,168,Color("929384"))
		for x in [20,450]:
			for y in [90,215]:
				plant(x,y)
	else:
		for y in range(65,230,12):
			box(12,y,456,1,Color("795c4a"))
			for x in range(14+(y%2)*20,467,40):
				box(x,y,1,12,Color("856247"))
		box(11,58,458,12,Color("556273"))
		box(11,69,458,3,Color("303e50"))
		box(11,58,3,172,INK)
		box(466,58,3,172,INK)
		for x in [120,280,410]:
			box(x,60,30,10,INK)
			box(x+2,61,12,7,Color("99b7c2"))
			box(x+16,61,12,7,Color("7e9fb5"))
		plant(25,215)
		plant(450,95)
		if game.area == "home":
			box(175,149,120,55,Color("5b7476"))
			box(178,152,114,49,Color("738e87"))
			box(182,156,106,41,Color("627c79"))
		else:
			box(220,144,100,49,Color("6b4967"))
			for x in range(226,320,12):
				box(x,151,6,6,Color("a77685"))
	for i in game.props.size():
		var p: Dictionary = game.props[i]
		var r := Rect2(p.rect.position/2,p.rect.size/2)
		var x := r.position.x
		var y := r.position.y
		var w := r.size.x
		var h := r.size.y
		box(x+2,y+3,w,h,Color("4b4c4e"))
		if r.size.x == 15:
			person(Vector2(x+7,y+h),p.color)
		elif game.area == "street" and p.action.begins_with("go:"):
			building(r,p.color)
		elif p.action == "sleep":
			box(x,y,w,h,WOOD)
			box(x+3,y+3,w-6,h-6,CREAM)
			box(x+3,y+12,w-6,h-15,Color("597f9c"))
			box(x+7,y+5,w-14,6,Color("ece1c1"))
			box(x+3,y+14,w-6,2,Color("87adc0"))
		elif p.action == "business" or p.action == "buy_snack":
			box(x,y,w,h,Color("e2bb70"))
			box(x+3,y+5,w-6,h-12,Color("69998d"))
			box(x+7,y+8,w-14,9,INK)
			for j in range(0,int(w),10):
				box(x+j,y,5,4,Color("b66050"))
			box(x+5,y+h-3,9,5,INK)
			box(x+w-14,y+h-3,9,5,INK)
		elif p.action.begins_with("go:"):
			box(x,y,w,h,Color("4f887c"))
			box(x+3,y+3,w-6,h-6,Color("79aa91"))
			box(x+w/2-8,y+h/2-1,14,3,CREAM)
			box(x+w/2+4,y+h/2-4,3,9,CREAM)
		else:
			box(x,y,w,h,WOOD)
			box(x+2,y+2,w-4,h-6,Color("b28d60"))
			box(x+6,y+4,12,8,CREAM)
			box(x+7,y+6,9,1,Color("8d8d7d"))
			box(x+w-14,y+5,5,6,Color("6c91ac"))
			if p.action == "party":
				for j in range(23,int(w)-15,18):
					box(x+j,y+4,4,9,Color("567966"))
		if i == game.nearest:
			draw_rect(r.grow(2),Color("f6dc92"),false,1)
	if game.area == "street" and game.state.data.heat >= 40 and not game.patrol_handled:
		var center := Vector2(240,145)
		for i in range(0,360,12):
			var pos := center+Vector2.from_angle(deg_to_rad(i))*30
			box(pos.x,pos.y,2,2,Color("e38b79"))
		person(center,Color("6588b6"))
	var step := 0
	if game.walking:
		step = 1 if int(game.walk_clock*9)%2 == 0 else -1
	person(game.player/2,Color("e9be69"),step,game.facing.y < -0.4)
	if game.state.data.period > 0:
		box(11,58,458,173,Color(0.07,0.06,0.24,0.12 if game.state.data.period == 1 else 0.40))
