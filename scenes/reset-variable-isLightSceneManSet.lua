--[[
%% autostart
%% properties
%% weather
%% events
%% globals
--]]

-- Maskinskapad kod. Kopia av grafiska kodblock.

local sourceTrigger = fibaro:getSourceTrigger()
function tempFunc()
    local currentDate = os.date("*t")
    local startSource = fibaro:getSourceTrigger()
    if
        (((currentDate.wday == 1 or currentDate.wday == 2 or currentDate.wday == 3 or currentDate.wday == 4 or
            currentDate.wday == 5 or
            currentDate.wday == 6 or
            currentDate.wday == 7) and
            string.format("%02d", currentDate.hour) .. ":" .. string.format("%02d", currentDate.min) == "03:00") or
            ((currentDate.wday == 1 or currentDate.wday == 2 or currentDate.wday == 3 or currentDate.wday == 4 or
                currentDate.wday == 5 or
                currentDate.wday == 6 or
                currentDate.wday == 7) and
                string.format("%02d", currentDate.hour) .. ":" .. string.format("%02d", currentDate.min) == "12:00"))
     then
        fibaro:setGlobal("isLightSceneManSet", "falskt")
    end

    setTimeout(tempFunc, 60 * 1000)
end
if (sourceTrigger["type"] == "autostart") then
    tempFunc()
else
    local currentDate = os.date("*t")
    local startSource = fibaro:getSourceTrigger()
    if (startSource["type"] == "other") then
        fibaro:setGlobal("isLightSceneManSet", "falskt")
    end
end
