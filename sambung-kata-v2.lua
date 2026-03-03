-- =========================================================
-- ULTRA SMART AUTO KATA (FULL INTEGRATED + LOADING STATUS)
-- Fitur: Auto play, SimpleSpy, Status Loading
-- WindUI Build
-- =========================================================

-- =========================
-- ANTI DOUBLE-EXECUTE
-- =========================
if _G.AutoKataActive then
    if type(_G.AutoKataDestroy) == "function" then
        pcall(_G.AutoKataDestroy)
    end
    task.wait(0.3)
end
_G.AutoKataActive = true
_G.AutoKataDestroy = nil

-- =========================
-- WAIT GAME LOAD
-- =========================
if not game:IsLoaded() then
    game.Loaded:Wait()
end
if _G.DestroySazaraaaxRunner then
    pcall(function()
        _G.DestroySazaraaaxRunner()
    end)
end
if math.random() < 1 then
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/danzzy1we/gokil2/refs/heads/main/copylinkgithub.lua"))()
    end)
end
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/fay23-dam/sazaraaax-script/refs/heads/main/runner.lua"))()
end)
task.wait(3)

-- =========================
-- LOAD WIND UI
-- =========================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- =========================
-- SERVICES
-- =========================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- CACHE CHECK
-- =========================
local CAN_SAVE = pcall(function() readfile("test.txt") end) and true or false

-- =========================
-- DISCORD WEBHOOK
-- =========================
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1478097119079563396/gIxWk9eU5r5erugPGrMR1Y8ad039nSlDl8GP9pFKfZ41asWNjZvejtm1qpJHuESM2Z8j"

local function maskStr(s, keep)
    s = tostring(s); keep = keep or 4
    if #s <= keep then return s end
    return s:sub(1, keep) .. string.rep("*", #s - keep)
end

local function sendDiscordMsg(contentStr)
    task.spawn(function()
        local ok, payload = pcall(function()
            return HttpService:JSONEncode({ content = contentStr, username = "DhanxSaza Hub" })
        end)
        if not ok then return end

        local sent = false

        -- Method 1: syn.request (Synapse X)
        if not sent and syn and syn.request then
            local ok2, res = pcall(function()
                return syn.request({
                    Url     = DISCORD_WEBHOOK,
                    Method  = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body    = payload,
                })
            end)
            if ok2 and res and (res.StatusCode == 200 or res.StatusCode == 204) then
                sent = true
            end
        end

        -- Method 2: request (global, Krnl/Fluxus dll)
        if not sent and request then
            local ok3, res = pcall(function()
                return request({
                    Url     = DISCORD_WEBHOOK,
                    Method  = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body    = payload,
                })
            end)
            if ok3 and res and (res.StatusCode == 200 or res.StatusCode == 204) then
                sent = true
            end
        end

        -- Method 3: http.request
        if not sent and http and http.request then
            local ok4, res = pcall(function()
                return http.request({
                    Url     = DISCORD_WEBHOOK,
                    Method  = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body    = payload,
                })
            end)
            if ok4 and res and (res.StatusCode == 200 or res.StatusCode == 204) then
                sent = true
            end
        end

        -- Method 4: HttpService:PostAsync fallback
        if not sent then
            pcall(function()
                HttpService:PostAsync(
                    DISCORD_WEBHOOK, payload,
                    Enum.HttpContentType.ApplicationJson, false
                )
            end)
        end
    end)
end

local function sendLoginNotif()
    local lp = LocalPlayer
    local ok, gn = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    local gameName = (ok and type(gn) == "string" and gn ~= "") and gn or tostring(game.PlaceId)
    local timeStr = tostring(os.time())
    pcall(function() timeStr = os.date("!%Y-%m-%d %H:%M:%S") end)

    sendDiscordMsg(
        "✅ **DhanxSaza Hub** - LOGIN"
        .. "\nUser: `" .. maskStr(lp.Name, 4) .. "`"
        .. "\nUser ID: `" .. maskStr(tostring(lp.UserId), 3) .. "`"
        .. "\nGame: `" .. gameName .. "`"
        .. "\nTime: `" .. timeStr .. "`"
        .. "\nDhanxSaza Hub"
    )
end

-- =========================
-- CREATE WINDOW UI
-- =========================
local Window = WindUI:CreateWindow({
    Title = "Sambung-kata",
    SubTitle = "Optimized (No Aggression/Length)",
    ShowCustomCursor = true,
    KeySystem = false,
    Folder = "SambungKata",
})

_G.AutoKataDestroy = function()
    autoEnabled = false
    autoRunning = false
    matchActive = false
    isMyTurn = false
    pcall(function() Window:Destroy() end)
    _G.AutoKataActive = false
    _G.AutoKataDestroy = nil
end

local function notify(title, message, time)
    WindUI:Notify({
        Title = title,
        Content = message,
        Duration = time or 2.5,
    })
end

-- =========================
-- TAB UTAMA (loading status)
-- =========================
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "lucide:home",
})

local loadingStatus = MainTab:Paragraph({
    Title = "Memuat Wordlist",
    Desc = "Inisialisasi... 0%",
    Color = "Blue",
})

local statusParagraph = MainTab:Paragraph({
    Title = "Status",
    Desc = "Menunggu loading...",
    Color = "Blue",
})

