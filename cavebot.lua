setDefaultTab("Tools")

local function addBotSwitch(text, initial, callback)
  local panel = setupUI(string.format([[
Panel
  height: 19

  BotSwitch
    id: switch
    anchors.left: parent.left
    anchors.right: parent.right
    text-align: center
    !text: tr('%s')
]], text))
  panel.switch:setOn(initial)
  panel.switch.onClick = function(widget)
    local state = not widget:isOn()
    widget:setOn(state)
    callback(state)
  end
  return panel.switch
end

local function getItemId(entry)
  if not entry then return nil end
  return type(entry) == "table" and entry.id or entry
end

local function getTime()
  if g_clock and g_clock.millis then return g_clock.millis() end
  return os.time() * 1000
end

local function canCastSpell(spell)
  if canCast then return canCast(spell) end
  return true
end

local CAVEBOT_INTERVAL = 200
local TARGETBOT_INTERVAL = 200
local CONTAINER_INTERVAL = 500
local EXETA_INTERVAL = 200
local EQ_INTERVAL = 1000
local MONSTER_TYPE_EXCLUDED = 3

if type(storage.cavebot) ~= "table" then
  storage.cavebot = { enabled = false, waypoints = {}, index = 1 }
end
if type(storage.cavebot.waypoints) ~= "table" then storage.cavebot.waypoints = {} end
if not storage.cavebot.index then storage.cavebot.index = 1 end

CaveBot = CaveBot or {}
function CaveBot.isOn()
  return storage.cavebot.enabled
end

function CaveBot.delay(ms)
  delay(ms)
end

function CaveBot.walkTo(pos, walkDelay, options)
  if not pos then return false end
  return autoWalk(pos, walkDelay or 20, options or {ignoreNonPathable = true, precision = 1})
end

UI.Separator()
UI.Label("Cavebot")

local cavebotCountLabel = UI.Label("")
local function updateCavebotLabel()
  local total = #storage.cavebot.waypoints
  local index = storage.cavebot.index or 1
  if total == 0 then index = 0 end
  cavebotCountLabel:setText(string.format("Waypoints: %d (idx %d)", total, index))
end

local cavebotSwitch = addBotSwitch("Cavebot", storage.cavebot.enabled, function(state)
  storage.cavebot.enabled = state
end)

local function addWaypoint()
  if not g_game.isOnline() then return end
  local player = g_game.getLocalPlayer()
  if not player then return end
  local p = player:getPosition()
  if not p then return end
  table.insert(storage.cavebot.waypoints, {x = p.x, y = p.y, z = p.z})
  updateCavebotLabel()
end

local addWaypointSwitch
addWaypointSwitch = addBotSwitch("Add waypoint", false, function()
  addWaypoint()
  addWaypointSwitch:setOn(false)
end)

local clearWaypointSwitch
clearWaypointSwitch = addBotSwitch("Clear waypoints", false, function()
  storage.cavebot.waypoints = {}
  storage.cavebot.index = 1
  updateCavebotLabel()
  clearWaypointSwitch:setOn(false)
end)

updateCavebotLabel()

macro(CAVEBOT_INTERVAL, function()
  if not CaveBot.isOn() then return end
  if not g_game.isOnline() then return end
  local player = g_game.getLocalPlayer()
  if not player then return end
  local waypoints = storage.cavebot.waypoints
  if not waypoints or #waypoints == 0 then return end
  local index = storage.cavebot.index or 1
  if index > #waypoints then index = 1 end
  local wp = waypoints[index]
  if not wp then
    storage.cavebot.index = 1
    return
  end
  local pos = player:getPosition()
  if pos.x == wp.x and pos.y == wp.y and pos.z == wp.z then
    index = index + 1
    if index > #waypoints then index = 1 end
    storage.cavebot.index = index
    updateCavebotLabel()
    return
  end
  if player:isWalking() then return end
  CaveBot.walkTo({x = wp.x, y = wp.y, z = wp.z}, 20, {ignoreNonPathable = true, precision = 1})
end)

if type(storage.targetBot) ~= "table" then
  storage.targetBot = { enabled = false, range = 6 }
end

TargetBot = TargetBot or {}
function TargetBot.isOn()
  return storage.targetBot.enabled
end

UI.Separator()
UI.Label("Target Bot")
local targetSwitch = addBotSwitch("Target Bot", storage.targetBot.enabled, function(state)
  storage.targetBot.enabled = state
end)
UI.Label("Range:")
UI.TextEdit(tostring(storage.targetBot.range), function(widget, text)
  local value = tonumber(text)
  if value then storage.targetBot.range = value end
end)

