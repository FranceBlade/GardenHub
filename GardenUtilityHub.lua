-- 🌱 Garden Utility Hub
-- ✅ Features: Infinite Seed Crafter, Auto Pet EXP, Anti-AFK
-- 👤 Made by France Blade | 📌 Discord: discord.gg/YOURINVITE

local library = loadstring(game:HttpGet("https://pastebin.com/raw/EDsBYg52"))()
local window = library:CreateWindow("🌱 Garden Utility Hub")

local crafting, autoExp = false, false
local selectedSeed, delayTime = "Sunflower", 0.1

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local craftSeedRemote = ReplicatedStorage:FindFirstChild("CraftSeed")
local petExpRemote = ReplicatedStorage:FindFirstChild("PetExp")

-- UI components below...

window:Dropdown("🌱 Select Seed", {"Sunflower", "Carrot", "Apple", "Pumpkin"}, function(val) selectedSeed = val end)

window:Slider("🕒 Craft Delay (sec)", { min = 0.1, max = 3, precise = true }, function(val) delayTime = val end)

window:Toggle("♻️ Auto Craft Seeds", false, function(on)
  crafting = on
  task.spawn(function()
    while crafting and craftSeedRemote do
      task.wait(delayTime)
      pcall(function() craftSeedRemote:FireServer(selectedSeed) end)
    end
  end)
end)

window:Toggle("💠 Auto Pet EXP (All Equipped)", false, function(on)
  autoExp = on
  task.spawn(function()
    while autoExp and petExpRemote do
      task.wait(0.5)
      local petsFolder = player:FindFirstChild("Pets")
      if petsFolder then
        for _, pet in ipairs(petsFolder:GetChildren()) do
          pcall(function() petExpRemote:FireServer(pet.Name) end)
          task.wait(0.1)
        end
      end
    end
  end)
end)

window:Toggle("💤 Anti-AFK", false, function(on)
  if on then
    local vu = game:GetService("VirtualUser")
    player.Idled:Connect(function()
      vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
      task.wait(1)
      vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
    print("[Anti-AFK] Enabled.")
  end
end)

window:Label("Made by: France Blade")
window:Label("Join Discord: discord.gg/YOURINVITE")
