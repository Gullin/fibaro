--[[
%% autostart
%% events
--]]

-- CP Windows 1252
-- Tänder när:
--  * alla dagar i veckan,
--  * minuter innan solnedgång styrs med global variabel sunsetHour,
--    om ej definierad gäller 90 minunter som standard och
--  * Tänder senast kl. 21:00
--  * om ingen scen är körd manuellt sedan morgonen kl. 03:00 eller lunch 12:00
--    styrs av logiska variabeln isLightSceneManSet
--  * tänder "Vardag lätt sovbarn-sys" om det tänds efter kl. 19:00
--  * annars tänds scen "Vardag lätt-sys"
-- Definierad push-notifiering, ID:t hittas genom Fibaro-API http://.../api/panels/notifications
--  Titel: Tänd solnedgång
--  Innehåll: Lampor tändes 90 min innan solnedgång

-- minuter före solnedgång från global variabel annars 90 min.
local minBeforeDusk = tonumber(fibaro:getGlobalValue("minBeforeDusk"))
if (minBeforeDusk == nil) then
    minBeforeDusk = 90
end
-- Timme och minut när "Vardag lätt sovbarn-sys" alt. "Vardag lätt-sys" ska användas
local hourNotToLight, minuteNotToLight = 19, 00
-- Timme och minut för när senast ska tändas
local hourLatestToLight, minuteLatestToLight = 21, 00

-- döda ev. extra instans av samma scen
if (fibaro:countScenes() > 1) then
    fibaro:abort()
end

local sourceTrigger = fibaro:getSourceTrigger()
function tempFunc()
    local currentDate = os.date("*t")
    -- Hantera om sommartid (daylightsaving), lägg till en timme
    if (currentDate.isdst) then
        currentDate.hour = currentDate.hour + 1
    end

    if
        ((currentDate.wday == 1 or currentDate.wday == 2 or currentDate.wday == 3 or currentDate.wday == 4 or
            currentDate.wday == 5 or
            currentDate.wday == 6 or
            currentDate.wday == 7) and
            ((os.date("%H:%M", os.time() + minBeforeDusk * 60) == fibaro:getValue(1, "sunsetHour")) or
                (os.date("%H:%M", os.time()) == (hourLatestToLight .. ":" .. minuteLatestToLight))) and
            fibaro:getGlobalValue("isLightSceneManSet") == "falskt")
     then
        -- om aktuell tid är större än (mer än) kl. 19:00 körs if
        -- annars om klockan är mindre än eller lika med kl. 19:00 körs else
        if
            (os.time() >
                os.time(
                    {
                        year = os.date("*t").year,
                        month = os.date("*t").month,
                        day = os.date("*t").day,
                        hour = hourNotToLight,
                        min = minuteNotToLight
                    }
                ))
         then
            fibaro:startScene(22) -- Vardag lätt sovbarn-sys
        else
            fibaro:startScene(9) -- Vardag lätt-sys
        end

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