macro(TARGETBOT_INTERVAL, function()
  if not storage.targetBot.enabled then return end
  if not g_game.isOnline() then return end
  if g_game.isAttacking() then return end
  local player = g_game.getLocalPlayer()
  if not player then return end
  local range = tonumber(storage.targetBot.range) or 6
  local pos = player:getPosition()
  local closest, closestDist
  for _, spec in ipairs(getSpectators()) do
    if spec:isMonster() and spec:getType() ~= MONSTER_TYPE_EXCLUDED then
      local sPos = spec:getPosition()
      if sPos then
        local dist = getDistanceBetween(pos, sPos)
        if dist <= range and (not closestDist or dist < closestDist) then
          closest = spec
          closestDist = dist
        end
      end
    end
  end
  if closest then g_game.attack(closest) end
end)

if type(storage.containerManager) ~= "table" then
  storage.containerManager = { enabled = false, containers = {} }
end
if type(storage.containerManager.containers) ~= "table" then storage.containerManager.containers = {} end

UI.Separator()
UI.Label("Container Manager")
local containerSwitch = addBotSwitch("Container Manager", storage.containerManager.enabled, function(state)
  storage.containerManager.enabled = state
end)
UI.Label("Backpacks:")
local containerWidget = UI.Container(function(widget, items) storage.containerManager.containers = items end, true)
containerWidget:setHeight(35)
containerWidget:setItems(storage.containerManager.containers)

local function isContainerOpen(itemId)
  for _, container in pairs(g_game.getContainers()) do
    local containerItem = container.getContainerItem and container:getContainerItem() or nil
    if containerItem and containerItem:getId() == itemId then return true end
  end
  return false
end

macro(CONTAINER_INTERVAL, function()
  if not storage.containerManager.enabled then return end
  if not g_game.isOnline() then return end
  local items = storage.containerManager.containers
  if not items or #items == 0 then return end
  for _, entry in ipairs(items) do
    local itemId = getItemId(entry)
    if itemId and not isContainerOpen(itemId) then
      local item = findItem(itemId)
      if item then
        g_game.open(item)
        return
      end
    end
  end
end)

if type(storage.exetaLowHp) ~= "table" then
  storage.exetaLowHp = { enabled = false, spell = "exeta res", hp = 50, cooldown = 2000 }
end

UI.Separator()
UI.Label("Exeta Low HP")
local exetaLowSwitch = addBotSwitch("Exeta Low HP", storage.exetaLowHp.enabled, function(state)
  storage.exetaLowHp.enabled = state
end)
UI.Label("Spell:")
UI.TextEdit(storage.exetaLowHp.spell, function(widget, text) storage.exetaLowHp.spell = text end)
UI.Label("HP%:")
UI.TextEdit(tostring(storage.exetaLowHp.hp), function(widget, text)
  local value = tonumber(text)
  if value then storage.exetaLowHp.hp = value end
end)

local lastExetaLow = 0
macro(EXETA_INTERVAL, function()
  if not storage.exetaLowHp.enabled then return end
  if not g_game.isOnline() then return end
  local spell = storage.exetaLowHp.spell
  if not spell or spell == "" then return end
  local threshold = tonumber(storage.exetaLowHp.hp) or 0
  if hppercent() > threshold then return end
  local nowTime = getTime()
  local cooldown = tonumber(storage.exetaLowHp.cooldown) or 2000
  if nowTime - lastExetaLow < cooldown then return end
  if not canCastSpell(spell) then return end
  say(spell)
  lastExetaLow = nowTime
end)

if type(storage.exetaPlayer) ~= "table" then
  storage.exetaPlayer = { enabled = false, spell = "exeta res", range = 3, cooldown = 2000 }
end

UI.Separator()
UI.Label("Exeta Player")
local exetaPlayerSwitch = addBotSwitch("Exeta Player", storage.exetaPlayer.enabled, function(state)
  storage.exetaPlayer.enabled = state
end)
UI.Label("Spell:")
UI.TextEdit(storage.exetaPlayer.spell, function(widget, text) storage.exetaPlayer.spell = text end)
UI.Label("Range:")
UI.TextEdit(tostring(storage.exetaPlayer.range), function(widget, text)
  local value = tonumber(text)
  if value then storage.exetaPlayer.range = value end
end)

