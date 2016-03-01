--[[ NEET Series Version 0.02 ]]--
require('Inspired')
require('IPrediction')
require('OpenPredict')

local NEETS_Update, NEETS_Predict, NEETS_OW = {}, "", ""
    NEETS_Update.ScriptVersion = 0.02
    NEETS_Update.UseHttps = true
    NEETS_Update.Host = "raw.githubusercontent.com"
    NEETS_Update.VersionPath = "/VTNEETS/NEET-Scripts/master/NEETSeries.version"
    NEETS_Update.ScriptPath = "/VTNEETS/NEET-Scripts/master/NEETSeries.lua"
    NEETS_Update.SavePath = SCRIPT_PATH.."/NEETSeries.lua"
    NEETS_Update.CallbackUpdate = function(NewVersion) NEETSeries_Print("Updated to "..NewVersion..". Please F6 x2 to reload.") end
    NEETS_Update.CallbackNoUpdate = function(NewVersion) NEETSeries_Print("You are using Lastest Version ("..NewVersion..")") NEETSeries_Hello() end
    NEETS_Update.CallbackNewVersion = function(NewVersion) NEETSeries_Print("New Version found ("..NewVersion.."). Please wait...") end
    NEETS_Update.CallbackError = function() NEETSeries_Print("Error when checking update. Please try again.") end
    Callback.Add("Load", function() AutoUpdater(NEETS_Update.ScriptVersion, NEETS_Update.UseHttps, NEETS_Update.Host, NEETS_Update.VersionPath, NEETS_Update.ScriptPath, NEETS_Update.SavePath, NEETS_Update.CallbackUpdate, NEETS_Update.CallbackNoUpdate, NEETS_Update.CallbackNewVersion, NEETS_Update.CallbackError) end)
local NEETS_Supported = {
    ["Xerath"] = true
}

local NEETSeries = MenuConfig("NEETS", "NEETSeries Version: "..NEETS_Update.ScriptVersion)
    NEETSeries:DropDown("predict", "Choose Prediction:", 1, {"OpenPredict", "IPrediction", "GoSPrediction"}, function() NEETS_PrintPredict() end)
    NEETSeries:Menu("info", "Current Supported Champ:")
    NEETSeries.info:Info("c1", " - Xerath")
    NEETSeries.info:Info("c2", " - More soon")

   if NEETSeries.predict:Value() == 1 then
    NEETS_Predict = "OpenPredict"
   elseif NEETSeries.predict:Value() == 2 then
    NEETS_Predict = "IPrediction"
   elseif NEETSeries.predict:Value() == 3 then
    NEETS_Predict = "GoSPrediction"
   end
   if _G.mc_cfg_orb.orb:Value() == 1 then
    NEETS_OW = "IOW"
   elseif _G.mc_cfg_orb.orb:Value() == 2 then
    NEETS_OW = "DAC"
   end

--[[ -------------------------------------------------- ]]--

class "NS_Xerath"
function NS_Xerath:__init()
 self:LoadValues()
 self:CreateMenu()
 Callback.Add("Tick", function(myHero) self:Fight(myHero) end)
 Callback.Add("Draw", function() self:Drawings() end)
 Callback.Add("DrawMinimap", function() self:DrawRRange() end)
 Callback.Add("ProcessSpell", function(unit, spell) self:AutoE(unit, spell) self:GetRCount(unit, spell) end)
 Callback.Add("UpdateBuff", function(unit, buff) self:UpdateBuff(unit, buff) end)
 Callback.Add("RemoveBuff", function(unit, buff) self:RemoveBuff(unit, buff) end)
end

