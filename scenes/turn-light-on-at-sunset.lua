--[[
%% autostart
%% properties
%% weather
%% events
%% globals
--]]
-- T�nder n�r:
--  * alla dagar i veckan,

local currentDate = os.date("*t")
if
    ((currentDate.wday == 1 or currentDate.wday == 2 or currentDate.wday == 3 or currentDate.wday == 4 or
        currentDate.wday == 5 or
        currentDate.wday == 6 or
        currentDate.wday == 7) and
        os.date("%H:%M", os.time() + 90 * 60) == fibaro:getValue(1, "sunsetHour"))
 then
    fibaro:startScene(22)
end

setTimeout(tempFunc, 60 * 1000)
