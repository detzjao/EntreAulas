extends RefCounted

static func prop(x: float, y: float, w: float, h: float, title: String, action: String, color: String) -> Dictionary:
	return {"rect": Rect2(x,y,w,h), "title": title, "action": action, "color": Color(color)}

static func get_area(area: String) -> Array:
	match area:
		"home":
			return [prop(60,145,120,64,"Cama","sleep","668db5"),prop(325,145,130,50,"Mesa de estudo","study","ab8564"),prop(650,245,30,42,"Lia • colega","lia","72baa6"),prop(770,365,100,48,"Cidade →","go:street","72baa6")]
		"campus":
			return [prop(110,140,200,58,"Prof. Helena","class","668db5"),prop(585,240,30,42,"Rafa • entrega","deliver","72baa6"),prop(85,310,145,56,"Biblioteca","study","ab8564"),prop(700,145,165,58,"Cantina • $15","buy_snack","d0a65c"),prop(770,365,100,48,"Cidade →","go:street","72baa6")]
		"street":
			return [prop(55,145,165,68,"República","go:home","ab8564"),prop(365,145,170,68,"Campus","go:campus","668db5"),prop(710,145,165,68,"Bar Aurora","go:bar","b77ba7"),prop(70,330,150,65,"Food truck","business","72baa6"),prop(725,330,160,65,"Trabalho legal","work","ab8564")]
		"bar":
			return [prop(75,150,330,62,"Balcão • socializar","party","ab8564"),prop(620,265,30,42,"Nico • contato","accept","72baa6"),prop(770,365,100,48,"Cidade →","go:street","72baa6")]
	return []
