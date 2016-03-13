--[[ Mix Lib Version 0.01 ]]--
require('Inspired')
require('IPrediction')
local MixLibVersion = 0.01

    Mix = MenuConfig("MixLib", "MixLib - Version "..MixLibVersion)
    Mix:DropDown("predict", "Choose Prediction:", 1, {"OpenPredict", "IPrediction", "GoSPrediction"}, function() Mix_PrintPredict() end)
    Mix:Menu("ifo", "Some Information")
    Mix.ifo:Info("if1", "Your LoL Version: "..GetGameVersion())

    pv, owv = Mix.predict:Value(), _G.mc_cfg_orb.orb:Value()
    _G.Mix_Predict = pv == 1 and "OpenPredict" or pv == 2 and "IPrediction" or pv == 3 and "GoSPrediction"
    _G.Mix_OW = owv == 1 and "IOW" or owv == 2 and "DAC" or (_G.PW_Loaded == true or _G.PW_Init == true) and "PW"
    if Mix_Predict == "OpenPredict" and FileExist(COMMON_PATH.."/OpenPredict.lua") then require('OpenPredict') end
    Mix.ifo:Info("if2", "Current Prediction: "..Mix_Predict)
    Mix.ifo:Info("if3", "Current OrbWalker: "..Mix_OW)

function Mix_SpellPredict1(unit, spellData, IPred)
   local hitChance, Position, PredictName = 0, nil, ""
   local Pred = nil
   local dash, pos, num = IPrediction.IsUnitDashing(unit, spellData.range, spellData.speed, spellData.delay, spellData.width)
    if dash == true and pos ~= nil and GetDistance(pos) <= spellData.range then
      Position, PredictName = pos, "Dashing"
    else
     if Mix_Predict == "OpenPredict" then
      Pred = spellData.type == "circular" and GetCircularAOEPrediction(unit, spellData) or spellData.type == "linear" and GetLinearAOEPrediction(unit, spellData) or spellData.type == "cone" and GetConicAOEPrediction(unit, spellData)
      hitChance, Position, PredictName = Pred.hitChance, Pred.castPos, "OpenPredict"
     elseif Mix_Predict == "IPrediction" then
      Pred = IPred
      hitChance, Position = Pred:Predict(unit)
      PredictName = "IPrediction"
     elseif Mix_Predict == "GoSPrediction" then
      Pred = GetPredictionForPlayer(myHero.pos, unit, unit.ms, spellData.speed, spellData.delay*1000, spellData.range, spellData.width, false, true)
      hitChance, Position, PredictName = Pred.HitChance, Pred.PredPos, "GoSPrediction"
     end
    end
    return hitChance, Position, PredictName
end

function Mix_SpellPredict2(unit, spellData, IPred)
   local hitChance, Position, CanCast, PredictName = 0, nil, false, ""
   local Pred = nil
   local dash, pos, num = IPrediction.IsUnitDashing(unit, spellData.range, spellData.speed, spellData.delay, spellData.width)
    if dash == true and pos ~= nil and GetDistance(pos) <= spellData.range then
      Position, PredictName = pos, "Dashing"
      CanCast = CountObjectsOnLineSegment(Vector(myHero), pos, spellData.width, minionManager.objects, MINION_ENEMY) + CountObjectsOnLineSegment(Vector(myHero), pos, spellData.width, minionManager.objects, MINION_JUNGLE) == 0 and true or false
    else
     if Mix_Predict == "OpenPredict" then
      Pred = GetPrediction(unit, spellData)
      if not Pred:mCollision(spellData.coll) then
      hitChance, Position, CanCast, PredictName = Pred.hitChance, Pred.castPos, true, "OpenPredict"
      else
      hitChance, Position, CanCast, PredictName = Pred.hitChance, Pred.castPos, false, "OpenPredict"
      end
     elseif Mix_Predict == "IPrediction" then
      Pred = IPred
      hitChance, Position = Pred:Predict(unit)
      CanCast, PredictName =  true, "IPrediction"
     elseif Mix_Predict == "GoSPrediction" then
      Pred = GetPredictionForPlayer(myHero.pos, unit, unit.ms, spellData.speed, spellData.delay*1000, spellData.range, spellData.width, true, false)
      hitChance, Position, CanCast, PredictName = Pred.HitChance, Pred.PredPos, true, "GoSPrediction"
     end
    end
    return hitChance, Position, CanCast, PredictName
end

function Mix_SpellPredict3(unit, slot, spellData, IPred)
   local hitChance, Position, PredictName = 0, nil, ""
   local Pred = nil
   local dash, pos, num = IPrediction.IsUnitDashing(unit, spellData.range, spellData.speed, spellData.delay, spellData.width)
    if dash == true and pos ~= nil and GetDistance(pos) <= spellData.range then
     Position, PredictName = pos, "Dashing"
    else
     if Mix_Predict == "OpenPredict" then
      Pred = spellData.type == "circular" and GetCircularAOEPrediction(unit, spellData) or spellData.type == "linear" and GetLinearAOEPrediction(unit, spellData) or spellData.type == "cone" and GetConicAOEPrediction(unit, spellData)
      hitChance, Position, PredictName = Pred.hitChance, Pred.castPos, "OpenPredict"
     elseif Mix_Predict == "IPrediction" then
      Pred = IPred[myHero:GetSpellData(slot).level]
      hitChance, Position = Pred:Predict(unit)
      PredictName = "IPrediction"
     elseif Mix_Predict == "GoSPrediction" then
      Pred = GetPredictionForPlayer(myHero.pos, unit, unit.ms, spellData.speed, spellData.delay*1000, spellData.range, spellData.width, false, true)
      hitChance, Position, PredictName = Pred.HitChance, Pred.PredPos, "GoSPrediction"
     end
    end
    return hitChance, Position, PredictName