local lastExetaPlayer = 0
macro(EXETA_INTERVAL, function()
  if not storage.exetaPlayer.enabled then return end
  if not g_game.isOnline() then return end
  local spell = storage.exetaPlayer.spell
  if not spell or spell == "" then return end
  local player = g_game.getLocalPlayer()
  if not player then return end
  local range = tonumber(storage.exetaPlayer.range) or 3
  local pos = player:getPosition()
  local hasEnemy = false
  for _, spec in ipairs(getSpectators()) do
    if spec:isPlayer() and not spec:isLocalPlayer() and not isFriend(spec:getName()) then
      local sPos = spec:getPosition()
      if sPos and getDistanceBetween(pos, sPos) <= range then
        hasEnemy = true
        break
      end
    end
  end
  if not hasEnemy then return end
  local nowTime = getTime()
  local cooldown = tonumber(storage.exetaPlayer.cooldown) or 2000
  if nowTime - lastExetaPlayer < cooldown then return end
  if not canCastSpell(spell) then return end
  say(spell)
  lastExetaPlayer = nowTime
end)

if type(storage.eqManager) ~= "table" then
  storage.eqManager = { enabled = false, slots = {} }
end
if type(storage.eqManager.slots) ~= "table" then storage.eqManager.slots = {} end
local eqSlots = storage.eqManager.slots
for _, name in ipairs({"head", "neck", "body", "legs", "feet", "ring", "ammo", "left", "right"}) do
  if type(eqSlots[name]) ~= "table" then eqSlots[name] = {} end
end

UI.Separator()
UI.Label("EQ Manager")
local eqSwitch = addBotSwitch("EQ Manager", storage.eqManager.enabled, function(state)
  storage.eqManager.enabled = state
end)

UI.Label("Head")
local headContainer = UI.Container(function(widget, items) eqSlots.head = items end, true)
headContainer:setHeight(35)
headContainer:setItems(eqSlots.head)

UI.Label("Neck")
local neckContainer = UI.Container(function(widget, items) eqSlots.neck = items end, true)
neckContainer:setHeight(35)
neckContainer:setItems(eqSlots.neck)

UI.Label("Body")
local bodyContainer = UI.Container(function(widget, items) eqSlots.body = items end, true)
bodyContainer:setHeight(35)
bodyContainer:setItems(eqSlots.body)

UI.Label("Legs")
local legsContainer = UI.Container(function(widget, items) eqSlots.legs = items end, true)
legsContainer:setHeight(35)
legsContainer:setItems(eqSlots.legs)

UI.Label("Feet")
local feetContainer = UI.Container(function(widget, items) eqSlots.feet = items end, true)
feetContainer:setHeight(35)
feetContainer:setItems(eqSlots.feet)

UI.Label("Ring")
local ringContainer = UI.Container(function(widget, items) eqSlots.ring = items end, true)
ringContainer:setHeight(35)
ringContainer:setItems(eqSlots.ring)

UI.Label("Ammo")
local ammoContainer = UI.Container(function(widget, items) eqSlots.ammo = items end, true)
ammoContainer:setHeight(35)
ammoContainer:setItems(eqSlots.ammo)

UI.Label("Left")
local leftContainer = UI.Container(function(widget, items) eqSlots.left = items end, true)
leftContainer:setHeight(35)
leftContainer:setItems(eqSlots.left)

UI.Label("Right")
local rightContainer = UI.Container(function(widget, items) eqSlots.right = items end, true)
rightContainer:setHeight(35)
rightContainer:setItems(eqSlots.right)

local slotGetters = {
  head = getHead,
  neck = getNeck,
  body = getBody,
  legs = getLeg,
  feet = getFeet,
  ring = getFinger,
  ammo = getAmmo,
  left = getLeft,
  right = getRight
}

local slotOrder = {"head", "neck", "body", "legs", "feet", "ring", "ammo", "left", "right"}

local function isItemEquipped(slot, itemId)
  local getter = slotGetters[slot]
  if not getter then return false end
  local item = getter()
  if not item then return false end
  local currentId = item:getId()
  if currentId == itemId then return true end
  if getActiveItemId and getActiveItemId(itemId) == currentId then return true end
  if getInactiveItemId and getInactiveItemId(itemId) == currentId then return true end
  return false
end

local function equipItem(itemId)
  local item = findItem(itemId)
  if item then
    g_game.use(item)
    return true
  end
  return false
end

macro(EQ_INTERVAL, function()
  if not storage.eqManager.enabled then return end
  if not g_game.isOnline() then return end
  for _, slot in ipairs(slotOrder) do
    local entry = storage.eqManager.slots[slot] and storage.eqManager.slots[slot][1]
    local itemId = getItemId(entry)
    if itemId and not isItemEquipped(slot, itemId) then
      if equipItem(itemId) then return end
    end
  end
end)