function NS_Xerath:LoadValues()
  self.Ignite = (GetCastName(myHero, SUMMONER_1):lower():find("summonerdot") and SUMMONER_1 or (GetCastName(myHero, SUMMONER_2):lower():find("summonerdot") and SUMMONER_2 or nil))
  self.data = function(spell) return myHero:GetSpellData(spell) end
  self.Q = { Range = 0, minRange = 750, maxRange = 1500, Range2 = 0,           Speed = math.huge, Delay = 0.575, Width = 100, Predict = nil, Damage = function(unit) return myHero:CalcMagicDamage(unit, 40 + 40*self.data(_Q).level + 0.75*myHero.ap) end, Charging = false, LastCastTime = 0}
  self.W = { Range = self.data(_W).range,                                      Speed = math.huge, Delay = 0.675, Width = 200, Predict = nil, Damage = function(unit) return myHero:CalcMagicDamage(unit, 30 + 30*self.data(_W).level + 0.6*myHero.ap) end}
  self.E = { Range = self.data(_E).range,                                      Speed = 1200,      Delay = 0.3,   Width = 60,  Predict = nil, Damage = function(unit) return myHero:CalcMagicDamage(unit, 50 + 30*self.data(_E).level + 0.45*myHero.ap) end}
  self.R = { Range = function() return 2000 + 1200*self.data(_R).level end,    Speed = math.huge, Delay = 0.675, Width = 140, Predict = nil, Damage = function(unit) return myHero:CalcMagicDamage(unit, 135 + 55*self.data(_R).level + 0.433*myHero.ap) end, Activating = false, Count = 3, Delay1 = 0, Delay2 = 0, Delay3 = 0}
  QT = TargetSelector(self.Q.maxRange, 8, DAMAGE_MAGIC)
  WT = TargetSelector(self.W.Range, 8, DAMAGE_MAGIC)
  ET = TargetSelector(self.E.Range, 2, DAMAGE_MAGIC)
  self.Q.IPrediction = IPrediction.Prediction({ name = "XerathQ", speed = self.Q.Speed, delay = self.Q.Delay, range = self.Q.maxRange, width = self.Q.Width, collision = false, aoe = true, type = "linear"})
  self.W.IPrediction = IPrediction.Prediction({ name = "XerathW", speed = self.W.Speed, delay = self.W.Delay, range = self.W.Range, width = self.W.Width, collision = false, aoe = true, type = "circular"})
  self.E.IPrediction = IPrediction.Prediction({ name = "XerathE", speed = self.E.Speed, delay = self.E.Delay, range = self.E.Range, width = self.E.Width, collision = true, aoe = false, type = "linear"})
  self.R.IPrediction = IPrediction.Prediction({ name = "XerathR", speed = self.R.Speed, delay = self.R.Delay, range = self.R.Range(), width = self.R.Width, collision = false, aoe = true, type = "circular"})
end

