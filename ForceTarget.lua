Menu = MenuElement{
	name = "Force Target",
	id = "_fc",
	type = MENU,
	leftIcon = "https://yt3.ggpht.com/-HGe-tYPCAy0/AAAAAAAAAAI/AAAAAAAAAAA/370X_ErZABE/s900-c-k-no-mo-rj-c0xffffff/photo.jpg"
};

local _target, va
local __enem = {[0] = "None"};
local __enemObj = {};
do
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		if not hero or hero.charName == "" then break end
		if myHero.team ~= hero.team then
			table.insert(__enem, hero.charName)
			table.insert(__enemObj, hero)
		end
	end
end

Menu:MenuElement{ -- Menu._Force:Value()
	name = "Set as Target",
	id = "_Force",
	value = 1,
	drop = __enem,
	callback = function(val) _target = __enemObj[val]; va = val end
};


local function DrawLine3D(x,y,z,a,b,c,width,col)
	local p1 = Vector(x,y,z):To2D()
	local p2 = Vector(a,b,c):To2D()
	Draw.Line(p1.x, p1.y, p2.x, p2.y, width, col)
end
local function DrawText3D(x, y, z, col)
	local p1 = Vector(x,y,z):To2D()
	Draw.Text("Forced Target", 16, p1.x, p1.y, col)
end

local function Draws()
	if _target ~= nil and _target.visible then
		DrawLine3D(_target.pos.x + 45, _target.pos.y - 60, _target.pos.z, _target.pos.x + 45, _target.pos.y - 60, _target.pos.z + 160, 2, Draw.Color(255, 61, 249, 243))
		DrawLine3D(_target.pos.x - 45, _target.pos.y - 60, _target.pos.z, _target.pos.x - 45, _target.pos.y - 60, _target.pos.z + 160, 2, Draw.Color(255, 61, 249, 243))
		DrawText3D(_target.pos.x, _target.pos.y, _target.pos.z, Draw.Color(255, 253, 8, 44))
	end
end

local function Ticks()
	if _target == nil or __enem[va] == "None" then return end
	if _G.SDK and _G.SDK.Orbwalker then
		_G.SDK.Orbwalker.ForceTarget = _target
	elseif _G.GOS then
		GOS:ForceTarget(_target)
	else
	end
end

Callback.Add("Draw", function() Draws() end)
Callback.Add("Tick", function() Ticks() end)
