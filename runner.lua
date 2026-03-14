-- =========================================
-- SAZARAAAX CLEAN LOADING (BOTTOM RIGHT)
-- Fade In - Fade Out Animation
-- =========================================

if _G.SazaraaaxRunnerActive then
    return
end

_G.SazaraaaxRunnerActive = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then return end

local playerGui = player:WaitForChild("PlayerGui")

-- Destroy old if exists (hanya yang bernama sama, jangan hancurkan GUI lain)
local old = playerGui:FindFirstChild("RimuruHub")
if old then
    old:Destroy()
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "RimuruHub"
gui.ResetOnSpawn = false
gui.Parent = playerGui

-- Text
local text = Instance.new("TextLabel")
text.BackgroundTransparency = 1
text.Size = UDim2.new(0, 300, 0, 40)
text.AnchorPoint = Vector2.new(1,1)
text.Position = UDim2.new(1, -20, 1, -20) -- kanan bawah
text.Text = "by ryuhan"
text.Font = Enum.Font.GothamBold
text.TextSize = 18
text.TextColor3 = Color3.fromRGB(255,255,255)
text.TextTransparency = 1
text.TextStrokeTransparency = 1
text.Parent = gui

-- Fade animation loop
local running = true

task.spawn(function()
    while running and gui.Parent do

        -- Fade In
        local fadeIn = TweenService:Create(text, TweenInfo.new(0.8), {
            TextTransparency = 0
        })
        fadeIn:Play()
        fadeIn.Completed:Wait()

        task.wait(0.4)

        -- Fade Out
        local fadeOut = TweenService:Create(text, TweenInfo.new(0.8), {
            TextTransparency = 1
        })
        fadeOut:Play()
        fadeOut.Completed:Wait()

        task.wait(0.2)
    end
end)

-- Destroy function
_G.DestroySazaraaaxRunner = function()

    if not _G.SazaraaaxRunnerActive then
        return
    end

    _G.SazaraaaxRunnerActive = false
    running = false

    if gui then
        gui:Destroy()
    end
end
