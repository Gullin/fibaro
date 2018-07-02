--[[
%% autostart
%% properties
%% weather
%% events
%% globals
--]]
--
-- T�nder n�r:
--  * alla dagar i veckan,
--  * 90 minunter f�re solnedg�ng och
--  * om ingen scen �r k�rd manuellt sedan morgonen kl. 03:00
--    styrs av logiska variabeln isLightSceneManSet som s�tts i manuell scener
-- Definierad push-notifiering, ID:t hittas genom Fibaro-API http://.../api/panels/notifications
--  Titel: T�nd solnedg�ng
--  Inneh�ll: Lampor t�ndes 90 min innan solnedg�ng

local sourceTrigger = fibaro:getSourceTrigger()
function tempFunc()
    local currentDate = os.date("*t")
    local startSource = fibaro:getSourceTrigger()
    if
        (((currentDate.wday == 1 or currentDate.wday == 2 or currentDate.wday == 3 or currentDate.wday == 4 or
            currentDate.wday == 5 or
            currentDate.wday == 6 or
            currentDate.wday == 7) and
            os.date("%H:%M", os.time() + 90 * 60) == fibaro:getValue(1, "sunsetHour")) and
            fibaro:getGlobalValue("isLightSceneManSet") == "falskt")
     then
        fibaro:startScene(22)
        fibaro:call(4, "sendDefinedPushNotification", "76")
        fibaro:call(15, "sendDefinedPushNotification", "76")
    end

    setTimeout(tempFunc, 60 * 1000)
end

if (sourceTrigger["type"] == "autostart") then
    tempFunc()
else
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
        fibaro:call(4, "sendDefinedPushNotification", "76")
        fibaro:call(15, "sendDefinedPushNotification", "76")
    end
end