end

function Mix_GetHealthPrediction(unit, time, hpname)
    if name == "GoS" then
        return GetDamagePrediction(unit, time)
    elseif name == "OP" then
        return GetHealthPrediction(unit, time)
    elseif name == "OW" then
      if Mix_OW == "IOW" then
        return IOW:PredictHealth(unit, time)
      elseif Mix_OW == "DAC" then
        return DAC:PredictHealth(unit, time)
      elseif Mix_OW == "PW" then
        return PW:PredictHealth(unit, time)
      end
    end
end

function Mix_GetMob()
    if Mix_OW == "IOW" then
        return IOW:GetJungleClear()
    elseif Mix_OW == "DAC" then
        return DAC:GetJungleMob()
    elseif Mix_OW == "PW" then
        return PW:GetJungleClear()
    end
end

function Mix_Mode()
    if Mix_OW == "IOW" then
      if IOW:Mode() == "Combo" then return "Combo"
      elseif IOW:Mode() == "Harass" then return "Harass"
      elseif IOW:Mode() == "LaneClear" then return "LaneClear"
      elseif IOW:Mode() == "LastHit" then return "LastHit"
      end
    elseif Mix_OW == "DAC" then
      if DAC:Mode() == "Combo" then return "Combo"
      elseif DAC:Mode() == "Harass" then return "Harass"
      elseif DAC:Mode() == "LaneClear" then return "LaneClear"
      elseif DAC:Mode() == "LastHit" then return "LastHit"
      end
    elseif Mix_OW == "PW" then
      if PW:Mode() == "Combo" then return "Combo"
      elseif PW:Mode() == "Harass" then return "Harass"
      elseif PW:Mode() == "LaneClear" then return "LaneClear"
      elseif PW:Mode() == "LastHit" then return "LastHit"
      end
    end
        return "NotActive"
end

function Mix_BlockOrb(boolean)
    if boolean == true then
        Mix_BlockAttack(true)
        Mix_BlockMove(true)
    elseif boolean == false then
        Mix_BlockAttack(false)
        Mix_BlockMove(false)
    end
end

function Mix_BlockAttack(boolean)
    if boolean == true then
      if Mix_OW == "IOW" then
        IOW.attacksEnabled = false
      elseif Mix_OW == "DAC" then
        DAC:AttacksEnabled(false)
      elseif Mix_OW == "PW" then
        PW.attacksEnabled = false
      end
    elseif boolean == false then
      if Mix_OW == "IOW" then
        IOW.attacksEnabled = true
      elseif Mix_OW == "DAC" then
        DAC:AttacksEnabled(true)
      elseif Mix_OW == "PW" then
        PW.attacksEnabled = true
      end
    end
end

function Mix_BlockMove(boolean)
    if boolean == true then
      if Mix_OW == "IOW" then
        IOW.movementEnabled = false
      elseif Mix_OW == "DAC" then
        DAC:MovementEnabled(false)
      elseif Mix_OW == "PW" then
        PW.movementEnabled = false
      end
    elseif boolean == false then
      if Mix_OW == "IOW" then
        IOW.movementEnabled = true
      elseif Mix_OW == "DAC" then
        DAC:MovementEnabled(true)
      elseif Mix_OW == "PW" then
        PW.movementEnabled = true
      end
    end
end

function Mix_Print(text)
	return PrintChat(string.format("<font color=\"#4169E1\"><b>[Mix Lib]:</b></font><font color=\"#FFFFFF\"> %s</font>",tostring(text)))
end

function Mix_Hello()
    Mix_Print("MixLib(Library collection) "..NewVersion.." Loaded")
	PrintChat(string.format("<font color=\"#4169E1\"><b>[Mix Lib]:</b></font><font color=\"#FFFFFF\"> Current Prediction: %s | Orbwalker: %s</font>", Mix_Predict, Mix_OW))
end

function Mix_PrintPredict()
   local Prediction = Mix.predict:Value() == 1 and "OpenPredict" or Mix.predict:Value() == 2 and "IPrediction" or Mix.predict:Value() == 3 and "GoSPrediction"
    Mix_Print("Prediciton has been changed to: "..Prediction..". x2 F6 to apply changes.")
end

local MixLib_Update = {}
    MixLib_Update.ScriptVersion = MixLibVersion
    MixLib_Update.UseHttps = true
    MixLib_Update.Host = "raw.githubusercontent.com"
    MixLib_Update.VersionPath = "/VTNEETS/NEET-Scripts/master/MixLib.version"
    MixLib_Update.ScriptPath = "/VTNEETS/NEET-Scripts/master/MixLib.lua"
    MixLib_Update.SavePath = COMMON_PATH.."/MixLib.lua"
    MixLib_Update.CallbackUpdate = function(NewVersion) Mix_Print("Updated to "..NewVersion..". Please F6 x2 to reload.") end
    MixLib_Update.CallbackNoUpdate = function(NewVersion) Mix_Hello() end
    MixLib_Update.CallbackNewVersion = function(NewVersion) Mix_Print("New Version found ("..NewVersion.."). Please wait...") end
    MixLib_Update.CallbackError = function() Mix_Print("Error when checking update. Please try again.") end
    Callback.Add("Load", function() AutoUpdater(MixLib_Update.ScriptVersion, MixLib_Update.UseHttps, MixLib_Update.Host, MixLib_Update.VersionPath, MixLib_Update.ScriptPath, MixLib_Update.SavePath, MixLib_Update.CallbackUpdate, MixLib_Update.CallbackNoUpdate, MixLib_Update.CallbackNewVersion, MixLib_Update.CallbackError) end)
