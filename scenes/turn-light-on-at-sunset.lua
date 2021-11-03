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
--  * om hemma vid t�ndning eller kommer hem inom 120 min. (styrs av variabel 
--    homeWithIn) fr�n t�ndning t�nds kompletterande lampor
-- Definierad push-notifiering, ID:t hittas genom Fibaro-API http://.../api/panels/notifications
--  Titel: T�nd solnedg�ng
--  Inneh�ll: Lampor t�ndes 90 min innan solnedg�ng
-- Beroenden
--  * Virtuell enhet med enhets-ID 84 och med label lblStatusScen


-- Debug
local debug = true;

-- minuter f�re solnedg�ng fr�n global variabel annars 90 min.
local minBeforeDusk = tonumber(fibaro:getGlobalValue("minBeforeDusk"));
if (minBeforeDusk == nil) then
    minBeforeDusk = 90;
end
-- Timme och minut n�r "Vardag l�tt sovbarn-sys" alt. "Vardag l�tt-sys" ska anv�ndas
local hourNotToLight, minuteNotToLight = 19, 00;
-- Timme och minut f�r n�r senast ska t�ndas
local hourLatestToLight, minuteLatestToLight = 21, 00;
-- Kompletterande lampor t�nds om hemma inom tidsintervall (minuter)
local homeWithIn = 120;
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
local BVSovrumGraInnerst = fibaro:getGlobalValue("BVSovrumGraInnerst");
--[[ Bottenplan, Sovrum Bl� --]]
local BVSovrumBlaHallvag = fibaro:getGlobalValue("BVSovrumBlaHallvag");
--[[ Ovanv�nning --]]
local OVTVByra = fibaro:getGlobalValue("OVTVByra");
local OVGavelrumSkrivbor = fibaro:getGlobalValue("OVGavelrumSkrivbor");


local sourceTrigger = fibaro:getSourceTrigger()
function tempFunc()
    local currentDateTime = os.date("*t");
    local currentDateIsoFormat = TimeDateTableToIsoDateFormat(currentDateTime);
    -- Hantera om sommartid (daylightsaving), l�gg till en timme
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
            if debug then fibaro:debug(currentDateIsoFormat .. " -|- Scen k�rd: Vardag l�tt sovbarn-sys") end;
        else
            fibaro:startScene(9); -- Vardag l�tt-sys
            fibaro:setGlobal("LastAutoLitForDusk",os.time());
            if debug then fibaro:debug(currentDateIsoFormat .. " -|- Scen k�rd: Vardag l�tt-sys") end;
        end


        -- hantering av lampor vid enheter hemma (knuten till phone-check-indicate-home)
        if (fibaro:getGlobalValue("LastSeenHemma") == "1") then

            if debug then fibaro:debug("Hemma, t�nder ytterligare lampor") end;

            -- Inv�ntar fortsatt k�rning f�r att �ka sannolikheten att tidigare k�rda scener �r avslutade
            fibaro:sleep(30000);

            AdditionalLightsOn();

            if debug then fibaro:debug(currentDateIsoFormat .. " -|- Kompletterande lampor: T�nder, �r hemma") end;
        end 

        fibaro:call(tonumber(fibaro:getGlobalValue("mbDessi")), "sendDefinedPushNotification", "76");
        fibaro:call(tonumber(fibaro:getGlobalValue("mbChrille")), "sendDefinedPushNotification", "76");
    end


    -- Kompletterar med t�ndning av lampor om hemma senare �n t�ndning men inom 120 min. och inte t�nt manuellt
    LastAutoLitForDusk = 0+fibaro:getGlobal("LastAutoLitForDusk");
    -- fibaro:debug(currentDateIsoFormat .. " -|- Minuter sedan autot�nt: " .. tostring((os.time() - LastAutoLitForDusk)/60));
    if debug then fibaro:debug(currentDateIsoFormat .. " -|- Tid sedan autot�nt: " .. SecondsToClock(os.time() - LastAutoLitForDusk)) end;
    --TODO: Beh�ver �ven kontrollera om kompletterande t�ndning har gjorts, ska d� ej k�ras
    if 
        (tonumber(fibaro:getGlobalValue("LastSeenHemma")) == 1 and
            (os.time() - LastAutoLitForDusk)/60 < homeWithIn and
            fibaro:getGlobalValue("isLightSceneManSet") == "falskt"
        )
    then
        AdditionalLightsOn();

        if debug then fibaro:debug(currentDateIsoFormat .. " -|- Kompletterande lampor: T�nder, kom hem inom " .. tostring(homeWithIn) .. " min.") end;
    end


    fibaro:call(84, "setProperty", "ui.lblStatusScen.value", "k�r");

    if debug then fibaro:debug(currentDateIsoFormat .. " -|---------------------------------|-") end;
    setTimeout( function()
        status = xpcall( tempFunc, MyErrorHandler )
    end , 60 * 1000);
end


function AdditionalLightsOn()
    fibaro:call(BVKokStringHylla, "turnOn");
    fibaro:call(BVKokUnderTrappa, "turnOn");
    fibaro:call(BVHallEntreHylla, "turnOn");
    -- Barnrum, t�nder om innan viss tidpunkt
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
        errorMsg = "Ok�nt fel";
    end

    fibaro:debug("ERROR (" .. currentDateIsoFormat .. "): " .. errorMsg); 
    fibaro:call(84, "setProperty", "ui.lblStatusScen.value", errorMsg);

end



if (sourceTrigger["type"] == "autostart") then

    local currentDate = os.date("*t");
    local currentDateIsoFormat = TimeDateTableToIsoDateFormat(currentDate);

    fibaro:debug(currentDateIsoFormat .. " -|- K�r, autostart"); 
    fibaro:debug(currentDateIsoFormat .. " -|---------------------------------|-"); 

    -- K�r huvudfunktion med felhantering
    status = xpcall( tempFunc, MyErrorHandler );
    if (status) then
        fibaro:call(84, "setProperty", "ui.lblStatusScen.value", "k�r");
    else
        fibaro:debug("FEL"); 
        fibaro:call(84, "setProperty", "ui.lblStatusScen.value", "fel");
    end

else

    local currentDate = os.date("*t");
    local currentDateIsoFormat = TimeDateTableToIsoDateFormat(currentDate);

    fibaro:debug(currentDateIsoFormat .. " -|- K�r, startat annat �n autostart"); 
    fibaro:debug(currentDateIsoFormat .. " -|---------------------------------|-"); 

    -- K�r huvudfunktion med felhantering
    status = xpcall( tempFunc, MyErrorHandler );
    if (status) then
        fibaro:call(84, "setProperty", "ui.lblStatusScen.value", "k�r");
    else
        fibaro:debug("FEL"); 
        fibaro:call(84, "setProperty", "ui.lblStatusScen.value", "fel");
    end

end