local prefix = "|cff33ff99RollWinner|r: "

local rollOff = nil
local rollPattern

local function printMessage(message)
    print(prefix .. message)
end

local function escapePattern(text)
    return text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

local function makeRollPattern(format)
    local stringMarker = "\001"
    local numberMarker = "\002"
    local pattern = format:gsub("%%s", stringMarker):gsub("%%d", numberMarker)

    pattern = escapePattern(pattern)
    pattern = pattern:gsub(stringMarker, function() return "(.+)" end)
    pattern = pattern:gsub(numberMarker, function() return "(%d+)" end)
    return "^" .. pattern .. "$"
end

local function resetRollOff(minimum, maximum)
    rollOff = {
        minimum = minimum,
        maximum = maximum,
        rolls = {},
        arrivalOrder = {},
        output = { kind = "GROUP" },
    }
end

local function sendAnnouncement(message)
    local output = rollOff.output
    local chatType = output.kind
    local target

    if chatType == "GROUP" then
        if IsInRaid() then
            chatType = "RAID"
        elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            chatType = "INSTANCE_CHAT"
        elseif IsInGroup() then
            chatType = "PARTY"
        else
            printMessage(message)
            return
        end
    elseif chatType == "PARTY" and not IsInGroup() then
        printMessage("You are not in a party.")
        return
    elseif chatType == "RAID" and not IsInRaid() then
        printMessage("You are not in a raid.")
        return
    elseif chatType == "INSTANCE_CHAT" and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        printMessage("You are not in an instance group.")
        return
    elseif chatType == "CHANNEL" then
        target = output.channel
        if not GetChannelName(target) then
            printMessage("Channel " .. target .. " is not available.")
            return
        end
    end

    local sent, errorMessage = pcall(SendChatMessage, message, chatType, nil, target)
    if not sent then
        printMessage("Could not announce the result: " .. tostring(errorMessage))
    end
end

local function finishRollOff()
    if not rollOff then
        printMessage("No roll-off is active. Use /rw start <min>-<max> first.")
        return
    end

    if #rollOff.arrivalOrder == 0 then
        printMessage("No matching rolls were received.")
        return
    end

    local highest = -1
    local winners = {}
    for _, name in ipairs(rollOff.arrivalOrder) do
        local roll = rollOff.rolls[name]
        if roll > highest then
            highest = roll
            winners = { name }
        elseif roll == highest then
            table.insert(winners, name)
        end
    end

    sendAnnouncement("Winner: " .. table.concat(winners, ", ") .. " with " .. highest .. ".")
    rollOff = nil
end

local function handleCommand(message)
    local command, argument = message:match("^%s*(%S+)%s*(.-)%s*$")
    command = command and command:lower()

    if command == "start" then
        local minimum, maximum = argument:match("^(%d+)%s*%-%s*(%d+)$")
        minimum, maximum = tonumber(minimum), tonumber(maximum)
        if not minimum or not maximum or minimum > maximum then
            printMessage("Usage: /rw start <min>-<max>")
            return
        end
        resetRollOff(minimum, maximum)
        printMessage("Collecting rolls from " .. minimum .. " to " .. maximum .. ".")
    elseif command == "finish" then
        finishRollOff()
    elseif command == "say" or command == "yell" then
        if not rollOff then
            printMessage("Start a roll-off before choosing an announcement channel.")
            return
        end
        rollOff.output = { kind = command:upper() }
        printMessage("Announcements will use " .. command:upper() .. ".")
    elseif command == "group" then
        if not rollOff then
            printMessage("Start a roll-off before choosing an announcement channel.")
            return
        end
        rollOff.output = { kind = "GROUP" }
        printMessage("Announcements will use the current group.")
    elseif command == "raid" then
        if not rollOff then
            printMessage("Start a roll-off before choosing an announcement channel.")
            return
        end
        rollOff.output = { kind = "RAID" }
        printMessage("Announcements will use raid chat.")
    elseif command == "channel" then
        local channel = tonumber(argument)
        if not rollOff then
            printMessage("Start a roll-off before choosing an announcement channel.")
        elseif not channel or channel < 1 or channel % 1 ~= 0 then
            printMessage("Usage: /rw channel <channel-number>")
        else
            rollOff.output = { kind = "CHANNEL", channel = channel }
            printMessage("Announcements will use channel " .. channel .. ".")
        end
    else
        printMessage("Commands: start <min>-<max>, finish, say, yell, group, raid, channel <number>")
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:SetScript("OnEvent", function(_, _, message)
    if not rollOff or not rollPattern then
        return
    end

    local name, roll, minimum, maximum = message:match(rollPattern)
    roll, minimum, maximum = tonumber(roll), tonumber(minimum), tonumber(maximum)
    if not name or not roll or minimum ~= rollOff.minimum or maximum ~= rollOff.maximum then
        return
    end
    if roll < rollOff.minimum or roll > rollOff.maximum or rollOff.rolls[name] then
        return
    end

    rollOff.rolls[name] = roll
    table.insert(rollOff.arrivalOrder, name)
    printMessage(name .. " rolled " .. roll .. ".")
end)

SLASH_ROLLWINNER1 = "/rw"
SlashCmdList.ROLLWINNER = handleCommand

rollPattern = makeRollPattern(RANDOM_ROLL_RESULT)
printMessage("Loaded. Use /rw start <min>-<max> to begin.")