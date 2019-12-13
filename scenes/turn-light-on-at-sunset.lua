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
--  * om hemma vid tändning eller kommer hem inom 120 min. från tändning
--    tänds kompletterande lampor
-- Definierad push-notifiering, ID:t hittas genom Fibaro-API http://.../api/panels/notifications
--  Titel: Tänd solnedgång
--  Innehåll: Lampor tändes 90 min innan solnedgång

-- minuter före solnedgång från global variabel annars 90 min.
local minBeforeDusk = tonumber(fibaro:getGlobalValue("minBeforeDusk"));
if (minBeforeDusk == nil) then
    minBeforeDusk = 90;
end
-- Timme och minut när "Vardag lätt sovbarn-sys" alt. "Vardag lätt-sys" ska användas
local hourNotToLight, minuteNotToLight = 19, 00;
-- Timme och minut för när senast ska tändas
local hourLatestToLight, minuteLatestToLight = 21, 00;
-- Senast tänt
local LastAutoLitForDusk = 0+fibaro:getGlobal("LastAutoLitForDusk");

-- döda ev. extra instans av samma scen
if (fibaro:countScenes() > 1) then
    fibaro:abort();
end

-- Kompletterande lampor om hemma
--[[ Bottenplan, Kök --]]
local BVKokStringHylla = fibaro:getGlobalValue("BVKokStringHylla");
local BVKokUnderTrappa = fibaro:getGlobalValue("BVKokUnderTrappa");
--[[ Bottenplan, Entrehall --]]
local BVHallEntreHylla = fibaro:getGlobalValue("BVHallEntreHylla");
--[[ Bottenplan, Sovrum Grå --]]
local BVSovrumGraByra = fibaro:getGlobalValue("BVSovrumGraByra");
--[[ Ovanvånning --]]
local OVTVByra = fibaro:getGlobalValue("OVTVByra");


local sourceTrigger = fibaro:getSourceTrigger()
function tempFunc()
    local currentDate = os.date("*t");
    local currentDateIsoFormat = TimeDateTableToIsoDateFormat(currentDate);
    -- Hantera om sommartid (daylightsaving), lägg till en timme
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
            fibaro:startScene(22); -- Vardag lätt sovbarn-sys
            fibaro:setGlobal("LastAutoLitForDusk",os.time());
            fibaro:debug(currentDateIsoFormat .. " -|- Scen körd: Vardag lätt sovbarn-sys"); 
        else
            fibaro:startScene(9); -- Vardag lätt-sys
            fibaro:setGlobal("LastAutoLitForDusk",os.time());
            fibaro:debug(currentDateIsoFormat .. " -|- Scen körd: Vardag lätt-sys"); 
        end


        -- hantering av lampor vid enheter hemma (knuten till phone-check-indicate-home)
        if tonumber(fibaro:getGlobalValue("LastSeenHemma")) == 1 then  
            -- Inväntar fortsatt körning för att öka sannolikheten att tidigare körda scener är avslutade
            fibaro:sleep(60000);

            AdditionalLightsOn();

            fibaro:debug(currentDateIsoFormat .. " -|- Kompletterande lampor: Tänt för hemma"); 

            -- nollställer senast tändning om kompletterande lampor om hemma tändds, eliminera 
            fibaro:setGlobal("LastAutoLitForDusk",0);
        end 

        fibaro:call(tonumber(fibaro:getGlobalValue("mbDessi")), "sendDefinedPushNotification", "76");
        fibaro:call(tonumber(fibaro:getGlobalValue("mbChrille")), "sendDefinedPushNotification", "76");
    end


    -- Kompletterar med tändning av lampor om hemma senare än tändning men inom 120 min. och inte tänt manuellt
    LastAutoLitForDusk = 0+fibaro:getGlobal("LastAutoLitForDusk");
    if 
        (tonumber(fibaro:getGlobalValue("LastSeenHemma")) == 1 and
            (os.time() - LastAutoLitForDusk)/60 < 120 and
            fibaro:getGlobalValue("isLightSceneManSet") == "falskt"
        )
    then
        AdditionalLightsOn();

        fibaro:debug(currentDateIsoFormat .. " -|- Kompletterande lampor: Tänt kom hem"); 
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