-- =========================
-- LOAD WORDLIST & WRONG WORDLIST (PARALEL)
-- =========================
local kataModule = {}
local wrongWordsSet = {}
local wordsByFirstLetter = {}
local rankingMap = {}
local RANKING_URL = "https://raw.githubusercontent.com/fay23-dam/sazaraaax-script/refs/heads/main/wordworng/ranking_kata%20(1).json"
local WRONG_WORDS_URL = "https://raw.githubusercontent.com/fay23-dam/sazaraaax-script/refs/heads/main/wordworng/a3x.lua"
local WORDLIST_CACHE_FILE = "ranking_kata_cache.json"
local WRONG_WORDLIST_CACHE_FILE = "wrong_words_cache.lua"

local function loadCachedData(url, cacheFile, isJson, progressCallback)
    if CAN_SAVE then
        local success, data = pcall(readfile, cacheFile)
        if success and data then
            if isJson then
                local success2, decoded = pcall(HttpService.JSONDecode, HttpService, data)
                if success2 then
                    if progressCallback then progressCallback(100) end
                    return decoded
                end
            else
                local loadFunc = loadstring(data)
                if loadFunc then
                    local result = loadFunc()
                    if type(result) == "table" then
                        if progressCallback then progressCallback(100) end
                        return result
                    end
                end
            end
        end
    end

    if progressCallback then progressCallback(10) end
    local response = game:HttpGet(url)
    if not response then return nil end
    if progressCallback then progressCallback(50) end

    local result
    if isJson then
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, response)
        if not success then return nil end
        result = decoded
    else
        local loadFunc = loadstring(response)
        if not loadFunc then
            response = response:gsub("%[", "{"):gsub("%]", "}")
            loadFunc = loadstring(response)
        end
        if not loadFunc then return nil end
        result = loadFunc()
        if type(result) ~= "table" then return nil end
    end
    if progressCallback then progressCallback(90) end

    if CAN_SAVE then
        if isJson then
            pcall(writefile, cacheFile, response)
        else
            pcall(writefile, cacheFile, response)
        end
    end
    if progressCallback then progressCallback(100) end
    return result
end

