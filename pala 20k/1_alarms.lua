alarmsPanelName = "alarms"
local ui = setupUI([[
Panel
  height: 19

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('Alarme')

  Button
    id: alerts
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Edite

]])
ui:setId(alarmsPanelName)

if not storage[alarmsPanelName] then
    storage[alarmsPanelName] = {
      enabled = false,
      playerAttack = false,
      playerDetected = false,
      playerDetectedLogout = false,
      creatureDetected = false,
      healthBelow = false,
      healthValue = 40,
      manaBelow = false,
      manaValue = 50,
      privateMessage = false,
      playerpk = false
    }
end

ui.title:setOn(storage[alarmsPanelName].enabled)
ui.title.onClick = function(widget)
    storage[alarmsPanelName].enabled = not storage[alarmsPanelName].enabled
    widget:setOn(storage[alarmsPanelName].enabled)
end

rootWidget = g_ui.getRootWidget()
if rootWidget then
    alarmsWindow = g_ui.createWidget('AlarmsWindow', rootWidget)
    alarmsWindow:hide()

    alarmsWindow.closeButton.onClick = function(widget)
        alarmsWindow:hide()
    end

    alarmsWindow.playerAttack:setOn(storage[alarmsPanelName].playerAttack)
    alarmsWindow.playerAttack.onClick = function(widget)
        storage[alarmsPanelName].playerAttack = not storage[alarmsPanelName].playerAttack
        widget:setOn(storage[alarmsPanelName].playerAttack)
    end

    alarmsWindow.playerDetected:setOn(storage[alarmsPanelName].playerDetected)
    alarmsWindow.playerDetected.onClick = function(widget)
        storage[alarmsPanelName].playerDetected = not storage[alarmsPanelName].playerDetected
        widget:setOn(storage[alarmsPanelName].playerDetected)
    end

    alarmsWindow.playerDetectedLogout:setChecked(storage[alarmsPanelName].playerDetectedLogout)
    alarmsWindow.playerDetectedLogout.onClick = function(widget)
        storage[alarmsPanelName].playerDetectedLogout = not storage[alarmsPanelName].playerDetectedLogout
        widget:setChecked(storage[alarmsPanelName].playerDetectedLogout)
    end

    alarmsWindow.creatureDetected:setOn(storage[alarmsPanelName].creatureDetected)
    alarmsWindow.creatureDetected.onClick = function(widget)
        storage[alarmsPanelName].creatureDetected = not storage[alarmsPanelName].creatureDetected
        widget:setOn(storage[alarmsPanelName].creatureDetected)
    end

    alarmsWindow.playerpk:setOn(storage[alarmsPanelName].playerpk)
    alarmsWindow.playerpk.onClick = function(widget)
        storage[alarmsPanelName].playerpk = not storage[alarmsPanelName].playerpk
        widget:setOn(storage[alarmsPanelName].playerpk)
    end

    alarmsWindow.healthBelow:setOn(storage[alarmsPanelName].healthBelow)
    alarmsWindow.healthBelow.onClick = function(widget)
        storage[alarmsPanelName].healthBelow = not storage[alarmsPanelName].healthBelow
        widget:setOn(storage[alarmsPanelName].healthBelow)
    end

    alarmsWindow.healthValue.onValueChange = function(scroll, value)
        storage[alarmsPanelName].healthValue = value
        alarmsWindow.healthBelow:setText("Health < " .. storage[alarmsPanelName].healthValue .. "%")  
    end
    alarmsWindow.healthValue:setValue(storage[alarmsPanelName].healthValue)

    alarmsWindow.manaBelow:setOn(storage[alarmsPanelName].manaBelow)
    alarmsWindow.manaBelow.onClick = function(widget)
        storage[alarmsPanelName].manaBelow = not storage[alarmsPanelName].manaBelow
        widget:setOn(storage[alarmsPanelName].manaBelow)
    end

    alarmsWindow.manaValue.onValueChange = function(scroll, value)
        storage[alarmsPanelName].manaValue = value
        alarmsWindow.manaBelow:setText("Mana < " .. storage[alarmsPanelName].manaValue .. "%")  
    end
    alarmsWindow.manaValue:setValue(storage[alarmsPanelName].manaValue)

    alarmsWindow.privateMessage:setOn(storage[alarmsPanelName].privateMessage)
    alarmsWindow.privateMessage.onClick = function(widget)
        storage[alarmsPanelName].privateMessage = not storage[alarmsPanelName].privateMessage
        widget:setOn(storage[alarmsPanelName].privateMessage)
    end

    local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text;
    local function alarmSound(fileName)
        return "/bot/" .. configName .. "/Alarme/" .. fileName .. ".ogg"
    end
    local function inRange(posX, posY, specPos, range)
        return math.max(math.abs(posX - specPos.x), math.abs(posY - specPos.y)) <= range
    end

    onTextMessage(function(mode, text)
        local isEnabled = storage[alarmsPanelName].enabled and storage[alarmsPanelName].playerAttack
        local isAttackBy = text:find("hitpoints due to an attack by a ", 1, true)
        local isHitMessage = not isAttackBy and text:find("hitpoints due to an attack", 1, true)
        if isEnabled and mode == 16 and isHitMessage then
            playSound(alarmSound("Player_Attack"))
        end
    end)

    macro(100, function()
        if not storage[alarmsPanelName].enabled then return end
        
        local specs
        local posX, posY
        if storage[alarmsPanelName].playerDetected then
            if not posX then posX, posY = posx(), posy() end
            if not specs then specs = getSpectators() end
            for _, spec in ipairs(specs) do
                if spec:isPlayer() and spec:getName() ~= name() then
                    local specPos = spec:getPosition()
                    if specPos and inRange(posX, posY, specPos, 8) then
                        playSound(alarmSound("jogador"))
                        delay(1500)
                        if storage[alarmsPanelName].playerDetectedLogout then
                            modules.game_interface.tryLogout(false)
                        end
                        return
                    end
                end
            end
        end

        if storage[alarmsPanelName].creatureDetected then
            if not posX then posX, posY = posx(), posy() end
            if not specs then specs = getSpectators() end
            for _, spec in ipairs(specs) do
                if not spec:isPlayer()then
                    local specPos = spec:getPosition()
                    if specPos and inRange(posX, posY, specPos, 8) then
                        playSound(alarmSound("monstro"))
                        delay(1500)
                        return
                    end
                end
            end
        end

        if storage[alarmsPanelName].healthBelow then
            if hppercent() <= storage[alarmsPanelName].healthValue then
                playSound(alarmSound("vida"))
                delay(1500)
                return
            end
        end

        if storage[alarmsPanelName].playerpk then
            if not specs then specs = getSpectators() end
            for _, spec in ipairs(specs) do
                if spec:isPlayer() and spec:getSkull() ~= skull() then
                    playSound(alarmSound("pk"))
                    delay(1500)
                    return
                end
            end
        end

        if storage[alarmsPanelName].manaBelow then
            if manapercent() <= storage[alarmsPanelName].manaValue then
                playSound(alarmSound("mana"))
                delay(1500)
                return
            end
        end
    end)

    onTalk(function(name, level, mode, text, channelId, pos)
        if mode == 4 and storage[alarmsPanelName].enabled and storage[alarmsPanelName].privateMessage then
            playSound("/sounds/mensagem.ogg")
            return
        end
    end)
end

ui.alerts.onClick = function(widget)
    alarmsWindow:show()
    alarmsWindow:raise()
    alarmsWindow:focus()
end
