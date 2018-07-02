--[[
%% autostart
%% properties
%% weather
%% events
%% globals
--]]

-- Tänder när:
--  * alla dagar i veckan,
--  * 90 minunter före solnedgång och
--  * om ingen scen är körd manuellt sedan morgonen kl. 03:00
--    styrs av logiska variabeln isLightSceneManSet som sätts i manuell scener

local currentDate = os.date("*t")
if
    (((currentDate.wday == 1 or currentDate.wday == 2 or currentDate.wday == 3 or currentDate.wday == 4 or
        currentDate.wday == 5 or
        currentDate.wday == 6 or
        currentDate.wday == 7) and
        os.date("%H:%M", os.time() + 90 * 60) == fibaro:getValue(1, "sunsetHour")) and
        fibaro:getGlobalValue("isLightSceneManSet") == "falskt")
 then
    fibaro:startScene(22)
end

setTimeout(tempFunc, 60 * 1000)
