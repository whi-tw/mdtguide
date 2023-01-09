---@class Addon
local Addon = select(2, ...)

function Addon.IsNPC(guid)
    return guid and guid:sub(1, 8) == "Creature"
end

function Addon.GetNPCId(guid)
    return tonumber(select(6, ("-"):split(guid)), 10)
end

function Addon.GetInstanceDungeonId(map)
    if not map then return end

    if MDT.zoneIdToDungeonIdx[map] then
        return MDT.zoneIdToDungeonIdx[map]
    end

    local instance = EJ_GetInstanceForMap(map)
    if not instance then return end

    for id,enemies in pairs(MDT.dungeonEnemies) do
        for _,enemy in pairs(enemies) do
            if enemy.instanceID == instance then
                return id
            end
        end
    end
end

function Addon.GetCurrentDungeonId()
    return MDT:GetDB().currentDungeonIdx
end

function Addon.IsCurrentInstance()
    return Addon.currentDungeon == Addon.GetCurrentDungeonId()
end

function Addon.GetDungeonScale(dungeon)
    return MDT.scaleMultiplier[dungeon or Addon.GetCurrentDungeonId()] or 1
end

function Addon.GetZoomScale(dungeon)
    local data = Addon.dungeons[dungeon or Addon.GetCurrentDungeonId()]
    return data and data.scale or 1
end

function Addon.GetCurrentEnemies()
    return MDT.dungeonEnemies[Addon.GetCurrentDungeonId()]
end

function Addon.GetCurrentPulls()
    return MDT:GetCurrentPreset().value.pulls
end

function Addon.IteratePull(pull, fn, ...)
    local enemies = Addon.GetCurrentEnemies()

    if type(pull) == "number" then
        pull = Addon.GetCurrentPulls()[pull]
    end

    for enemyId,clones in pairs(pull) do
        local enemy = enemies[enemyId]
        if enemy then
            for _,cloneId in pairs(clones) do
                if MDT:IsCloneIncluded(enemyId, cloneId) then
                    local a, b = fn(enemy.clones[cloneId], enemy, cloneId, enemyId, pull, ...)
                    if a then return a, b end
                end
            end
        end
    end
end

function Addon.IteratePulls(fn, ...)
    for i,pull in ipairs(Addon.GetCurrentPulls()) do
        local a, b = Addon.IteratePull(pull, fn, i, ...)
        if a then return a, b end
    end
end

function Addon.GetPullRect(pull, level, border)
    ---@type number, number, number, number
    local minX, minY, maxX, maxY

    Addon.IteratePull(pull, function (clone)
        local sub, x, y = clone.sublevel, clone.x, clone.y
        if sub == level then
            minX, minY = min(minX or x, x), min(minY or y, y)
            maxX, maxY = max(maxX or x, x), max(maxY or y, y)
        end
    end)

    if border then
        minX, minY, maxX, maxY = Addon.ExtendRect(minX, minY, maxX, maxY, border)
    end

    return minX, minY, maxX, maxY
end

function Addon.ExtendRect(minX, minY, maxX, maxY, left, top, right, bottom)
    if not minX or not left then return minX, minY, maxX, maxY end

    top = top or left
    right = right or left
    bottom = bottom or top

    return max(0, minX - left), min(0, minY - top), maxX + right, maxY + bottom
end

function Addon.CombineRects(minX, minY, maxX, maxY, minX2, minY2, maxX2, maxY2)
    if not minX or not minX2 then return minX, minY, maxX, maxY end

    local diffX, diffY = max(0, minX - minX2, maxX2 - maxX), max(0, minY - minY2, maxY2 - maxY)
    return Addon.ExtendRect(minX, minY, maxX, maxY, diffX, diffY)
end

function Addon.GetBestSubLevel(pull)
    local currSub, minDiff = MDT:GetCurrentSubLevel()
    Addon.IteratePull(pull, function (clone)
        local diff = clone.sublevel - currSub
        if not minDiff or abs(diff) < abs(minDiff) or abs(diff) == abs(minDiff) and diff < minDiff then
            minDiff = diff
        end
        return minDiff == 0
    end)
    return minDiff and currSub + minDiff
end

function Addon.GetLastSubLevel(pull)
    local sublevel
    Addon.IteratePull(pull, function (clone) sublevel = clone.sublevel or sublevel end)
    return sublevel
end

function Addon.FindWhere(tbl, key1, val1, key2, val2)
    for i,v in pairs(tbl) do
        if v[key1] == val1 and (not key2 or v[key2] == val2) then
            return v, i
        end
    end
end

Addon.Debug = function (...)
    if Addon.DEBUG then print(...) end
end

Addon.Echo = function (title, line, ...)
    print("|cff00bbbb[MDTGuide]|r " .. (title and title ..": " or "") .. (line or ""), ...)
end

Addon.Chat = function (msg)
    if IsInGroup() then
        SendChatMessage(msg, IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY")
    else
        Addon.Echo(nil, msg)
    end
end