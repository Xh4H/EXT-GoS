local AvVersion = "0.0.2"

local function GetVersion(name)
	local file = ""
	file = io.open(COMMON_PATH..name, "rb")
	if not file then return end
	local content = file:read "*all"
	file:close()
	return tostring(content) or AvVersion
end

local function Update()
	DownloadFileAsync("http://www.asyncext.xyz/scripts/AsyncVeigar/AsyncVeigar.lua", COMMON_PATH.."AsyncVeigar.lua", function() end)
	print("AsyncVeigar - SCRIPT HAS BEEN UPDATED. ||||||||||| PLEASE RESTART. |||||||||||")
	return
end


--print(GetWebResultAsync("http://www.asyncext.xyz/scripts/AsyncVeigar/AsyncVeigarV.c"))

if not FileExist(COMMON_PATH.."Collision.lua") then
	error("Collision file is missing.")
	--DownloadFileAsync("https://raw.githubusercontent.com/Maxxxel/GOS/master/ext/Common/Collision.lua", COMMON_PATH.."Collision.lua", function() end)
	return
end

if not FileExist(COMMON_PATH.."Callbacks.lua") then
	error("Callbacks file is missing.")
	return
end

--DownloadFileAsync("http://www.asyncext.xyz/scripts/AsyncVeigar/AsyncVeigarV.c", COMMON_PATH.."AsyncVeigarV.c", function() DelayAction()(function() print("Downloaded") end,.1) end)

--[[DelayAction(function() 
	if AvVersion < GetVersion("AsyncVeigarV.c") then
		--Update()
	end
end, 0.15)

]]
require("Collision")
require("DamageLib")
require("Callbacks")["Load"]({"levelup"})

local Prior = {} -- todo

local function Main()
	return myHero.charName == "Veigar" and Veigar() or print("AsyncVeigar -- This script will only work with Veigar. Please unload this script.")
end

function GetTarget(range)
    for i = 1,Game.HeroCount() do
        local unit = Game.Hero(i)
        if ValidTarget(unit, range) and unit.team ~= myHero.team then
            return unit
        end
    end
end

local _OnVision = {}
function OnVision(unit)
	if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.visible , tick = GetTickCount(), pos = unit.pos} end
	if _OnVision[unit.networkID].state == true and not unit.visible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = GetTickCount() end
	if _OnVision[unit.networkID].state == false and unit.visible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = GetTickCount() end
	return _OnVision[unit.networkID]
end

local visionTick = GetTickCount()
function OnVisionF()
	if GetTickCount() - visionTick > 100 then
		for i,v in pairs(GetEnemyHeroes()) do
			OnVision(v)
		end
	end
end

function GetDistance(p1, p2)
	return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2) + math.pow((p2.z - p1.z),2))
end

local function GetDistance2D(p1, p2)
	return math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2))
end

function GetDistanceSqr(Pos1, Pos2)
	local Pos2 = Pos2 or myHero.pos
	local dx = Pos1.x - Pos2.x
	local dz = (Pos1.z or Pos1.y) - (Pos2.z or Pos2.y)
	return dx^2 + dz^2
end

local _OnWaypoint = {}
function OnWaypoint(unit)
	if not unit then return end
	if _OnWaypoint[unit.networkID] == nil then _OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
	if _OnWaypoint[unit.networkID].pos ~= unit.posTo then 
		-- print("OnWayPoint:"..unit.charName.." | "..math.floor(Game.Timer()))
		_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
			DelayAction(function()
				local time = (Game.Timer() - _OnWaypoint[unit.networkID].time)
				if _OnWaypoint[unit.networkID].startPos and unit.pos and _OnWaypoint[unit.networkID].time then
					local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
					if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
						_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
					end
				end
			end,0.05)
	end
	return _OnWaypoint[unit.networkID]
end

function GetPred(unit,speed,delay)
	local speed = speed or math.huge
	local delay = delay or 0.25
	local unitSpeed = unit.ms
	if OnWaypoint(unit).speed > unitSpeed then unitSpeed = OnWaypoint(unit).speed end
	if OnVision(unit).state == false then
		local unitPos = unit.pos + Vector(unit.pos,unit.posTo):Normalized() * ((GetTickCount() - OnVision(unit).tick)/1000 * unitSpeed)
		local predPos = unitPos + Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unitPos)/speed)))
		if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
		return predPos
	else
		if unitSpeed > unit.ms then
			local predPos = unit.pos + Vector(OnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unit.pos)/speed)))
			if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
			return predPos
		elseif IsImmobileTarget(unit) then
			return unit.pos
		else
			return unit:GetPrediction(speed,delay)
		end
	end
end

function GetBuffs(unit)
	local t = {}
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.count > 0 then
			table.insert(t, buff)
		end
	end
	return t
end

function getLifePercentage(unit)
	return 100 * unit.health / unit.maxHealth
end

function getManaPercentage(unit)
	return 100 * unit.mana / unit.mana
end

function GetLife(unit)
	return unit.health  + (unit.shieldAP or 0)
end

function IsImmune(unit)
	for i, buff in pairs(GetBuffs(unit)) do
		if (buff.name == "KindredRNoDeathBuff" or buff.name == "UndyingRage") and getLifePercentage(unit) <= 10 then
			return true
		end
		if buff.name == "VladimirSanguinePool" or buff.name == "JudicatorIntervention" then 
			return true
		end
	end
	return false
end

