-- =====================================
-- 1. AUTO RECONNECT & UTILS
-- =====================================
local autoReconnectMacro = macro(3000, "Auto Reconnect", function()
    if g_game.isOnline() then return end
    local root = g_ui.getRootWidget()
    if root then
        local msgBox = root:recursiveGetChildById('msgBox')
        if msgBox then msgBox:destroy() end
    end
    if EnterGame and EnterGame.doLogin then EnterGame.doLogin()
    elseif EnterGame then EnterGame.show() end
end)
if autoReconnectIcon then autoReconnectIcon:destroy() end
autoReconnectIcon = addIcon("AutoReconnect", {item=3058, text="Reconnect", moveable=true}, autoReconnectMacro)

UI.Separator()

-- =====================================
-- 2. CONVERTER DINHEIRO
-- =====================================
if type(storage.moneyItems) ~= "table" or not storage.moneyItems[1] then
  storage.moneyItems = { {id=3031}, {id=3035} }
end

macro(500, "Converter dinheiro", function()
  local moneyItems = storage.moneyItems
  if not moneyItems then return end
  local moneyIds = buildIdSet(moneyItems)
  local containers = g_game.getContainers()
  for index, container in pairs(containers) do
    if not container.lootContainer then 
      for i, item in ipairs(container:getItems()) do
        if item:getCount() == 100 and moneyIds[item:getId()] then
          return g_game.use(item)
        end
      end
    end
  end
end)
local moneyContainer = UI.Container(function(widget, items) storage.moneyItems = items end, true)
moneyContainer:setHeight(35)
moneyContainer:setItems(storage.moneyItems)

UI.Separator()

-- =====================================
-- 3. BOSS TIMER
-- =====================================
local defaultBossAlarmLeadMinutes = 5
if storage.bossAlarmLeadMinutes == nil then storage.bossAlarmLeadMinutes = defaultBossAlarmLeadMinutes end
local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text
local bossConfig = {
    soundPath = "/bot/" .. configName .. "/Alarme/AlarmClock.wav",
    raidHours = {"01:30","03:30","05:30","07:30","09:30","11:30","13:30","15:30","17:30","19:30","21:30","23:30"}
}
UI.Label("Boss alarm (min):")
UI.TextEdit(tostring(storage.bossAlarmLeadMinutes), function(widget, text)
    local value = tonumber(text)
    if value then storage.bossAlarmLeadMinutes = value end
end)
local lastAlarmTime = ""
local function timeToSeconds(hhmm)
    local h, m = string.match(hhmm, "(%d+):(%d+)")
    return tonumber(h) * 3600 + tonumber(m) * 60
end
local function getNextRaid()
    local t = os.date("*t")
    local now = t.hour * 3600 + t.min * 60 + t.sec
    for _, timeStr in ipairs(bossConfig.raidHours) do
        local raidSec = timeToSeconds(timeStr)
        if raidSec > now then return raidSec - now, timeStr end
    end
    local firstRaidSec = timeToSeconds(bossConfig.raidHours[1])
    return (24 * 3600 - now) + firstRaidSec, bossConfig.raidHours[1]
end
local bossMacro = macro(1000, "Boss Timer", function()
    local remaining, nextTime = getNextRaid()
    local hrs = math.floor(remaining / 3600)
    local mins = math.floor((remaining % 3600) / 60)
    local secs = remaining % 60
    local leadSeconds = math.max(0, tonumber(storage.bossAlarmLeadMinutes) or defaultBossAlarmLeadMinutes) * 60
    if bossIcon then
        local timerText = string.format("Boss Timer\n%s\n%02d:%02d:%02d", nextTime, hrs, mins, secs)
        bossIcon:setText(timerText)
        bossIcon:setColor(remaining <= leadSeconds and "red" or "yellow")
    end
    if remaining <= leadSeconds and lastAlarmTime ~= nextTime then
        playSound(bossConfig.soundPath)
        lastAlarmTime = nextTime
    end
end)
if bossIcon then bossIcon:destroy() end
bossIcon = addIcon("BossTimerFix", {item=2036, text="", moveable=true}, bossMacro)
bossIcon:setSize({height=95, width=65})
bossIcon:setX(35)
bossIcon:setY(50)