function NS_Xerath:CreateMenu()
 self.cfg = MenuConfig("NS_Xerath", "--> NEETS Xerath <--")

    --[[ Combo Menu ]]--
    self.cfg:Menu("cb", "Combo")
        self.cfg.cb:Boolean("Q", "Use Q", true)
        self.cfg.cb:Boolean("W", "Use W", true)
        self.cfg.cb:Boolean("E", "Use E", true)

    --[[ Harass Menu ]]--
    self.cfg:Menu("hr", "Harass")
        self.cfg.hr:Boolean("Q", "Use Q", true)
        self.cfg.hr:Boolean("W", "Use W", true)
        self.cfg.hr:Boolean("E", "Use E", true)
        self.cfg.hr:Slider("Enable", "Enable if %MP >=", 15, 1, 100, 1)

    --[[ KillSteal Menu ]]--
    self.cfg:Menu("ks", "Kill Steal")
        self.cfg.ks:Boolean("Q", "Use Q", true)
        self.cfg.ks:Boolean("W", "Use W", true)
        self.cfg.ks:Boolean("E", "Use E", true)
        self.cfg.ks:Boolean("ignite", "Use Ignite", true)
        self.cfg.ks:Slider("Enable", "Enable if %MP >=", 15, 1, 100, 1)

    --[[ Ultimate Menu ]]--
    self.cfg:Menu("ult", "Ultimate Settings")
      self.cfg.ult:Menu("use", "Active Mode")
        self.cfg.ult.use:DropDown("mode", "Choose Your Mode:", 1, {"Press R", "Auto Use"})
        self.cfg.ult.use:Info("if1", "Press R: You Must PressR to Enable AutoCasting")
        self.cfg.ult.use:Info("if2", "Auto Use: Auto PresR if find Target Killable")
        self.cfg.ult.use:Info("if3", "Note: It Only Active Ult Not AutoCast")
        self.cfg.ult.use:Info("if3", "Recommend using Press R Mode")
      self.cfg.ult:Menu("cast", "Casting Mode")
        self.cfg.ult.cast:DropDown("mode", "Choose Your Mode:", 1, {"Press Key", "Auto Cast", "Target In Mouse Range"})
        self.cfg.ult.cast:KeyBinding("key", "Seclect Key For PressKey Mode:", string.byte("T"))
        self.cfg.ult.cast:Slider("range", "Range for Target NearMouse", 500, 200, 1500, 50)
        self.cfg.ult.cast:Boolean("draw", "Draw NearMouse Range", true)
        self.cfg.ult.cast:Info("if1", "Press Key: Press a Key everywhere to AutoCast")
        self.cfg.ult.cast:Info("if2", "Auto Cast: AutoCasting Target")
        self.cfg.ult.cast:Info("if3", "Mouse: AutoCast Target In Range NearMouse")
        self.cfg.ult.cast:Info("if4", "Recommend using Press Key")

    --[[ Lane Clear Menu ]]--
    self.cfg:Menu("lc", "Lane Clear")
        self.cfg.lc:Slider("Q", "Use Q if hit Minions >=", 2, 1, 10, 1)
        self.cfg.lc:Slider("W", "Use W if hit Minions >=", 3, 1, 10, 1)
        self.cfg.lc:Slider("Enable", "Enable if %MP >=", 15, 1, 100, 1)

    --[[ Jungle Clear Menu ]]--
    self.cfg:Menu("jc", "Jungle Clear")
        self.cfg.jc:Boolean("Q", "Use Q", true)
        self.cfg.jc:Boolean("W", "Use W", true)
        self.cfg.jc:Boolean("E", "Use E", true)

    --[[ Drawings Menu ]]--
    self.cfg:Menu("dw", "Drawings Mode")
        self.cfg.dw:Boolean("Q", "Draw Q Range", true)
        self.cfg.dw:Boolean("W", "Draw W Range", true)
        self.cfg.dw:Boolean("E", "Draw E Range", true)
        self.cfg.dw:Boolean("R", "Draw R Range Minimap", true)
        self.cfg.dw:Boolean("HB", "Draw Dmg On HP Bar", true)
		self.cfg.dw:Boolean("TK", "Draw Text Target R Killable", true)
        self.cfg.dw:Slider("Qlt", "Range Quality", 55, 1, 100, 1)

    --[[ Misc Menu ]]--
    self.cfg:Menu("misc", "Misc Mode")  
      self.cfg.misc:Menu("castCombo", "Combo Casting")
        self.cfg.misc.castCombo:Info("if", "Only Cast QWE if W or E Ready")
        self.cfg.misc.castCombo:Boolean("WE", "Enable? (default off)", false)
      self.cfg.misc:Menu("hc", "Spell HitChance")
        self.cfg.misc.hc:Slider("Q", "Q Hit-Chance", 25, 1, 100, 1)
        self.cfg.misc.hc:Slider("W", "W Hit-Chance", 25, 1, 100, 1)
        self.cfg.misc.hc:Slider("E", "E Hit-Chance", 30, 1, 100, 1)
        self.cfg.misc.hc:Slider("R", "R Hit-Chance", 40, 1, 100, 1)
      self.cfg.misc:Menu("delay", "R Casting Delays")
        self.cfg.misc.delay:Slider("c1", "Delay CastR 1 (ms)", 200, 0, 1000, 1)
        self.cfg.misc.delay:Slider("c2", "Delay CastR 2 (ms)", 250, 0, 1000, 1)
        self.cfg.misc.delay:Slider("c3", "Delay CastR 3 (ms)", 250, 0, 1000, 1)
      self.cfg.misc:Menu("Interrupt", "Interrupt With E")
      self.cfg.misc:Menu("GapClose", "Anti-GapClose With E")

    DelayAction(function()
    local str = {[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"}
     for i, spell in pairs(CHANELLING_SPELLS) do
      for _,k in pairs(GetEnemyHeroes()) do
       if spell["Name"] == k.charName then
        self.cfg.misc.Interrupt:Boolean(k.charName.."Inter", "On "..k.charName.." "..(type(spell.Spellslot) == 'number' and str[spell.Spellslot]), true)
       end
      end
     end
    end, 1)
    AddGapcloseEvent(_E, self.E.Range, false, self.cfg.misc.GapClose)
end

function NS_Xerath:CastR(target)
    if target == nil then return end
    local hc, Pos, Name = self:RPrediction(target)
    if (Name == "Dashing" and hc == 1) or (Name == "OpenPredict" and hc >= self.cfg.misc.hc.R:Value()/100) or (Name == "IPrediction" and hc > 2) or (Name == "GoSPrediction" and hc >= 1) then
     if self.R.Count == 3 and os.clock() - self.R.Delay1 > self.cfg.misc.delay.c1:Value()/1000 then
      CastSkillShot(_R, Pos)
     elseif self.R.Count == 2 and os.clock() - self.R.Delay2 > self.cfg.misc.delay.c2:Value()/1000 then
      CastSkillShot(_R, Pos)
     elseif self.R.Count == 1 and os.clock() - self.R.Delay3 > self.cfg.misc.delay.c3:Value()/1000 then
      CastSkillShot(_R, Pos)
     end
    end
end

function NS_Xerath:CastQ(target)
   if not ValidTarget(target, self.Q.maxRange) then return end
    if self.Q.Charging == false then
      CastSkillShot(_Q, GetMousePos())
    else
    local hc, Pos, Name = self:QPrediction(target)
     if (Name == "Dashing" and hc == 1) or (Name == "OpenPredict" and hc >= self.cfg.misc.hc.Q:Value()/100) or (Name == "IPrediction" and hc > 2) or (Name == "GoSPrediction" and hc >= 1) then
       if GetDistance(Pos) <= self.Q.Range2 then CastSkillShot2(_Q, Pos) end
     end
    end
end

function NS_Xerath:CastW(target)
   if not ValidTarget(target, self.W.Range) then return end
    local hc, Pos, Name = self:WPrediction(target)
    if (Name == "Dashing" and hc == 1) or (Name == "OpenPredict" and hc >= self.cfg.misc.hc.W:Value()/100) or (Name == "IPrediction" and hc > 2) or (Name == "GoSPrediction" and hc >= 1) then
     CastSkillShot(_W, Pos)
    end
end

function NS_Xerath:CastE(target)
   if not ValidTarget(target, self.E.Range) then return end
    local hc, Pos, CanCast, Name = self:EPrediction(target)
    if (Name == "Dashing" and hc == 1) or (Name == "OpenPredict" and hc >= self.cfg.misc.hc.E:Value()/100) or (Name == "IPrediction" and hc > 2) or (Name == "GoSPrediction" and hc >= 1) then
     if CanCast then CastSkillShot(_E, Pos) end
    end
end

function NS_Xerath:UpdateValues()
    if IsReady(_Q) then
     if self.Q.Charging == false then
      if self.Q.Range ~= self.Q.minRange then self.Q.Range = self.Q.minRange end
      if self.Q.Range2 ~= self.Q.minRange then self.Q.Range2 = self.Q.minRange end
     else
      self.Q.Range = math.min(self.Q.minRange + (os.clock() - self.Q.LastCastTime)*500, self.Q.maxRange)
      self.Q.Range2 = math.min(self.Q.minRange-15 + (os.clock() - self.Q.LastCastTime)*500, self.Q.maxRange)
     end
    end
    if IsReady(_R) then
     if self.R.Activating == false then
      self:CheckRUsing()
	 else
      self:CheckRCasting()
      if EnemiesAround(myHero.pos, 1500) == 0 then
      NEETSeries_BlockOrb(true)
      else
      NEETSeries_BlockOrb(false)
      end
     end
    end
end

function NS_Xerath:CheckRUsing()
   if not IsReady(_R) then return end
    if self.cfg.ult.use.mode:Value() == 2 then
     local target = self:GetRTarget(myHero.pos, self.R.Range())
     if (target.health + target.shieldAD + target.shieldAP) < self.R.Damage(target) * self.R.Count then
      CastSpell(_R)
     end
    end
end

function NS_Xerath:CheckRCasting()
    if self.cfg.ult.cast.mode:Value() < 3 then
    local target = self:GetRTarget(myHero.pos, self.R.Range())
     if self.cfg.ult.cast.mode:Value() == 1 and self.cfg.ult.cast.key:Value() then
      self:CastR(target)
     elseif self.cfg.ult.cast.mode:Value() == 2 then
      self:CastR(target)
     end
    else
    local target = self:GetRTarget(GetMousePos(), self.cfg.ult.cast.range:Value())
      self:CastR(target)
    end
end

function NS_Xerath:GetRCount(unit, spell)
   if not self.R.Activating then return end
    if unit == myHero and spell.name == "xerathlocuspulse" then
    self.R.Count = self.R.Count - 1
     if self.R.Count == 2 then
     self.R.Delay2 = os.clock()
     elseif self.R.Count == 1 then
     self.R.Delay3 = os.clock()
     end
    end
end

function NS_Xerath:Fight(myHero)
   if myHero.dead then return end
    self:UpdateValues()
    if self.R.Activating then return end
    QTarget, WTarget, ETarget = QT:GetTarget(), WT:GetTarget(), ET:GetTarget()
    self.R.Count = 3
    if NEETSeries_Mode("Combo") then
     if self.cfg.misc.castCombo.WE:Value() then
      if IsReady(_W) or IsReady(_E) then
       if IsReady(_E) and self.cfg.cb.E:Value() and ETarget then self:CastE(ETarget) end
       if IsReady(_W) and self.cfg.cb.W:Value() and WTarget then self:CastW(WTarget) end
       if IsReady(_Q) and self.cfg.cb.Q:Value() and QTarget then self:CastQ(QTarget) end
      end
     else
       if IsReady(_E) and self.cfg.cb.E:Value() and ETarget then self:CastE(ETarget) end
       if IsReady(_W) and self.cfg.cb.W:Value() and WTarget then self:CastW(WTarget) end
       if IsReady(_Q) and self.cfg.cb.Q:Value() and QTarget then self:CastQ(QTarget) end
     end

    elseif NEETSeries_Mode("Harass") and self.cfg.hr.Enable:Value() <= GetPercentMP(myHero) then
       if IsReady(_E) and self.cfg.hr.E:Value() and ETarget then self:CastE(ETarget) end
       if IsReady(_W) and self.cfg.hr.W:Value() and WTarget then self:CastW(WTarget) end
       if IsReady(_Q) and self.cfg.hr.Q:Value() and QTarget then self:CastQ(QTarget) end

    elseif NEETSeries_Mode("LaneClear") then
     if self.cfg.lc.Enable:Value() <= GetPercentMP(myHero) then self:LaneClear() end
	 self:JungleClear()
    end

    if self.cfg.ks.Enable:Value() <= GetPercentMP(myHero) then self:KillSteal() end
end

function NS_Xerath:KillSteal()
    for i, enemy in pairs(GetEnemyHeroes()) do	
     if self.Ignite and self.cfg.ks.ignite:Value() and IsReady(self.Ignite) and 20*GetLevel(myHero)+50 > (enemy.health + enemy.shieldAD) + enemy.hpRegen*2.5 and ValidTarget(enemy, 600) then
      CastTargetSpell(enemy, self.Ignite)
     end

     if IsReady(_E) and self.cfg.ks.E:Value() and (enemy.health + enemy.shieldAD + enemy.shieldAP) < self.E.Damage(enemy) then 
      self:CastE(enemy)
     end

     if IsReady(_W) and self.cfg.ks.W:Value() and (enemy.health + enemy.shieldAD + enemy.shieldAP) < self.W.Damage(enemy) then 
      self:CastW(enemy)
     end

     if IsReady(_Q) and self.cfg.ks.Q:Value() and (enemy.health + enemy.shieldAD + enemy.shieldAP) < self.Q.Damage(enemy) then 
      self:CastQ(enemy)
     end
    end
end

function NS_Xerath:LaneClear()
    if IsReady(_W) then
    local WPos, WHit = GetFarmPosition2(self.W.Range, self.W.Width)
       if WHit >= self.cfg.lc.W:Value() then CastSkillShot(_W, WPos) end
    end
    if IsReady(_Q) then
    local QPos, QHit = GetLineFarmPosition2(self.Q.maxRange, self.Q.Width)
     if self.Q.Charging == false then
       if QHit >= self.cfg.lc.Q:Value() then CastSkillShot(_Q, GetMousePos()) end
     else
      if GetDistance(QPos) <= self.Q.Range then
       if QHit >= self.cfg.lc.Q:Value() then CastSkillShot2(_Q, QPos) end
      end
     end
    end
end

function NS_Xerath:JungleClear()
    local mob = NEETS_OW == "IOW" and IOW:GetJungleClear() or NEETS_OW == "DAC" and DAC:GetJungleMob()
     if mob and ValidTarget(mob, self.Q.maxRange, MINION_JUNGLE) then
      if IsReady(_W) and self.cfg.jc.W:Value() and ValidTarget(mob, self.W.Range, MINION_JUNGLE) then
       CastSkillShot(_W, GetCircularAOEPrediction(mob, { delay = self.W.Delay, speed = self.W.Speed, width = self.W.Width, range = self.W.Range }).castPos)
      end
      if IsReady(_E) and self.cfg.jc.E:Value() and ValidTarget(mob, self.E.Range, MINION_JUNGLE) then
       CastSkillShot(_E, GetLinearAOEPrediction(mob, { delay = self.E.Delay, speed = self.E.Speed, width = self.E.Width, range = self.E.Range }).castPos)
      end
      if IsReady(_Q) and self.cfg.jc.Q:Value() and not self.Q.Charging then
       CastSkillShot(_Q, GetMousePos())
      elseif IsReady(_Q) and self.cfg.jc.Q:Value() and self.Q.Charging then
       local QPred = GetLinearAOEPrediction(mob, { delay = self.Q.Delay, speed = self.Q.Speed, width = self.Q.Width, range = self.Q.maxRange })
       if QPred and GetDistance(Vector(QPred.castPos), myHero.pos) <= self.Q.Range then CastSkillShot2(_Q, QPred.castPos) end
      end
     end
end

function NS_Xerath:AutoE(unit, spell)
   if self.R.Activating then return end
    if unit.type == myHero.type and unit.team ~= myHero.team then
     if CHANELLING_SPELLS[spell.name] then
      if ValidTarget(unit, self.E.Range) and unit.charName == CHANELLING_SPELLS[spell.name].Name and self.cfg.misc.Interrupt[unit.charName.."Inter"]:Value() then 
      local pos, CanCast, hc = self:SpellPrediction(_E, unit)
       if CanCast and hc >= self.cfg.misc.hc.E:Value()/100 then myHero:Cast(_E, pos) end
      end
     end
    end
end

function NS_Xerath:Drawings()
   if myHero.dead then return end
   if self.cfg.dw.TK:Value() and IsReady(_R) then self:RKillable() end
   if self.cfg.dw.HB:Value() then self:DmgHPBar() end
   self:DrawRange()
end

function NS_Xerath:RKillable()
    local i = 0
    for i, enemy in pairs(GetEnemyHeroes()) do
     i = i+1
     if ValidTarget(enemy, self.R.Range()) and (enemy.health + enemy.shieldAD + enemy.shieldAP) < self.R.Damage(enemy) * self.R.Count then
      DrawText(enemy.charName.." R Killable", 30, GetResolution().x/80, GetResolution().y/7+i*26, GoS.Red)
     end
    end
end

function NS_Xerath:DrawRRange()
    if not IsReady(_R) then return end
    if self.cfg.dw.R:Value() then DrawCircleMinimap(myHero.pos, self.R.Range(), 1, 120, 0x20FFFF00) end
end

function NS_Xerath:DrawRange()
    local Pos, mPos = myHero.pos, GetMousePos()
    if IsReady(_Q) and self.cfg.dw.Q:Value() then
     DrawCircle3D(Pos.x, Pos.y, Pos.z, self.Q.maxRange, 1, 0x8000F5FF, self.cfg.dw.Qlt:Value())
     DrawCircle3D(Pos.x, Pos.y, Pos.z, self.Q.Range, 1, 0x8000F5FF, self.cfg.dw.Qlt:Value())
    end
    if IsReady(_W) and self.cfg.dw.W:Value() then DrawCircle3D(Pos.x, Pos.y, Pos.z, self.W.Range, 1, 0x80BA55D3, self.cfg.dw.Qlt:Value()) end
    if IsReady(_E) and self.cfg.dw.E:Value() then DrawCircle3D(Pos.x, Pos.y, Pos.z, self.E.Range, 1, 0x8000FFCC, self.cfg.dw.Qlt:Value()) end
    if self.cfg.ult.cast.mode:Value() == 3 and self.R.Activating and self.cfg.ult.cast.draw:Value() then DrawCircle3D(mPos.x, mPos.y, mPos.z, self.cfg.ult.cast.range:Value(), 1, 0xFFFFFF00, self.cfg.dw.Qlt:Value()) end
end

function NS_Xerath:DmgHPBar()
    for i, enemy in pairs(GetEnemyHeroes()) do
     if ValidTarget(enemy, self.R.Range()) then
      if IsReady(_R) then DrawDmgOverHpBar(enemy, enemy.health, 0, math.min(self.R.Damage(enemy) * self.R.Count, enemy.health), ARGB(155, 255, 255, 0)) end
      if IsReady(_Q) then DrawDmgOverHpBar(enemy, enemy.health, 0, math.min(self.Q.Damage(enemy), enemy.health), ARGB(195, 0, 228, 240)) end
      if IsReady(_W) then DrawDmgOverHpBar(enemy, enemy.health, 0, math.min(self.W.Damage(enemy), enemy.health), ARGB(225, 186, 85, 211)) end
      if IsReady(_E) then DrawDmgOverHpBar(enemy, enemy.health, 0, math.min(self.E.Damage(enemy), enemy.health), ARGB(255, 0, 255, 204)) end
     end
    end
end

function NS_Xerath:QPrediction(unit)
   local hitChance, Position, PredictName = 0, nil, ""
   local dash, pos, num = IPrediction.IsUnitDashing(unit, self.Q.maxRange, self.Q.Speed, self.Q.Delay, self.Q.Width)
    if dash == true and pos ~= nil and GetDistance(pos) <= self.Q.maxRange then
      hitChance, Position, PredictName = 1, pos, "Dashing"
    else
     if NEETSeries.predict:Value() == 1 then
      self.Q.Predict = GetLinearAOEPrediction(unit, { delay = self.Q.Delay, speed = self.Q.Speed, width = self.Q.Width, range = self.Q.maxRange })
      hitChance, Position, PredictName = self.Q.Predict.hitChance, self.Q.Predict.castPos, "OpenPredict"
     elseif NEETSeries.predict:Value() == 2 then
      self.Q.Predict = self.Q.IPrediction
      hitChance, Position = self.Q.Predict:Predict(unit)
      PredictName = "IPrediction"
     elseif NEETSeries.predict:Value() == 3 then
      self.Q.Predict = GetPredictionForPlayer(myHero.pos, unit, unit.ms, self.Q.Speed, self.Q.Delay*100, self.Q.maxRange, self.Q.Width, false, true)
      hitChance, Position, PredictName = self.Q.Predict.HitChance, self.Q.Predict.PredPos, "GoSPrediction"
     end
    end
    return hitChance, Position, PredictName
end

function NS_Xerath:WPrediction(unit)
   local hitChance, Position, PredictName = 0, nil, ""
   local dash, pos, num = IPrediction.IsUnitDashing(unit, self.W.Range, self.W.Speed, self.W.Delay, self.W.Width)
    if dash == true and pos ~= nil and GetDistance(pos) <= self.W.Range then
     hitChance, Position, PredictName = 1, pos, "Dashing"
    else
     if NEETSeries.predict:Value() == 1 then
      self.W.Predict = GetCircularAOEPrediction(unit, { delay = self.W.Delay, speed = self.W.Speed, radius = self.W.Width/2, range = self.W.Range })
      hitChance, Position, PredictName = self.W.Predict.hitChance, self.W.Predict.castPos, "OpenPredict"
     elseif NEETSeries.predict:Value() == 2 then
      self.W.Predict = self.W.IPrediction
      hitChance, Position = self.W.Predict:Predict(unit)
      PredictName = "IPrediction"
     elseif NEETSeries.predict:Value() == 3 then
      self.W.Predict = GetPredictionForPlayer(myHero.pos, unit, unit.ms, self.W.Speed, self.W.Delay*100, self.W.Range, self.W.Width, false, true)
      hitChance, Position, PredictName = self.W.Predict.HitChance, self.W.Predict.PredPos, "GoSPrediction"
     end
    end
    return hitChance, Position, PredictName
end

function NS_Xerath:EPrediction(unit)
   local hitChance, Position, CanCast, PredictName = 0, nil, false, ""
   local dash, pos, num = IPrediction.IsUnitDashing(unit, self.E.Range, self.E.Speed, self.E.Delay, self.E.Width)
    if dash == true and pos ~= nil and GetDistance(pos) <= self.E.Range then
      hitChance, Position, CanCast, PredictName = 1, pos, true, "Dashing"
    else
     if NEETSeries.predict:Value() == 1 then
      self.E.Predict = GetPrediction(unit, { delay = self.E.Delay, speed = self.E.Speed, width = self.E.Width, range = self.E.Range })
      if not self.E.Predict:mCollision(1) then
      hitChance, Position, CanCast, PredictName = self.E.Predict.hitChance, self.E.Predict.castPos, true, "OpenPredict"
      else
      hitChance, Position, CanCast, PredictName = self.E.Predict.hitChance, self.E.Predict.castPos, false, "OpenPredict"
      end
     elseif NEETSeries.predict:Value() == 2 then
      self.E.Predict = self.E.IPrediction
      hitChance, Position = self.E.Predict:Predict(unit)
      CanCast, PredictName =  true, "IPrediction"
     elseif NEETSeries.predict:Value() == 3 then
      self.E.Predict = GetPredictionForPlayer(myHero.pos, unit, unit.ms, self.E.Speed, self.E.Delay*100, self.E.Range, self.E.Width, true, false)
      hitChance, Position, CanCast, PredictName = self.E.Predict.HitChance, self.E.Predict.PredPos, true, "GoSPrediction"
     end
    end
    return hitChance, Position, CanCast, PredictName
end

function NS_Xerath:RPrediction(unit)
   local hitChance, Position, PredictName = 0, nil, ""
   local dash, pos, num = IPrediction.IsUnitDashing(unit, self.R.Range(), self.R.Speed, self.R.Delay, self.R.Width)
    if dash == true and pos ~= nil and GetDistance(pos) <= self.R.Range() then
     hitChance, Position, PredictName = 1, pos, "Dashing"
    else
     if NEETSeries.predict:Value() == 1 then
      self.R.Predict = GetCircularAOEPrediction(unit, { delay = self.R.Delay, speed = self.R.Speed, radius = self.R.Width/2, range = self.R.Range() })
      hitChance, Position, PredictName = self.R.Predict.hitChance, self.R.Predict.castPos, "OpenPredict"
     elseif NEETSeries.predict:Value() == 2 then
      self.R.Predict = self.R.IPrediction
      hitChance, Position = self.R.Predict:Predict(unit)
      PredictName = "IPrediction"
     elseif NEETSeries.predict:Value() == 3 then
      self.R.Predict = GetPredictionForPlayer(myHero.pos, unit, unit.ms, self.R.Speed, self.R.Delay*100, self.R.Range(), self.R.Width, false, true)
      hitChance, Position, PredictName = self.R.Predict.HitChance, self.R.Predict.PredPos, "GoSPrediction"
     end
    end
    return hitChance, Position, PredictName
end

function NS_Xerath:GetRTarget(pos, range)
    local RTarget = nil
     for i, enemy in pairs(GetEnemyHeroes()) do
      if ValidTarget(enemy, 2000 + 1200*myHero:GetSpellData(_R).level) and GetDistanceSqr(pos, enemy) <= range * range then
       if RTarget == nil then
                 RTarget = enemy
       elseif enemy.health - self.R.Damage(enemy) * self.R.Count < RTarget.health - self.R.Damage(RTarget) * self.R.Count then
                 RTarget = enemy
       end
      end
     end
    return RTarget
end

function GetLineFarmPosition2(range, width)
    local Pos, Hit = nil, 0
    for i, minion in pairs(minionManager.objects) do
     if ValidTarget(minion, range, MINION_ENEMY) and minion.team == MINION_ENEMY then
      if Pos == nil then
       Pos = Vector(minion)
      elseif CountObjectsOnLineSegment(Vector(myHero), Pos, width, minionManager.objects, MINION_ENEMY) < CountObjectsOnLineSegment(Vector(myHero), Vector(minion), width, minionManager.objects, MINION_ENEMY) then
       Pos = Vector(minion)
      end
     end
    end
    Hit = CountObjectsOnLineSegment(Vector(myHero), Vector(Pos), width, minionManager.objects, MINION_ENEMY)
    return Pos, Hit
end

function GetFarmPosition2(range, width)
    local Pos, Hit = nil, 0
    for i, minion in pairs(minionManager.objects) do
     if ValidTarget(minion, range, MINION_ENEMY) and minion.team == MINION_ENEMY then
      if Pos == nil then
       Pos = Vector(minion)
      elseif MinionsAround(Pos, width, MINION_ENEMY) < MinionsAround(Vector(minion), width, MINION_ENEMY) then
       Pos = Vector(minion)
      end
     end
    end
    Hit = MinionsAround(Pos, width, MINION_ENEMY)
    return Pos, Hit
end

function NS_Xerath:UpdateBuff(unit, buff)
    if unit == myHero and unit.dead == false then
     if buff.Name == "XerathArcanopulseChargeUp" then
      self.Q.LastCastTime = os.clock()
      self.Q.Charging = true
     elseif buff.Name == "XerathLocusOfPower2" then
      self.R.Delay1 = os.clock()
      self.R.Activating = true
     end
    end
end

function NS_Xerath:RemoveBuff(unit, buff)
    if unit == myHero and unit.dead == false then
     if buff.Name == "XerathArcanopulseChargeUp" then
      self.Q.Charging = false
     elseif buff.Name == "XerathLocusOfPower2" then
      self.R.Activating = false
      self.R.Count = 3
      NEETSeries_BlockOrb(false)
     end
    end
end

function NEETSeries_Mode(mode)
    if NEETS_OW == "IOW" then
     if mode == "Combo" then
      return IOW:Mode() == "Combo"
     elseif mode == "Harass" then
      return IOW:Mode() == "Harass"
     elseif mode == "LaneClear" then
      return IOW:Mode() == "LaneClear"
     elseif mode == "LastHit" then
      return IOW:Mode() == "LastHit"
     end
    elseif NEETS_OW == "DAC" then
     if mode == "Combo" then
      return DAC:Mode() == "Combo"
     elseif mode == "Harass" then
      return DAC:Mode() == "Harass"
     elseif mode == "LaneClear" then
      return DAC:Mode() == "LaneClear"
     elseif mode == "LastHit" then
      return DAC:Mode() == "LastHit"
     end
    end
end

function NEETSeries_BlockOrb(boolean)
    if boolean == true then
     if NEETS_OW == "IOW" then
      IOW.attacksEnabled = false
      IOW.movementEnabled = false
     elseif NEETS_OW == "DAC" then
      DAC:MovementEnabled(false) 
      DAC:AttacksEnabled(false)
     end
    else
     if NEETS_OW == "IOW" then
      IOW.attacksEnabled = true
      IOW.movementEnabled = true
     elseif NEETS_OW == "DAC" then
      DAC:MovementEnabled(true) 
      DAC:AttacksEnabled(true)
     end
    end
end

function NEETSeries_Print(text)
	return PrintChat(string.format("<font color=\"#4169E1\"><b>[NEET Series]:</b></font><font color=\"#FFFFFF\"> %s</font>",tostring(text)))
end

function NEETSeries_Hello()
    if NEETS_Supported[myHero.charName] ~= true then return end
    PrintChat(string.format("<font color=\"#4169E1\"><b>[NEET Series]:</b></font><font color=\"#FFFFFF\"><i> Load Successfully</i> | Good Luck <u>%s</u></font>",GetUser()))
	PrintChat(string.format("<font color=\"#4169E1\"><b>[NEET Series]:</b></font><font color=\"#FFFFFF\"> Current Champ: %s | Prediction: %s | Orbwalker: %s</font>", myHero.charName, NEETS_Predict, NEETS_OW))
end

function NEETS_PrintPredict()
local Prediction = NEETSeries.predict:Value() == 1 and "OpenPredict" or NEETSeries.predict:Value() == 2 and "IPrediction" or NEETSeries.predict:Value() == 3 and "GoSPrediction"
    NEETSeries_Print("Changed Prediction to: "..Prediction)
end

if myHero.charName == "Xerath" then
    NS_Xerath()
else
    NEETSeries_Print("Not Supported For "..myHero.charName) return
end
