-- tools tab
setDefaultTab("Tools")

UI.Separator()
UI.Label("Player")

local posLabel = UI.Label("X: --  Y: --  Z: --")

macro(200, function()
  local p = g_game.getLocalPlayer()
  if not p then return end
  local pos = p:getPosition()
  posLabel:setText("X: "..pos.x.."  Y: "..pos.y.."  Z: "..pos.z)
end)

UI.Separator()

macro(1000, "Abrir Bag Principal", function()
    bpItem = getBack()
    bp = getContainer(0)

    if not bp and bpItem ~= nil then
        g_game.open(bpItem)
    end

end)

UI.Separator()

local pt = false
addSwitch("pt", "Auto PT = falar pt", function(widget)
    pt = not pt
    widget:setOn(pt)
end)

onTalk(function(name, level, mode, text, channelId, pos)
if name == player:getName() then return end
    if mode ~= 1 then  return end
    if string.find(text, "pt")  and pt == true then
        local friend = getPlayerByName(name)
        g_game.partyInvite(friend:getId())
    end
end)

UI.Separator()

macro(1000, "Juntar itens", function()
  local containers = g_game.getContainers()
  local toStack = {}
  for index, container in pairs(containers) do
    if not container.lootContainer then -- ignore monster containers
      for i, item in ipairs(container:getItems()) do
        if item:isStackable() and item:getCount() < 100 then
          local stackWith = toStack[item:getId()]
          if stackWith then
            g_game.move(item, stackWith[1], math.min(stackWith[2], item:getCount()))
            return
          end
          toStack[item:getId()] = {container:getSlotPosition(i - 1), 100 - item:getCount()}
        end
      end
    end
  end
end)

UI.Separator()

-- allows to test/edit bot lua scripts ingame, you can have multiple scripts like this, just change storage.ingame_lua
UI.Button("Hotkeys", function(newText)
  UI.MultilineEditorWindow(storage.ingame_hotkeys or "", {title="Hotkeys editor", description="Adicione suas scripts aqui!\n@Luiz"}, function(text)
    storage.ingame_hotkeys = text
    reload()
  end)
end)


for _, scripts in pairs({storage.ingame_hotkeys}) do
  if type(scripts) == "string" and scripts:len() > 3 then
    local status, result = pcall(function()
      assert(load(scripts, "ingame_editor"))()
    end)
    if not status then 
      error("Hotkeys:\n" .. result)
    end
  end
end

UI.Separator()

playSound("/sounds/click.ogg")
info("Odeio baiano")