UI.Separator()

-- =====================================
-- 4. STAMINA POTION
-- =====================================
if storage.staminaPanel then storage.staminaPanel:destroy() storage.staminaPanel = nil end
local staminaConfig = { potionId = 36725, staminaLimit = 39 * 60 }
local staminaLabel = UI.Label("Stamina: Calculando...")
staminaLabel:setColor("#FFA500") 
macro(1000, "Auto Stamina Potion", function()
    if not g_game.isOnline() then return end
    local player = g_game.getLocalPlayer()
    if not player then return end
    local stamina = player:getStamina()
    staminaLabel:setText(string.format("Stamina: %02d:%02d", math.floor(stamina / 60), stamina % 60))
    if stamina <= staminaConfig.staminaLimit then
        if use then use(staminaConfig.potionId) else g_game.useInventoryItem(staminaConfig.potionId) end
    end
end)

UI.Separator()

-- =====================================
-- 5. MONSTRO HP % & FOLLOW
-- =====================================
local showhp = macro(20000, "Monstro Hp %", function() end)
onCreatureHealthPercentChange(function(creature, healthPercent)
    if showhp:isOff() then return end
    if creature:isMonster() or (creature:isPlayer() and creature:getPosition()) then
        if creature:getPosition() then creature:setText(healthPercent .. "%") else creature:clearText() end
    end
end)

UI.Separator()

macro(250, "Atacar Seguindo", "Shift+R", function()
   if g_game.isOnline() and g_game.isAttacking() then g_game.setChaseMode(1) end
end)

UI.Separator()

-- =====================================
-- 7. AUTO SELL+BANK
-- =====================================
local seqConfig = { sellId = 54995, bankId = 54991, delay = 5000 }
local autoSellBankMacro = macro(30000, "Auto Sell+Bank (Store)", function()
    local function useItemById(id)
        if g_game.useInventoryItem then g_game.useInventoryItem(id)
        else local item = findItem(id) if item then g_game.use(item) end end
    end
    useItemById(seqConfig.sellId)
    schedule(seqConfig.delay, function() useItemById(seqConfig.bankId) end)
end)
if autoSellBankIcon then autoSellBankIcon:destroy() end
autoSellBankIcon = addIcon("AutoSellBank", {item=seqConfig.sellId, text="Sell+Bank", moveable=true}, autoSellBankMacro)

UI.Separator()

-- =====================================
-- 8. HOUSE TRAINER
-- =====================================
local trainerConfig = {
    house = { x1 = 1051, y1 = 1040, x2 = 1057, y2 = 1044, z = 7 },
    dummy = { id = 54005, pos = {x = 1051, y = 1043, z = 7} },
    wands = { 55486, 55484, 55634, 55485 }, delay = 1500
}
local function isInsideHouse()
    local p = pos() 
    if not p then return false end
    return p.z == trainerConfig.house.z and p.x >= trainerConfig.house.x1 and p.x <= trainerConfig.house.x2 and p.y >= trainerConfig.house.y1 and p.y <= trainerConfig.house.y2
end
local function getPriorityWand()
    for _, id in ipairs(trainerConfig.wands) do
        local item = findItem(id) if item then return item end
    end
    return nil
end
local function getDummyThing()
    local tile = g_map.getTile(trainerConfig.dummy.pos)
    if not tile then return nil end
    for _, thing in ipairs(tile:getThings()) do
        if thing:getId() == trainerConfig.dummy.id then return thing end
    end
    return nil
end
local HouseMacro = macro(trainerConfig.delay, "House Trainer", function()
    if not isInsideHouse() then return end
    local targetDummy = getDummyThing()
    if not targetDummy then return end
    local wandItem = getPriorityWand()
    if wandItem then g_game.useWith(wandItem, targetDummy) end
end)
if trainerIcon then trainerIcon:destroy() end
trainerIcon = addIcon("TrainerFix", {item=55486, text="Trainer", moveable=true}, HouseMacro)
trainerIcon:setX(35)
trainerIcon:setY(130)

UI.Separator()

