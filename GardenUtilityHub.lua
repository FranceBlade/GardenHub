--// Load the UI Library
local Library = loadstring(game:HttpGet("https://pastebin.com/raw/VHkYJF6H"))()
local Lib = Library.CreateLibrary("Binz Hub", "Grow a Garden")
Library.CreateFloatingIcon(Lib, "rbxassetid://81222227536540", 56)

--// Tabs
local Tab = Lib:AddTab("Home","rbxassetid://106809791072683")
local Tab2 = Lib:AddTab("Main","rbxassetid://105364893099735")
local Tab3 = Lib:AddTab("Others","rbxassetid://116044796070364")
local Tab4 = Lib:AddTab("Misc","rbxassetid://88316127549460")

--// Services & Player
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Workspace = workspace

---------------------------------------------------
--// Auto Collect
local CollectRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Crops"):WaitForChild("Collect")
getgenv().SelectedFruit = nil
getgenv().AutoCollect = false
local fruits = {"Carrot","Strawberry","Blueberry","Tomato","Bamboo","Cactus","Pepper","Cacao","Pumpkin","Watermelon","Pineapple","Grape","Feijoa","Prickly Pear","Pear","Apple","Dragonfruit","Coconut","Mushroom","Orange Tulip","Corn","Beanstalk","Sugar Apple","Pitcher Plant","Giant Pinecone","Elder Strawberry","Bone Blossom","Candy Blossom"}
local FruitDropdown = Tab:AddDropdown("Pick Fruit", fruits)
FruitDropdown.OnChanged:Connect(function(val) getgenv().SelectedFruit = typeof(val)=="table" and val[1] or val end)
Tab:AddToggle("Auto Collect", false, function(v) getgenv().AutoCollect = v end)
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().AutoCollect and getgenv().SelectedFruit then
            local toCollect = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and obj:HasTag("CollectPrompt") then
                    local model = obj.Parent
                    while model and not model:IsA("Model") do model = model.Parent end
                    if model and string.find(model.Name, getgenv().SelectedFruit, 1, true) then table.insert(toCollect, model) end
                end
            end
            if #toCollect>0 then pcall(function() CollectRemote:FireServer(toCollect) end) end
        end
    end
end)

---------------------------------------------------
--// Auto Plant
getgenv().SelectedSeed = nil
getgenv().AutoPlant = false
local seeds = fruits
local function equipSeed(seedName)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local current = char:FindFirstChildOfClass("Tool")
    if current and current.Name:lower():find(seedName:lower()) then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find(seedName:lower().." seed") then hum:EquipTool(tool); return end
        end
    end
end
local SeedDropdown = Tab:AddDropdown("Pick Seed", seeds)
SeedDropdown.OnChanged:Connect(function(val) getgenv().SelectedSeed = typeof(val)=="table" and val[1] or val end)
Tab:AddToggle("Auto Plant", false, function(v) getgenv().AutoPlant = v end)
RunService.Heartbeat:Connect(function()
    if getgenv().AutoPlant and getgenv().SelectedSeed then
        equipSeed(getgenv().SelectedSeed)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos = hrp.Position
            pcall(function() ReplicatedStorage.GameEvents.Plant_RE:FireServer(Vector3.new(pos.X,pos.Y,pos.Z), getgenv().SelectedSeed) end)
            task.wait(1.2)
        end
    end
end)

---------------------------------------------------
--// Auto Buy
local Events = ReplicatedStorage:WaitForChild("GameEvents")
local selectedSeeds, selectedGears, selectedEggs = {}, {}, {}
getgenv().AutoBuy = false
local autoBuyRunning = false
local SeedDropdown2 = Tab2:AddDropdown("Seed List", seeds)
SeedDropdown2.OnChanged:Connect(function(val) selectedSeeds = typeof(val)=="table" and val or {tostring(val)} end)
local GearDropdown = Tab2:AddDropdown("Gear List", {"Watering Can","Trowel","Recall Wrench","Basic Sprinkler","Advance Sprinkler","Medium Toy","Trading Ticket","Medium Treat","Godly Sprinkler","Magnifying Glass","Tanning Mirror","Master Sprinkler","Grandmaster Sprinkler","Cleaning Spray","Favorite Tool","Harvest Tool","Friendship Pot","Levelup Lollipop"})
GearDropdown.OnChanged:Connect(function(val) selectedGears = typeof(val)=="table" and val or {tostring(val)} end)
local EggDropdown = Tab2:AddDropdown("Pet Egg List", {"Common Egg","Common Summer Egg","Rare Summer Egg","Mythical Egg","Paradise Egg","Bug Egg"})
EggDropdown.OnChanged:Connect(function(val) selectedEggs = typeof(val)=="table" and val or {tostring(val)} end)
Tab2:AddToggle("Auto Buy", false, function(v)
    getgenv().AutoBuy = v
    if v and not autoBuyRunning then
        autoBuyRunning = true
        task.spawn(function()
            while getgenv().AutoBuy do
                for _, s in ipairs(selectedSeeds) do pcall(function() Events.BuySeedStock:FireServer(s) end) end
                for _, g in ipairs(selectedGears) do pcall(function() Events.BuyGearStock:FireServer(g) end) end
                for _, e in ipairs(selectedEggs) do pcall(function() Events.BuyPetEgg:FireServer(e) end) end
                task.wait(0.5)
            end
            autoBuyRunning = false
        end)
    end
end)