function IsImmobileTarget(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 then
			return true
		end
	end
	return false	
end

function VectorPointProjectionOnLineSegment(v1, v2, v)
	local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
    local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
    local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
    local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
    local isOnSegment = rS == rL
    local pointSegment = isOnSegment and pointLine or {x = ax + rS * (bx - ax), y = ay + rS * (by - ay)}
	return pointSegment, pointLine, isOnSegment
end

function MinionsOnLine(startpos, endpos, width, team)
	local Count = 0
	for i = 1, Game.MinionCount() do
		local m = Game.Minion(i)
		if m and m.team == team and not m.dead then
			local w = width + m.boundingRadius
			local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(startpos, endpos, m.pos)
			if isOnSegment and GetDistanceSqr(pointSegment, m.pos) < w^2 and GetDistanceSqr(startpos, endpos) > GetDistanceSqr(startpos, m.pos) then
				Count = Count + 1
			end
		end
	end
	return Count
end

function MinionsAround(pos, range, team)
	local Count = 0
	for i = 1, Game.MinionCount() do
		local m = Game.Minion(i)
		if m and m.team == team and not m.dead and GetDistance(pos, m.pos) <= range then
			Count = Count + 1
		end
	end
	return Count
end

function GetBestCircularFarmPos(range, radius)
	local BestPos = nil
	local MostHit = 0
	for i = 1, Game.MinionCount() do
		local m = Game.Minion(i)
		if m and m.isEnemy and not m.dead and GetDistance(m.pos, myHero.pos) <= range then
			local Count = MinionsAround(m.pos, radius, m.team)
			if Count > MostHit then
				MostHit = Count
				BestPos = m.pos
			end
		end
	end
	return BestPos, MostHit
end

function GetBestLinearFarmPos(range, width)
	local BestPos = nil
	local MostHit = 0
	for i = 1, Game.MinionCount() do
		local m = Game.Minion(i)
		if m and m.isEnemy and not m.dead then
			local EndPos = myHero.pos + (m.pos - myHero.pos):Normalized() * range
			local Count = MinionsOnLine(myHero.pos, EndPos, width, m.team)
			if Count > MostHit then
				MostHit = Count
				BestPos = m.pos
			end
		end
	end
	return BestPos, MostHit
end

function ValidTarget(unit, range)
	if unit == nil or not unit.valid or not unit.visible or unit.dead or not unit.isTargetable or IsImmune(unit) then 
		return false 
	end 
	return unit.pos:DistanceTo(myHero.pos) < range 
end



class "Veigar"

function Veigar:__init()
	self.ready = function(spellIndex) 
		return myHero:GetSpellData(spellIndex).currentCd == 0 and myHero:GetSpellData(spellIndex).level > 0
	end;
	self.ignite = "";
	self.__ignite = myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and {[1] = SUMMONER_1, [2] = HK_SUMMONER_1} or myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and {[1] = SUMMONER_2, [2] = HK_SUMMONER_2} or nil;
	do
		if self.__ignite then
			self.ignite = {true, self.__ignite[1], self.__ignite[2]}
		else
			self.ignite = {false}
		end
	end;
	self.spells = {"Q", "W", "E", "R"}
	self.spell = {
		["_Q"] = {
			currentCd = 0,
			minSpeed = 3.4028234663853e+038,
			coneDistance = 100,
			coneAngle = 45,
			ammoTime = 0,
			speed = 1200,
			ammoCurrentCd = 0,
			range = 900,
			castTime = 0,
			width = 70,
			toggleState = 0,
			ammo = 0,
			ammoCd = 0,
			acceleration = 0,
			name = "VeigarBalefulStrike",
			maxSpeed = 3.4028234663853e+038,
			level = function() return (myHero:GetSpellData(_Q).level) end,
			castFrame = 1.9800000190735,
			targetingType = 1836639352,
			cd = 0,
			mana = function() return (myHero:GetSpellData(_Q).mana) end,
		},
		["_W"] = {
			currentCd = 0,
			minSpeed = 3.4028234663853e+038,
			coneDistance = 100,
			coneAngle = 45,
			ammoTime = 0,
			speed = 20,
			ammoCurrentCd = 0,
			range = 900,
			castTime = 0,
			width = 0,
			toggleState = 0,
			ammo = 0,
			ammoCd = 0,
			acceleration = 0,
			name = "VeigarDarkMatter",
			maxSpeed = 3.4028234663853e+038,
			level = function() return (myHero:GetSpellData(_W).level) end,
			castFrame = 13,
			targetingType = 1836639352,
			cd = 0,
			mana = function() return (myHero:GetSpellData(_W).mana) end,
		},
		["_E"] = {
			currentCd = 0,
			minSpeed = 3.4028234663853e+038,
			coneDistance = 100,
			coneAngle = 45,
			ammoTime = 0,
			speed = 20,
			ammoCurrentCd = 0,
			range = 725,
			castTime = 0,
			width = 0,
			toggleState = 0,
			ammo = 0,
			ammoCd = 0,
			acceleration = 0,
			name = "VeigarEventHorizon",
			maxSpeed = 3.4028234663853e+038,
			level = function() return (myHero:GetSpellData(_E).level) end,
			castFrame = 20.159999847412,
			targetingType = 1836639352,
			cd = 0,
			mana = function() return (myHero:GetSpellData(_E).mana) end,
		},
		["_R"] = {
			currentCd = 0,
			minSpeed = 500,
			coneDistance = 100,
			coneAngle = 45,
			ammoTime = 0,
			speed = 500,
			ammoCurrentCd = 0,
			range = 650,
			castTime = 0,
			width = 0,
			toggleState = 0,
			ammo = 0,
			ammoCd = 0,
			acceleration = 4000,
			name = "VeigarR",
			maxSpeed = 4000,
			level = function() return (myHero:GetSpellData(_R).level) < 4 and myHero:GetSpellData(_R).level end,
			castFrame = 7.960000038147,
			targetingType = 1836639352,
			cd = 0,
			mana = function() return (myHero:GetSpellData(_R).mana) end,
			damage = function(hero, target) return (({175, 250, 325})[myHero:GetSpellData(_R).level])*(hero.ap*0.75)+(1)
		},
		["Flash"] = {
			width = 0,
			ammoCd = 0,
			coneAngle = 45,
			maxSpeed = 3.4028234663853e+038,
			currentCd = 0,
			ammoTime = 0,
			minSpeed = 3.4028234663853e+038,
			mana = 0,
			level = 1,
			cd = 15,
			targetingType = 1836639352,
			acceleration = 0,
			range = 425,
			ammo = 0,
			speed = 0,
			castFrame = 10,
			toggleState = 0,
			coneDistance = 100,
			name = "SummonerFlash",
			ammoCurrentCd = 0,
			castTime = 15,
		},
		["Ignite"] = {
			width = 0,
			ammoCd = 0,
			coneAngle = 45,
			maxSpeed = 828.5,
			currentCd = 0,
			ammoTime = 0,
			minSpeed = 828.5,
			mana = 0,
			level = 1,
			cd = 15,
			targetingType = 1836639352,
			acceleration = 0,
			range = 600,
			ammo = 0,
			speed = 828.5,
			castFrame = 5.1700000762939,
			toggleState = 0,
			coneDistance = 100,
			name = "SummonerDot",
			ammoCurrentCd = 0,
			castTime = 15,
		}
	};
	self.qCollision = Collision:SetSpell(self.spell["_Q"].range, self.spell["_Q"].speed, 0.25, self.spell["_Q"].width, true)
	self:Menu()
end

--[[
-- Auto Q mana > 50% -- Hecho
-- Si se puede matar con Q no usar R  - Hecho
-- Si Tiempo W es inferior a stun entonces usar W - Hecho
]]

function Veigar:_()
	return { 
		["Ignite"] = function()
			if self.ignite[1] or myHero:GetSpellData(__ignite).currentCd <= 16 then
				if self.Menu._COMBO._IGNITE == nil then
					self.Menu._COMBO:MenuElement{
						id = "_IGNITE", 
						name = "Ignite configs.", 
						type = MENU
					};
				end 
				if self.Menu._COMBO._IGNITE.ignBool == nil then
					self.Menu._COMBO._IGNITE:MenuElement{ -- IGNITE BOOLEAN
						id = "ignBool", 
						name = "Use Ignite on combo", 
						value = true,
						onclick = function() self:_()["Ignite"]() end
					};
				end 
				if self.Menu._COMBO._IGNITE.ignBool:Value() == true then
					self.Menu._COMBO._IGNITE:MenuElement{ -- IGNITE HP Slider
						id = "ignLife", 
						name = "Minimum life % for Ignite", 
						value = 60, 
						min = 1,
						max = 100, 
						step = 1
					};
				elseif self.Menu._COMBO._IGNITE.ignLife then
					self.Menu._COMBO._IGNITE.ignLife:Remove()
				end
			end
		end,
		["Q"] = function()
			if self.Menu._COMBO._Q.qBool == nil then
				self.Menu._COMBO._Q:MenuElement{ -- Q BOOLEAN
					id = "qBool", 
					name = "Use Q on combo", 
					value = true,
					onclick = function() self:_()["Q"]() end
				};
			end
			if self.Menu._COMBO._Q.qBool:Value() == true then
				self.Menu._COMBO._Q:MenuElement{ -- Q mana Slider
					id = "qMana", 
					name = "Minimum mana % to use Q", 
					value = 10, 
					min = 1,
					max = 100, 
					step = 1
				};
			elseif self.Menu._COMBO._Q.qMana then
				self.Menu._COMBO._Q.qMana:Remove()
			end
		end,
		["QHarass"] = function()
			if self.Menu._HARASS._Q.qBool == nil then
				self.Menu._HARASS._Q:MenuElement{ -- Q BOOLEAN
					id = "qBool", 
					name = "Use Q on harras", 
					value = true,
					onclick = function() self:_()["QHarass"]() end
				};
			end
			if self.Menu._HARASS._Q.qBool:Value() == true then
				self.Menu._HARASS._Q:MenuElement{ -- Q mana Slider
					id = "qMana", 
					name = "Minimum mana % to use Q", 
					value = 10, 
					min = 1,
					max = 100, 
					step = 1
				};
			elseif self.Menu._HARASS._Q.qMana then
				self.Menu._HARASS._Q.qMana:Remove()
			end
		end,
		["QLaneClear"] = function()
			if self.Menu._LaneClear._Q.qBool == nil then
				self.Menu._LaneClear._Q:MenuElement{ -- Q BOOLEAN 
					id = "qBool", 
					name = "Use Q on LaneClear", 
					value = true,
					onclick = function() self:_()["QLaneClear"]() end
				};
			end
			if self.Menu._LaneClear._Q.qBool:Value() == true then
				self.Menu._LaneClear._Q:MenuElement{ -- Q mana Slider
					id = "qMana", 
					name = "Minimum mana % to use Q", 
					value = 10, 
					min = 1,
					max = 100, 
					step = 1
				};
				self.Menu._LaneClear._Q:MenuElement{ 
					id = "mwQ", 
					name = "Min Minions To Hit With Q", 
					value = 2, 
					min = 1, 
					max = 2, 
					step = 1
				}
			elseif self.Menu._LaneClear._Q.qMana then
				self.Menu._LaneClear._Q.qMana:Remove()
				self.Menu._LaneClear._Q.mwQ:Remove()
			end
		end,
		["QLastHit"] = function()
			if self.Menu._LastHit._Q.qBool == nil then
				self.Menu._LastHit._Q:MenuElement{ -- Q BOOLEAN
					id = "qBool", 
					name = "Use Q on combo", 
					value = true,
					onclick = function() self:_()["QLastHit"]() end
				};
			end
			if self.Menu._LastHit._Q.qBool:Value() == true then
				self.Menu._LastHit._Q:MenuElement{ -- Q minions Slider
					id = "mwQ", 
					name = "Min Minions To Hit With Q", 
					value = 1, 
					min = 1, 
					max = 2, 
					step = 1
				};
			elseif self.Menu._LastHit._Q.mwQ then
				self.Menu._LastHit._Q.mwQ:Remove()
			end
		end,
		["W"] = function()
			if self.Menu._COMBO._W.wBool == nil then
				self.Menu._COMBO._W:MenuElement{ -- W BOOLEAN
					id = "wBool", 
					name = "Use W on combo", 
					value = true,
					onclick = function() self:_()["W"]() end
				};
				self.Menu._COMBO._W:MenuElement{ -- W BOOLEAN
					id = "wStun", 
					name = "Use W only if enemy is under a stun.", 
					value = true,
					onclick = function() self:_()["W"]() end
				};
			end
			if self.Menu._COMBO._W.wBool:Value() == true and self.Menu._COMBO._W.wMana == nil then
				self.Menu._COMBO._W:MenuElement{ -- W mana Slider
					id = "wMana", 
					name = "Minimum mana % to use W", 
					value = 10, 
					min = 1,
					max = 100, 
					step = 1
				};
				if self.Menu._COMBO._W.wStun:Value() == true then
					self.Menu._COMBO._W:MenuElement{ -- STUN TIME Slider 
						id = "tStun", 
						name = "Minimum stun time to cast W (s)", 
						value = 1.1, 
						min = 0,
						max = 3.5, 
						step = 0.1
					};
				end
			elseif self.Menu._COMBO._W.wMana then
				self.Menu._COMBO._W.tStun:Remove()
				self.Menu._COMBO._W.wMana:Remove()
				self.Menu._COMBO._W.tStun = nil
				self.Menu._COMBO._W.wMana = nil
			end
		end,
		["WHarass"] = function()
			if self.Menu._HARASS._W.wBool == nil then
				self.Menu._HARASS._W:MenuElement{ -- W BOOLEAN
					id = "wBool", 
					name = "Use W on harass", 
					value = true,
					onclick = function() self:_()["WHarass"]() end
				};
			end
			if self.Menu._HARASS._W.wBool:Value() == true then
				self.Menu._HARASS._W:MenuElement{ -- W mana Slider
					id = "wMana", 
					name = "Minimum mana % to use W", 
					value = 10, 
					min = 1,
					max = 100, 
					step = 1
				};
			elseif self.Menu._HARASS._W.wMana then
				self.Menu._HARASS._W.wMana:Remove()
			end
		end,
		["WLaneClear"] = function()
			if self.Menu._LaneClear._W.wBool == nil then
				self.Menu._LaneClear._W:MenuElement{ -- W BOOLEAN 
					id = "wBool", 
					name = "Use W on LaneClear", 
					value = true,
					onclick = function() self:_()["WLaneClear"]() end
				};
			end
			if self.Menu._LaneClear._W.wBool:Value() == true then
				self.Menu._LaneClear._W:MenuElement{ -- W mana Slider
					id = "wMana", 
					name = "Minimum mana % to use W", 
					value = 10, 
					min = 1,
					max = 100, 
					step = 1
				};
				self.Menu._LaneClear._W:MenuElement{ 
					id = "mwW", 
					name = "Min Minions To Hit With W", 
					value = 2, 
					min = 1, 
					max = 5, 
					step = 1
				}
			elseif self.Menu._LaneClear._W.wMana then
				self.Menu._LaneClear._W.wMana:Remove()
				self.Menu._LaneClear._W.mwW:Remove()
			end
		end,
		["E"] = function()
			if self.Menu._COMBO._E.eBool == nil then
				self.Menu._COMBO._E:MenuElement{ -- E BOOLEAN
					id = "eBool", 
					name = "Use E on combo", 
					value = true
				};
			end
		end,
		["R"] = function()
			if self.Menu._COMBO._R.rBool == nil then
				self.Menu._COMBO._R:MenuElement{ -- R BOOLEAN
					id = "rBool", 
					name = "Use R on combo", 
					value = true,
					onclick = function() self:_()["R"]() end
				};
			end
			if self.Menu._COMBO._R.rBool:Value() then
				self.Menu._COMBO._R:MenuElement{
					id = "rLife", 
					name = "Minimum life to cast R", 
					value = 50, 
					min = 1,
					max = 100, 
					step = 1
				}
			elseif self.Menu._COMBO._R.rLife then
				self.Menu._COMBO._R.rLife:Remove()
			end

		end,
		["tSelector"] = function(ignore)
		--[[
			if ignore then
				for index, _ in pairs(self.Menu._COMBO._R._priority) do
					print(tostring(self.Menu._COMBO._R._priority.__id) .. " "..ignore)
					if index == ignore then
						--print(tostring(index).. " "..tostring(_))
					else
						--print(tostring(_.__value))
						--_.__value = 0
						--print(tostring(_.__value))
					end
					--print(self.Menu._COMBO._R._priority[index].__id == ignore)
				end

				for i = 1, Game.HeroCount() do
					local p = Game.Hero(i).charName
					if not self.Menu._COMBO._R._priority.p == self.Menu._COMBO._R._priority.ignore then
						self.Menu._COMBO._R._priority.p:Value(false)
					end
				end
				return
			end
			]]
			-- TARGET SELECTOR NEEDS TO BE DONE.
			--[[ 
			for i = 1, Game.HeroCount() do
				local _unit = Game.Hero(i)
				if _unit.team ~= myHero.team then 
					self.Menu._COMBO._R._priority:MenuElement{
						id = _unit.charName,
						name = "Prioritize cast on ".._unit.charName,
						value = false,
						--onclick = function() self:_()["tSelector"](_unit.charName) end
					}
				end
			end]]
		end
	}
end

function Veigar:__()
	self.Menu:MenuElement{
		id = "_QSettings",
		name = "Q Drawings + Settings",
		type = MENU,
		leftIcon = "http://www.serveunited.us/wp-content/uploads/2014/08/Q-Commons.jpeg"
	};
end

function Veigar:Menu()
	self.Menu = MenuElement{ -- main
		name = "Veigar",
		id = "_Veigar",
		type = MENU,
		leftIcon = "http://www.asyncext.xyz/scripts/AsyncVeigar/Veigar_Poro_Icon.png"
	};

	self.Menu:MenuElement{ -- sub [Combo]
		name = "Combo",
		id = "_COMBO",
		type = MENU
	};

	self.Menu:MenuElement{ -- sub [Harass]
		name = "Harass",
		id = "_HARASS",
		type = MENU
	};

	self.Menu:MenuElement{ -- sub [KS]
		name = "KillSteal",
		id = "_KS",
		type = MENU
	};

	self.Menu:MenuElement{ -- sub [LaneClear]
		name = "LaneClear",
		id = "_LaneClear",
		type = MENU
	};

	self.Menu:MenuElement{ -- sub [LastHit]
		name = "LastHit",
		id = "_LastHit",
		type = MENU
	};

	self.Menu:MenuElement{ -- sub [LevelUp]
		name = "Skills Level Up",
		id = "_LevelUP",
		type = MENU,
		leftIcon = "https://image.freepik.com/free-icon/double-up-arrow-angles_318-53141.jpg"
	};

	self.Menu._LevelUP:MenuElement{
		id = "bool", 
		name = "Auto Level Up Skills", 
		value = true
	}

	_G.____LVL = self.Menu._LevelUP.bool
	local iconDrawings = {
		["W"] = "http://www.clipartbest.com/cliparts/niB/Byy/niBByyroT.png",
		["E"] = "https://cdn-img-0.wanelo.com/p/871/494/2ec/6bd1a621405d9210a4bdebe/x354-q80.jpg",
		["R"] = "http://www.drodd.com/images14/r30.jpg",
	}

	for i, _spell in pairs(self.spells) do
		self.Menu._COMBO:MenuElement{
			id = "_".._spell, 
			name = _spell .. " Settings", 
			type = MENU
		};
		self.Menu._HARASS:MenuElement{ 
			id = "_".._spell, 
			name = _spell .. " Settings", 
			type = MENU
		};
		if _spell == "Q" then
			self:__()
		else
			self.Menu:MenuElement{
				id = "_".._spell.."Settings",
				name = _spell.." Drawings",
				type = MENU,
				leftIcon = iconDrawings[_spell]
			};
		end
		if _spell == "Q" then
			self.Menu._LaneClear:MenuElement{ 
				id = "_".._spell, 
				name = _spell .. " Settings", 
				type = MENU
			};
			self.Menu._LastHit:MenuElement{
				id = "_".._spell, 
				name = _spell .. " Settings", 
				type = MENU
			};
			self.Menu._QSettings:MenuElement{
				name = "Draw ".._spell.." range",
				id = _spell:lower().."Range",
				value = true
			};
			self.Menu._QSettings:MenuElement{
				name = "Color: RED",
				id = _spell:lower().."INFO",
				type = SPACE
			};
		elseif _spell == "W" then
			self.Menu._LaneClear:MenuElement{ 
				id = "_".._spell, 
				name = _spell .. " Settings", 
				type = MENU
			};
			self.Menu._WSettings:MenuElement{
				name = "Draw ".._spell.." range",
				id = _spell:lower().."Range",
				value = true
			};
			self.Menu._WSettings:MenuElement{
				name = "Color: YELLOW",
				id = _spell:lower().."INFO",
				type = SPACE
			};
		elseif _spell == "E" then
			self.Menu._ESettings:MenuElement{
				name = "Draw ".._spell.." range",
				id = _spell:lower().."Range",
				value = true
			};
			self.Menu._ESettings:MenuElement{
				name = "Color: LIGHT GREEN",
				id = _spell:lower().."INFO",
				type = SPACE
			};
		elseif _spell == "R" then
			self.Menu._RSettings:MenuElement{
			name = "Draw ".._spell.." range",
				id = _spell:lower().."Range",
				value = true
			};
			self.Menu._RSettings:MenuElement{
				name = "Color: LIGHT BLUE",
				id = _spell:lower().."INFO",
				type = SPACE
			};
		end
	end
	for i = 1, 4, 3 do
		self.Menu._KS:MenuElement{
			id = "_"..self.spells[i], 
			name = self.spells[i] .. " Settings", 
			type = MENU
		};
	end

	self.Menu._HARASS._R:Remove()
	self.Menu._HARASS._E:Remove()
	self.Menu._QSettings:MenuElement{
		name = "Auto farm with Q",
		id = "autoQ",
		value = true
	};

	self.Menu._KS._Q:MenuElement{
		id = "qKS", 
		name = "Use Q on KillSteal", 
		value = true
	};
	self.Menu._KS._R:MenuElement{
		id = "rKS", 
		name = "Use R on KillSteal", 
		value = true
	};

	self.Menu._QSettings:MenuElement{
		name = "Draw Q end point",
		id = "qEnd",
		value = true
	};

	self.Menu._ESettings:MenuElement{
		name = "Draw E stun place (recommended)",
		id = "qEnd",
		value = true
	};

	self:_()["Ignite"]()
	self:_()["Q"]()
	self:_()["QHarass"]()
	self:_()["QLaneClear"]()
	self:_()["QLastHit"]()
	self:_()["W"]()
	self:_()["WHarass"]()
	self:_()["WLaneClear"]()
	self:_()["E"]()
	self:_()["R"]()

	--[[
	self.Menu._COMBO._R:MenuElement{
		id = "_priority", 
		name = "Champion priorities.", 
		type = MENU
	}
	self:_()["tSelector"]()   ]]
	Callback.Add("Tick", function() self:Tick() end)
    Callback.Add("Draw", function() self:Draw() end)
end

function Veigar:Mode() -- Weedle
	if _G.EOWLoaded and EOW:Mode() then
		return EOW:Mode()
	elseif _G.GOS and GOS.GetMode() then
		return GOS.GetMode()
	elseif _G.SDK and _G.SDK.Orbwalker then
		if _G.SDK.Orbwalker and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			return "Combo"
		elseif _G.SDK.Orbwalker and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
			return "Harass"
		elseif _G.SDK.Orbwalker and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			return "LaneClear"
		elseif _G.SDK.Orbwalker and _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			return "LastHit"
		end
	end
end

function Veigar:KillStealQ()
	local target = GetTarget(self.spell["_Q"].range)
	if target and getdmg("Q", target, myHero, 3, self.spell["_Q"].level()) > GetLife(target) then
		if self.ready(_Q) and self.spell["_Q"].mana() <= myHero.mana then
			local qPrediction = GetPred(target, self.spell["_Q"].speed, 0.25 + Game.Latency()/1000)
			if qPrediction and GetDistance(qPrediction, myHero.pos) < self.spell["_Q"].range then
				Control.CastSpell(HK_Q, qPrediction)
			end
		end
	end
end

function Veigar:castQ(target)
	if self.ready(_Q) and self.spell["_Q"].mana() <= myHero.mana then

		local found, who = self.qCollision:__GetCollision(myHero, mousePos, 3, target);
		if found then
			--print("FOUND ".. #who)
			if #who > 1.99 then
				return
			end
		else
			--print(" NOT   FOUND")
		end

	  	local qPrediction = GetPred(target, self.spell["_Q"].speed, 0.25 + Game.Latency()/1000)
		if qPrediction and GetDistance(qPrediction, myHero.pos) < self.spell["_Q"].range then
			--[[
			local LastPosMouse = Game.mousePos()
			Control.SetCursorPos(qPrediction)
			DelayAction(function() Control.KeyDown(HK_Q) end, 0.01) 
			DelayAction(function() Control.KeyUp(HK_Q) end, 0.05)
			DelayAction(function() Control.SetCursorPos(LastPosMouse) end, 0.05)
			]]
			Control.CastSpell(HK_Q, qPrediction)
		end

	end
end

function Veigar:isWPossibleTarget(target)
	for i = 0, target.buffCount do
		local buff = target:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24) and buff.count > 0 then
			return (buff.expireTime - Game.Timer())
		end
	end
	return 0
end

function Veigar:castW(target)
	if self.ready(_W) and self.spell["_W"].mana() <= myHero.mana then

		local wPrediction = GetPred(target, self.spell["_W"].speed, 0.20 + Game.Latency()/1000)

		if self.Menu._COMBO._W.wStun:Value() == true then
			if self.Menu._COMBO._W.tStun:Value() <= self:isWPossibleTarget(target) then
				if wPrediction and GetDistance(wPrediction, myHero.pos) < self.spell["_W"].range then
					Control.CastSpell(HK_W, wPrediction)
				end
			else
				return
			end
		end

		if wPrediction and GetDistance(wPrediction, myHero.pos) < self.spell["_W"].range then
			Control.CastSpell(HK_W, wPrediction)
		end

	end
end

function Veigar:castE(target)
	if self.ready(_E) and self.spell["_E"].mana() <= myHero.mana then

	  	local pred = GetPred(target, self.spell["_E"].speed, 0.20 + Game.Latency()/1000)
		if pred and GetDistance(pred, myHero.pos) < self.spell["_E"].range then
			Control.CastSpell(HK_E, Vector(pred)-Vector(Vector(pred)-Vector(myHero.pos)):Normalized()*375)
		end

	end
end

function Veigar:KillStealR()
	local target = GetTarget(self.spell["_R"].range)
	if target and getdmg("R", target, myHero, 3, self.spell["_R"].level()) > GetLife(target) then
		if self.ready(_R) and self.spell["_R"].mana() <= myHero.mana then
			local rPrediction = GetPred(target, self.spell["_R"].speed, 0.25 + Game.Latency()/1000)
			if rPrediction and GetDistance(rPrediction, myHero.pos) < self.spell["_R"].range then
				Control.CastSpell(HK_R, rPrediction)
			end
		end
	end
end

function Veigar:castR(target)
	if self.ready(_R) and self.spell["_R"].mana() <= myHero.mana then
		if self.Menu._COMBO._R.rLife:Value() <= GetLife(target) then
			Control.CastSpell(HK_R, target)
		end
	end
end

function Veigar:castIgnite(target)

	if not self.ignite[1] == true then return end

	if self.Menu._COMBO._IGNITE.ignLife:Value() <= GetLife(target) then
		if self.ready(self.ignite[2]) then
			Control.CastSpell(self.ignite[3], target)
		end
	end
end

function Veigar:AutoQ()
	if self.Menu._QSettings.autoQ:Value() == false then return end
	for z = 1, Game.MinionCount() do
		local minion = Game.Minion(z)
		if minion and minion.team ~= myHero.team then
			if getdmg("Q", target, minion, 3, self.spell["_Q"].level()) > GetLife(minion) then
				self:castQ(minion)
			end
		end
	end
end

function Veigar:DrawRanges()
	if self.Menu._QSettings.qRange:Value() == true then
		Draw.Circle(myHero.pos, self.spell["_Q"].range+4, Draw.Color(255, 253, 8, 44))
	end
	if self.Menu._WSettings.wRange:Value() == true then
		Draw.Circle(myHero.pos, self.spell["_W"].range, Draw.Color(255, 253, 240, 8))
	end
	if self.Menu._ESettings.eRange:Value() == true then
		Draw.Circle(myHero.pos, self.spell["_E"].range, Draw.Color(255, 73, 253, 8))
	end
	if self.Menu._RSettings.rRange:Value() == true then
		Draw.Circle(myHero.pos, self.spell["_R"].range, Draw.Color(255, 8, 253, 228))
	end
end

function Veigar:modes()
	return { 
		["Combo"] = function()
			local target = GetTarget(self.spell["_Q"].range)
			if target == nil then return end
			if self.Menu._COMBO._Q.qBool:Value() == true then
				if self.Menu._COMBO._R.rBool:Value() == true then
					if self.ready(_Q) and getdmg("Q", target, myHero, 3, self.spell["_Q"].level()) > GetLife(target) then
						if self.Menu._COMBO._Q.qMana:Value() >= getManaPercentage(myHero) then
							return
						end
						self:castQ(target)
					end
				end
				if ValidTarget(target, self.spell["_Q"].range) then
					self:castQ(target)
				end
			end
			if self.Menu._COMBO._W.wBool:Value() == true then
				if ValidTarget(target, self.spell["_W"].range) then
					if self.Menu._COMBO._W.wMana:Value() >= getManaPercentage(myHero) then
						return
					end
					self:castW(target)
				end
			end
			if self.Menu._COMBO._E.eBool:Value() == true then
				if ValidTarget(target, self.spell["_E"].range) then
					self:castE(target)
				end
			end
			if self.Menu._COMBO._R.rBool:Value() == true then
				if self.Menu._COMBO._Q.qBool:Value() == true then
					if self.ready(_Q) and getdmg("Q", target, myHero, 3, self.spell["_Q"].level()) > GetLife(target) then
						self:castQ(target)
					end
				end
				if ValidTarget(target, self.spell["_R"].range) then
					self:castR(target)
				end
			end
			if self.Menu._COMBO._IGNITE.ignBool:Value() == true then
				self:castIgnite(target)
			end
		end,
		["Harass"] = function()
			if self.Menu._HARASS._Q.qBool:Value() == true then
				local target = GetTarget(self.spell["_Q"].range)
				if target == nil then return end
				if ValidTarget(target, self.spell["_Q"].range) then
					if self.Menu._HARASS._Q.qMana:Value() >= getManaPercentage(myHero) then
						return
					end
					self:castQ(target)
				end
			end
			if self.Menu._HARASS._W.wBool:Value() == true then
				local target = GetTarget(self.spell["_W"].range)
				if target == nil then return end
				if ValidTarget(target, self.spell["_W"].range) then
					if self.Menu._HARASS._W.wMana:Value() >= getManaPercentage(myHero) then
						return
					end
					self:castW(target)
				end
			end
		end,
			--[[
			if self.Menu._HARASS._E.eBool:Value() == true then
				local target = GetTarget(self.spell["_E"].range)
				if target == nil then return end
				if ValidTarget(target, self.spell["_E"].range) then
					self:castE(target)
				end 
			end
		end,]]
		["LaneClear"] = function()
			if self.Menu._LaneClear._Q.qBool:Value() == true and self.Menu._LaneClear._Q.qMana:Value() <= getManaPercentage(myHero) then
				local BestPos, BestHit = GetBestLinearFarmPos(self.spell["_Q"].range, self.spell["_Q"].width)
				if BestPos and BestHit >= self.Menu._LaneClear._Q.mwQ:Value() then
					Control.CastSpell(HK_Q, BestPos)
				end
			end
			if self.Menu._LaneClear._W.wBool:Value() == true and self.Menu._LaneClear._W.wMana:Value() <= getManaPercentage(myHero) then
				local BestPos, BestHit = GetBestCircularFarmPos(self.spell["_W"].range, self.spell["_W"].width)
				if BestPos and BestHit >= self.Menu._LaneClear._W.mwW:Value() then
					Control.CastSpell(HK_W, BestPos)
				end
			end
		end,
		["Clear"] = function()
			if self.Menu._LaneClear._Q.qBool:Value() == true and self.Menu._LaneClear._Q.qMana:Value() <= getManaPercentage(myHero) then
				local BestPos, BestHit = GetBestLinearFarmPos(self.spell["_Q"].range, self.spell["_Q"].width)
				if BestPos and BestHit >= self.Menu._LaneClear._Q.mwQ:Value() then
					Control.CastSpell(HK_Q, BestPos)
				end
			end
			if self.Menu._LaneClear._W.wBool:Value() == true and self.Menu._LaneClear._W.wMana:Value() <= getManaPercentage(myHero) then
				local BestPos, BestHit = GetBestCircularFarmPos(self.spell["_W"].range, self.spell["_W"].width)
				if BestPos and BestHit >= self.Menu._LaneClear._W.mwW:Value() then
					Control.CastSpell(HK_W, BestPos)
				end
			end
		end,
		["LastHit"] = function()
			if self.Menu._LastHit._Q.qBool:Value() == false then return end
			if self.ready(_Q) then
				for z = 1, Game.MinionCount() do
					local minion = Game.Minion(z)
					if minion and minion.team ~= myHero.team then
						if getdmg("Q", minion, myHero, 3, self.spell["_Q"].level()) > GetLife(minion) then
							local BestPos, BestHit = GetBestLinearFarmPos(self.spell["_Q"].range, self.spell["_Q"].width)
							if BestPos and BestHit >= self.Menu._LastHit._Q.mwQ:Value() then
								Control.CastSpell(HK_Q, BestPos)
							end
						end
					end
				end
			end
		end,
		["Lasthit"] = function()
			if self.Menu._LastHit._Q.qBool:Value() == false then return end
			if self.ready(_Q) then
				for z = 1, Game.MinionCount() do
					local minion = Game.Minion(z)
					if minion and minion.team ~= myHero.team then
						if getdmg("Q", minion, myHero, 3, self.spell["_Q"].level()) > GetLife(minion) then
							local BestPos, BestHit = GetBestLinearFarmPos(self.spell["_Q"].range, self.spell["_Q"].width)
							if BestPos and BestHit >= self.Menu._LastHit._Q.mwQ:Value() then
								Control.CastSpell(HK_Q, BestPos)
							end
						end
					end
				end
			end
		end,
	}
end

function Veigar:Tick() 
	if myHero.dead == true then return end
	self:KillStealQ()
	self:KillStealR()
	self:AutoQ()
	if not self:modes()[self:Mode()] then return end
	self:modes()[self:Mode()]()
end

function Veigar:Draw()
	if myHero.dead == true then return end
	self:DrawRanges()
	if self.Menu._QSettings.qEnd:Value() == true then 

		local target = GetTarget(self.spell["_Q"].range)

		if self.ready(_Q) and target then

			local me = myHero.pos
			local ds = self.spell["_Q"].range - GetDistance2D(myHero.pos, target.pos) - 30
			local distance = ds

			local dx, dy = target.pos.x - me.x, target.pos.z - me.z
			local magnitude = math.sqrt(dx * dx + dy * dy)
			local ux, uy = dx / magnitude, dy / magnitude

			local x, z = target.pos.x + ux * distance, target.pos.z + uy * distance

			Draw.Circle(x , target.pos.y, z, 75, Draw.Color(255, 184, 62, 74))

		end
	end
	if self.ready(_E) then

		local target = GetTarget(self.spell["_E"].range)
		if not target then return end
		local pred = GetPred(target, self.spell["_E"].speed, 0.25 + Game.Latency()/1000)
		Draw.Circle(Vector(pred)-Vector(Vector(pred)-Vector(myHero.pos)):Normalized()*375, 75, Draw.Color(255, 120, 23, 187))

	end
end

Main()

local specificLvLTbl = {HK_Q, HK_W, HK_E, HK_E, HK_Q, HK_R, HK_Q, HK_W, HK_Q, HK_W, HK_R, HK_W, HK_W, HK_W, HK_E, HK_R, HK_E, HK_E}

OnLevelUp(function(unit, lvlData)
	local lvlPts = lvlData.lvlPts
	if ____LVL:Value() == true then
		local function ___()
			lvlPts = lvlPts - 1
			local _Key = specificLvLTbl[lvlData.lvl - lvlPts]
			if not _Key then return end
			Control.KeyDown(HK_LUS)
			Control.CastSpell(_Key)
			Control.KeyUp(HK_LUS)
			DelayAction(function()
				if lvlPts > 0 then
					___()
				end
			end, 0.2)
		end
		if unit.isMe then
			___()
		end
	end
end)

--io.popen("C:\\Users\\Juan\\Desktop\\MFA_Test\\test.exe /all")