-- =====================================
-- ATTACK SPELLS & ITENS
-- =====================================
local attackMacro = macro(100, "Attack", function()
    if g_game.isAttacking() then
      if storage.magia1 and storage.magia1 ~= "" then say(storage.magia1) end
      if storage.magia2 and storage.magia2 ~= "" then delay(100) say(storage.magia2) end
      if storage.magia3 and storage.magia3 ~= "" then delay(100) say(storage.magia3) end
    end
end)
UI.TextEdit(storage.magia1 or "spell", function(widget, newText) storage.magia1 = newText end)
UI.TextEdit(storage.magia2 or "spell2", function(widget, newText) storage.magia2 = newText end)
UI.TextEdit(storage.magia3 or "spell3", function(widget, newText) storage.magia3 = newText end)
if attackIcon then attackIcon:destroy() end
attackIcon = addIcon("AttackMacro", {item=55484, text="Attack", moveable=true}, attackMacro)

UI.Separator()

if type(storage.attackItemObj) ~= "table" then storage.attackItemObj = {3155} end
local autoAttackItemMacro = macro(200, "Auto attack item", function()
    if not g_game.isAttacking() then return end
    local target = g_game.getAttackingCreature()
    if not target then return end
    local itemEntry = storage.attackItemObj[1]
    if not itemEntry then return end
    local itemId = resolveItemId(itemEntry)
    if g_game.useInventoryItemWith then g_game.useInventoryItemWith(itemId, target)
    else local item = findItem(itemId) if item then g_game.useWith(item, target) end end
end)
UI.Label("Arraste o item de ataque aqui:")
local attackItemContainer = UI.Container(function(widget, items) storage.attackItemObj = items end, true)
attackItemContainer:setHeight(35)
attackItemContainer:setItems(storage.attackItemObj)
local attackItemIconId = 3155
local attackItemEntry = storage.attackItemObj[1]
if attackItemEntry then attackItemIconId = resolveItemId(attackItemEntry) end
if autoAttackItemIcon then autoAttackItemIcon:destroy() end
autoAttackItemIcon = addIcon("AutoAttackItem", {item=attackItemIconId, text="Atk Item", moveable=true}, autoAttackItemMacro)

UI.Separator()

-- =====================================
-- BOSS DODGE
-- =====================================
local dodgeConfig = { forbiddenId = 55636, searchRange = 7 }
local function hasItemOnPos(pos, itemId)
    local tile = g_map.getTile(pos)
    if tile then
        local things = tile:getThings()
        for _, thing in ipairs(things) do if thing:getId() == itemId then return true end end
    end
    return false
end
local function getSafeTile(pos)
    local bestPos = nil
    local shortestDist = 99999
    for x = -dodgeConfig.searchRange, dodgeConfig.searchRange do
        for y = -dodgeConfig.searchRange, dodgeConfig.searchRange do
            local checkPos = {x = pos.x + x, y = pos.y + y, z = pos.z}
            local tile = g_map.getTile(checkPos)
            if tile and tile:isWalkable() and tile:isPathable() then
                if not hasItemOnPos(checkPos, dodgeConfig.forbiddenId) then
                    local dist = getDistanceBetween(pos, checkPos)
                    if dist < shortestDist then shortestDist = dist bestPos = checkPos end
                end
            end
        end
    end
    return bestPos
end
local bossDodgeMacro = macro(100, "Boss Dodge", function()
    local player = g_game.getLocalPlayer()
    if not player then return end
    local playerPos = player:getPosition()
    if hasItemOnPos(playerPos, dodgeConfig.forbiddenId) then
        if g_game.isAttacking() or g_game.isFollowing() then g_game.stop() end
        local safeSpot = getSafeTile(playerPos)
        if safeSpot and (playerPos.x ~= safeSpot.x or playerPos.y ~= safeSpot.y) then
            autoWalk(safeSpot, 100, {ignoreNonPathable = true, precision = 0})
        end
    end
end)
if bossDodgeIcon then bossDodgeIcon:destroy() end
bossDodgeIcon = addIcon("BossDodge", {item=dodgeConfig.forbiddenId, text="Dodge", moveable=true}, bossDodgeMacro)

UI.Separator()

-- =====================================
-- UTILS: PARALYZE, BUFF, BLESS, TASK
-- =====================================
if Panels and Panels.AntiParalyze then Panels.AntiParalyze() UI.Separator() end

