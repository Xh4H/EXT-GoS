math.randomseed(os.time())

class "AntiAfk"

function AntiAfk:__init()
	self.Menu = MenuElement{name = "Anti-Afk", id = "AntiAfk", type = MENU, leftIcon = "https://pbs.twimg.com/profile_images/662397591955468288/tQnSMXYy.png"};
	self.Menu:MenuElement{name = "Enable Anti-Afk", id = "isOn", value = false, onclick = function() self:Iterate("1") end};
	if self.Menu.isOn:Value() == true then self.Menu.isOn:Value(false) end
	self:Iterate("all")
	self.lastMoved = ""
	self.time = os.clock()
end

function AntiAfk:Iterate(index)
	if index == "1" then
		if self.Menu.isRandomized then
			self.Menu.isRandomized:Remove()
			self.Menu.isRandomized = nil
		else
			self.Menu:MenuElement{name = "Randomize click period", id = "isRandomized", value = false, onclick = function() self:Iterate("2") end}
			if self.Menu.isRandomized:Value() == true then self.Menu.isRandomized:Value(false) end
		end
	elseif index == "2" then
		if self.Menu.period then
			self.Menu.period:Remove()
			self.Menu.period = nil
		else
			self.Menu:MenuElement{name = "Select click period (seconds)", id = "period", value = 50, min = 30, max = 120, step = 2}
		end
	elseif index == "all" then
		if self.Menu.period then
			self.Menu.period:Remove()
			self.Menu.period = nil
		end
		if self.Menu.isRandomized then
			self.Menu.isRandomized:Remove()
			self.Menu.isRandomized = nil
		end
	end
	Callback.Add("Tick", function() self:Tick() end)
end

function AntiAfk:Click()
	Control.SetCursorPos(myHero.pos)
	Control.mouse_event(MOUSEEVENTF_RIGHTDOWN)
	Control.mouse_event(MOUSEEVENTF_RIGHTUP)
end


function AntiAfk:Tick()
	if self.Menu.isOn:Value() == false then return end
	if self.lastMoved == myHero.pos then 
		if self.time < os.clock() then 
			if self.Menu.isRandomized:Value() == true then
				self.time = os.clock() + math.random(20, 65);
			else
				if not self.Menu.period then return end
				self.time = os.clock() + self.Menu.period:Value();
			end
			self:Click()
		end
	else 
		self.lastMoved = myHero.pos
	end
end

AntiAfk()
