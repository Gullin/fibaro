--[[
%% autostart
%% events
--]]

-- CP Windows 1252
-- T�nder n�r:
--  * alla dagar i veckan,
--  * minuter innan solnedg�ng styrs med global variabel sunsetHour,
--    om ej definierad g�ller 90 minunter som standard och
--  * T�nder senast kl. 21:00
--  * om ingen scen �r k�rd manuellt sedan morgonen kl. 03:00 eller lunch 12:00
--    styrs av logiska variabeln isLightSceneManSet
--  * t�nder "Vardag l�tt sovbarn-sys" om det t�nds efter kl. 19:00
--  * annars t�nds scen "Vardag l�tt-sys"
-- Definierad push-notifiering, ID:t hittas genom Fibaro-API http://.../api/panels/notifications
--  Titel: T�nd solnedg�ng
--  Inneh�ll: Lampor t�ndes 90 min innan solnedg�ng

-- minuter f�re solnedg�ng fr�n global variabel annars 90 min.
local minBeforeDusk = tonumber(fibaro:getGlobalValue("minBeforeDusk"))
if (minBeforeDusk == nil) then
    minBeforeDusk = 90
end
-- Timme och minut n�r "Vardag l�tt sovbarn-sys" alt. "Vardag l�tt-sys" ska anv�ndas
local hourNotToLight, minuteNotToLight = 19, 00
-- Timme och minut f�r n�r senast ska t�ndas
local hourLatestToLight, minuteLatestToLight = 21, 00

-- d�da ev. extra instans av samma scen
if (fibaro:countScenes() > 1) then
    fibaro:abort()
end

--[[ Bottenplan, Entrehall --]]
local BVHallEntreHylla = fibaro:getGlobalValue("BVHallEntreHylla")
--[[ Ovanv�nning --]]
local TVRoomBureau = fibaro:getGlobalValue("TVRoomBureau")


local sourceTrigger = fibaro:getSourceTrigger()
function tempFunc()
    local currentDate = os.date("*t")
    -- Hantera om sommartid (daylightsaving), l�gg till en timme
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
        -- om aktuell tid �r st�rre �n (mer �n) kl. 19:00 k�rs if
        -- annars om klockan �r mindre �n eller lika med kl. 19:00 k�rs else
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
            fibaro:startScene(22) -- Vardag l�tt sovbarn-sys
        else
            fibaro:startScene(9) -- Vardag l�tt-sys
        end


        -- hantering av lampor vid enheter hemma (knuten till phone-check-indicate-home)
        if tonumber(fibaro:getGlobalValue("LastSeenHemma")) == 1 then  
            -- Inv�ntar fortsatt k�rning f�r att �ka sannolikheten att tidigare k�rda scener �r avslutade
            fibaro:sleep(60000);

            fibaro:call(BVHallEntreHylla, "turnOn");
            fibaro:call(TVRoomBureau, "turnOn");
        end 

        fibaro:call(tonumber(fibaro:getGlobalValue("mbDessi")), "sendDefinedPushNotification", "76");
        fibaro:call(tonumber(fibaro:getGlobalValue("mbChrille")), "sendDefinedPushNotification", "76");
    end

    setTimeout(tempFunc, 60 * 1000)
end

if (sourceTrigger["type"] == "autostart") then
    tempFunc()
else
    tempFunc()
end