local buffMacro = macro(1000, "Buff System", function()
    if not hasPartyBuff() and not isInPz() then
        if storage.buff1 and storage.buff1:len() > 0 then say(storage.buff1) end
    end
end)
UI.Label("Buff:")
addTextEdit("buff1", storage.buff1 or "utito tempo san", function(widget, text) storage.buff1 = text end)

UI.Separator()
local renewTaskMacro = macro(2 * 60 * 1000, "Renovar Task (2min)", function() say("!taskrenew") end)
if renewTaskIcon then renewTaskIcon:destroy() end
renewTaskIcon = addIcon("RenewTask", {item=1950, text="Task", moveable=true}, renewTaskMacro)

-- =====================================
-- AUTO BLESS (SEM SPAM)
-- =====================================
if not storage.blessId then storage.blessId = "54981" end

-- Variavel de controle: assume true para usar ao carregar o script
local pendingBless = true 

local autoBlessMacro = macro(500, "Auto Bless (Smart)", function()
    -- Checa se o player esta online e vivo
    local player = g_game.getLocalPlayer()
    local isAlive = g_game.isOnline() and player and player:getHealth() > 0

    if not isAlive then
        -- Se morreu ou caiu, marca para usar bless assim que voltar
        pendingBless = true
        return
    end

    -- Se esta vivo e temos um bless pendente
    if isAlive and pendingBless then
        local id = tonumber(storage.blessId)
        local item = findItem(id)
        
        if item then
            g_game.use(item)
            modules.game_textmessage.displayGameMessage("🛡️ AutoBless: Item Usado!")
            -- Marca como false para NAO usar de novo (evita spam)
            -- Só voltara a ser true se morrer ou relogar
            pendingBless = false 
        end
    end
end)
UI.Label("ID do Bless:")
UI.TextEdit(storage.blessId, function(widget, text) storage.blessId = text end)
local blessIconId = tonumber(storage.blessId) or 54981
if autoBlessIcon then autoBlessIcon:destroy() end
autoBlessIcon = addIcon("AutoBless", {item=blessIconId, text="Bless", moveable=true}, autoBlessMacro)

UI.Separator()

-- =====================================
-- TURBO FOLLOW LOGIC
-- =====================================
local config = { distance = 1, interactionDelay = 100 }
local useIds = {433,435,482,1948,1968,5542,7771,9116,12799,17230,20469,20474,20488,20489,20895,20896,28209,28210,28656,31129,31130,31262,33770,34324,43374}
local stepIds = {166,167,413,427,427,428,433,437,438,465,468,566,855,856,857,1947,1950,1951,1952,1953,1954,1955,1956,1957,1958,1977,1978,4823,5081,5257,5258,5259,7881,7888,8657,8658,8690,8932,10206,11707,11709,14133,15144,15145,15146,15147,15718,16272,17394,17395,15590,15591,20123,20124,20142,20224,20225,20253,20254,20255,20256,20257,20258,20259,20328,20329,20330,20331,20332,20333,20334,20335,20336,20491,20492,20493,20494,20495,20496,20750,20751,20752,20753,20754,20755,21365,21564,21566,21568,21570,21156,22517,22565,22566,22749,29111,31907,39919,39921,39923,39925,40262,40263,40279,40281,40296,40298,40302,40428,40430,40432,40434,42619,42621,42623,42632,43134,42395,42391,23483,1967,1966,293,294,369,370,385,394,411,412,414,426,432,434,469,476,483,484,485,594,595,600,601,602,607,609,610,615,868,874,877,1066,1067,1080,1156,4824,4825,4826,5544,5691,5731,5763,6127,6128,6129,6130,6172,6173,6754,6755,6756,6916,7053,7181,7182,7476,7477,7478,7479,7515,7516,7517,7518,7520,7521,7522,7729,7730,7731,7732,7733,7734,7735,7736,7737,7755,7764,8144,8709,8924,12200,12236,12797,12798,12939,12940,12941,12942,12943,12944,12945,12946,12947,12948,12949,12950,12951,12952,12953,12954,12955,12956,12957,12958,12959,12960,14134,16265,16266,16267,16268,16269,16270,16271,16696,16697,16698,16699,16700,16701,16702,16703,16785,16786,16787,16788,16789,16790,16791,16792,17239,18642,18643,18644,18645,18646,18647,18648,18649,19143,19220,20260,20261,20262,20263,20344,20470,20471,20472,20073,21034,21342,21344,21971,21972,21973,22157,22748,23364,27628,28655,30452,30453,31168,32020,33709,34166,34255,38831,38832,43372,6920,505,628,775,878,1756,1761,1949,1959,5022,5756,8193,11552,11553,12795,15320,19243,20142,21739,21740,21741,21743,22106,22747,22761,23482,25047,25049,25051,25052,25053,25054,25055,25056,25057,25058,27589,27590,27658,28671,29975,29979,29980,32974,33004,33005,33006,33007,33790,34111,35502,36972,37000,37001,31469,37065,5068,5069,44027,32979,23483}
local useIdSet = buildIdSet(useIds)
local stepIdSet = buildIdSet(stepIds)

