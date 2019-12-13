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
--  * om hemma vid t�ndning eller kommer hem inom 120 min. fr�n t�ndning
--    t�nds kompletterande lampor
-- Definierad push-notifiering, ID:t hittas genom Fibaro-API http://.../api/panels/notifications
--  Titel: T�nd solnedg�ng
--  Inneh�ll: Lampor t�ndes 90 min innan solnedg�ng

-- minuter f�re solnedg�ng fr�n global variabel annars 90 min.
local minBeforeDusk = tonumber(fibaro:getGlobalValue("minBeforeDusk"));
if (minBeforeDusk == nil) then
    minBeforeDusk = 90;
end
-- Timme och minut n�r "Vardag l�tt sovbarn-sys" alt. "Vardag l�tt-sys" ska anv�ndas
local hourNotToLight, minuteNotToLight = 19, 00;
-- Timme och minut f�r n�r senast ska t�ndas
local hourLatestToLight, minuteLatestToLight = 21, 00;
-- Senast t�nt
local LastAutoLitForDusk = 0+fibaro:getGlobal("LastAutoLitForDusk");

-- d�da ev. extra instans av samma scen
if (fibaro:countScenes() > 1) then
    fibaro:abort();
end

-- Kompletterande lampor om hemma
--[[ Bottenplan, K�k --]]
local BVKokStringHylla = fibaro:getGlobalValue("BVKokStringHylla");
local BVKokUnderTrappa = fibaro:getGlobalValue("BVKokUnderTrappa");
--[[ Bottenplan, Entrehall --]]
local BVHallEntreHylla = fibaro:getGlobalValue("BVHallEntreHylla");
--[[ Bottenplan, Sovrum Gr� --]]
local BVSovrumGraByra = fibaro:getGlobalValue("BVSovrumGraByra");
--[[ Ovanv�nning --]]
local OVTVByra = fibaro:getGlobalValue("OVTVByra");


local sourceTrigger = fibaro:getSourceTrigger()
function tempFunc()
    local currentDate = os.date("*t");
    local currentDateIsoFormat = TimeDateTableToIsoDateFormat(currentDate);
    -- Hantera om sommartid (daylightsaving), l�gg till en timme
    if (currentDate.isdst) then
        currentDate.hour = currentDate.hour + 1;
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
            fibaro:startScene(22); -- Vardag l�tt sovbarn-sys
            fibaro:setGlobal("LastAutoLitForDusk",os.time());
            fibaro:debug(currentDateIsoFormat .. " -|- Scen k�rd: Vardag l�tt sovbarn-sys"); 
        else
            fibaro:startScene(9); -- Vardag l�tt-sys
            fibaro:setGlobal("LastAutoLitForDusk",os.time());
            fibaro:debug(currentDateIsoFormat .. " -|- Scen k�rd: Vardag l�tt-sys"); 
        end


        -- hantering av lampor vid enheter hemma (knuten till phone-check-indicate-home)
        if tonumber(fibaro:getGlobalValue("LastSeenHemma")) == 1 then  
            -- Inv�ntar fortsatt k�rning f�r att �ka sannolikheten att tidigare k�rda scener �r avslutade
            fibaro:sleep(60000);

            AdditionalLightsOn();

            fibaro:debug(currentDateIsoFormat .. " -|- Kompletterande lampor: T�nt f�r hemma"); 

            -- nollst�ller senast t�ndning om kompletterande lampor om hemma t�ndds, eliminera 
            fibaro:setGlobal("LastAutoLitForDusk",0);
        end 

        fibaro:call(tonumber(fibaro:getGlobalValue("mbDessi")), "sendDefinedPushNotification", "76");
        fibaro:call(tonumber(fibaro:getGlobalValue("mbChrille")), "sendDefinedPushNotification", "76");
    end


    -- Kompletterar med t�ndning av lampor om hemma senare �n t�ndning men inom 120 min. och inte t�nt manuellt
    LastAutoLitForDusk = 0+fibaro:getGlobal("LastAutoLitForDusk");
    if 
        (tonumber(fibaro:getGlobalValue("LastSeenHemma")) == 1 and
            (os.time() - LastAutoLitForDusk)/60 < 120 and
            fibaro:getGlobalValue("isLightSceneManSet") == "falskt"
        )
    then
        AdditionalLightsOn();

        fibaro:debug(currentDateIsoFormat .. " -|- Kompletterande lampor: T�nt kom hem"); 
    end


    setTimeout(tempFunc, 60 * 1000);
end


function AdditionalLightsOn()
    fibaro:call(BVKokStringHylla, "turnOn");
    fibaro:call(BVKokUnderTrappa, "turnOn");
    fibaro:call(BVHallEntreHylla, "turnOn");
    fibaro:call(BVSovrumGraByra, "turnOn");
    fibaro:call(OVTVByra, "turnOn");
end



function TimeDateTableToIsoDateFormat(TimeDate)
    result = TimeDate.year .. "-";

    if (tonumber(TimeDate.month) > 0 and tonumber(TimeDate.month) < 10) then
        result = result .. "0" .. TimeDate.month .. "-";
    else
        result = result .. TimeDate.month .. "-";
    end

    if (tonumber(TimeDate.day) > 0 and tonumber(TimeDate.day) < 10) then
        result = result .. "0" .. TimeDate.day;
    else
        result = result .. TimeDate.day;
    end

    return result;
end



if (sourceTrigger["type"] == "autostart") then
    tempFunc();
else
    tempFunc();
end