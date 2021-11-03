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
--  * om hemma vid tändning eller kommer hem inom 120 min. (styrs av variabel 
--    homeWithIn) från tändning tänds kompletterande lampor
-- Definierad push-notifiering, ID:t hittas genom Fibaro-API http://.../api/panels/notifications
--  Titel: Tänd solnedgång
--  Innehåll: Lampor tändes 90 min innan solnedgång
-- Beroenden
--  * Virtuell enhet med enhets-ID 84 och med label lblStatusScen


-- Debug
local debug = true;

-- minuter före solnedgång från global variabel annars 90 min.
local minBeforeDusk = tonumber(fibaro:getGlobalValue("minBeforeDusk"));
if (minBeforeDusk == nil) then
    minBeforeDusk = 90;
end
-- Timme och minut när "Vardag lätt sovbarn-sys" alt. "Vardag lätt-sys" ska användas
local hourNotToLight, minuteNotToLight = 19, 00;
-- Timme och minut för när senast ska tändas
local hourLatestToLight, minuteLatestToLight = 21, 00;
-- Kompletterande lampor tänds om hemma inom tidsintervall (minuter)
local homeWithIn = 120;
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
local BVSovrumGraInnerst = fibaro:getGlobalValue("BVSovrumGraInnerst");
--[[ Bottenplan, Sovrum Blå --]]
local BVSovrumBlaHallvag = fibaro:getGlobalValue("BVSovrumBlaHallvag");
--[[ Ovanvånning --]]
local OVTVByra = fibaro:getGlobalValue("OVTVByra");
local OVGavelrumSkrivbor = fibaro:getGlobalValue("OVGavelrumSkrivbor");


