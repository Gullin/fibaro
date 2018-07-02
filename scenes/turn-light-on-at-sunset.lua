--[[
%% autostart
%% events
--]]
--
-- T�nder n�r:
--  * alla dagar i veckan,
--  * 90 minunter innan solnedg�ng styrs med variabel sunsetHour,
--    om ej definierad g�ller 90 minunter som standard och
--  * om ingen scen �r k�rd manuellt sedan morgonen kl. 03:00
--    styrs av logiska variabeln isLightSceneManSet som s�tts i manuell scener
-- Definierad push-notifiering, ID:t hittas genom Fibaro-API http://.../api/panels/notifications
--  Titel: T�nd solnedg�ng
--  Inneh�ll: Lampor t�ndes 90 min innan solnedg�ng

-- minuter f�re solnedg�ng fr�n global variabel annars 90 min.
local minBeforeDusk = tonumber(fibaro:getGlobalValue("minBeforeDusk"))
if (minBeforeDusk == nil) then
    minBeforeDusk = 90
end

-- d�da ev. extra instans av samma scen
if (fibaro:countScenes() > 1) then
    fibaro:abort()
end

local sourceTrigger = fibaro:getSourceTrigger()
function tempFunc()
    local currentDate = os.date("*t")
    if
        (((currentDate.wday == 1 or currentDate.wday == 2 or currentDate.wday == 3 or currentDate.wday == 4 or
            currentDate.wday == 5 or
            currentDate.wday == 6 or
            currentDate.wday == 7) and
            os.date("%H:%M", os.time() + minBeforeDusk * 60) == fibaro:getValue(1, "sunsetHour")) and
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
    tempFunc()
end
