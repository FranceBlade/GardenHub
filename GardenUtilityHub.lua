--// Load the UI Library
local Library = loadstring(game:HttpGet("https://pastebin.com/raw/LKivCcbW"))()

--// Create Window
local Lib = Library.CreateLibrary("Binz Hub", "Grow a Garden")
-- Attach floating icon for this window
Library.CreateFloatingIcon(main, "rbxassetid://81222227536540", 56)

--// Tabs
local Tab1 = Lib:AddTab("Home","rbxassetid://106809791072683")
local Tab2 = Lib:AddTab("Main","rbxassetid://105364893099735")
local Tab3 = Lib:AddTab("Others","rbxassetid://116044796070364")
local Tab4 = Lib:AddTab("Misc","rbxassetid://88316127549460")

---------------------------------------------------
--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local LocalPlayer = player
local Farm = workspace:WaitForChild("Farm")
local Important = Farm:WaitForChild("Farm"):WaitForChild("Important")
local plantFolder = Important:WaitForChild("Plants_Physical")
local CalculatePlantValue = require(ReplicatedStorage.Modules.CalculatePlantValue)

---------------------------------------------------
--// Auto Collect
getgenv().SelectedCollectFruit = nil
getgenv().AutoCollect = false

local CollectRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Crops"):WaitForChild("Collect")

local fruits = {
    "Carrot","Strawberry","Blueberry","Tomato","Bamboo","Cactus","Pepper","Cacao",
    "Pumpkin","Watermelon","Pineapple","Grape","Feijoa","Prickly Pear","Pear","Apple",
    "Dragonfruit","Coconut","Mushroom","Orange Tulip","Corn","Beanstalk","Sugar Apple",
    "Pitcher Plant","Giant Pinecone","Elder Strawberry","Bone Blossom","Candy Blossom"
}

local CollectDropdown = Tab1:AddDropdown("Pick Fruit", fruits)
CollectDropdown.OnChanged:Connect(function(val)
    if typeof(val) == "table" then val = val[1] or tostring(val) end
    getgenv().SelectedCollectFruit = tostring(val)
end)

local CollectToggle = Tab1:AddToggle("Auto Collect", false, function(v)
    getgenv().AutoCollect = v
end)

task.spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoCollect and getgenv().SelectedCollectFruit then
            local toCollect = {}
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and obj:HasTag("CollectPrompt") then
                    local model = obj.Parent
                    while model and not model:IsA("Model") do
                        model = model.Parent
                    end
                    if model and string.find(model.Name, getgenv().SelectedCollectFruit, 1, true) then
                        table.insert(toCollect, model)
                    end
                end
            end
            if #toCollect > 0 then
                pcall(function()
                    CollectRemote:FireServer(toCollect)
                end)
            end
        end
    end
end)

---------------------------------------------------
--// Auto Plant
getgenv().SelectedSeed = nil
getgenv().AutoPlant = false

local seeds = fruits  -- same list as fruits

local function equipSeed(seedName)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local current = char:FindFirstChildOfClass("Tool")
    if current and current.Name:lower():find(seedName:lower()) then return end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(seedName:lower() .. " seed") then
            hum:EquipTool(tool)
            return
        end
    end
end

local SeedDropdown = Tab1:AddDropdown("Pick Seed", seeds)
SeedDropdown.OnChanged:Connect(function(val)
    if typeof(val) == "table" then getgenv().SelectedSeed = val[1] else getgenv().SelectedSeed = val end
end)

local PlantToggle = Tab1:AddToggle("Auto Plant", false, function(v)
    getgenv().AutoPlant = v
end)

RunService.Heartbeat:Connect(function()
    if getgenv().AutoPlant and getgenv().SelectedSeed then
        equipSeed(getgenv().SelectedSeed)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos = hrp.Position
            local args = {Vector3.new(pos.X, pos.Y, pos.Z), getgenv().SelectedSeed}
            ReplicatedStorage.GameEvents.Plant_RE:FireServer(unpack(args))
            task.wait(1.2)
        end
    end
end)

