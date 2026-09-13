# Entre Aulas — v0.3.0 / Pixel art

Projeto editável para **Godot 4.5.1 Standard**, em GDScript. Sem plugins ou .NET. Protagonista adulto e missão de pacote ficcional.

## Abrir

1. Extraia o ZIP inteiro em uma pasta nova.
2. Abra a Godot, clique em Importar e selecione `project.godot`.
3. Escolha Importar e editar. Pressione F5 para jogar.
4. Clique dentro da janela e pressione Enter, Espaço ou o botão Continuar.

Versão utilizada nos testes: https://godotengine.org/download/archive/4.5.1-stable/
Godot é gratuita inclusive para uso comercial: https://godotengine.org/license/

## O que mudou

- **Pixel art original por código:** cenário desenhado em 480×270 e ampliado 2× sem suavização. Personagens com passos de caminhada e vista de costas; camas, mesas, cantina, food truck, fachadas, plantas e pisos distintos.
- Interface em resolução maior para textos legíveis. Escala inteira da janela preserva a nitidez; pode haver bordas em tamanhos intermediários.
- **Diário (J):** objetivo contextual, preparo acadêmico, frequência, avaliação e bolsas.
- **Mochila (I):** pacote e até cinco lanches. Cada lanche recupera até 25 de energia sem gastar período. Não é consumido se a energia estiver cheia.
- **Cantina:** vende lanches por $15 no campus.
- **Amizade com Lia:** conversar uma vez ao dia concede um ponto. Com três pontos, o trabalho legal passa de $35 para $45.
- **Semana acadêmica:** ao encerrar cada sétimo dia, o preparo acumulado vira nota de 0 a 10. Com nota de pelo menos 6 e quatro aulas naquela semana, recebe bolsa de $100. Sem atingir os critérios, não recebe bolsa. Preparo e frequência reiniciam na semana seguinte.
- **Autosave separado** após ações confirmadas e abordagem, sem substituir o save manual. F8 restaura o automático, F9 o manual. Carregar sempre retorna à república. Não há carregamento automático ao abrir.
- Saves completos da v0.2.x são migrados para o novo formato. Novos campos começam nos valores iniciais; não é inventada frequência acadêmica passada.

## Controles

| Entrada | Ação |
|---|---|
| WASD / setas | Andar |
| E | Interagir com destaque |
| Enter / Enter numérico / Espaço | Confirmar diálogo |
| Esc | Cancelar / pausar |
| J | Diário e regras da avaliação |
| I | Mochila e opção de consumir lanche |
| F5 no jogo | Save manual |
| F9 | Carregar save manual |
| F8 | Carregar autosave |
| Mouse | Botões do diálogo |

Cancelar uma oferta não aplica custo. A abordagem policial aplica a consequência antes de mostrar seu resultado.

## Percurso sugerido

Converse com Lia na república → entre no campus pela cidade → assista à aula pela manhã → vá ao Bar Aurora à tarde → aceite o pacote com Nico → entregue a Rafa no campus → volte à república para dormir.

Use J para acompanhar a semana. Repita aulas e estudo para obter a bolsa, mantenha contato com Lia e junte $250 para o food truck. O negócio rende $40 menos $15 de manutenção por dia. Com calor 40+, a cidade avisa sobre a patrulha e mostra a área de abordagem. Uma abordagem por visita.

Ações importantes consomem um período; explorar, conversar, comprar e comer não. Atividade noturna encerra o dia e retorna à república. Descanso recupera energia e reduz 15 de calor.

## Arquitetura

- `scenes/main.tscn`: cena principal.
- `scripts/main.gd`: interação, movimento, painéis e fluxo.
- `scripts/pixel_world.gd`: arte pixelada e animação procedural.
- `scripts/world_data.gd`: geometria e interações das quatro áreas.
- `scripts/game_state.gd`: regras, progressão e saves.
- `tests/`: testes executáveis na engine e resultados.

Os personagens e cenários ainda não são sprites PNG ou tilesets editáveis: são pixel art gerada por comandos de desenho. As áreas compartilham uma cena e dados. A arquitetura permite substituir essa camada por sprites e TileMaps depois.

## Validação

Godot 4.5.1 oficial, Linux, modo headless:

- 24 verificações do jogo base.
- 7 verificações de teclado e clique no viewport.
- 16 verificações de progressão, save legado, superfície pixelada e dimensões dos painéis.
- **Total: 47 verificações aprovadas.**

```
godot --headless --path . --script tests/test_game.gd
godot --headless --path . --script tests/test_input.gd
godot --headless --path . --script tests/test_progression.gd
```

A aparência renderizada em janela e o uso no Windows ainda precisam de validação. As dimensões dos painéis foram verificadas pela engine, mas isso não equivale à inspeção visual. Não há executável Windows ou APK neste ZIP.

## Próximas etapas

1. Validar visual e percurso no Windows; calibrar tamanho dos pixels, movimento e rótulos.
2. Evoluir a arte para sprites e tilesets com mais direções, expressões e animações.
3. Expandir narrativa, tipos de missão e rotinas dos NPCs.
4. Implementar patrulha móvel e segurança do campus com horários.
5. Adicionar áudio original, opções de volume e acessibilidade.
6. Implementar controles de toque e validar em aparelho antes de exportar mobile.

Não implementado nesta versão: áudio, NPCs andando, segurança do campus, combate, missões variadas, joystick, exportações mobile. A bolsa é a consequência acadêmica inicial; não há reprovação, expulsão ou calendário complexo.

## Créditos

Godot Engine — licença MIT: https://godotengine.org/license/
Componentes da engine: https://godotengine.org/license/#thirdparty
Arte procedural original criada para este protótipo, sem assets externos.
