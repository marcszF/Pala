# Prompt de Implementação — Módulo de Bot OTC (Pala 20k)

## Objetivo deste documento
Este arquivo serve como **prompt base** para futuras implementações neste módulo de bot para OTC (OTClient / OTServer Tibia Client). Use-o como referência para entender o projeto, manter o padrão de código existente e planejar alterações com o menor impacto possível.

## Contexto do projeto
- Projeto em **Lua** voltado para o ambiente de bot do OTC/OTClient.
- Scripts usam **macros** (`macro(intervalo, nome, fn)`), eventos (`onTalk`, `onTextMessage`, `onPlayerPositionChange`, etc.), **UI dinâmica** (`UI.*`, `setupUI`, `g_ui.createWidget`) e **persistência** em `storage`.
- Há arquivos de **áudio de alarme** em `Alarme/` e layouts de UI em `alarms.otui`.

## Mapa de arquivos e responsabilidades
- `_main.lua`:
  - Macro principal com automações: reconexão, conversão de dinheiro, timer de boss/raid, stamina potion, HP% no monstro, follow de ataque, auto sell+bank, trainer de house, ataques por spell/item, dodge de boss, buff/task/auto bless, turbo follow.
- `_vlib.lua`:
  - Biblioteca de utilidades: checagens de container, buff, amigos/inimigos, cooldown/feitiços, contagem de mobs/jogadores, helpers de itens, padrões de áreas para spells.
- `0_AAmain.lua`:
  - Painel/UI com efeito visual (rainbow/glitch) e macro de animação.
- `1_alarms.lua` + `alarms.otui`:
  - Sistema de alarmes com UI própria, toggles e sons (player na tela, HP/Mana baixos, PK, PM, etc.).
- `tools.lua`:
  - Aba de ferramentas (posição, abrir backpack, auto PT, juntar itens) e editor de hotkeys.
- `tools2.lua`:
  - Hotkeys adicionais, follow/auto-follow, sense target, anti-push (drop de itens).
- `spy_level.lua`:
  - Bloqueio/desbloqueio de níveis do mapa via teclas.
- `storage/profile_1.json`:
  - Exemplo de persistência/configuração (binário/compactado pelo client).

## Padrões de código e APIs locais
- **Persistência:** use `storage.<chave>` com valores default protegidos por `if not storage.<chave> then ... end`.
- **Macros:** preferir intervalos leves (ex: 50–1000ms) e early return quando offline.
- **Checks comuns:**
  - `if not g_game.isOnline() then return end`
  - `local player = g_game.getLocalPlayer()`
- **UI:**
  - Separar seções com `UI.Separator()`.
  - Controles: `UI.Label`, `UI.TextEdit`, `UI.Container`, `UI.Button`.
  - `setupUI` para painéis simples, `.otui` para janelas completas.
- **Sons:** `playSound("/bot/<configName>/Alarme/<arquivo>")`. O `<configName>` vem de `modules.game_bot.contentsPanel.config:getCurrentOption().text`.
- **Eventos úteis:** `onTextMessage`, `onTalk`, `onCreaturePositionChange`, `onPlayerPositionChange`, `onCreatureHealthPercentChange`.
- **Cuidado com nil:** sempre validar `tile`, `target`, `player`, `pos()`.

## Checklist para futuras implementações
1. **Defina o objetivo**: qual automação/feature será criada e em qual aba (Tools, etc.).
2. **Escolha o arquivo certo**:
   - Macro geral → `_main.lua`
   - Utilitários reutilizáveis → `_vlib.lua`
   - UI específica → `1_alarms.lua` + `alarms.otui` ou novo `.otui`
   - Tools/Hotkeys → `tools.lua` / `tools2.lua`
3. **Crie config em `storage`** com defaults e UI para edição.
4. **Use macros enxutos** e evite loops pesados.
5. **Garanta compatibilidade** com o ambiente OTC (funções `g_game`, `g_map`, `modules.*`).
6. **Se houver som/UI nova**, adicionar arquivo em `Alarme/` e atualizar caminhos.

## Prompt sugerido para novas tarefas
Use este template quando for pedir implementações futuras:

> **Pedido**: Descreva a nova automação/feature (ex.: “Auto heal quando HP < 60% usando spell X”).
> **Arquivo alvo**: Indique se vai em `_main.lua`, `tools.lua`, etc.
> **Configuração**: Quais parâmetros devem ser editáveis (ex.: %HP, ID do item, nome do alvo).
> **UI**: Precisa de botão, toggle, label, container de item, ou janela `.otui`?
> **Som**: Precisa de alerta sonoro? Qual arquivo?
> **Restrições**: Alguma regra de segurança (não usar em PZ, respeitar stamina, etc.)?

## Observações finais
- Este projeto assume **OTClient/OTC com bot habilitado** (API padrão de macros e UI do OTClientV8).
- Manter alterações **mínimas e localizadas** para evitar efeitos colaterais.