---------------------------------------------------
--// Auto Buy
local selectedSeeds = {}
local selectedGears = {}
local selectedEggs = {}
getgenv().AutoBuy = false
local autoBuyRunning = false
local Events = ReplicatedStorage:WaitForChild("GameEvents")

local SeedDropdown2 = Tab2:AddDropdown("Seed List", seeds)
SeedDropdown2.OnChanged:Connect(function(val)
    selectedSeeds = typeof(val) == "table" and val or {tostring(val)}
end)

local GearDropdown = Tab2:AddDropdown("Gear List", {
    "Watering Can", "Trowel", "Recall Wrench", "Basic Sprinkler",
    "Advance Sprinkler", "Medium Toy", "Trading Ticket", "Medium Treat",
    "Godly Sprinkler", "Magnifying Glass", "Tanning Mirror",
    "Master Sprinkler", "Grandmaster Sprinkler", "Cleaning Spray",
    "Favorite Tool", "Harvest Tool", "Friendship Pot", "Levelup Lollipop"
})
GearDropdown.OnChanged:Connect(function(val)
    selectedGears = typeof(val) == "table" and val or {tostring(val)}
end)

local EggDropdown = Tab2:AddDropdown("Pet Egg List", {
    "Common Egg","Common Summer Egg","Rare Summer Egg","Mythical Egg",
    "Paradise Egg","Bug Egg"
})
EggDropdown.OnChanged:Connect(function(val)
    selectedEggs = typeof(val) == "table" and val or {tostring(val)}
end)

local AutoBuyToggle = Tab2:AddToggle("Auto Buy", false, function(v)
    getgenv().AutoBuy = v
    if v and not autoBuyRunning then
        autoBuyRunning = true
        task.spawn(function()
            while getgenv().AutoBuy do
                local boughtSomething = false
                for _, seed in ipairs(selectedSeeds) do pcall(function() Events.BuySeedStock:FireServer(seed) end) boughtSomething = true end
                for _, gear in ipairs(selectedGears) do pcall(function() Events.BuyGearStock:FireServer(gear) end) boughtSomething = true end
                for _, egg in ipairs(selectedEggs) do pcall(function() Events.BuyPetEgg:FireServer(egg) end) boughtSomething = true end
                if not boughtSomething then task.wait(1) end
                task.wait()
            end
            autoBuyRunning = false
        end)
    end
end)

---------------------------------------------------
--// Sprinkler + Auto Shovel
local sprinklerNames = {"Basic Sprinkler","Advanced Sprinkler","Godly Sprinkler","Master Sprinkler","Honey Sprinkler","Chocolate Sprinkler"}
local selectedSprinklers = {}
local SprinklerDropdown = Tab3:AddDropdown("Sprinkler List", sprinklerNames)
SprinklerDropdown.OnChanged:Connect(function(val)
    if val then
        if typeof(val) == "table" then
            selectedSprinklers = {}
            for _, v in ipairs(val) do selectedSprinklers[v] = true end
        else
            if selectedSprinklers[val] then selectedSprinklers[val] = nil else selectedSprinklers[val] = true end
        end
    end
end)

local autoShovelState = false
local ShovelToggle = Tab3:AddToggle("Auto Shovel", false, function(v) autoShovelState = v end)

local DeleteObject = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("DeleteObject")
local SprinklerFolder = workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Objects_Physical")

local function equipShovel()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local current = char:FindFirstChildOfClass("Tool")
    if current and current.Name:lower():find("shovel") then return end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("shovel") then
            hum:EquipTool(tool)
            return
        end
    end
end

task.spawn(function()
    while task.wait(0.3) do
        if autoShovelState and next(selectedSprinklers) then
            equipShovel()
            for _, model in ipairs(SprinklerFolder:GetChildren()) do
                if model:IsA("Model") then
                    for name,_ in pairs(selectedSprinklers) do
                        if model.Name:lower():find(name:lower()) then
                            pcall(function() DeleteObject:FireServer(model) end)
                            task.wait(0.15)
                            break
                        end
                    end
                end
            end
        end
    end
end)

---------------------------------------------------
--// For ESP Egg
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local local_player = Players.LocalPlayer
local current_camera = workspace.CurrentCamera