local sourceTrigger = fibaro:getSourceTrigger()
function tempFunc()
    local currentDateTime = os.date("*t");
    local currentDateIsoFormat = TimeDateTableToIsoDateFormat(currentDateTime);
    -- Hantera om sommartid (daylightsaving), lägg till en timme
    if (currentDateTime.isdst) then
        -- currentDateTime.hour = currentDateTime.hour + 1;
        if debug then fibaro:debug(currentDateIsoFormat .. " -|- Sommartid") end;
    else
        if debug then fibaro:debug(currentDateIsoFormat .. " -|- Vintertid") end; 
    end

    local currentTime = os.date("%H:%M", os.time(currentDateTime));
    if debug then fibaro:debug(currentDateIsoFormat .. " -|---- currentTime : " .. currentTime) end;
    local timeBeforeDusk = os.date("%H:%M", 
        os.time(
            {
                year = currentDateTime.year,
                month = currentDateTime.month,
                day = currentDateTime.day,
                hour = (currentDateTime.hour + math.floor(minBeforeDusk/60)),
                min = (currentDateTime.min + (minBeforeDusk - math.floor(minBeforeDusk/60)*60))
            })
    );
    if debug then fibaro:debug(currentDateIsoFormat .. " -|---- timeBeforeDusk : " .. timeBeforeDusk) end;



    local timeLatestTolight = os.date("%H:%M", 
        os.time(
            {
                year = currentDateTime.year,
                month = currentDateTime.month,
                day = currentDateTime.day,
                hour = hourLatestToLight,
                min = minuteLatestToLight
            })
    );

    if debug then fibaro:debug(currentDateIsoFormat .. " -|---- isLightSceneManSet : " .. fibaro:getGlobalValue("isLightSceneManSet")) end;
    if debug then fibaro:debug(currentDateIsoFormat .. " -|---- sunsetHour (timeBeforeDusk) : " .. fibaro:getValue(1, "sunsetHour") .. " (" .. timeBeforeDusk .. ")" ) end;
    if debug then fibaro:debug(currentDateIsoFormat .. " -|---- hourLatestToLight:minuteLatestToLight (currentTime) : " .. timeLatestTolight .. " (" .. currentTime .. ")") end;


    LastAutoLitForDusk = 0+fibaro:getGlobal("LastAutoLitForDusk");
    local LastAutoLitForDuskDateIsoFormat = TimeDateTableToIsoDateFormat(os.date("*t", LastAutoLitForDusk));
    if debug then fibaro:debug(currentDateIsoFormat .. " -|---- currentDateIsoFormat (LastAutoLitForDuskDateIsoFormat) : " .. currentDateIsoFormat .. " (" .. LastAutoLitForDuskDateIsoFormat .. ")") end;

    if
        ((currentDateTime.wday == 1 or currentDateTime.wday == 2 or currentDateTime.wday == 3 or currentDateTime.wday == 4 or
            currentDateTime.wday == 5 or
            currentDateTime.wday == 6 or
            currentDateTime.wday == 7) and
         ((timeBeforeDusk == fibaro:getValue(1, "sunsetHour")) or
          (currentTime == timeLatestTolight and currentDateIsoFormat ~= LastAutoLitForDuskDateIsoFormat)) and
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
            if debug then fibaro:debug(currentDateIsoFormat .. " -|- Scen körd: Vardag lätt sovbarn-sys") end;
        else
            fibaro:startScene(9); -- Vardag lätt-sys
            fibaro:setGlobal("LastAutoLitForDusk",os.time());
            if debug then fibaro:debug(currentDateIsoFormat .. " -|- Scen körd: Vardag lätt-sys") end;
        end


        -- hantering av lampor vid enheter hemma (knuten till phone-check-indicate-home)
        if (fibaro:getGlobalValue("LastSeenHemma") == "1") then

            if debug then fibaro:debug("Hemma, tänder ytterligare lampor") end;

            -- Inväntar fortsatt körning för att öka sannolikheten att tidigare körda scener är avslutade
            fibaro:sleep(30000);

            AdditionalLightsOn();

            if debug then fibaro:debug(currentDateIsoFormat .. " -|- Kompletterande lampor: Tänder, är hemma") end;
        end 

        fibaro:call(tonumber(fibaro:getGlobalValue("mbDessi")), "sendDefinedPushNotification", "76");
        fibaro:call(tonumber(fibaro:getGlobalValue("mbChrille")), "sendDefinedPushNotification", "76");
    end


    -- Kompletterar med tändning av lampor om hemma senare än tändning men inom 120 min. och inte tänt manuellt
    LastAutoLitForDusk = 0+fibaro:getGlobal("LastAutoLitForDusk");
    -- fibaro:debug(currentDateIsoFormat .. " -|- Minuter sedan autotänt: " .. tostring((os.time() - LastAutoLitForDusk)/60));
    if debug then fibaro:debug(currentDateIsoFormat .. " -|- Tid sedan autotänt: " .. SecondsToClock(os.time() - LastAutoLitForDusk)) end;
    --TODO: Behöver även kontrollera om kompletterande tändning har gjorts, ska då ej köras
    if 
        (tonumber(fibaro:getGlobalValue("LastSeenHemma")) == 1 and
            (os.time() - LastAutoLitForDusk)/60 < homeWithIn and
            fibaro:getGlobalValue("isLightSceneManSet") == "falskt"
        )
    then
        AdditionalLightsOn();

        if debug then fibaro:debug(currentDateIsoFormat .. " -|- Kompletterande lampor: Tänder, kom hem inom " .. tostring(homeWithIn) .. " min.") end;
    end


    fibaro:call(84, "setProperty", "ui.lblStatusScen.value", "kör");

    if debug then fibaro:debug(currentDateIsoFormat .. " -|---------------------------------|-") end;
    setTimeout( function()
        status = xpcall( tempFunc, MyErrorHandler )
    end , 60 * 1000);
end


function AdditionalLightsOn()
    fibaro:call(BVKokStringHylla, "turnOn");
    fibaro:call(BVKokUnderTrappa, "turnOn");
    fibaro:call(BVHallEntreHylla, "turnOn");
    -- Barnrum, tänder om innan viss tidpunkt
    if
        (os.time() <=
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
        fibaro:call(BVSovrumGraByra, "turnOn");
        fibaro:call(BVSovrumGraInnerst, "turnOn");
        fibaro:call(BVSovrumBlaHallvag, "turnOn");
        fibaro:call(OVGavelrumSkrivbor, "turnOn");
    end
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



function SecondsToClock(seconds)
    local seconds = tonumber(seconds)
  
    if seconds <= 0 then
        return "00:00:00";
    else
        days = string.format("%02.f", math.floor(seconds/(3600*24)));
        hours = string.format("%02.f", math.floor(seconds/3600) - (days*24));
        mins = string.format("%02.f", math.floor(seconds/60  - (days*24*60)- (hours*60)));
        secs = string.format("%02.f", math.floor(seconds - (days*24*3600) - hours*3600 - mins *60));
        return days .. " dag(ar) " .. hours..":"..mins..":"..secs
    end
  end



function MyErrorHandler( errorMsg )

    local currentDate = os.date("*t");
    local currentDateIsoFormat = TimeDateTableToIsoDateFormat(currentDate);

    if (errorMsg == nil or errorMsg ~= "") then
        errorMsg = "Okänt fel";
    end

    fibaro:debug("ERROR (" .. currentDateIsoFormat .. "): " .. errorMsg); 
    fibaro:call(84, "setProperty", "ui.lblStatusScen.value", errorMsg);

end



if (sourceTrigger["type"] == "autostart") then

    local currentDate = os.date("*t");
    local currentDateIsoFormat = TimeDateTableToIsoDateFormat(currentDate);

    fibaro:debug(currentDateIsoFormat .. " -|- Kör, autostart"); 
    fibaro:debug(currentDateIsoFormat .. " -|---------------------------------|-"); 

    -- Kör huvudfunktion med felhantering
    status = xpcall( tempFunc, MyErrorHandler );
    if (status) then
        fibaro:call(84, "setProperty", "ui.lblStatusScen.value", "kör");
    else
        fibaro:debug("FEL"); 
        fibaro:call(84, "setProperty", "ui.lblStatusScen.value", "fel");
    end

else

    local currentDate = os.date("*t");
    local currentDateIsoFormat = TimeDateTableToIsoDateFormat(currentDate);

    fibaro:debug(currentDateIsoFormat .. " -|- Kör, startat annat än autostart"); 
    fibaro:debug(currentDateIsoFormat .. " -|---------------------------------|-"); 

    -- Kör huvudfunktion med felhantering
    status = xpcall( tempFunc, MyErrorHandler );
    if (status) then
        fibaro:call(84, "setProperty", "ui.lblStatusScen.value", "kör");
    else
        fibaro:debug("FEL"); 
        fibaro:call(84, "setProperty", "ui.lblStatusScen.value", "fel");
    end

end