-- config

local keyUp = "="
local keyDown = "-"
setDefaultTab("Tools")

-- script

local lockedLevel = pos().z
local mapPanel = modules.game_interface.getMapPanel()
local function ensureMapPanel()
    if not mapPanel then mapPanel = modules.game_interface.getMapPanel() end
    return mapPanel
end

onPlayerPositionChange(function(newPos, oldPos)
    lockedLevel = pos().z
    local panel = ensureMapPanel()
    if panel then panel:unlockVisibleFloor() end
end)

onKeyPress(function(keys)
    if keys == keyDown then
        lockedLevel = lockedLevel + 1
        local panel = ensureMapPanel()
        if panel then panel:lockVisibleFloor(lockedLevel) end
    elseif keys == keyUp then
        lockedLevel = lockedLevel - 1
        local panel = ensureMapPanel()
        if panel then panel:lockVisibleFloor(lockedLevel) end
    end
end)