local lastKnownX, lastKnownY, lastKnownZ = 0, 0, 0
local hasLastPos, lastInteraction = false, 0
if not storage.TurboFollowName then storage.TurboFollowName = "" end
UI.Label("Nome do Alvo:")
local followEdit = UI.TextEdit(storage.TurboFollowName or "", function(widget, text) storage.TurboFollowName = text end)

local function findTarget(name)
    if not name or #name < 1 then return nil end
    local player = g_game.getLocalPlayer()
    if not player then return nil end
    local specs = g_map.getSpectators(player:getPosition(), false)
    for _, c in ipairs(specs) do
        if c:isPlayer() and c ~= player and c:getName():lower() == name:lower() then return c end
    end
    return nil
end
local function getDist(pos1, pos2)
    return math.max(math.abs(pos1.x - pos2.x), math.abs(pos1.y - pos2.y))
end
local function checkSurroundings(pPos)
    if now - lastInteraction < config.interactionDelay then return end
    for x = -1, 1 do
        for y = -1, 1 do
            local checkPos = {x = pPos.x + x, y = pPos.y + y, z = pPos.z}
            local tile = g_map.getTile(checkPos)
            if tile then
                local things = tile:getThings()
                for _, thing in ipairs(things) do
                    if thing:isItem() then
                        local id = thing:getId()
                        if stepIdSet[id] then
                            autoWalk(checkPos, 10, {ignoreNonPathable=true, precision=0})
                            lastInteraction = now
                            return
                        end
                        if useIdSet[id] then
                            g_game.use(thing)
                            lastInteraction = now
                            return
                        end
                    end
                end
            end
        end
    end
end
local followMacro = macro(50, "Turbo Follow", function()
    local player = g_game.getLocalPlayer()
    if not player then return end
    local myPos = player:getPosition()
    local targetName = storage.TurboFollowName
    local target = findTarget(targetName)
    if target then
        local tPos = target:getPosition()
        if tPos then 
            lastKnownX, lastKnownY, lastKnownZ = tPos.x, tPos.y, tPos.z
            hasLastPos = true
            local dist = getDist(myPos, tPos)
            if dist > config.distance then
                autoWalk(tPos, 10, {ignoreNonPathable=true, precision=1})
            end
        end
    elseif hasLastPos then
        local lastPos = {x=lastKnownX, y=lastKnownY, z=lastKnownZ}
        if lastPos.x ~= 0 then
            local dist = getDist(myPos, lastPos)
            if dist > 1 then
                autoWalk(lastPos, 10, {ignoreNonPathable=true, precision=1})
            else
                checkSurroundings(lastPos)
            end
        end
    end
end)
onTextMessage(function(mode, text)
    if not followMacro or not followMacro.isOn() then return end
    if string.find(text, "You see") then
        local name = string.match(text, "You see ([^%.%(]+)")
        if name then
            name = string.gsub(name, "^%s*(.-)%s*$", "%1")
            storage.TurboFollowName = name
            if followEdit then followEdit:setText(name) end
        end
    end
end)
if turboFollowIcon then turboFollowIcon:destroy() end
turboFollowIcon = addIcon("TurboFollow", {item=3088, text="Follow", moveable=true}, followMacro)

UI.Separator()