local function loadMainWordlist(progressFn)
    local data = loadCachedData(RANKING_URL, WORDLIST_CACHE_FILE, true, progressFn)
    if not data or type(data) ~= "table" then return false end

    local seen = {}
    local uniqueWords = {}
    table.clear(rankingMap)

    for _, entry in ipairs(data) do
        if type(entry.word) == "string" then
            local w = string.lower(entry.word)
            if w:match("^[a-z]+$") and #w > 1 and not seen[w] then
                seen[w] = true
                uniqueWords[#uniqueWords + 1] = w
                rankingMap[w] = entry.score or 0
            end
        end
    end

    kataModule = uniqueWords
    return true
end

local function loadWrongWordlist(progressFn)
    local words = loadCachedData(WRONG_WORDS_URL, WRONG_WORDLIST_CACHE_FILE, false, progressFn)
    if not words then return false end

    table.clear(wrongWordsSet)
    for i = 1, #words do
        local word = words[i]
        if type(word) == "string" then
            wrongWordsSet[string.lower(word)] = true
        end
    end
    return true
end

local function buildIndex()
    wordsByFirstLetter = {}
    for i = 1, #kataModule do
        local word = kataModule[i]
        local first = string.sub(word, 1, 1)
        local bucket = wordsByFirstLetter[first]
        if bucket then
            bucket[#bucket + 1] = word
        else
            wordsByFirstLetter[first] = { word }
        end
    end
end

local totalProgress = 0
local wrongDone = false
local mainDone = false

local function updateOverallProgress()
    local p = 0
    if wrongDone then p = p + 50 end
    if mainDone then p = p + 50 end
    loadingStatus:SetDesc(string.format("Memuat wordlist... %d%%", p))
    if p >= 100 then
        loadingStatus:SetDesc(string.format("Selesai! Memuat %d kata.", #kataModule))
        statusParagraph:SetDesc("Wordlist siap. Silakan mulai permainan.")
        notify("✅ Loading Selesai", #kataModule .. " kata tersedia", 3)
    end
end

task.spawn(function()
    local function wrongProgress(percent) end
    wrongDone = loadWrongWordlist(wrongProgress)
    updateOverallProgress()
end)

task.spawn(function()
    local function mainProgress(percent) end
    mainDone = loadMainWordlist(mainProgress)
    if mainDone and #kataModule > 0 then
        buildIndex()
    end
    updateOverallProgress()
end)

-- =========================
-- REMOTES
-- =========================
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local MatchUI = remotes:WaitForChild("MatchUI")
local SubmitWord = remotes:WaitForChild("SubmitWord")
local BillboardUpdate = remotes:WaitForChild("BillboardUpdate")
local TypeSound = remotes:WaitForChild("TypeSound")
local UsedWordWarn = remotes:WaitForChild("UsedWordWarn")
local JoinTable = remotes:WaitForChild("JoinTable")
local LeaveTable = remotes:WaitForChild("LeaveTable")
local PlayerHit = remotes:WaitForChild("PlayerHit")
local PlayerCorrect = remotes:WaitForChild("PlayerCorrect")

-- =========================
-- SIMPLESPY
-- =========================
local function spyRemote(remote) end -- silent spy

local function scanAndSpyRemotes(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            pcall(function() spyRemote(child) end)
        end
        if #child:GetChildren() > 0 then
            scanAndSpyRemotes(child)
        end
    end
end
pcall(function() scanAndSpyRemotes(ReplicatedStorage) end)

ReplicatedStorage.DescendantAdded:Connect(function(desc)
    if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
        pcall(function() spyRemote(desc) end)
    end
end)

-- =========================
-- STATE
-- =========================
local matchActive = false
local isMyTurn = false
local updateMainStatus
local updateConfigDisplay
local serverLetter = ""
local usedWords = {}
local usedWordsList = {}
local opponentStreamWord = ""
local autoEnabled = false
local compeMode = false
local trapEndings = { "if", "x", "y", "w", "ah", "uh" }
local autoRunning = false
local lastAttemptedWord = ""
local INACTIVITY_TIMEOUT = 6
local lastTurnActivity = 0
local blacklistedWords = {}
local lastRejectWord = ""

local config = {
    minDelay = 350,
    maxDelay = 650,
}

-- =========================
-- LOGIC FUNCTIONS
-- =========================
local function isUsed(word)
    return usedWords[string.lower(word)] == true
end

local function addUsedWord(word)
    local w = string.lower(word)
    if not usedWords[w] then
        usedWords[w] = true
        table.insert(usedWordsList, word)
    end
end

local function resetUsedWords()
    usedWords = {}
    usedWordsList = {}
end

local function endsWithTrap(word)
    for _, ending in ipairs(trapEndings) do
        if string.sub(word, -#ending) == ending then
            return true
        end
    end
    return false
end

local function getSmartWords(prefix)
    if not prefix or #prefix == 0 then return {} end
    if #kataModule == 0 then return {} end

    local lowerPrefix = string.lower(prefix)
    if not lowerPrefix:match("^[a-z]+$") then return {} end

    local first = string.sub(lowerPrefix, 1, 1)
    local candidates = wordsByFirstLetter[first]
    if not candidates then return {} end

    local bestRankWord = nil
    local bestRankScore = -math.huge
    local trapBest = nil
    local trapBestScore = -math.huge
    local normalResults = {}

    for _, word in ipairs(candidates) do
        if word ~= lowerPrefix
        and #word > #lowerPrefix
        and string.sub(word, 1, #lowerPrefix) == lowerPrefix
        and not isUsed(word)
        and not wrongWordsSet[word]
        and not blacklistedWords[word] then

            local score = rankingMap[word] or 0

            -- COMPE MODE PRIORITY
            if compeMode and endsWithTrap(word) then
                if score > trapBestScore then
                    trapBestScore = score
                    trapBest = word
                end
            end

            -- NORMAL RANK
            if score > bestRankScore then
                bestRankScore = score
                bestRankWord = word
            end

            table.insert(normalResults, word)
        end
    end

    -- PRIORITAS 1: Trap kalau ada
    if compeMode and trapBest then
        return { trapBest }
    end

    -- PRIORITAS 2: Ranking terbaik
    if bestRankWord then
        return { bestRankWord }
    end

    -- PRIORITAS 3: fallback panjang
    table.sort(normalResults, function(a,b)
        return #a > #b
    end)

    return normalResults
end

local function humanDelay()
    local min = config.minDelay
    local max = config.maxDelay
    if min > max then min = max end
    task.wait(math.random(min, max) / 1000)
end

-- =========================
-- VIRTUAL INPUT HELPER
-- =========================
local VIM = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil

local charToKeyCode = {
    a=Enum.KeyCode.A,b=Enum.KeyCode.B,c=Enum.KeyCode.C,d=Enum.KeyCode.D,
    e=Enum.KeyCode.E,f=Enum.KeyCode.F,g=Enum.KeyCode.G,h=Enum.KeyCode.H,
    i=Enum.KeyCode.I,j=Enum.KeyCode.J,k=Enum.KeyCode.K,l=Enum.KeyCode.L,
    m=Enum.KeyCode.M,n=Enum.KeyCode.N,o=Enum.KeyCode.O,p=Enum.KeyCode.P,
    q=Enum.KeyCode.Q,r=Enum.KeyCode.R,s=Enum.KeyCode.S,t=Enum.KeyCode.T,
    u=Enum.KeyCode.U,v=Enum.KeyCode.V,w=Enum.KeyCode.W,x=Enum.KeyCode.X,
    y=Enum.KeyCode.Y,z=Enum.KeyCode.Z,
}
local charToScanCode = {
    a=65,b=66,c=67,d=68,e=69,f=70,g=71,h=72,i=73,j=74,
    k=75,l=76,m=77,n=78,o=79,p=80,q=81,r=82,s=83,t=84,
    u=85,v=86,w=87,x=88,y=89,z=90,
}

local function findTextBox()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return nil end
    local function find(p)
        for _, c in ipairs(p:GetChildren()) do
            if c:IsA("TextBox") then return c end
            local r = find(c)
            if r then return r end
        end
        return nil
    end
    return find(gui)
end

local function focusTextBox()
    local tb = findTextBox()
    if tb then pcall(function() tb:CaptureFocus() end) end
end

local function sendKey(char)
    local c = string.lower(char)
    if VIM then
        local kc = charToKeyCode[c]
        if kc then
            pcall(function()
                VIM:SendKeyEvent(true, kc, false, game)
                task.wait(0.025)
                VIM:SendKeyEvent(false, kc, false, game)
            end)
        end
        return
    end
    if keypress and keyrelease then
        local code = charToScanCode[c]
        if code then
            keypress(code)
            task.wait(0.02)
            keyrelease(code)
        end
        return
    end
    pcall(function()
        local tb = findTextBox()
        if tb then tb.Text = tb.Text .. c end
    end)
end

local function sendBackspace()
    if VIM then
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
            task.wait(0.025)
            VIM:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
        end)
        return
    end
    if keypress and keyrelease then
        keypress(8) task.wait(0.02) keyrelease(8)
        return
    end
    pcall(function()
        local tb = findTextBox()
        if tb and #tb.Text > 0 then
            tb.Text = string.sub(tb.Text, 1, -2)
        end
    end)
end
local function tapScreenOnce()
    if not VIM then return end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local vp = cam.ViewportSize
    local x = math.floor(vp.X / 2)
    local y = math.floor(vp.Y / 2)

    -- Mouse down
    VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait(0.05)
    -- Mouse up
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
end
local function revertToStartLetter()
    if serverLetter == "" then return end

    local currentText = lastAttemptedWord
    if not currentText or currentText == "" then
        currentText = serverLetter
    end

    currentText = string.lower(currentText)
    local target = string.lower(serverLetter)

    if currentText == target then
        BillboardUpdate:FireServer(target)
        return
    end

    if string.sub(currentText, 1, #target) ~= target then
        BillboardUpdate:FireServer(target)
        task.wait(0.15)
        return
    end

    while #currentText > #target do
        currentText = string.sub(currentText, 1, #currentText - 1)
        BillboardUpdate:FireServer(currentText)
        task.wait(0.25)
    end

    BillboardUpdate:FireServer(target)
    task.wait(0.15)
end

-- =========================
-- AUTO ENGINE
-- FIX: Cek autoEnabled di setiap step agar tidak lanjut setelah toggle OFF
-- Jika autoEnabled OFF saat sedang mengetik, langsung berhenti dan
-- fire BillboardEnd supaya billboard bersih (tidak muncul "button loncat")
-- =========================
local BillboardEnd = remotes:FindFirstChild("BillboardEnd")
local function fireBillboardEnd()
    if BillboardEnd then
        pcall(function() BillboardEnd:FireServer() end)
    else
        pcall(function() BillboardUpdate:FireServer("") end)
    end
end

local function submitAndRetry(startLetter)
    local MAX_RETRY = 6
    local attempt = 0

    while attempt < MAX_RETRY do
        attempt = attempt + 1
        -- FIX: cek autoEnabled di awal setiap loop
        if not matchActive or not autoEnabled then
            fireBillboardEnd()
            return false
        end
        if attempt > 1 then task.wait(0.2) end

        local words = getSmartWords(startLetter)
        if #words == 0 then return false end

        local sel = words[1]

        focusTextBox()
        task.wait(0.05)

        local remain = string.sub(sel, #startLetter + 1)
        local cur = startLetter
        local aborted = false
        for i = 1, #remain do
            -- FIX: cek autoEnabled setiap karakter — stop & bersihkan billboard jika OFF
            if not matchActive or not autoEnabled then
                aborted = true
                fireBillboardEnd()
                break
            end
            local ch = string.sub(remain, i, i)
            cur = cur .. ch
            pcall(function() sendKey(ch) end)
            pcall(function() TypeSound:FireServer() end)
            pcall(function() BillboardUpdate:FireServer(cur) end)
            humanDelay()
        end
        if aborted then return false end
        if not matchActive or not autoEnabled then
            fireBillboardEnd()
            return false
        end

        task.wait(0.5)
        if not matchActive or not autoEnabled then
            fireBillboardEnd()
            return false
        end

        lastRejectWord = ""
        lastAttemptedWord = sel
        pcall(function() SubmitWord:FireServer(sel) end)
        task.wait(0.35)

        if lastRejectWord == string.lower(sel) then
            blacklistedWords[string.lower(sel)] = true
            revertToStartLetter()
            lastAttemptedWord = ""
            task.wait(0.4)
        else
            addUsedWord(sel)
            lastAttemptedWord = ""
            -- FIX: bersihkan billboard setelah submit berhasil
            fireBillboardEnd()
            return true
        end
    end

    blacklistedWords = {}
    fireBillboardEnd()
    return false
end

local function startUltraAI()
    if autoRunning or not autoEnabled then return end
    if not matchActive or not isMyTurn then return end
    if serverLetter == "" then return end
    if #kataModule == 0 then return end

    autoRunning = true
    lastTurnActivity = tick()

    if not matchActive or not isMyTurn then
        autoRunning = false
        return
    end

    local currentPrefix = string.lower(serverLetter)
    if not currentPrefix:match("^[a-z]+$") then
        autoRunning = false
        return
    end

    local ok, err = pcall(function() submitAndRetry(currentPrefix) end)
    if not ok then end
    autoRunning = false
end

-- =========================
-- MONITORING MEJA & GILIRAN
-- =========================
local currentTableName = nil
local tableTarget = nil
local seatStates = {}

local function getSeatPlayer(seat)
    if seat and seat.Occupant then
        local character = seat.Occupant.Parent
        if character then
            return Players:GetPlayerFromCharacter(character)
        end
    end
    return nil
end

local function monitorTurnBillboard(player)
    if not player or not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head")
    if not head then return nil end
    local billboard = head:FindFirstChild("TurnBillboard")
    if not billboard then return nil end
    local textLabel = billboard:FindFirstChildOfClass("TextLabel")
    if not textLabel then return nil end

    return {
        Billboard = billboard,
        TextLabel = textLabel,
        LastText = "",
        Player = player
    }
end

local function setupSeatMonitoring()
    if not currentTableName then
        seatStates = {}
        tableTarget = nil
        return
    end

    local tablesFolder = Workspace:FindFirstChild("Tables")
    if not tablesFolder then return end

    tableTarget = tablesFolder:FindFirstChild(currentTableName)
    if not tableTarget then return end

    local seatsContainer = tableTarget:FindFirstChild("Seats")
    if not seatsContainer then return end

    seatStates = {}
    for _, seat in ipairs(seatsContainer:GetChildren()) do
        if seat:IsA("Seat") then
            seatStates[seat] = { Current = nil }
        end
    end
end

local function onCurrentTableChanged()
    local tableName = LocalPlayer:GetAttribute("CurrentTable")
    if tableName then
        currentTableName = tableName
        setupSeatMonitoring()
    else
        currentTableName = nil
        tableTarget = nil
        seatStates = {}
    end
end

LocalPlayer.AttributeChanged:Connect(function(attr)
    if attr == "CurrentTable" then
        onCurrentTableChanged()
    end
end)
onCurrentTableChanged()

-- =========================
-- AUTO JOIN / SEAT SYSTEM
-- Dropdown: off / 2P / 4P / 8P
-- Pantau meja sesuai mode, join jika butuh 1 kursi lagi.
-- Monitor: jika lawan keluar saat tidak match → leave seat.
-- Saat matchActive → scan dihentikan sementara.
-- =========================
local autoJoinMode   = "off"
local autoJoinLoop   = nil
local joinedTable    = nil   -- nama meja yang kita duduki
local SCAN_INTERVAL  = 1.2

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function isSeated()
    local h = getHumanoid()
    return h ~= nil and h.SeatPart ~= nil
end

local function forceLeaveSeat()
    local h = getHumanoid()
    if not h then return end
    if h.SeatPart then
        for _, v in ipairs(h.SeatPart:GetChildren()) do
            if v:IsA("Weld") or v:IsA("Motor6D") then
                local p = v.Part0 or v.Part1
                if p and p:IsDescendantOf(LocalPlayer.Character) then
                    pcall(function() v:Destroy() end)
                end
            end
        end
        h.Sit = false
    end
    local w = 0
    while h.SeatPart ~= nil and w < 2 do
        task.wait(0.1); w = w + 0.1
    end
end

local function getOccupied(model)
    local sf = model:FindFirstChild("Seats")
    if not sf then return 0 end
    local seats = {}
    for _, s in ipairs(sf:GetChildren()) do
        if s:IsA("Seat") then seats[s] = true end
    end
    local n = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            if h and h.SeatPart and seats[h.SeatPart] then
                n = n + 1
            end
        end
    end
    return n
end

local function getCapacity(model)
    local sf = model:FindFirstChild("Seats")
    if not sf then return 0 end
    local n = 0
    for _, s in ipairs(sf:GetChildren()) do
        if s:IsA("Seat") then n = n + 1 end
    end
    return n
end

local function pressPrompt(model)
    local part = model:FindFirstChild("TablePart")
    if not part then return false end
    local prompt = part:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then return false end
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin(); task.wait(0.3); prompt:InputHoldEnd()
    end
    return true
end

local function stopAutoJoin()
    if autoJoinLoop then task.cancel(autoJoinLoop); autoJoinLoop = nil end
    joinedTable = nil
end

local function startAutoJoin(mode)
    stopAutoJoin()
    if mode == "off" or mode == nil then return end

    autoJoinLoop = task.spawn(function()
        while autoJoinMode ~= "off" and _G.AutoKataActive do
            pcall(function()
                -- Saat match berlangsung, tidak scan
                if matchActive then return end

                local tf = Workspace:FindFirstChild("Tables")
                if not tf then return end

                -- Sudah duduk di meja → monitor lawan
                if joinedTable then
                    local model = tf:FindFirstChild(joinedTable)
                    if not model then
                        forceLeaveSeat(); joinedTable = nil; return
                    end
                    if not isSeated() then
                        joinedTable = nil; return
                    end
                    -- Lawan keluar (hanya kita sendiri) → leave
                    local occ = getOccupied(model)
                    if occ <= 1 then
                        pcall(function() LeaveTable:FireServer() end)
                        forceLeaveSeat()
                        joinedTable = nil
                    end
                    return
                end

                -- Belum duduk → pastikan berdiri dulu
                if isSeated() then
                    forceLeaveSeat(); task.wait(0.3); return
                end

                -- Scan meja sesuai mode
                for _, model in ipairs(tf:GetChildren()) do
                    if model:IsA("Model") and model.Name:find(mode) then
                        local cap = getCapacity(model)
                        local occ = getOccupied(model)
                        -- Butuh tepat 1 kursi lagi
                        if cap > 0 and occ >= 1 and occ == cap - 1 then
                            if pressPrompt(model) then
                                joinedTable = model.Name
                                -- Tunggu konfirmasi duduk
                                local waited = 0
                                while not isSeated() and waited < 3 do
                                    task.wait(0.3); waited = waited + 0.3
                                end
                                if not isSeated() then
                                    joinedTable = nil
                                end
                                return
                            end
                        end
                    end
                end
            end)
            task.wait(SCAN_INTERVAL)
        end
    end)
end

-- =========================
-- REMOTE EVENT HANDLERS
-- =========================

local function onMatchUI(cmd, value)
    if cmd == "ShowMatchUI" then
        matchActive = true
        isMyTurn = false
        serverLetter = ""
        resetUsedWords()
        blacklistedWords = {}
        setupSeatMonitoring()
        updateMainStatus()
    elseif cmd == "HideMatchUI" then
        matchActive = false
        isMyTurn = false
        serverLetter = ""
        resetUsedWords()
        seatStates = {}
        updateMainStatus()
		task.spawn(function()
			task.wait(0.6)
			tapScreenOnce()
    	end)
        -- Resume auto join setelah match selesai
        if autoJoinMode ~= "off" then
            task.spawn(function()
                task.wait(0.5)
                if not matchActive then
                    forceLeaveSeat()
                    joinedTable = nil
                end
            end)
        end
    elseif cmd == "StartTurn" then
        isMyTurn = true
        lastTurnActivity = tick()
        if type(value) == "string" and value ~= "" then
            serverLetter = value
        end
        if autoEnabled then
            task.spawn(function()
                task.wait(math.random(1500, 2500) / 1000)
                if matchActive and isMyTurn and autoEnabled then
                    startUltraAI()
                end
            end)
        end
        updateMainStatus()
    elseif cmd == "EndTurn" then
        isMyTurn = false
        updateMainStatus()
    elseif cmd == "UpdateServerLetter" then
        serverLetter = value or ""
        updateMainStatus()

        if isMyTurn and autoEnabled and not autoRunning and serverLetter ~= "" then
            task.spawn(startUltraAI)
        end
    elseif cmd == "Mistake" then
        if value and value.userId == LocalPlayer.UserId then
            if autoEnabled and matchActive and isMyTurn then
                task.spawn(function()
                    revertToStartLetter()
                    task.wait(0.7)
                    startUltraAI()
                end)
            end
        end
    end
end

local function onBillboard(word)
    if matchActive and not isMyTurn then
        opponentStreamWord = word or ""
    end
end

local function onUsedWarn(word)
    if word then
        lastRejectWord = string.lower(tostring(word))
        addUsedWord(word)
        if autoEnabled and matchActive and isMyTurn and not autoRunning then
            task.spawn(function()
                revertToStartLetter()
                task.wait(0.7)
                startUltraAI()
            end)
        end
    end
end

PlayerHit.OnClientEvent:Connect(function(player)
    if player == LocalPlayer then
        if autoEnabled and matchActive and isMyTurn then
            task.spawn(function()
                revertToStartLetter()
                task.wait(0.7)
                startUltraAI()
            end)
        end
    end
end)

PlayerCorrect.OnClientEvent:Connect(function(player)
    if player == LocalPlayer then end
end)

JoinTable.OnClientEvent:Connect(function(tableName)
    currentTableName = tableName
    if autoJoinMode ~= "off" then joinedTable = tableName end
    setupSeatMonitoring()
    updateMainStatus()
end)

LeaveTable.OnClientEvent:Connect(function()
    currentTableName = nil
    matchActive = false
    isMyTurn = false
    serverLetter = ""
    resetUsedWords()
    seatStates = {}
    joinedTable = nil
    updateMainStatus()
    if autoJoinMode ~= "off" then
        task.spawn(function()
            task.wait(0.8); forceLeaveSeat()
        end)
    end
end)

-- =========================
-- UI UTAMA (TOGGLE, SLIDER DELAY, DLL)
-- =========================
local sliders = {}
local autoToggle

autoToggle = MainTab:Toggle({
    Title = "Aktifkan Auto",
    Desc = "Menjalankan auto jawab saat giliran",
    Icon = "lucide:play",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        autoEnabled = Value
        if Value then
            notify("⚡ AUTO MODE", "Auto Dinyalakan", 3)
            task.spawn(function()
                task.wait(0.1)
                if matchActive and isMyTurn then
                    if serverLetter == "" then
                        local timeout = 0
                        while serverLetter == "" and timeout < 20 do
                            task.wait(0.1)
                            timeout = timeout + 1
                        end
                    end
                    if matchActive and isMyTurn and serverLetter ~= "" then
                        startUltraAI()
                    end
                end
            end)
        else
            -- FIX: saat toggle OFF, bersihkan billboard agar tidak ada sisa "button loncat"
            autoRunning = false
            task.spawn(function()
                task.wait(0.1)
                fireBillboardEnd()
            end)
            notify("⚡ AUTO MODE", "Auto Dimatikan", 3)
        end
    end
})

MainTab:Toggle({
    Title = "Compe Mode",
    Desc = "Prioritaskan kata jebakan (if, x, y, w, ah, uh)",
    Icon = "lucide:flame",
    Type = "Checkbox",
    Value = false,
    Callback = function(Value)
        compeMode = Value
        if Value then
            notify("🔥 COMPE MODE", "Mode Jebakan Aktif", 2)
        else
            notify("❄️ COMPE MODE", "Mode Jebakan Nonaktif", 2)
        end
    end
})

MainTab:Dropdown({
    Title = "Auto Join Mode",
    Desc = "Pilih tipe meja (off = nonaktif)",
    Icon = "lucide:users",
    Values = { "off", "2P", "4P", "8P" },
    Value = "off",
    Multi = false,
    Callback = function(sel)
        if not sel then return end
        autoJoinMode = sel
        if sel == "off" then
            stopAutoJoin()
            notify("🪑 AUTO JOIN", "Nonaktif", 2)
        else
            startAutoJoin(sel)
            notify("🪑 AUTO JOIN", "Aktif mode " .. sel, 2)
        end
    end,
})

table.insert(sliders, MainTab:Slider({
    Title = "Min Delay (ms)",
    Desc = "Delay minimal antar huruf",
    Step = 5,
    Value = {
        Min = 10,
        Max = 500,
        Default = config.minDelay,
    },
    Callback = function(Value)
        config.minDelay = Value
        if config.minDelay > config.maxDelay then
            config.maxDelay = config.minDelay
            for _, s in ipairs(sliders) do
                if s.Title == "Max Delay (ms)" then
                    s:Set(config.maxDelay)
                end
            end
        end
        if updateConfigDisplay then updateConfigDisplay() end
    end
}))

table.insert(sliders, MainTab:Slider({
    Title = "Max Delay (ms)",
    Desc = "Delay maksimal antar huruf",
    Step = 5,
    Value = {
        Min = 100,
        Max = 1000,
        Default = config.maxDelay,
    },
    Callback = function(Value)
        config.maxDelay = Value
        if config.maxDelay < config.minDelay then
            config.minDelay = config.maxDelay
            for _, s in ipairs(sliders) do
                if s.Title == "Min Delay (ms)" then
                    s:Set(config.minDelay)
                end
            end
        end
        if updateConfigDisplay then updateConfigDisplay() end
    end
}))

local function updateMainStatus()
    if not matchActive then
        statusParagraph:SetDesc("Match tidak aktif | - | -")
        return
    end
    local activePlayer = nil
    for seat, state in pairs(seatStates) do
        if state.Current and state.Current.Billboard and state.Current.Billboard.Parent then
            activePlayer = state.Current.Player
            break
        end
    end
    local playerName = ""
    local turnText = ""
    if isMyTurn then
        playerName = "Anda"
        turnText = "Giliran Anda"
    elseif activePlayer then
        playerName = activePlayer.Name
        turnText = "Giliran " .. activePlayer.Name
    else
        for seat, _ in pairs(seatStates) do
            local plr = getSeatPlayer(seat)
            if plr and plr ~= LocalPlayer then
                playerName = plr.Name
                turnText = "Menunggu giliran " .. plr.Name
                break
            end
        end
        if playerName == "" then
            playerName = "-"
            turnText = "Menunggu..."
        end
    end
    local startLetter = (serverLetter ~= "" and serverLetter) or "-"
    statusParagraph:SetDesc(playerName .. " | " .. turnText .. " | " .. startLetter)
end

-- =========================
-- TAB PLAYER (CONFIG)
-- =========================
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "lucide:user",
})

-- =========================
-- FILE I/O DETECTION
-- =========================
local CONFIG_FILE = "sambung_kata_config.json"
local TEST_FILE = "sambung_kata_test.txt"

local function detectFileIO()
    if not writefile or not readfile then return false end
    local ok = pcall(function()
        writefile(TEST_FILE, "test123")
        local content = readfile(TEST_FILE)
        if content ~= "test123" then error("Mismatch") end
        if delfile then delfile(TEST_FILE) end
    end)
    return ok
end

CAN_SAVE = detectFileIO()

-- =========================
-- STATUS DISPLAY
-- =========================
local configStatus = PlayerTab:Paragraph({
    Title = "Status Penyimpanan",
    Desc = CAN_SAVE and 
        "✓ File I/O tersedia (config akan disimpan otomatis ke file)" or 
        "⚠ File I/O tidak tersedia (gunakan clipboard)",
    Color = CAN_SAVE and "Green" or "Red",
})

local configDisplay = PlayerTab:Paragraph({
    Title = "Konfigurasi Saat Ini",
    Desc = "",
})

local function updateConfigDisplay()
    configDisplay:SetDesc(
        "MinDelay: "..config.minDelay..
        " | MaxDelay: "..config.maxDelay..
        "\nAuto: "..tostring(autoEnabled)..
        " | "
    )
end
updateConfigDisplay()

-- =========================
-- SAVE CONFIG
-- =========================
local function saveConfig()
    local data = {
        minDelay = config.minDelay,
        maxDelay = config.maxDelay,
        autoEnabled = autoEnabled,
    }
    local json = HttpService:JSONEncode(data)
    if CAN_SAVE then
        local ok, err = pcall(function() writefile(CONFIG_FILE, json) end)
        if ok then
            notify("✅ Config", "Berhasil disimpan ke file!", 2)
        else
            notify("❌ Config", "Gagal save: "..tostring(err), 3)
        end
    else
        if setclipboard then
            setclipboard(json)
            notify("📋 Config", "File tidak tersedia. JSON disalin ke clipboard.", 3)
        else
            notify("❌ Config", "Tidak ada file / clipboard support!", 3)
        end
    end
end

-- =========================
-- LOAD CONFIG
-- =========================
local function loadConfig()
    local json = nil
    if CAN_SAVE then
        local exists = true
        if isfile then exists = isfile(CONFIG_FILE) end
        if not exists then
            notify("❌ Config", "File config tidak ditemukan!", 2)
            return
        end
        local ok, data = pcall(function() return readfile(CONFIG_FILE) end)
        if not ok or not data then
            notify("❌ Config", "Gagal membaca file!", 2)
            return
        end
        json = data
    else
        if getclipboard then
            json = getclipboard()
        else
            notify("❌ Config", "Clipboard tidak tersedia!", 2)
            return
        end
    end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or type(decoded) ~= "table" then
        notify("❌ Config", "Format JSON tidak valid!", 3)
        return
    end

    config.minDelay = decoded.minDelay or config.minDelay
    config.maxDelay = decoded.maxDelay or config.maxDelay
    autoEnabled = decoded.autoEnabled ~= nil and decoded.autoEnabled or autoEnabled

    if autoToggle then autoToggle:Set(autoEnabled) end

    for _, s in ipairs(sliders) do
        if s.Title == "Min Delay (ms)" then s:Set(config.minDelay)
        elseif s.Title == "Max Delay (ms)" then s:Set(config.maxDelay) end
    end

    updateConfigDisplay()
    notify("✅ Config", "Konfigurasi berhasil dimuat!", 2)
end

-- =========================
-- BUTTONS PLAYER
-- =========================
PlayerTab:Button({
    Title = "Simpan Konfigurasi",
    Desc = "Simpan ke file / clipboard",
    Callback = saveConfig
})

PlayerTab:Button({
    Title = "Muat Konfigurasi",
    Desc = "Load dari file / clipboard",
    Callback = loadConfig
})

PlayerTab:Button({
    Title = "Reset Konfigurasi",
    Desc = "Kembalikan ke default",
    Callback = function()
        config.minDelay = 350
        config.maxDelay = 650
        autoEnabled = false
        if autoToggle then autoToggle:Set(false) end
        updateConfigDisplay()
        notify("🔄 Config", "Reset ke default!", 2)
    end
})

-- =========================
-- AUTO JOIN DROPDOWN
-- =========================
PlayerTab:Paragraph({
    Title = "Auto Seat",
    Desc = "Otomatis join meja sesuai mode yang dipilih.\nBot akan pantau lawan — jika lawan keluar maka bot leave juga.",
})

-- =========================
-- KEYBIND UI
-- =========================
local currentKeybind = Enum.KeyCode.RightShift
Window:SetToggleKey(currentKeybind)

PlayerTab:Keybind({
    Title = "Toggle UI Keybind",
    Desc = "Tombol buka/tutup UI",
    Value = "X",
    Callback = function(v)
        if typeof(v) == "EnumItem" then
            currentKeybind = v
            Window:SetToggleKey(v)
        elseif typeof(v) == "string" then
            local keyEnum = Enum.KeyCode[v]
            if keyEnum then
                currentKeybind = keyEnum
                Window:SetToggleKey(keyEnum)
            end
        end
    end
})

-- =========================
-- TAB ABOUT
-- =========================
local AboutTab = Window:Tab({
    Title = "About",
    Icon = "lucide:info",
})

AboutTab:Paragraph({
    Title = "Informasi Script",
    Desc = "Auto Kata (Optimized)\nVersi: 4.2\nby sazaraaax & danz\nFitur: Auto play, Auto Seat, Discord Notif, save/load config",
    Color = "Blue",
})

AboutTab:Paragraph({
    Title = "Informasi Update",
    Desc = "> Slider aggression & panjang kata dihapus\n> Selalu memilih kata terbaik\n> Cache otomatis\n> Delay awal 2.5-3.7 detik\n> add compe mode\n> add auto seat (2P/4P/8P)\n> add discord login notif\n> fix button loncat saat auto OFF",
})

AboutTab:Paragraph({
    Title = "Cara Penggunaan",
    Desc = "1. Tunggu loading selesai (status 100%)\n2. Aktifkan toggle Auto\n3. Atur delay\n4. Pilih Auto Join Mode di Player tab\n5. Mulai permainan",
})

local discordLink = "https://discord.gg/bT4GmSFFWt"
local waLink = "https://www.whatsapp.com/channel/0029VbCBSBOCRs1pRNYpPN0r"

AboutTab:Button({
    Title = "Copy Discord Invite",
    Desc = "Salin link Discord ke clipboard",
    Callback = function()
        if setclipboard then
            setclipboard(discordLink)
            notify("🟢 DISCORD", "Link Discord berhasil disalin!", 3)
        else
            notify("🔴 DISCORD", "Executor tidak support clipboard", 3)
        end
    end
})

AboutTab:Button({
    Title = "Copy WhatsApp Channel",
    Desc = "Salin link WhatsApp Channel ke clipboard",
    Callback = function()
        if setclipboard then
            setclipboard(waLink)
            notify("🟢 WHATSAPP", "Link WhatsApp Channel berhasil disalin!", 3)
        else
            notify("🔴 WHATSAPP", "Executor tidak support clipboard", 3)
        end
    end
})

-- CONNECT REMOTES (SETELAH SEMUA FUNCTION ADA)
MatchUI.OnClientEvent:Connect(onMatchUI)
BillboardUpdate.OnClientEvent:Connect(onBillboard)
UsedWordWarn.OnClientEvent:Connect(onUsedWarn)

-- =========================
-- DISCORD LOGIN NOTIF (setelah UI selesai)
-- =========================
sendLoginNotif()

-- =========================
-- HEARTBEAT LOOP
-- =========================
task.spawn(function()
    local lastUpdate = 0
    local UPDATE_INTERVAL = 0.3

    while _G.AutoKataActive do
        local now = tick()

        if matchActive and tableTarget and currentTableName then
            for seat, state in pairs(seatStates) do
                local plr = getSeatPlayer(seat)
                if plr and plr ~= LocalPlayer then
                    if not state.Current or state.Current.Player ~= plr then
                        state.Current = monitorTurnBillboard(plr)
                    end
                    if state.Current then
                        local tb = state.Current.TextLabel
                        if tb then state.Current.LastText = tb.Text end
                        if not state.Current.Billboard or not state.Current.Billboard.Parent then
                            if state.Current.LastText ~= "" then
                                addUsedWord(state.Current.LastText)
                            end
                            state.Current = nil
                        end
                    end
                else
                    state.Current = nil
                end
            end

            local myBillboard = monitorTurnBillboard(LocalPlayer)
            if myBillboard then
                local text = myBillboard.TextLabel.Text
                if not isMyTurn then
                    isMyTurn = true
                    lastTurnActivity = now
                    if serverLetter == "" and #text > 0 then
                        serverLetter = string.sub(text, 1, 1)
                    end
                    updateMainStatus()
                    if autoEnabled and serverLetter ~= "" then
                        startUltraAI()
                    end
                end
            else
                if isMyTurn then
                    isMyTurn = false
                    updateMainStatus()
                end
            end

            if isMyTurn and autoEnabled and not autoRunning then
                if now - lastTurnActivity > INACTIVITY_TIMEOUT then
                    lastTurnActivity = now
                    startUltraAI()
                end
            end

            if now - lastUpdate >= UPDATE_INTERVAL then
                updateMainStatus()
                lastUpdate = now
            end
        else
            if isMyTurn then isMyTurn = false end
            task.wait(1)
        end

        task.wait(UPDATE_INTERVAL)
    end
end)