---------------------------------------------------
--// Auto Shovel
local DeleteObject = Events:WaitForChild("DeleteObject")
local SprinklerFolder = Workspace:WaitForChild("Farm"):WaitForChild("Farm"):WaitForChild("Important"):WaitForChild("Objects_Physical")
local selectedSprinklers, autoShovelState = {}, false
local sprinklerNames = {"Basic Sprinkler","Advanced Sprinkler","Godly Sprinkler","Master Sprinkler","Honey Sprinkler","Chocolate Sprinkler"}
local SprinklerDropdown = Tab3:AddDropdown("Sprinkler List", sprinklerNames)
SprinklerDropdown.OnChanged:Connect(function(val)
    if typeof(val)=="table" then selectedSprinklers={} for _,v in ipairs(val) do selectedSprinklers[v]=true end
    else selectedSprinklers[val] = not selectedSprinklers[val] end
end)
Tab3:AddToggle("Auto Shovel", false, function(v) autoShovelState=v end)
local function equipShovel()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local current = char:FindFirstChildOfClass("Tool")
    if current and current.Name:lower():find("shovel") then return end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:lower():find("shovel") then hum:EquipTool(tool); return end
        end
    end
end
task.spawn(function()
    while task.wait(0.3) do
        if autoShovelState and next(selectedSprinklers) then
            equipShovel()
            for _, model in ipairs(SprinklerFolder:GetChildren()) do
                for name,_ in pairs(selectedSprinklers) do
                    if model.Name:lower():find(name:lower()) then pcall(function() DeleteObject:FireServer(model) end) break end
                end
            end
        end
    end
end)

---------------------------------------------------
--// ESP Egg & Fruit
local current_camera = Workspace.CurrentCamera
local esp_enabled, esp_cache, active_eggs = false, {}, {}
local hatch_function = getupvalue(getupvalue(getconnections(Events.PetEggService.OnClientEvent)[1].Function,1),2)
local egg_models, egg_pets = getupvalue(hatch_function,1), getupvalue(hatch_function,2)
local function get_object_from_id(object_id) for _,egg_model in ipairs(egg_models) do if egg_model:GetAttribute("OBJECT_UUID")==object_id then return egg_model end end return nil end
local function update_esp(object_id,pet_name) if not esp_enabled then return end local object = get_object_from_id(object_id) if not object or not esp_cache[object_id] then return end esp_cache[object_id].Text = (pet_name and pet_name~="?" and pet_name) or "Not Ready"; esp_cache[object_id].Color = pet_name and Color3.new(0,1,0) or Color3.new(1,0,0) end
local function add_esp(object) if not esp_enabled or object:GetAttribute("OWNER")~=LocalPlayer.Name then return end local pet_name = egg_pets[object:GetAttribute("OBJECT_UUID")] local object_id = object:GetAttribute("OBJECT_UUID") if not object_id then return end local label = Drawing.new("Text") label.Text = pet_name or "Not Ready"; label.Color = pet_name and Color3.new(0,1,0) or Color3.new(1,0,0); label.Size=18; label.Outline=true; label.OutlineColor=Color3.new(0,0,0); label.Center=true; label.Visible=false esp_cache[object_id]=label; active_eggs[object_id]=object end
local function remove_esp(object) local id=object:GetAttribute("OBJECT_UUID") if esp_cache[id] then esp_cache[id]:Remove(); esp_cache[id]=nil end active_eggs[id]=nil end
local function clear_all_esp() for _,label in esp_cache do if label then label:Remove() end end; esp_cache={}; active_eggs={} end
local function update_all_esp()
    if not esp_enabled then for _,label in esp_cache do label.Visible=false end return end
    for object_id,object in active_eggs do
        if not object or not object:IsDescendantOf(Workspace) then active_eggs[object_id]=nil; if esp_cache[object_id] then esp_cache[object_id].Visible=false end continue end
        local label=esp_cache[object_id]
        if label then
            local pos,on_screen = current_camera:WorldToViewportPoint(object:GetPivot().Position+Vector3.new(0,3,0))
            label.Position=Vector2.new(pos.X,pos.Y); label.Visible=on_screen
        end
    end
end
CollectionService:GetInstanceAddedSignal("PetEggServer"):Connect(function(obj) if esp_enabled then add_esp(obj) end end)
CollectionService:GetInstanceRemovedSignal("PetEggServer"):Connect(remove_esp)
local old_func = hookfunction(getconnections(Events.EggReadyToHatch_RE.OnClientEvent)[1].Function,newcclosure(function(id,name) if esp_enabled then update_esp(id,name) end return old_func(id,name) end))
RunService.PreRender:Connect(update_all_esp)
Tab3:AddToggle("ESP Egg", false, function(v) esp_enabled=v; if not v then clear_all_esp() else for _,obj in CollectionService:GetTagged("PetEggServer") do add_esp(obj) end end)

