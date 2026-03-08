-- Simple Update GUI

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "UpdateNotice"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Frame utama
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,300,0,150)
frame.Position = UDim2.new(0.5,-150,0.5,-75)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0
frame.Parent = gui

-- Judul
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,40)
title.BackgroundTransparency = 1
title.Text = "Informasi"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

-- Pesan
local message = Instance.new("TextLabel")
message.Size = UDim2.new(1,-20,0,60)
message.Position = UDim2.new(0,10,0,45)
message.BackgroundTransparency = 1
message.Text = "Script sedang di update.\nSilakan tunggu versi terbaru."
message.TextColor3 = Color3.fromRGB(200,200,200)
message.TextWrapped = true
message.TextScaled = true
message.Font = Enum.Font.Gotham
message.Parent = frame

-- Tombol Close
local close = Instance.new("TextButton")
close.Size = UDim2.new(0,100,0,35)
close.Position = UDim2.new(0.5,-50,1,-45)
close.BackgroundColor3 = Color3.fromRGB(200,60,60)
close.Text = "Close"
close.TextColor3 = Color3.new(1,1,1)
close.TextScaled = true
close.Font = Enum.Font.GothamBold
close.Parent = frame

-- Function close
close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)
