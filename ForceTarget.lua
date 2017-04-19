Menu = MenuElement{
	name = "Lines",
	id = "_fc",
	type = MENU
};

Menu:MenuElement{
	name = "X",
	id = "X",
	value = 1, min = 0, max = 200, step = 1
};
Menu:MenuElement{
	name = "Y",
	id = "Y",
	value = 1, min = 0, max = 200, step = 1
};
Menu:MenuElement{
	name = "Z",
	id = "Z",
	value = 1, min = 0, max = 200, step = 1
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
		DrawLine3D(_target.pos.x + Menu.X:Value(), _target.pos.y - Menu.Y:Value(), _target.pos.z, _target.pos.x + Menu.X:Value(), _target.pos.y - Menu.Y:Value(), _target.pos.z + Menu.Z:Value(), 2, Draw.Color(255, 61, 249, 243))
		DrawLine3D(_target.pos.x - Menu.X:Value(), _target.pos.y - Menu.Y:Value(), _target.pos.z, _target.pos.x - Menu.X:Value(), _target.pos.y - Menu.Y:Value(), _target.pos.z + Menu.Z:Value(), 2, Draw.Color(255, 61, 249, 243))
		DrawText3D(_target.pos.x, _target.pos.y, _target.pos.z, Draw.Color(255, 253, 8, 44))
	end
end

Callback.Add("Draw", function() Draws() end)
Callback.Add("Tick", function() Ticks() end)