local hatch_function = getupvalue(getupvalue(getconnections(ReplicatedStorage.GameEvents.PetEggService.OnClientEvent)[1].Function, 1), 2)
local egg_models = getupvalue(hatch_function, 1)
local egg_pets = getupvalue(hatch_function, 2)

local esp_cache = {}
local active_eggs = {}
local esp_enabled = false

local function get_object_from_id(object_id: string)
	for egg_model in egg_models do
		if egg_model:GetAttribute("OBJECT_UUID") == object_id then
			return egg_model
		end
	end
	return nil
end

local function update_esp(object_id: string, pet_name: string)
	if not esp_enabled then return end
	local object = get_object_from_id(object_id)
	if not object or not esp_cache[object_id] then return end

	if not pet_name or pet_name == "?" then
		esp_cache[object_id].Text = "Not Ready"
		esp_cache[object_id].Color = Color3.new(1, 0, 0)
	else
		esp_cache[object_id].Text = pet_name
		esp_cache[object_id].Color = Color3.new(0, 1, 0)
	end
end

local function add_esp(object: Instance)
	if not esp_enabled then return end
	if object:GetAttribute("OWNER") ~= local_player.Name then return end

	local pet_name = egg_pets[object:GetAttribute("OBJECT_UUID")]
	local object_id = object:GetAttribute("OBJECT_UUID")
	if not object_id then return end

	local label = Drawing.new("Text")
	if pet_name then
		label.Text = pet_name
		label.Color = Color3.new(0, 1, 0)
	else
		label.Text = "Not Ready"
		label.Color = Color3.new(1, 0, 0)
	end
	label.Size = 18
	label.Outline = true
	label.OutlineColor = Color3.new(0, 0, 0)
	label.Center = true
	label.Visible = false

	esp_cache[object_id] = label
	active_eggs[object_id] = object
end

local function remove_esp(object: Instance)
	local object_id = object:GetAttribute("OBJECT_UUID")
	if esp_cache[object_id] then
		esp_cache[object_id]:Remove()
		esp_cache[object_id] = nil
	end
	active_eggs[object_id] = nil
end

local function clear_all_esp()
	for _, label in esp_cache do
		if label then label:Remove() end
	end
	esp_cache = {}
	active_eggs = {}
end

local function update_all_esp()
	if not esp_enabled then
		for _, label in esp_cache do
			label.Visible = false
		end
		return
	end

	for object_id, object in active_eggs do
		if not object or not object:IsDescendantOf(workspace) then
			active_eggs[object_id] = nil
			if esp_cache[object_id] then
				esp_cache[object_id].Visible = false
			end
			continue
		end

		local label = esp_cache[object_id]
		if label then
			local pos, on_screen = current_camera:WorldToViewportPoint(object:GetPivot().Position + Vector3.new(0, 3, 0))
			if on_screen then
				label.Position = Vector2.new(pos.X, pos.Y)
				label.Visible = true
			else
				label.Visible = false
			end
		end
	end
end

CollectionService:GetInstanceAddedSignal("PetEggServer"):Connect(function(obj)
	if esp_enabled then add_esp(obj) end
end)
CollectionService:GetInstanceRemovedSignal("PetEggServer"):Connect(remove_esp)

local old_function
old_function = hookfunction(getconnections(ReplicatedStorage.GameEvents.EggReadyToHatch_RE.OnClientEvent)[1].Function, newcclosure(function(object_id, pet_name)
	if esp_enabled then
		update_esp(object_id, pet_name)
	end
	return old_function(object_id, pet_name)
end))

RunService.PreRender:Connect(update_all_esp)

local Toggle = Tab3:AddToggle("ESP Egg", false, function(v)
    esp_enabled = v
    if not v then
        clear_all_esp()
    else
        for _, object in CollectionService:GetTagged("PetEggServer") do
            add_esp(object)
        end
    end
end)
---------------------------------------------------
--// ESP Fruit
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Farm = workspace:WaitForChild("Farm")
local Important = Farm:WaitForChild("Farm"):WaitForChild("Important")
local plantFolder = Important:WaitForChild("Plants_Physical")
local CalculatePlantValue = require(ReplicatedStorage.Modules.CalculatePlantValue)

