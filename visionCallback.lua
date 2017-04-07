_G._VISION_TABLE = {}


class("Vision")

function Vision:__init()
	self.GainVisionCallback = {}
	self.LoseVisionCallback = {}
	self.Champs = {}
	_G._VISION_STARTED = true
	for _ = 0, Game.HeroCount() do
		local obj = Game.Hero(_)
		if obj then
			table.insert(self.Champs, obj)
			_VISION_TABLE[obj.networkID] = {visible = obj.visible}
		end
	end
	Callback.Add("Tick", function () self:Tick() end)
end

function Vision:Tick()
	for _, champ in pairs(self.Champs) do
		for i = 0, Game.HeroCount() do
			local hero = Game.Hero(i)
			if hero then
				local netID = hero.networkID
				if hero.visible == false and _VISION_TABLE[netID] and _VISION_TABLE[netID].visible == true then
					_VISION_TABLE[netID] = {visible = hero.visible}
					self:LoseVision(hero)
				elseif hero.visible == true and _VISION_TABLE[netID] and _VISION_TABLE[netID].visible == false then
					_VISION_TABLE[netID] = {visible = hero.visible}
					self:GainVision(hero)
				end
			end
		end
	end
end

function Vision:LoseVision(unit)
	for _, Emit in pairs(self.LoseVisionCallback) do
		Emit(unit)
	end
end
	
function Vision:GainVision(unit)
	for _, Emit in pairs(self.GainVisionCallback) do
		Emit(unit)
	end
end

if not _VISION_STARTED then  
	_G.Vision = Vision()
end


function OnGainVision(fn)
	table.insert(Vision.GainVisionCallback, fn)
end
function OnLoseVision(fn)
	table.insert(Vision.LoseVisionCallback, fn)
end
