-- ======================================================
-- INFORMATION UPDATE POPUP (WHATSAPP CHANNEL EDITION)
-- ======================================================

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- Bersihkan jika ada UI lama
if CoreGui:FindFirstChild("InformationUpdatePopup") then
    CoreGui.InformationUpdatePopup:Destroy()
end

-- ================= CONFIG =================
local WhatsAppLink = "https://www.whatsapp.com/channel/0029VbCBSBOCRs1pRNYpPN0r"
local AccentColor = Color3.fromRGB(255, 255, 255)
local BgColor = Color3.fromRGB(15, 15, 15)

-- 1️⃣ Root UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InformationUpdatePopup"
ScreenGui.Parent = CoreGui

-- 2️⃣ Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.Size = UDim2.new(0, 320, 0, 160)
MainFrame.Position = UDim2.new(0.5, -160, 1, 60)
MainFrame.BackgroundColor3 = BgColor
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 1
UIStroke.Color = AccentColor
UIStroke.Transparency = 0.8
UIStroke.Parent = MainFrame

-- 3️⃣ Title
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 12)
Title.BackgroundTransparency = 1
Title.Text = "INFORMATION UPDATE"
Title.TextColor3 = AccentColor
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold

-- 4️⃣ Description
local Desc = Instance.new("TextLabel")
Desc.Parent = MainFrame
Desc.Size = UDim2.new(0.85, 0, 0, 45)
Desc.Position = UDim2.new(0.075, 0, 0, 50)
Desc.BackgroundTransparency = 1
Desc.Text = "Join our WhatsApp channel to get the latest update info."
Desc.TextColor3 = AccentColor
Desc.TextTransparency = 0.4
Desc.TextSize = 12
Desc.Font = Enum.Font.Gotham
Desc.TextWrapped = true

-- 5️⃣ Copy Button
local CopyBtn = Instance.new("TextButton")
CopyBtn.Parent = MainFrame
CopyBtn.Size = UDim2.new(0.42, 0, 0, 38)
CopyBtn.Position = UDim2.new(0.08, 0, 0, 105)
CopyBtn.BackgroundColor3 = AccentColor
CopyBtn.Text = "Wa channel link"
CopyBtn.TextColor3 = BgColor
CopyBtn.TextSize = 12
CopyBtn.Font = Enum.Font.GothamMedium
CopyBtn.AutoButtonColor = false

local UICornerBtn = Instance.new("UICorner")
UICornerBtn.CornerRadius = UDim.new(0, 8)
UICornerBtn.Parent = CopyBtn

-- 6️⃣ Later Button
local CloseBtn = CopyBtn:Clone()
CloseBtn.Parent = MainFrame
CloseBtn.Position = UDim2.new(0.52, 0, 0, 105)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CloseBtn.Text = "Later"
CloseBtn.TextColor3 = AccentColor

-- ================= ANIMATION =================

-- Animate In
MainFrame:TweenPosition(UDim2.new(0.5, -160, 0.5, -80), "Out", "Quart", 1, true)

-- Copy Logic
CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(WhatsAppLink)
        CopyBtn.Text = "Copied!"
        task.wait(2)
        CopyBtn.Text = "Wa channel Link"
    else
        CopyBtn.Text = "Not Supported"
    end
end)

-- Close Logic
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame:TweenPosition(UDim2.new(0.5, -160, 1, 60), "In", "Quart", 0.8, true)
    task.wait(0.8)
    ScreenGui:Destroy()
end)

-- Hover Effect
local function addHover(btn, colorOn, colorOff)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.25), {BackgroundColor3 = colorOn}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.25), {BackgroundColor3 = colorOff}):Play()
    end)
end

addHover(CopyBtn, Color3.fromRGB(200,200,200), AccentColor)
addHover(CloseBtn, Color3.fromRGB(60,60,60), Color3.fromRGB(40,40,40))

print("INFORMATION UPDATE POPUP LOADED")