--// ESP Fruit
local Farm = Workspace:WaitForChild("Farm")
local Important = Farm:WaitForChild("Farm"):WaitForChild("Important")
local plantFolder = Important:WaitForChild("Plants_Physical")
local CalculatePlantValue = require(ReplicatedStorage.Modules.CalculatePlantValue)
getgenv().FruitESPEnabled=false
local function formatNumber(n) return tostring(math.floor(n)):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","") end
local function clearESP() for _,plant in ipairs(plantFolder:GetChildren()) do if plant:FindFirstChild("Fruits") then for _,fruit in ipairs(plant.Fruits:GetChildren()) do local bb = fruit:FindFirstChild("FruitBillboard"); if bb then bb:Destroy() end end end end end
local function createESP(fruit,name) if not fruit or not fruit.Parent then return end local base = fruit:FindFirstChild("Base") or fruit if not base or base:FindFirstChild("FruitBillboard") then return end local bb = Instance.new("BillboardGui"); bb.Name="FruitBillboard"; bb.Adornee=base; bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,160,0,36); bb.StudsOffset=Vector3.new(0,2,0); bb.Parent=base local label = Instance.new("TextLabel"); label.Size=UDim2.new(1,0,1,0); label.BackgroundTransparency=1; label.TextColor3=Color3.fromRGB(0,160,0); label.TextStrokeTransparency=0; label.TextStrokeColor3=Color3.fromRGB(0,0,0); label.Font=Enum.Font.GothamBold; label.TextScaled=true; local weight=(fruit:FindFirstChild("Weight") and fruit.Weight.Value) or 0 local value = 0; pcall(function() value=CalculatePlantValue(fruit) end) label.Text=string.format("%s\n%.2f kg | $%s",tostring(name),weight,formatNumber(value)); label.Parent=bb end
local function updateESP() clearESP() if not getgenv().FruitESPEnabled or not getgenv().SelectedFruit then return end local plant=plantFolder:FindFirstChild(getgenv().SelectedFruit) if plant and plant:FindFirstChild("Fruits") then for _,fruit in ipairs(plant.Fruits:GetChildren()) do createESP(fruit,getgenv().SelectedFruit) end end end
local fruitList = {"Serenity","Tranquil Bloom","Carrot","Strawberry","Blueberry","Tomato","Bamboo","Cactus","Pepper","Cacao","Blood Banana","Giant Pinecone","Pumpkin","Beanstalk","Watermelon","Pineapple","Grape","Sugar Apple","Pitcher Plant","Feijoa","Prickly Pear","Pear","Apple","Dragonfruit","Coconut","Mushroom","Orange Tulip","Corn","Candy Blossom","Bone Blossom","Moon Blossom"}
local FruitESPDropdown = Tab3:AddDropdown("Pick Fruit",fruitList)
FruitESPDropdown.OnChanged:Connect(function(val) getgenv().SelectedFruit = typeof(val)=="table" and val[1] or val; updateESP() end)
Tab3:AddToggle("ESP Fruit", false, function(v) getgenv().FruitESPEnabled=v; if not v then clearESP() else updateESP() end end)
plantFolder.ChildAdded:Connect(function() if getgenv().FruitESPEnabled then task.wait(0.2); updateESP() end end)
plantFolder.ChildRemoved:Connect(updateESP)
task.spawn(function() while task.wait(5) do if getgenv().FruitESPEnabled then updateESP() end end end)

---------------------------------------------------
--// Walk Speed
local WalkSpeedEnabled=false; local CurrentSpeed=50; local DefaultSpeed=16
local function getHumanoid() local char=LocalPlayer.Character; return char and char:FindFirstChildOfClass("Humanoid") end
Tab4:AddSlider("Speed",0,500,50,function(v) CurrentSpeed=v end)
Tab4:AddToggle("Walk Speed",false,function(v) WalkSpeedEnabled=v; local hum=getHumanoid(); if hum then hum.WalkSpeed=WalkSpeedEnabled and CurrentSpeed or DefaultSpeed end end)
RunService.RenderStepped:Connect(function() local hum=getHumanoid(); if hum then hum.WalkSpeed=hum.WalkSpeed + ((WalkSpeedEnabled and CurrentSpeed or DefaultSpeed)-hum.WalkSpeed)*0.6 end end)
LocalPlayer.CharacterAdded:Connect(function(char) char:WaitForChild("Humanoid").WalkSpeed=WalkSpeedEnabled and CurrentSpeed or DefaultSpeed end)

---------------------------------------------------
--// Infinite Jump
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local InfiniteJumpEnabled=false
UserInputService.JumpRequest:Connect(function() if InfiniteJumpEnabled then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end)
Tab4:AddToggle("Infinite Jump",false,function(v) InfiniteJumpEnabled=v end)
