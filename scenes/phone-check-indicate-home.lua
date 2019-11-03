--[[ 
%% autostart
%% properties
%% globals
LastSeenChristian
LastSeenDesiree
LastSeenHemma
LastAutoLitForDusk
--]] 

--kill any extra instances of the same scene 
if (fibaro:countScenes() > 1) then fibaro:abort() end; 

--Loop 
while true do 

--Settings
local ExecuteTimer = 300; -- Execute Every N-th second 
local GlobalVariablesDevice = 138; -- ID of virtual device
local AbsenceTime = 30; -- 30 minutes 


--Setup local variables 
local CurrentDate = os.date("*t"); 

--Announce start 
fibaro:debug(" -|- Start: "..os.date("%Y-%m-%d %H:%M:%S",os.time())) 

-- LastSeenXXXXXXXX 
fibaro:call(GlobalVariablesDevice, "pressButton", "1"); -- Check if Christian is at Home 
fibaro:call(GlobalVariablesDevice, "pressButton", "2"); -- Check if Desirée is at Home
local LastSeenChristian = 0+fibaro:getGlobal("LastSeenChristian"); 
local LastSeenDesiree = 0+fibaro:getGlobal("LastSeenDesiree");
local LastAutoLitForDusk = 0+fibaro:getGlobal("LastAutoLitForDusk");
fibaro:debug(" -|- LastSeenChristian: "..os.date("%Y-%m-%d %H:%M:%S",LastSeenChristian)); 
fibaro:debug(" -|- LastSeenDesiree: "..os.date("%Y-%m-%d %H:%M:%S",LastSeenDesiree));
fibaro:debug(" -|- LastAutoLitForDusk: "..os.date("%Y-%m-%d %H:%M:%S",LastAutoLitForDusk));

-- Home, anyone ? 
AbsenceTime = os.time() - (AbsenceTime * 60); 
fibaro:debug(" -|- AbsenceTime: "..os.date("%Y-%m-%d %H:%M:%S",AbsenceTime)); 
if tonumber(LastSeenChristian) < AbsenceTime and tonumber(LastSeenDesiree) < AbsenceTime then 
    fibaro:debug(" -|- Home: Nobody is Home!");
      if tonumber(fibaro:getGlobalValue("LastSeenHemma")) == 1 then 
         fibaro:setGlobal("LastSeenHemma", 0);
      end
 
else 
    fibaro:debug(" -|- Home: Someone is at home!");
     if tonumber(fibaro:getGlobalValue("LastSeenHemma")) == 0 then  
        fibaro:setGlobal("LastSeenHemma", 1);
    end 
end 
 
  --Announce end 
fibaro:debug(" -|- End: "..os.date("%Y-%m-%d %H:%M:%S",os.time())) 

--Sleep XX seconds 
fibaro:sleep(ExecuteTimer*1000); 
  
end 