getgenv().SelectedFruit = nil
getgenv().FruitESPEnabled = false

local function formatNumber(n)
    local str = tostring(math.floor(n))
    return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function clearESP()
    for _, plant in ipairs(plantFolder:GetChildren()) do
        if plant:FindFirstChild("Fruits") then
            for _, fruit in ipairs(plant.Fruits:GetChildren()) do
                local bb = fruit:FindFirstChild("FruitBillboard")
                if bb then bb:Destroy() end
            end
        end
    end
end

local function createESP(fruit, name)
    if not fruit or not fruit.Parent then return end
    local base = fruit:FindFirstChild("Base") or fruit
    if not base or base:FindFirstChild("FruitBillboard") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "FruitBillboard"
    billboard.Adornee = base
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 160, 0, 36)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Parent = base

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0, 160, 0)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true

    local weight = (fruit:FindFirstChild("Weight") and fruit.Weight.Value) or 0
    local value = 0
    local ok, result = pcall(function() return CalculatePlantValue(fruit) end)
    if ok and typeof(result) == "number" then value = result end

    label.Text = string.format("%s\n%.2f kg | $%s", tostring(name), weight, formatNumber(value))
    label.Parent = billboard
end

local function updateESP()
    clearESP()
    if not getgenv().FruitESPEnabled or not getgenv().SelectedFruit then return end
    local plant = plantFolder:FindFirstChild(getgenv().SelectedFruit)
    if plant and plant:FindFirstChild("Fruits") then
        for _, fruit in ipairs(plant.Fruits:GetChildren()) do
            createESP(fruit, getgenv().SelectedFruit)
        end
    end
end

local fruitList = {
    "Serenity","Tranquil Bloom","Carrot","Strawberry","Blueberry","Tomato","Bamboo","Cactus","Pepper","Cacao",
    "Blood Banana","Giant Pinecone","Pumpkin","Beanstalk","Watermelon","Pineapple","Grape","Sugar Apple",
    "Pitcher Plant","Feijoa","Prickly Pear","Pear","Apple","Dragonfruit","Coconut","Mushroom","Orange Tulip",
    "Corn","Candy Blossom","Bone Blossom","Moon Blossom"
}

local Dropdown = Tab3:AddDropdown("Pick Fruit", fruitList)
Dropdown.OnChanged:Connect(function(val)
    if typeof(val) == "table" then val = val[1] end
    getgenv().SelectedFruit = val
    updateESP()
end)

local Toggle = Tab3:AddToggle("ESP Fruit", false, function(v)
    getgenv().FruitESPEnabled = v
    if not v then clearESP() else updateESP() end
end)

plantFolder.ChildAdded:Connect(function()
    if getgenv().FruitESPEnabled then task.wait(0.2) updateESP() end
end)
plantFolder.ChildRemoved:Connect(updateESP)

task.spawn(function()
    while task.wait(5) do
        if getgenv().FruitESPEnabled then updateESP() end
    end
end)

---------------------------------------------------
--// Walk Speed + Infinite Jump
getgenv().WalkSpeedEnabled = false
getgenv().CurrentSpeed = 50
getgenv().DefaultSpeed = 16
getgenv().InfiniteJumpEnabled = false

local function getHumanoid()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChildOfClass("Humanoid") end
end

local SpeedSlider = Tab4:AddSlider("Speed",0,500,50,function(v)
    getgenv().CurrentSpeed=v
end)

local SpeedToggle = Tab4:AddToggle("Walk Speed", false, function(v)
    getgenv().WalkSpeedEnabled=v
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = v and getgenv().CurrentSpeed or getgenv().DefaultSpeed
    end
end)

local InfiniteJumpToggle = Tab4:AddToggle("Infinite Jump", false, function(v)
    getgenv().InfiniteJumpEnabled=v
end)

UserInputService.JumpRequest:Connect(function()
    if getgenv().InfiniteJumpEnabled then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Heartbeat:Connect(function()
    if getgenv().WalkSpeedEnabled then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = getgenv().CurrentSpeed end
    end
end)
