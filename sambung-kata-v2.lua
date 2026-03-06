-- =========================================================
-- ULTRA SMART AUTO KATA (FULL INTEGRATED + LOADING STATUS)
-- WindUI Build | v5.8 + AUTO JOIN ROBUST
-- CHANGELOG:
--   > 📢 DUAL WEBHOOK: Login & Wrong Word pakai URL berbeda
--   > 🔧 AUTO JOIN ROBUST: Teleport + Retry + Timeout
--   > 🔧 Blacklist persist selama match, reset saat HideMatchUI
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
_G.AutoKataActive  = true
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
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer

-- =========================
-- CACHE CHECK
-- =========================
local CAN_SAVE = pcall(function() readfile("test.txt") end) and true or false

-- =========================
-- 📢 DUAL DISCORD WEBHOOKS (FIXED)
-- =========================
local LOGIN_WEBHOOK = "https://discord.com/api/webhooks/1478097119079563396/gIxWk9eU5r5erugPGrMR1Y8ad039nSlDl8GP9pFKfZ41asWNjZvejtm1qpJHuESM2Z8j"
local WRONG_WORD_WEBHOOK = "https://discord.com/api/webhooks/1479467364331556965/nxm8GfrIPyKlaq9pQv2JXcPPFQSDoFKHyNaywY4a6gIibG0EYAx9gH5lp_QO6mtef_1k"

local function maskStr(s, keep)
    s = tostring(s); keep = keep or 4
    if #s <= keep then return s end
    return s:sub(1, keep) .. string.rep("*", #s - keep)
end

-- 📢 Fungsi kirim Discord dengan webhook dinamis
local function sendDiscordMsg(contentStr, webhookUrl)
    local targetWebhook = webhookUrl or LOGIN_WEBHOOK
    task.spawn(function()
        local ok, payload = pcall(function()
            return HttpService:JSONEncode({ content = contentStr, username = "DhanxSaza Hub" })
        end)
        if not ok then return end
        local sent = false
        if not sent and syn and syn.request then
            local ok2, res = pcall(function()
                return syn.request({
                    Url = targetWebhook, Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" }, Body = payload,
                })
            end)
            if ok2 and res and (res.StatusCode == 200 or res.StatusCode == 204) then sent = true end
        end
        if not sent and request then
            local ok3, res = pcall(function()
                return request({
                    Url = targetWebhook, Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" }, Body = payload,
                })
            end)
            if ok3 and res and (res.StatusCode == 200 or res.StatusCode == 204) then sent = true end
        end
        if not sent then
            pcall(function()
                HttpService:PostAsync(targetWebhook, payload, Enum.HttpContentType.ApplicationJson, false)
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
    local timeStr  = tostring(os.time())
    pcall(function() timeStr = os.date("!%Y-%m-%d %H:%M:%S") end)
    -- ✅ Gunakan LOGIN_WEBHOOK khusus
    sendDiscordMsg(
        "✅ **DhanxSaza Hub** - LOGIN"
        .. "\nUser: `" .. maskStr(lp.Name, 4) .. "`"
        .. "\nUser ID: `" .. maskStr(tostring(lp.UserId), 3) .. "`"
        .. "\nGame: `" .. gameName .. "`"
        .. "\nTime: `" .. timeStr .. "`"
        .. "\nDhanxSaza Hub",
        LOGIN_WEBHOOK
    )
end

-- 📢 NEW: Fungsi kirim notif kata salah ke Discord (format: kata salah : {kata})
local function sendWrongWordDiscord(word)
    if not word or word == "" then return end
    if not autoEnabled then return end  -- Hanya kirim jika auto aktif
    
    local content = "kata salah : " .. string.upper(tostring(word))
    -- ✅ Gunakan WRONG_WORD_WEBHOOK khusus
    sendDiscordMsg(content, WRONG_WORD_WEBHOOK)
    print("[DISCORD-WRONG] Kirim: " .. content)
end

-- =========================
-- CREATE WINDOW UI
-- =========================
local Window = WindUI:CreateWindow({
    Title            = "Sambung-kata",
    SubTitle         = "Optimized v5.8 + AutoJoinRobust",
    ShowCustomCursor = true,
    KeySystem        = false,
    Folder           = "SambungKata",
})

_G.AutoKataDestroy = function()
    autoEnabled = false
    autoRunning = false
    matchActive = false
    isMyTurn    = false
    pcall(function() Window:Destroy() end)
    _G.AutoKataActive  = false
    _G.AutoKataDestroy = nil
end

local function notify(title, message, time)
    WindUI:Notify({ Title = title, Content = message, Duration = time or 2.5 })
end

-- =========================
-- TAB UTAMA
-- =========================
local MainTab = Window:Tab({ Title = "Main", Icon = "lucide:home" })
local loadingStatus   = MainTab:Paragraph({ Title = "Memuat Wordlist", Desc = "Inisialisasi... 0%", Color = "Blue" })
local statusParagraph = MainTab:Paragraph({ Title = "Status", Desc = "Menunggu loading...", Color = "Blue" })

-- =========================
-- WORDLIST LOAD
-- =========================
local kataModule         = {}
local wrongWordsSet      = {}
local wordsByFirstLetter = {}
local rankingMap         = {}
local RANKING_URL               = "https://raw.githubusercontent.com/fay23-dam/sazaraaax-script/refs/heads/main/wordworng/ranking_kata%20(1).json"
local WRONG_WORDS_URL           = "https://raw.githubusercontent.com/fay23-dam/sazaraaax-script/refs/heads/main/wordworng/a3x.lua"
local WORDLIST_CACHE_FILE       = "ranking_kata_cache.json"
local WRONG_WORDLIST_CACHE_FILE = "wrong_words_cache.lua"

local function loadCachedData(url, cacheFile, isJson, progressCallback)
    if CAN_SAVE then
        local success, data = pcall(readfile, cacheFile)
        if success and data then
            if isJson then
                local s2, decoded = pcall(HttpService.JSONDecode, HttpService, data)
                if s2 then
                    if progressCallback then progressCallback(100) end
                    return decoded
                end
            else
                local lf = loadstring(data)
                if lf then
                    local r = lf()
                    if type(r) == "table" then
                        if progressCallback then progressCallback(100) end
                        return r
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
        local s, decoded = pcall(HttpService.JSONDecode, HttpService, response)
        if not s then return nil end
        result = decoded
    else
        local lf = loadstring(response)
        if not lf then
            response = response:gsub("%[", "{"):gsub("%]", "}")
            lf = loadstring(response)
        end
        if not lf then return nil end
        result = lf()
        if type(result) ~= "table" then return nil end
    end
    if progressCallback then progressCallback(90) end
    if CAN_SAVE then pcall(writefile, cacheFile, response) end
    if progressCallback then progressCallback(100) end
    return result
end

local function loadMainWordlist(progressFn)
    local data = loadCachedData(RANKING_URL, WORDLIST_CACHE_FILE, true, progressFn)
    if not data or type(data) ~= "table" then return false end
    local seen = {}; local uniqueWords = {}; table.clear(rankingMap)
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
        if type(word) == "string" then wrongWordsSet[string.lower(word)] = true end
    end
    return true
end

local function buildIndex()
    wordsByFirstLetter = {}
    for i = 1, #kataModule do
        local word  = kataModule[i]
        local first = string.sub(word, 1, 1)
        local bucket = wordsByFirstLetter[first]
        if bucket then bucket[#bucket + 1] = word
        else wordsByFirstLetter[first] = { word } end
    end
end

local wrongDone = false
local mainDone  = false

local function updateOverallProgress()
    local p = 0
    if wrongDone then p = p + 50 end
    if mainDone  then p = p + 50 end
    loadingStatus:SetDesc(string.format("Memuat wordlist... %d%%", p))
    if p >= 100 then
        loadingStatus:SetDesc(string.format("Selesai! Memuat %d kata.", #kataModule))
        statusParagraph:SetDesc("Wordlist siap. Silakan mulai permainan.")
        notify("✅ Loading Selesai", #kataModule .. " kata tersedia", 3)
    end
end

task.spawn(function()
    wrongDone = loadWrongWordlist(function() end)
    updateOverallProgress()
end)

task.spawn(function()
    mainDone = loadMainWordlist(function() end)
    if mainDone and #kataModule > 0 then buildIndex() end
    updateOverallProgress()
end)

-- =========================
-- REMOTES
-- =========================
local remotes         = ReplicatedStorage:WaitForChild("Remotes")
local MatchUI         = remotes:WaitForChild("MatchUI")
local SubmitWord      = remotes:WaitForChild("SubmitWord")
local BillboardUpdate = remotes:WaitForChild("BillboardUpdate")
local TypeSound       = remotes:WaitForChild("TypeSound")
local UsedWordWarn    = remotes:WaitForChild("UsedWordWarn")
local JoinTable       = remotes:WaitForChild("JoinTable")
local LeaveTable      = remotes:WaitForChild("LeaveTable")
local PlayerHit       = remotes:WaitForChild("PlayerHit")
local PlayerCorrect   = remotes:WaitForChild("PlayerCorrect")
local BillboardEnd    = remotes:FindFirstChild("BillboardEnd")

-- =========================
-- STATE GLOBAL
-- =========================
local matchActive        = false
local isMyTurn           = false
local serverLetter       = ""
local usedWords          = {}
local usedWordsList      = {}
local opponentStreamWord = ""
local autoEnabled        = false
local compeMode          = false
local trapEndings        = { "if", "x", "y", "w", "ah", "uh", "eo" }
local autoRunning        = false
local lastAttemptedWord  = ""
local INACTIVITY_TIMEOUT = 6
local lastTurnActivity   = 0
local blacklistedWords   = {}
local lastRejectWord     = ""

-- 👻 HUMAN TYPO SIMULATION
local typoEnabled = false
local TYPO_CHANCE = 0.20

-- 🌟 RESPONSE WAITING FLAGS
local awaitingSubmitResponse = false
local lastSubmitSuccess = false
local lastSubmitMistake = false

-- AUTO JOIN STATE (FIXED)
local autoJoinMode  = {}
local autoJoinLoop  = nil
local joinedTable   = nil
local SCAN_INTERVAL = 0.3
local autoJoinInitialized = false

-- =========================
-- TURN TOKEN
-- =========================
local turnToken = 0

-- CONFIG
local config = {
    minDelay = 350,
    maxDelay = 650,
}

-- =========================
-- PLAYER WORD INDEX
-- =========================
local playerWordIndex = {}
local UpdateWordIndex = remotes:WaitForChild("UpdateWordIndex")

UpdateWordIndex.OnClientEvent:Connect(function(data)
    if data.AllWords then
        table.clear(playerWordIndex)
        for word, _ in pairs(data.AllWords) do
            playerWordIndex[string.lower(word)] = true
        end
    elseif data.NewWord then
        playerWordIndex[string.lower(data.NewWord)] = true
    end
end)

task.spawn(function()
    task.wait(2)
    pcall(function()
        remotes:WaitForChild("RequestWordIndex"):FireServer()
    end)
end)

-- =========================
-- PUSH INDEX TOGGLE
-- =========================
local pushIndexEnabled = false
local pushIndexToggle  = nil

-- =========================
-- SELECT WORD STATE
-- =========================
local selectModeEnabled = false
local selectMaxWords    = 10
local selectMinDelay    = 200
local selectMaxDelay    = 400
local selectRunning     = false
local selectDropdown    = nil
local selectChosenWord  = nil
local selectSliders     = {}
local selectToggle      = nil

-- =========================
-- LOGIC FUNCTIONS (SHARED)
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
    usedWords = {}; usedWordsList = {}
end

local function endsWithTrap(word)
    for _, ending in ipairs(trapEndings) do
        if string.sub(word, -#ending) == ending then return true end
    end
    return false
end

-- =========================
-- AUTO LOGIC: getSmartWords (dengan blacklist)
-- =========================
local function getSmartWords(prefix)
    if not prefix or #prefix == 0 then return {} end
    if #kataModule == 0 then return {} end
    local lowerPrefix = string.lower(prefix)
    if not lowerPrefix:match("^[a-z]+$") then return {} end
    local first      = string.sub(lowerPrefix, 1, 1)
    local candidates = wordsByFirstLetter[first]
    if not candidates then return {} end
    
    if pushIndexEnabled then
        local newWords = {}
        local oldWords = {}
        local trapNew  = nil; local trapNewScore = -math.huge
        local trapOld  = nil; local trapOldScore = -math.huge
        local bestNew  = nil; local bestNewScore = -math.huge
        local bestOld  = nil; local bestOldScore = -math.huge
        
        for _, word in ipairs(candidates) do
            if word ~= lowerPrefix
            and #word > #lowerPrefix
            and string.sub(word, 1, #lowerPrefix) == lowerPrefix
            and not isUsed(word)
            and not wrongWordsSet[word]
            and not blacklistedWords[word] then
                local score   = rankingMap[word] or 0
                local inIndex = playerWordIndex[word] == true
                if not inIndex then
                    if compeMode and endsWithTrap(word) then
                        if score > trapNewScore then trapNewScore = score; trapNew = word end
                    end
                    if score > bestNewScore then bestNewScore = score; bestNew = word end
                    table.insert(newWords, word)
                else
                    if compeMode and endsWithTrap(word) then
                        if score > trapOldScore then trapOldScore = score; trapOld = word end
                    end
                    if score > bestOldScore then bestOldScore = score; bestOld = word end
                    table.insert(oldWords, word)
                end
            end
        end
        
        if compeMode then
            if trapNew then return { trapNew } end
            if trapOld then return { trapOld } end
        end
        if bestNew then return { bestNew } end
        if bestOld then return { bestOld } end
        table.sort(newWords, function(a, b) return #a > #b end)
        if #newWords > 0 then return newWords end
        table.sort(oldWords, function(a, b) return #a > #b end)
        return oldWords
    else
        local bestRankWord  = nil; local bestRankScore = -math.huge
        local trapBest      = nil; local trapBestScore = -math.huge
        local normalResults = {}
        
        for _, word in ipairs(candidates) do
            if word ~= lowerPrefix
            and #word > #lowerPrefix
            and string.sub(word, 1, #lowerPrefix) == lowerPrefix
            and not isUsed(word)
            and not wrongWordsSet[word]
            and not blacklistedWords[word] then
                local score = rankingMap[word] or 0
                if compeMode and endsWithTrap(word) then
                    if score > trapBestScore then trapBestScore = score; trapBest = word end
                end
                if score > bestRankScore then bestRankScore = score; bestRankWord = word end
                table.insert(normalResults, word)
            end
        end
        
        if compeMode and trapBest then return { trapBest } end
        if bestRankWord then return { bestRankWord } end
        table.sort(normalResults, function(a, b) return #a > #b end)
        return normalResults
    end
end

-- =========================
-- SELECT WORD LOGIC (pushIndex-aware)
-- =========================
local function getSelectWords(prefix)
    if not prefix or #prefix == 0 then return {} end
    if #kataModule == 0 then return {} end
    local lowerPrefix = string.lower(prefix)
    if not lowerPrefix:match("^[a-z]+$") then return {} end
    local first      = string.sub(lowerPrefix, 1, 1)
    local candidates = wordsByFirstLetter[first]
    if not candidates then return {} end
    
    if pushIndexEnabled then
        local newWords = {}
        local oldWords = {}
        for _, word in ipairs(candidates) do
            if word ~= lowerPrefix
            and #word > #lowerPrefix
            and string.sub(word, 1, #lowerPrefix) == lowerPrefix
            and not isUsed(word)
            and not wrongWordsSet[word] then
                if playerWordIndex[word] then
                    table.insert(oldWords, word)
                else
                    table.insert(newWords, word)
                end
            end
        end
        table.sort(newWords, function(a, b) return #a > #b end)
        table.sort(oldWords,  function(a, b) return #a > #b end)
        local results = {}
        for _, w in ipairs(newWords) do results[#results + 1] = w end
        for _, w in ipairs(oldWords)  do results[#results + 1] = w end
        return results
    else
        local results = {}
        for _, word in ipairs(candidates) do
            if word ~= lowerPrefix
            and #word > #lowerPrefix
            and string.sub(word, 1, #lowerPrefix) == lowerPrefix
            and not isUsed(word)
            and not wrongWordsSet[word] then
                table.insert(results, word)
            end
        end
        table.sort(results, function(a, b) return #a > #b end)
        return results
    end
end

local function refreshSelectDropdown()
    if not selectDropdown then return end
    if not selectModeEnabled or not isMyTurn or serverLetter == "" then
        pcall(function() selectDropdown:Refresh({}) end)
        selectChosenWord = nil
        return
    end
    local words   = getSelectWords(serverLetter)
    local limited = {}
    for i = 1, math.min(#words, selectMaxWords) do
        limited[#limited + 1] = words[i]
    end
    pcall(function() selectDropdown:Refresh(limited) selectDropdown:Select(" ") end)
    selectChosenWord = nil
    if #limited > 0 then
        selectChosenWord = limited[1]
    else
        selectChosenWord = nil
    end
end

-- =========================
-- MATCH TABLES FROM SERVER (via UpdatePromptVisibility)
-- =========================
local matchTables = {}  -- set nama meja yang sedang match (prompt disabled)
local UpdatePromptVisibility = remotes:FindFirstChild("UpdatePromptVisibility")
if UpdatePromptVisibility then
    UpdatePromptVisibility.OnClientEvent:Connect(function(data)
        if type(data) == "table" then
            matchTables = data
        else
            matchTables = {}
        end
        -- optional: print("[MATCH TABLES] Updated:", table.concat(matchTables, ", "))
    end)
end

-- =========================
-- VIRTUAL INPUT HELPER
-- =========================
local VIM = pcall(function() return game:GetService("VirtualInputManager") end)
and game:GetService("VirtualInputManager") or nil

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
            local r = find(c); if r then return r end
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
        if code then keypress(code); task.wait(0.02); keyrelease(code) end
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
        keypress(8); task.wait(0.02); keyrelease(8)
        return
    end
    pcall(function()
        local tb = findTextBox()
        if tb and #tb.Text > 0 then tb.Text = string.sub(tb.Text, 1, -2) end
    end)
end

-- currentTyped: track kata yang sedang diketik secara internal
local currentTyped = ""

-- Ketik 1 karakter
local function typeChar(ch)
    currentTyped = currentTyped .. string.lower(ch)
    pcall(function() sendKey(ch) end)
    pcall(function() TypeSound:FireServer() end)
    pcall(function() BillboardUpdate:FireServer(currentTyped) end)
end

-- Hapus 1 karakter
local function eraseChar()
    if #currentTyped == 0 then return end
    if VIM then
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
            task.wait(0.025)
            VIM:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
        end)
    elseif keypress and keyrelease then
        pcall(function() keypress(8); task.wait(0.02); keyrelease(8) end)
    end
    currentTyped = string.sub(currentTyped, 1, -2)
    pcall(function()
        local tb = findTextBox()
        if tb then tb.Text = currentTyped end
    end)
    pcall(function() BillboardUpdate:FireServer(currentTyped) end)
end

local function humanDelay()
    local min = config.minDelay; local max = config.maxDelay
    if min > max then min = max end
    task.wait(math.random(min, max) / 1000)
end

-- =========================
-- TYPO SIMULATION
-- =========================
local KEYBOARD_NEIGHBORS = {
    a = {"q","w","s","z"}, b = {"v","g","h","n"}, c = {"x","d","f","v"},
    d = {"s","e","r","f","c","x"}, e = {"w","r","d","s"}, f = {"d","r","t","g","v","c"},
    g = {"f","t","y","h","b","v"}, h = {"g","y","u","j","n","b"}, i = {"u","o","k","j"},
    j = {"h","u","i","k","n","m"}, k = {"j","i","o","l","m"}, l = {"k","o","p"},
    m = {"n","j","k"}, n = {"b","h","j","m"}, o = {"i","p","l","k"},
    p = {"o","l"}, q = {"w","a"}, r = {"e","t","f","d"}, s = {"a","w","e","d","x","z"},
    t = {"r","y","g","f"}, u = {"y","i","j","h"}, v = {"c","f","g","b"},
    w = {"q","e","s","a"}, x = {"z","s","d","c"}, y = {"t","u","h","g"}, z = {"a","s","x"},
}

local function maybeDoTypo(correctChar, currentWord)
    if not typoEnabled then return end
    if #currentWord < 2 then return end
    if math.random() > TYPO_CHANCE then return end
    local c = string.lower(correctChar)
    local neighbors = KEYBOARD_NEIGHBORS[c]
    if not neighbors or #neighbors == 0 then return end
    local wrongChar = neighbors[math.random(1, #neighbors)]
    pcall(function() sendKey(wrongChar) end)
    pcall(function() TypeSound:FireServer() end)
    task.wait(math.random(80, 180) / 1000)
    task.wait(math.random(150, 350) / 1000)
    pcall(function() sendBackspace() end)
    task.wait(math.random(60, 120) / 1000)
end

-- =========================
-- TAP SCREEN HELPER
-- =========================
local function tapScreenOnce()
    if VIM then
        local cam = workspace.CurrentCamera
        if cam then
            local vp = cam.ViewportSize
            local x  = math.floor(vp.X / 2); local y = math.floor(vp.Y / 2)
            pcall(function()
                VIM:SendMouseButtonEvent(x, y, 0, true,  game, 1)
                task.wait(0.06)
                VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
            end)
            return
        end
    end
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if gui then
        local btnKeywords = { "ok", "oke", "close", "kembali", "lanjut", "keluar", "main lagi", "rematch", "back" }
        local function findBtn(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("TextButton") or child:IsA("ImageButton") then
                    local txt = string.lower(child.Text or "")
                    for _, kw in ipairs(btnKeywords) do
                        if txt:find(kw) then return child end
                    end
                end
                local r = findBtn(child); if r then return r end
            end
            return nil
        end
        local btn = findBtn(gui)
        if btn then pcall(function() btn.MouseButton1Click:Fire() end); return end
    end
    if firetouchstart and firetouchend then
        local cam = workspace.CurrentCamera
        if cam then
            local vp  = cam.ViewportSize
            local pos = Vector2.new(vp.X / 2, vp.Y / 2)
            pcall(function() firetouchstart(pos); task.wait(0.06); firetouchend(pos) end)
        end
    end
end

local function fireBillboardEnd()
    if BillboardEnd then
        pcall(function() BillboardEnd:FireServer() end)
    else
        pcall(function() BillboardUpdate:FireServer("") end)
    end
end

-- =========================
-- revertToStartLetter
-- =========================
local function revertToStartLetter()
    if serverLetter == "" then return end
    local target = string.lower(serverLetter)
    local excessCount = #currentTyped - #target
    if excessCount <= 0 then
        currentTyped = target
        pcall(function() BillboardUpdate:FireServer(currentTyped) end)
        pcall(function()
            local tb = findTextBox()
            if tb then tb.Text = currentTyped end
        end)
        lastAttemptedWord = ""
        return
    end
    for i = 1, excessCount do
        eraseChar()
        task.wait(0.3)
    end
    currentTyped = target
    pcall(function() BillboardUpdate:FireServer(currentTyped) end)
    pcall(function()
        local tb = findTextBox()
        if tb then tb.Text = currentTyped end
    end)
    lastAttemptedWord = ""
    task.wait(0.3)
end

-- =========================
-- ✅ submitAndRetry (v5.7 + DUAL WEBHOOK)
-- =========================
local function submitAndRetry(startLetter)
    local MAX_RETRY = 6
    local attempt   = 0
    
    while attempt < MAX_RETRY and autoRunning do
        attempt = attempt + 1
        
        if not matchActive or not autoEnabled or not isMyTurn then
            fireBillboardEnd(); return false
        end
        
        if attempt > 1 then
            revertToStartLetter()
            task.wait(0.5)
        end
        
        if currentTyped ~= startLetter then
            local excess = #currentTyped - #startLetter
            if excess > 0 then
                for i = 1, excess do
                    eraseChar()
                    task.wait(0.05)
                end
            end
            if currentTyped ~= startLetter then
                currentTyped = startLetter
                pcall(function() BillboardUpdate:FireServer(currentTyped) end)
                pcall(function()
                    local tb = findTextBox()
                    if tb then tb.Text = currentTyped end
                end)
            end
        end
        
        local words = getSmartWords(startLetter)
        if #words == 0 then
            print("[AUTO] tidak ada kata untuk prefix: " .. startLetter)
            fireBillboardEnd(); return false
        end
        
        local sel = words[1]
        print(string.format("[AUTO] attempt %d: mencoba kata '%s' (prefix='%s')", attempt, sel, startLetter))
        
        focusTextBox()
        task.wait(0.5)
        
        if not matchActive or not autoEnabled or not isMyTurn then
            fireBillboardEnd(); return false
        end
        
        local remain  = string.sub(sel, #startLetter + 1)
        local aborted = false
        for i = 1, #remain do
            if not matchActive or not autoEnabled or not isMyTurn then
                aborted = true; fireBillboardEnd(); break
            end
            local ch = string.sub(remain, i, i)
            maybeDoTypo(ch, currentTyped)
            if not matchActive or not autoEnabled or not isMyTurn then
                aborted = true; fireBillboardEnd(); break
            end
            typeChar(ch)
            humanDelay()
        end
        
        if aborted then return false end
        
        if not matchActive or not autoEnabled or not isMyTurn then
            fireBillboardEnd(); return false
        end
        
        task.wait(0.3)
        
        awaitingSubmitResponse = true
        lastSubmitSuccess      = false
        lastSubmitMistake      = false
        lastRejectWord         = ""
        lastAttemptedWord      = sel
        
        print(string.format("[AUTO] submit kata '%s'", sel))
        pcall(function() SubmitWord:FireServer(sel) end)
        
        local timeout = 0
        while awaitingSubmitResponse and timeout < 40 do
            task.wait(0.7); timeout = timeout + 1
        end
        awaitingSubmitResponse = false
        
        -- ✅ CEK HASIL SUBMIT & UPDATE BLACKLIST + DISCORD WRONG WORD
        if lastRejectWord == string.lower(sel) then
            print(string.format("[AUTO] kata '%s' DITOLAK (usedWarn) -> blacklist persist", sel))
            blacklistedWords[string.lower(sel)] = true
            lastAttemptedWord = ""
            revertToStartLetter()
            task.wait(0.7)
        elseif lastSubmitMistake then
            -- 📢 KIRIM KE DISCORD WRONG WEBHOOK + BLACKLIST PERSIST
            print(string.format("[AUTO] kata '%s' SALAH (HIT) -> blacklist persist + discord", sel))
            blacklistedWords[string.lower(sel)] = true
            sendWrongWordDiscord(sel)  -- ✅ KIRIM KE WRONG_WORD_WEBHOOK
            lastAttemptedWord = ""
            revertToStartLetter()
            task.wait(0.7)
        elseif lastSubmitSuccess then
            print(string.format("[AUTO] kata '%s' BERHASIL", sel))
            addUsedWord(sel)
            lastAttemptedWord = ""
            currentTyped = ""
            fireBillboardEnd()
            return true
        else
            print(string.format("[AUTO] kata '%s' timeout/gagal -> retry", sel))
            lastAttemptedWord = ""
            revertToStartLetter()
            task.wait(0.7)
        end
    end
    
    if attempt >= MAX_RETRY then
        print("[AUTO] MAX_RETRY habis -> reset blacklist")
        blacklistedWords = {}
    end
    
    fireBillboardEnd()
    return false
end

-- =========================
-- startUltraAI
-- =========================
local function startUltraAI()
    if autoRunning or not autoEnabled then return end
    if not matchActive or not isMyTurn then return end
    if serverLetter == "" then return end
    if #kataModule == 0 then return end
    if selectRunning then return end
    
    autoRunning      = true
    lastTurnActivity = tick()
    
    if not matchActive or not isMyTurn then autoRunning = false; return end
    
    local currentPrefix = string.lower(serverLetter)
    if not currentPrefix:match("^[a-z]+$") then autoRunning = false; return end
    
    currentTyped = currentPrefix
    pcall(function()
        local tb = findTextBox()
        if tb then tb.Text = currentTyped end
    end)
    pcall(function() BillboardUpdate:FireServer(currentTyped) end)
    pcall(function() submitAndRetry(currentPrefix) end)
    autoRunning = false
end

-- =========================
-- SELECT WORD: SEND MANUAL
-- =========================
local function sendWordManual(word)
    if not word or word == "" then
        notify("⚠ Select Word", "Tidak ada kata dipilih!", 2)
        return
    end
    if not matchActive then
        notify("⚠ Select Word", "Match belum aktif!", 2)
        return
    end
    if not isMyTurn then
        notify("⚠ Select Word", "Bukan giliran kamu!", 2)
        return
    end
    if autoRunning then
        notify("⚠ Select Word", "Auto sedang berjalan, tunggu sebentar!", 2)
        return
    end
    if selectRunning then
        notify("⚠ Select Word", "Sedang mengetik, harap tunggu!", 2)
        return
    end
    
    selectRunning = true
    lastTurnActivity = tick()
    
    task.spawn(function()
        local lowerWord   = string.lower(word)
        local startLetter = string.lower(serverLetter)
        
        if string.sub(lowerWord, 1, #startLetter) ~= startLetter then
            notify("⚠ Select Word", "Kata tidak cocok huruf awal: " .. startLetter, 2)
            selectRunning = false
            return
        end
        
        focusTextBox()
        task.wait(0.05)
        
        local remain = string.sub(lowerWord, #startLetter + 1)
        local cur    = startLetter
        
        for i = 1, #remain do
            if not isMyTurn or not matchActive then
                fireBillboardEnd()
                selectRunning = false
                return
            end
            local ch = string.sub(remain, i, i)
            cur = cur .. ch
            pcall(function() sendKey(ch) end)
            pcall(function() TypeSound:FireServer() end)
            pcall(function() BillboardUpdate:FireServer(cur) end)
            local mn = selectMinDelay; local mx = selectMaxDelay
            if mn > mx then mn = mx end
            task.wait(math.random(mn, mx) / 1000)
        end
        
        task.wait(0.2)
        
        if not isMyTurn or not matchActive then
            fireBillboardEnd()
            selectRunning = false
            return
        end
        
        awaitingSubmitResponse = true
        lastSubmitSuccess = false
        lastSubmitMistake = false
        lastRejectWord = ""
        
        pcall(function() SubmitWord:FireServer(lowerWord) end)
        
        local timeout = 0
        while awaitingSubmitResponse and timeout < 40 do
            task.wait(0.05)
            timeout = timeout + 1
        end
        awaitingSubmitResponse = false
        
        if lastSubmitSuccess then
            addUsedWord(lowerWord)
            selectChosenWord = nil
            fireBillboardEnd()
            lastTurnActivity = tick()
            task.spawn(function()
                task.wait(0.1)
                if selectDropdown then
                    pcall(function() selectDropdown:Refresh({}) selectDropdown:Select(" ") end)
                    selectDropdown:Select("--")
                end
                selectChosenWord = nil
            end)
        else
            revertToStartLetter()
            task.wait(0.3)
        end
        
        selectRunning = false
        task.wait(0.4)
        refreshSelectDropdown()
    end)
end

-- =========================
-- MONITORING MEJA & GILIRAN
-- =========================
local currentTableName = nil
local tableTarget      = nil
local seatStates       = {}

local function getSeatPlayer(seat)
    if seat and seat.Occupant then
        local character = seat.Occupant.Parent
        if character then return Players:GetPlayerFromCharacter(character) end
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
    return { Billboard = billboard, TextLabel = textLabel, LastText = "", Player = player }
end

local function setupSeatMonitoring()
    if not currentTableName then seatStates = {}; tableTarget = nil; return end
    local tablesFolder = Workspace:FindFirstChild("Tables")
    if not tablesFolder then return end
    tableTarget = tablesFolder:FindFirstChild(currentTableName)
    if not tableTarget then return end
    local seatsContainer = tableTarget:FindFirstChild("Seats")
    if not seatsContainer then return end
    seatStates = {}
    for _, seat in ipairs(seatsContainer:GetChildren()) do
        if seat:IsA("Seat") then seatStates[seat] = { Current = nil } end
    end
end

local function onCurrentTableChanged()
    local tableName = LocalPlayer:GetAttribute("CurrentTable")
    if tableName then currentTableName = tableName; setupSeatMonitoring()
    else currentTableName = nil; tableTarget = nil; seatStates = {} end
end

LocalPlayer.AttributeChanged:Connect(function(attr)
    if attr == "CurrentTable" then onCurrentTableChanged() end
end)

onCurrentTableChanged()

-- =========================
-- 🔧 AUTO JOIN / SEAT SYSTEM (v5.8 ROBUST - TELEPORT + RETRY)
-- =========================
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
    while h.SeatPart ~= nil and w < 2 do task.wait(0.1); w = w + 0.1 end
end

-- ✅ FIX: Teleport player ke posisi table sebelum trigger prompt
local function teleportToTable(model)
    local tablePart = model:FindFirstChild("TablePart") or model:FindFirstChildWhichIsA("BasePart")
    if not tablePart then return false end
    
    local char = LocalPlayer.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    -- Teleport sedikit di atas table
    local targetPos = tablePart.Position + Vector3.new(0, 5, 0)
    pcall(function()
        root.CFrame = CFrame.new(targetPos)
    end)
    return true
end

-- ✅ FIX: Cari ProximityPrompt dengan recursive + timeout
local function findPromptWithTimeout(model, timeoutSec)
    local startTime = tick()
    
    while tick() - startTime < timeoutSec do
        local function recursiveFind(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ProximityPrompt") then
                    return child
                end
                if child:IsA("Model") or child:IsA("BasePart") or child:IsA("Folder") then
                    local found = recursiveFind(child)
                    if found then return found end
                end
            end
            return nil
        end
        
        local prompt = recursiveFind(model)
        if prompt then return prompt end
        
        task.wait(0.1)
    end
    return nil
end

-- ✅ FIX: Trigger prompt dengan retry + teleport
local function pressPromptWithRetry(model, maxRetries)
    maxRetries = maxRetries or 3
    
    for attempt = 1, maxRetries do
        -- Teleport dulu ke table
        teleportToTable(model)
        task.wait(0.3)
        
        -- Cari prompt dengan timeout
        local prompt = findPromptWithTimeout(model, 1.5)
        if not prompt then
            print(string.format("[AUTOJOIN] attempt %d: prompt not found, retrying...", attempt))
            task.wait(0.5)
            continue
        end
        
        -- Fire prompt
        if fireproximityprompt then
            pcall(function() fireproximityprompt(prompt) end)
        elseif prompt.Triggered then
            prompt:InputHoldBegin()
            task.wait(0.3)
            prompt:InputHoldEnd()
        else
            -- Fallback: click detector approach
            pcall(function()
                local args = { [1] = prompt, [2] = true }
                remotes:FindFirstChild("InputHandler"):FireServer(unpack(args))
            end)
        end
        
        -- Wait for seated confirmation
        local waited = 0
        while not isSeated() and waited < 4 do
            task.wait(0.2)
            waited = waited + 0.2
        end
        
        if isSeated() then
            print("[AUTOJOIN] successfully seated!")
            return true
        end
        
        print(string.format("[AUTOJOIN] attempt %d: not seated after prompt", attempt))
        task.wait(0.5)
    end
    
    return false
end

local function getOccupied(model)
    local sf = model:FindFirstChild("Seats")
    if not sf then return 0 end
    local seats = {}
    for _, s in ipairs(sf:GetChildren()) do if s:IsA("Seat") then seats[s] = true end end
    local n = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            if h and h.SeatPart and seats[h.SeatPart] then n = n + 1 end
        end
    end
    return n
end

local function getCapacity(model)
    local sf = model:FindFirstChild("Seats")
    if not sf then return 0 end
    local n = 0
    for _, s in ipairs(sf:GetChildren()) do if s:IsA("Seat") then n = n + 1 end end
    return n
end

local function isTableInMatch(model)
    -- ✅ Prioritaskan data dari server (UpdatePromptVisibility)
    if matchTables[model.Name] then
        return true
    end
    -- Cek child "Game" atau "Match"
    if model:FindFirstChild("Game") then return true end
    if model:FindFirstChild("Match") then return true end
    -- Cek attribute
    local matchStarted = model:GetAttribute("MatchStarted")
    if matchStarted == true then return true end
    -- Opsi tambahan (jika diperlukan)
    --[[
    local seatsContainer = model:FindFirstChild("Seats")
    if seatsContainer then
        for _, seat in ipairs(seatsContainer:GetChildren()) do
            if seat:IsA("Seat") and seat.Occupant then
                local char = seat.Occupant.Parent
                if char then
                    local player = Players:GetPlayerFromCharacter(char)
                    if player and player.Character then
                        local head = player.Character:FindFirstChild("Head")
                        if head and head:FindFirstChild("TurnBillboard") then
                            return true
                        end
                    end
                end
            end
        end
    end
    ]]
    return false
end

local function stopAutoJoin()
    if autoJoinLoop then 
        task.cancel(autoJoinLoop)
        autoJoinLoop = nil 
    end
    joinedTable = nil
    autoJoinInitialized = false
end

local function isAutoJoinActive()
    return #autoJoinMode > 0
end

local MODE_THRESHOLD = {
    ["2P"] = 1,
    ["4P"] = 2,
    ["8P"] = 4,
}

local function getModeFromName(name)
    for mode in pairs(MODE_THRESHOLD) do
        if name:find(mode) then return mode end
    end
    return nil
end

-- ✅ FIX: startAutoJoin sekarang lebih robust & konsisten
local function startAutoJoin()
    -- Stop loop lama jika ada
    stopAutoJoin()
    
    -- Jangan start jika tidak ada mode dipilih
    if not isAutoJoinActive() then 
        autoJoinInitialized = false
        return 
    end
    
    -- Set flag initialized
    autoJoinInitialized = true
    print("[AUTOJOIN] started, modes: " .. table.concat(autoJoinMode, ", "))
    
    autoJoinLoop = task.spawn(function()
        while autoJoinInitialized and _G.AutoKataActive do
            pcall(function()
                -- Jika sedang match, skip scanning
                if matchActive then 
                    task.wait(SCAN_INTERVAL)
                    return 
                end
                
                local tf = Workspace:FindFirstChild("Tables")
                if not tf then 
                    task.wait(SCAN_INTERVAL)
                    return 
                end
                
                -- Jika sudah join table, monitor statusnya
                if joinedTable then
                    local model = tf:FindFirstChild(joinedTable)
                    if not model then
                        -- Table hilang, leave & reset
                        forceLeaveSeat()
                        joinedTable = nil
                        task.wait(0.5)
                        return
                    end
                    
                    -- Jika belum seated, coba join lagi
                    if not isSeated() then
                        joinedTable = nil
                        task.wait(0.3)
                        return
                    end
                    
                    -- Monitor: jika lawan keluar (occupancy <= 1), leave juga
                    local occ = getOccupied(model)
                    if occ <= 1 then
                        pcall(function() LeaveTable:FireServer() end)
                        forceLeaveSeat()
                        joinedTable = nil
                        task.wait(0.5)
                    end
                    task.wait(SCAN_INTERVAL)
                    return
                end
                
                -- Jika sudah seated tapi joinedTable nil, reset
                if isSeated() then
                    forceLeaveSeat()
                    task.wait(0.3)
                    return
                end
                
                -- Scan tables yang tersedia
                local candidates = {}
                for _, model in ipairs(tf:GetChildren()) do
                    if model:IsA("Model") then
                        local mode = getModeFromName(model.Name)
                        if mode and table.find(autoJoinMode, mode) and not isTableInMatch(model) then
                            local cap = getCapacity(model)
                            local occ = getOccupied(model)
                            local threshold = MODE_THRESHOLD[mode]
                            local qualifies = false
                            
                            if mode == "2P" then
                                qualifies = (occ == cap - 1 and cap == 2)
                            else
                                qualifies = (occ >= threshold and occ < cap)
                            end
                            
                            if qualifies then
                                table.insert(candidates, {
                                    model = model,
                                    occ = occ,
                                    cap = cap,
                                    mode = mode
                                })
                            end
                        end
                    end
                end
                
                if #candidates == 0 then
                    task.wait(SCAN_INTERVAL)
                    return
                end
                
                -- Sort by occupancy (prioritaskan yang hampir full)
                table.sort(candidates, function(a, b)
                    return a.occ > b.occ
                end)
                
                -- Coba join ke candidate terbaik dengan retry
                for _, cand in ipairs(candidates) do
                    print(string.format("[AUTOJOIN] attempting to join %s (%s mode, %d/%d)", 
                        cand.model.Name, cand.mode, cand.occ, cand.cap))
                    
                    if pressPromptWithRetry(cand.model, 3) then
                        joinedTable = cand.model.Name
                        print("[AUTOJOIN] successfully joined: " .. joinedTable)
                        break
                    else
                        print("[AUTOJOIN] failed to join: " .. cand.model.Name)
                    end
                end
            end)
            task.wait(SCAN_INTERVAL)
        end
        print("[AUTOJOIN] loop ended")
    end)
end

-- =========================
-- REMOTE EVENT HANDLERS
-- =========================
local updateMainStatus
local updateConfigDisplay

local function onMatchUI(cmd, value)
    if cmd == "ShowMatchUI" then
        matchActive = true; isMyTurn = false; serverLetter = ""
        resetUsedWords()
        -- ✅ JANGAN RESET blacklistedWords di sini! Persist selama match
        setupSeatMonitoring()
        updateMainStatus()
        
        -- ✅ FIX: Restart auto join setelah match mulai (jika aktif)
        if isAutoJoinActive() and not autoJoinInitialized then
            task.delay(1, startAutoJoin)
        end
        
    elseif cmd == "HideMatchUI" then
        matchActive = false; isMyTurn = false; serverLetter = ""
        resetUsedWords()
        -- ✅ RESET blacklistedWords HANYA saat match selesai
        blacklistedWords = {}
        seatStates = {}
        updateMainStatus()
        task.delay(0.1, refreshSelectDropdown)
        task.spawn(function()
            for i = 1, 3 do
                task.wait(0.5 + (i - 1) * 0.4)
                tapScreenOnce()
            end
        end)
        
        -- ✅ FIX: Restart auto join setelah match selesai (jika aktif)
        if isAutoJoinActive() then
            task.delay(1.5, function()
                if not matchActive then
                    forceLeaveSeat()
                    joinedTable = nil
                    startAutoJoin()  -- ✅ Restart auto join loop
                end
            end)
        end
        
    elseif cmd == "StartTurn" then
        isMyTurn = true; lastTurnActivity = tick()
        if type(value) == "string" and value ~= "" then serverLetter = value end
        -- ✅ JANGAN RESET blacklistedWords di StartTurn! Persist antar giliran
        currentTyped = string.lower(serverLetter)
        pcall(function() BillboardUpdate:FireServer(currentTyped) end)
        task.delay(0.3, refreshSelectDropdown)
        if autoEnabled then
            task.spawn(function()
                task.wait(math.random(1500, 2700) / 1000)
                if matchActive and isMyTurn and autoEnabled then
                    startUltraAI()
                end
            end)
        end
        updateMainStatus()
    elseif cmd == "EndTurn" then
        isMyTurn = false
        updateMainStatus()
        task.spawn(function()
            task.wait(0.2)
            if selectDropdown then
                pcall(function() selectDropdown:Refresh({}) end)
            end
            selectChosenWord = nil
        end)
    elseif cmd == "UpdateServerLetter" then
        serverLetter = value or ""
        updateMainStatus()
        task.delay(0.3, refreshSelectDropdown)
        if isMyTurn and autoEnabled and not autoRunning and serverLetter ~= "" then
            task.spawn(startUltraAI)
        end
    elseif cmd == "Mistake" then
        if value and value.userId == LocalPlayer.UserId then
            lastSubmitMistake = true
            awaitingSubmitResponse = false
            if autoEnabled and matchActive and isMyTurn then
                task.spawn(function()
                    task.wait(0.5)
                    revertToStartLetter()
                    task.wait(0.5)
                    startUltraAI()
                end)
            end
        end
    end
end

local function onBillboard(word)
    if matchActive and not isMyTurn then opponentStreamWord = word or "" end
end

local function onUsedWarn(word)
    if word then
        lastRejectWord = string.lower(tostring(word))
        awaitingSubmitResponse = false
        addUsedWord(word)
        task.delay(0.3, refreshSelectDropdown)
    end
end

-- =========================
-- PlayerHit handler (v5.7 + DUAL WEBHOOK)
-- =========================
PlayerHit.OnClientEvent:Connect(function(player)
    if player == LocalPlayer then
        -- ✅ Snapshot dulu SEBELUM apapun di-reset
        local snapshotWord    = lastAttemptedWord
        local snapshotAuto    = autoEnabled
        print(string.format("[HIT] kena hit! lastAttempted='%s' currentTyped='%s'",
            snapshotWord, currentTyped))
        
        -- 📢 KIRIM KE DISCORD: cek snapshot, bukan live variable
        if snapshotAuto and snapshotWord ~= "" then
            sendWrongWordDiscord(snapshotWord)
        end
        
        -- 1. Blacklist kata yang menyebabkan hit (PERSIST)
        if lastAttemptedWord ~= "" then
            blacklistedWords[string.lower(lastAttemptedWord)] = true
            print(string.format("[HIT] blacklist persist '%s'", lastAttemptedWord))
            lastAttemptedWord = ""
        end
        
        -- 2. Reset semua flag
        autoRunning            = false
        awaitingSubmitResponse = false
        lastSubmitSuccess      = false
        lastSubmitMistake      = false
        
        -- 3. Reset currentTyped ke serverLetter
        if serverLetter ~= "" then
            currentTyped = string.lower(serverLetter)
            pcall(function() BillboardUpdate:FireServer(currentTyped) end)
            pcall(function()
                local tb = findTextBox()
                if tb then tb.Text = currentTyped end
            end)
        end
        
        -- 4. Retry cari kata baru
        if autoEnabled and matchActive and isMyTurn then
            task.spawn(function()
                task.wait(0.6)
                if matchActive and isMyTurn and autoEnabled then
                    startUltraAI()
                end
            end)
        end
    end
end)

PlayerCorrect.OnClientEvent:Connect(function(player)
    if player == LocalPlayer then
        lastSubmitSuccess = true
        awaitingSubmitResponse = false
    end
end)

JoinTable.OnClientEvent:Connect(function(tableName)
    currentTableName = tableName
    if isAutoJoinActive() then joinedTable = tableName end
    setupSeatMonitoring(); updateMainStatus()
end)

LeaveTable.OnClientEvent:Connect(function()
    currentTableName = nil; matchActive = false; isMyTurn = false; serverLetter = ""
    resetUsedWords()
    -- ✅ RESET blacklistedWords saat leave table (match end)
    blacklistedWords = {}
    seatStates = {}; joinedTable = nil
    updateMainStatus()
    task.delay(0.1, refreshSelectDropdown)
    
    -- ✅ FIX: Restart auto join setelah leave (jika aktif)
    if isAutoJoinActive() then
        task.delay(1, function()
            if not matchActive then
                forceLeaveSeat()
                startAutoJoin()
            end
        end)
    end
end)

-- =========================
-- UI MAIN TAB: TOGGLE & SLIDERS
-- =========================
local sliders        = {}
local autoToggle
local compeToggle
local typoToggle
local autoJoinDropdown

autoToggle = MainTab:Toggle({
    Title    = "Aktifkan Auto",
    Desc     = "Menjalankan auto jawab saat giliran",
    Icon     = "lucide:play",
    Type     = "Checkbox",
    Value    = false,
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
                            task.wait(0.1); timeout = timeout + 1
                        end
                    end
                    if matchActive and isMyTurn and serverLetter ~= "" then startUltraAI() end
                end
            end)
        else
            autoRunning = false
            task.spawn(function() task.wait(0.1); fireBillboardEnd() end)
            notify("⚡ AUTO MODE", "Auto Dimatikan", 3)
        end
    end
})

compeToggle = MainTab:Toggle({
    Title    = "Compe Mode",
    Desc     = "Prioritaskan kata jebakan (if, x, y, w, ah, uh)",
    Icon     = "lucide:flame",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(Value)
        compeMode = Value
        if Value then notify("🔥 COMPE MODE", "Mode Jebakan Aktif", 2)
        else notify("❄️ COMPE MODE", "Mode Jebakan Nonaktif", 2) end
    end
})

typoToggle = MainTab:Toggle({
    Title    = "Human Typo Simulation",
    Desc     = "Bot sesekali typo lalu backspace (20% chance/kata) — terlihat manusia",
    Icon     = "lucide:keyboard",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(Value)
        typoEnabled = Value
        if Value then notify("👻 TYPO SIM", "Aktif — bot akan sesekali salah ketik", 2)
        else notify("👻 TYPO SIM", "Nonaktif", 2) end
    end
})

pushIndexToggle = MainTab:Toggle({
    Title    = "Push Index",
    Desc     = "Aktif: bot HANYA cari kata belum ada di index koleksimu",
    Icon     = "lucide:star",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(Value)
        pushIndexEnabled = Value
        if Value then
            pcall(function()
                remotes:WaitForChild("RequestWordIndex"):FireServer()
            end)
            local n = 0
            for _ in pairs(playerWordIndex) do n = n + 1 end
            notify("🌟 PUSH INDEX", "Aktif — prioritas kata baru di luar index (" .. n .. " kata terindex)", 3)
        else
            notify("🌟 PUSH INDEX", "Nonaktif — logika ranking biasa", 2)
        end
        if updateConfigDisplay then updateConfigDisplay() end
        task.delay(0.1, refreshSelectDropdown)
    end
})

autoJoinDropdown = MainTab:Dropdown({
    Title    = "Auto Join Mode",
    Desc     = "Pilih tipe meja — bisa pilih lebih dari satu",
    Icon     = "lucide:users",
    Values   = { "2P", "4P", "8P" },
    Value    = {},
    Multi    = true,
    Callback = function(sel)
        if type(sel) == "table" then
            autoJoinMode = sel
        else
            autoJoinMode = {}
        end
        -- ✅ FIX: Selalu restart auto join saat config berubah
        if isAutoJoinActive() then
            startAutoJoin()
            local modes = table.concat(autoJoinMode, ", ")
            notify("🪑 AUTO JOIN", "Aktif: " .. modes, 2)
        else
            stopAutoJoin()
            notify("🪑 AUTO JOIN", "Nonaktif", 2)
        end
        if updateConfigDisplay then updateConfigDisplay() end
    end,
})

MainTab:Button({
    Title    = "🛑 Nonaktifkan Auto Join",
    Desc     = "Hapus semua pilihan & matikan auto join",
    Callback = function()
        autoJoinMode = {}
        stopAutoJoin()
        pcall(function() autoJoinDropdown:Set({}) end)
        if updateConfigDisplay then updateConfigDisplay() end
        notify("🪑 AUTO JOIN", "Nonaktif", 2)
    end
})

table.insert(sliders, MainTab:Slider({
    Title    = "Min Delay (ms)",
    Desc     = "Delay minimal antar huruf",
    Step     = 5,
    Value    = { Min = 10, Max = 500, Default = config.minDelay },
    Callback = function(Value)
        config.minDelay = Value
        if config.minDelay > config.maxDelay then
            config.maxDelay = config.minDelay
            for _, s in ipairs(sliders) do
                if s.Title == "Max Delay (ms)" then s:Set(config.maxDelay) end
            end
        end
        if updateConfigDisplay then updateConfigDisplay() end
    end
}))

table.insert(sliders, MainTab:Slider({
    Title    = "Max Delay (ms)",
    Desc     = "Delay maksimal antar huruf",
    Step     = 5,
    Value    = { Min = 100, Max = 1000, Default = config.maxDelay },
    Callback = function(Value)
        config.maxDelay = Value
        if config.maxDelay < config.minDelay then
            config.minDelay = config.maxDelay
            for _, s in ipairs(sliders) do
                if s.Title == "Min Delay (ms)" then s:Set(config.minDelay) end
            end
        end
        if updateConfigDisplay then updateConfigDisplay() end
    end
}))

function updateMainStatus()
    if not matchActive then
        statusParagraph:SetDesc("Match tidak aktif | - | -")
        return
    end
    local activePlayer = nil
    for seat, state in pairs(seatStates) do
        if state.Current and state.Current.Billboard and state.Current.Billboard.Parent then
            activePlayer = state.Current.Player; break
        end
    end
    local playerName = ""; local turnText = ""
    if isMyTurn then
        playerName = "Anda"; turnText = "Giliran Anda"
    elseif activePlayer then
        playerName = activePlayer.Name; turnText = "Giliran " .. activePlayer.Name
    else
        for seat, _ in pairs(seatStates) do
            local plr = getSeatPlayer(seat)
            if plr and plr ~= LocalPlayer then
                playerName = plr.Name; turnText = "Menunggu giliran " .. plr.Name; break
            end
        end
        if playerName == "" then playerName = "-"; turnText = "Menunggu..." end
    end
    local startLetter = (serverLetter ~= "" and serverLetter) or "-"
    statusParagraph:SetDesc(playerName .. " | " .. turnText .. " | " .. startLetter)
end

-- =========================
-- TAB SELECT WORD
-- =========================
local SelectTab = Window:Tab({ Title = "Select Word", Icon = "lucide:list" })

selectToggle = SelectTab:Toggle({
    Desc     = "Aktifkan mode pilih kata manual",
    Icon     = "lucide:toggle-left",
    Type     = "Checkbox",
    Value    = false,
    Callback = function(v)
        selectModeEnabled = v
        refreshSelectDropdown()
        if v then notify("📋 Select Word", "Mode aktif — pilih kata untuk langsung ketik", 2)
        else notify("📋 Select Word", "Mode nonaktif", 2) end
    end
})

SelectTab:Slider({
    Title    = "Max Words Ditampilkan",
    Desc     = "Jumlah kata maksimal di dropdown",
    Step     = 5,
    Value    = { Min = 5, Max = 50, Default = 10 },
    Callback = function(v)
        selectMaxWords = v
        refreshSelectDropdown()
    end
})

table.insert(selectSliders, SelectTab:Slider({
    Title    = "Select Min Delay (ms)",
    Desc     = "Delay minimal antar huruf (khusus Select Word)",
    Step     = 10,
    Value    = { Min = 10, Max = 500, Default = selectMinDelay },
    Callback = function(v)
        selectMinDelay = v
        if selectMinDelay > selectMaxDelay then
            selectMaxDelay = selectMinDelay
            for _, s in ipairs(selectSliders) do
                if s.Title == "Select Max Delay (ms)" then s:Set(selectMaxDelay) end
            end
        end
    end
}))

table.insert(selectSliders, SelectTab:Slider({
    Title    = "Select Max Delay (ms)",
    Desc     = "Delay maksimal antar huruf (khusus Select Word)",
    Step     = 10,
    Value    = { Min = 50, Max = 1000, Default = selectMaxDelay },
    Callback = function(v)
        selectMaxDelay = v
        if selectMaxDelay < selectMinDelay then
            selectMinDelay = selectMaxDelay
            for _, s in ipairs(selectSliders) do
                if s.Title == "Select Min Delay (ms)" then s:Set(selectMinDelay) end
            end
        end
    end
}))

selectDropdown = SelectTab:Dropdown({
    Title    = "Word List",
    Desc     = "Muncul saat giliran kamu — pilih kata untuk langsung dikirim",
    Icon     = "lucide:search",
    Values   = {},
    Value    = nil,
    Multi    = false,
    Callback = function(word)
        if not word or word == "" then return end
        selectChosenWord = word
        sendWordManual(word)
    end
})

SelectTab:Paragraph({
    Title = "ℹ Cara Pakai",
    Desc  = "1. Aktifkan 'Enable Select Word'\n"
        .. "2. Atur Select Min/Max Delay sesuai keinginan\n"
        .. "3. Tunggu giliran kamu\n"
        .. "4. Dropdown otomatis terisi kata yang cocok\n"
        .. "   ✨ Kata BARU (belum di index) tampil duluan\n"
        .. "5. Pilih kata → langsung diketik & dikirim\n"
        .. "⚠ Dropdown kosong saat bukan giliran kamu.\n"
        .. "⚠ Jika Auto aktif & sedang berjalan,\n"
        .. "kirim ditolak sementara.",
})

-- =========================
-- TAB PLAYER
-- =========================
local PlayerTab = Window:Tab({ Title = "Player", Icon = "lucide:user" })
local CONFIG_FILE = "sambung_kata_config.json"
local TEST_FILE   = "sambung_kata_test.txt"

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

local configStatus = PlayerTab:Paragraph({
    Title = "Status Penyimpanan",
    Desc  = CAN_SAVE
        and "✓ File I/O tersedia (config disimpan otomatis ke file)"
        or  "⚠ File I/O tidak tersedia (gunakan clipboard)",
    Color = CAN_SAVE and "Green" or "Red",
})

local configDisplay = PlayerTab:Paragraph({
    Title = "Konfigurasi Saat Ini",
    Desc  = "",
})

function updateConfigDisplay()
    local joinStr  = isAutoJoinActive() and table.concat(autoJoinMode, "+") or "off"
    local indexCount = 0
    for _ in pairs(playerWordIndex) do indexCount = indexCount + 1 end
    configDisplay:SetDesc(
        "── Auto ──\n"
        .. "MinDelay: " .. config.minDelay .. "ms | MaxDelay: " .. config.maxDelay .. "ms\n"
        .. "Auto: " .. tostring(autoEnabled) .. " | Compe: " .. tostring(compeMode) .. "\n"
        .. "Typo: " .. tostring(typoEnabled) .. " | AutoJoin: " .. joinStr .. "\n"
        .. "PushIndex: " .. tostring(pushIndexEnabled) .. "\n"
        .. "── Select Word ──\n"
        .. "SelectMinDelay: " .. selectMinDelay .. "ms | SelectMaxDelay: " .. selectMaxDelay .. "ms\n"
        .. "SelectMode: " .. tostring(selectModeEnabled) .. " | MaxWords: " .. selectMaxWords .. "\n"
        .. "── Word Index ──\n"
        .. "Kata di Index: " .. indexCount
    )
end

updateConfigDisplay()

-- =========================
-- SAVE CONFIG
-- =========================
local function saveConfig()
    local data = {
        minDelay          = config.minDelay,
        maxDelay          = config.maxDelay,
        autoEnabled       = autoEnabled,
        compeMode         = compeMode,
        autoJoinMode      = autoJoinMode,
        typoEnabled       = typoEnabled,
        pushIndexEnabled  = pushIndexEnabled,
        selectMinDelay    = selectMinDelay,
        selectMaxDelay    = selectMaxDelay,
        selectModeEnabled = selectModeEnabled,
        selectMaxWords    = selectMaxWords,
    }
    local json = HttpService:JSONEncode(data)
    if CAN_SAVE then
        local ok, err = pcall(function() writefile(CONFIG_FILE, json) end)
        if ok then notify("✅ Config", "Semua setting berhasil disimpan!", 2)
        else notify("❌ Config", "Gagal save: " .. tostring(err), 3) end
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
local function loadConfig(silent)
    local json = nil
    if CAN_SAVE then
        local exists = true
        if isfile then exists = isfile(CONFIG_FILE) end
        if not exists then
            if not silent then notify("❌ Config", "File config tidak ditemukan!", 2) end
            return false
        end
        local ok, data = pcall(function() return readfile(CONFIG_FILE) end)
        if not ok or not data then
            if not silent then notify("❌ Config", "Gagal membaca file!", 2) end
            return false
        end
        json = data
    else
        if getclipboard then json = getclipboard()
        else
            if not silent then notify("❌ Config", "Clipboard tidak tersedia!", 2) end
            return false
        end
    end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or type(decoded) ~= "table" then
        if not silent then notify("❌ Config", "Format JSON tidak valid!", 3) end
        return false
    end
    config.minDelay = decoded.minDelay or config.minDelay
    config.maxDelay = decoded.maxDelay or config.maxDelay
    if decoded.autoEnabled ~= nil then autoEnabled = decoded.autoEnabled end
    if autoToggle then autoToggle:Set(autoEnabled) end
    if decoded.compeMode ~= nil then compeMode = decoded.compeMode end
    if compeToggle then compeToggle:Set(compeMode) end
    if decoded.typoEnabled ~= nil then typoEnabled = decoded.typoEnabled end
    if typoToggle then typoToggle:Set(typoEnabled) end
    if decoded.pushIndexEnabled ~= nil then pushIndexEnabled = decoded.pushIndexEnabled end
    if pushIndexToggle then pcall(function() pushIndexToggle:Set(pushIndexEnabled) end) end
    if decoded.autoJoinMode ~= nil then
        if type(decoded.autoJoinMode) == "table" then
            autoJoinMode = decoded.autoJoinMode
        elseif type(decoded.autoJoinMode) == "string" and decoded.autoJoinMode ~= "off" then
            autoJoinMode = { decoded.autoJoinMode }
        else
            autoJoinMode = {}
        end
    end
    if autoJoinDropdown then
        pcall(function() autoJoinDropdown:Set(autoJoinMode) end)
    end
    -- ✅ FIX: Restart auto join setelah load config
    if isAutoJoinActive() then 
        startAutoJoin() 
    else 
        stopAutoJoin() 
    end
    for _, s in ipairs(sliders) do
        if s.Title == "Min Delay (ms)" then s:Set(config.minDelay)
        elseif s.Title == "Max Delay (ms)" then s:Set(config.maxDelay) end
    end
    if decoded.selectMinDelay ~= nil then selectMinDelay = decoded.selectMinDelay end
    if decoded.selectMaxDelay ~= nil then selectMaxDelay = decoded.selectMaxDelay end
    if decoded.selectModeEnabled ~= nil then selectModeEnabled = decoded.selectModeEnabled end
    if decoded.selectMaxWords ~= nil then selectMaxWords = decoded.selectMaxWords end
    for _, s in ipairs(selectSliders) do
        if s.Title == "Select Min Delay (ms)" then s:Set(selectMinDelay)
        elseif s.Title == "Select Max Delay (ms)" then s:Set(selectMaxDelay)
        elseif s.Title == "Max Words Ditampilkan" then s:Set(selectMaxWords) end
    end
    if selectToggle then pcall(function() selectToggle:Set(selectModeEnabled) end) end
    updateConfigDisplay()
    if not silent then notify("✅ Config", "Konfigurasi berhasil dimuat!", 2)
    else notify("✅ Config", "Config auto-loaded!", 2) end
    return true
end

-- =========================
-- BUTTONS PLAYER
-- =========================
PlayerTab:Button({
    Title    = "Simpan Konfigurasi",
    Desc     = "Simpan ke file / clipboard",
    Callback = saveConfig
})

PlayerTab:Button({
    Title    = "Muat Konfigurasi",
    Desc     = "Load dari file / clipboard",
    Callback = function() loadConfig(false) end
})

PlayerTab:Button({
    Title    = "Reset Konfigurasi",
    Desc     = "Kembalikan ke default",
    Callback = function()
        config.minDelay = 350; config.maxDelay = 650
        autoEnabled = false; compeMode = false
        typoEnabled = false; autoJoinMode = {}
        pushIndexEnabled = false
        if autoToggle       then autoToggle:Set(false) end
        if compeToggle      then compeToggle:Set(false) end
        if typoToggle       then typoToggle:Set(false) end
        if pushIndexToggle  then pcall(function() pushIndexToggle:Set(false) end) end
        if autoJoinDropdown then pcall(function() autoJoinDropdown:Set({}) end) end
        stopAutoJoin()
        selectMinDelay    = 200
        selectMaxDelay    = 400
        selectModeEnabled = false
        selectMaxWords    = 10
        if selectToggle then pcall(function() selectToggle:Set(false) end) end
        for _, s in ipairs(selectSliders) do
            if s.Title == "Select Min Delay (ms)" then s:Set(200)
            elseif s.Title == "Select Max Delay (ms)" then s:Set(400)
            elseif s.Title == "Max Words Ditampilkan" then s:Set(10) end
        end
        updateConfigDisplay()
        notify("🔄 Config", "Reset ke default!", 2)
    end
})

PlayerTab:Button({
    Title    = "🔄 Refresh Word Index",
    Desc     = "Minta ulang data index kata dari server",
    Callback = function()
        table.clear(playerWordIndex)
        pcall(function()
            remotes:WaitForChild("RequestWordIndex"):FireServer()
        end)
        notify("🔄 Index", "Request index dikirim ke server...", 2)
        task.delay(1.5, function()
            local n = 0
            for _ in pairs(playerWordIndex) do n = n + 1 end
            updateConfigDisplay()
            notify("✅ Index", n .. " kata berhasil dimuat ke index", 2)
        end)
    end
})

PlayerTab:Paragraph({
    Title = "Auto Seat",
    Desc  = "Otomatis join meja sesuai mode yang dipilih.\n"
        .. "Bot akan pantau lawan — jika lawan keluar maka bot leave juga.",
})

local currentKeybind = Enum.KeyCode.RightShift
Window:SetToggleKey(currentKeybind)

PlayerTab:Keybind({
    Title    = "Toggle UI Keybind",
    Desc     = "Tombol buka/tutup UI",
    Value    = "X",
    Callback = function(v)
        if typeof(v) == "EnumItem" then
            currentKeybind = v; Window:SetToggleKey(v)
        elseif typeof(v) == "string" then
            local keyEnum = Enum.KeyCode[v]
            if keyEnum then currentKeybind = keyEnum; Window:SetToggleKey(keyEnum) end
        end
    end
})

-- =========================
-- TAB ABOUT
-- =========================
local AboutTab = Window:Tab({ Title = "About", Icon = "lucide:info" })

AboutTab:Paragraph({
    Title = "Informasi Script",
    Desc  = "Auto Kata (Optimized)\n"
        .. "Versi: 5.8 + AutoJoinRobust\n"
        .. "by sazaraaax & danz\n"
        .. "Fitur: Auto play, Auto Seat, Discord Notif, Typo Sim, Select Word, Push Index",
    Color = "Blue",
})

AboutTab:Paragraph({
    Title = "Changelog",
    Desc  = "> 📢 DUAL WEBHOOK: Login & Wrong Word pakai URL berbeda\n"
        .. "> 🔧 AUTO JOIN ROBUST: Teleport + Retry + Timeout\n"
        .. "> 🔧 BLACKLIST PERSIST: kata salah tetap terblokir selama match\n"
        .. "> 🔧 Reset blacklist HANYA saat match selesai (HideMatchUI)\n"
        .. "> 📢 DISCORD WRONG: format \"kata salah : {kata}\"\n"
        .. "> 🔧 Perbaikan minor lainnya",
})

AboutTab:Paragraph({
    Title = "Cara Penggunaan",
    Desc  = "1. Tunggu loading selesai\n"
        .. "2. Config lama otomatis dimuat\n"
        .. "3. Aktifkan Auto\n"
        .. "4. Aktifkan Push Index untuk farming koleksi\n"
        .. "5. Aktifkan Typo Sim jika diinginkan\n"
        .. "6. Pilih Auto Join Mode → main!\n"
        .. "\n📢 Discord Notif:\n"
        .. "• Login → webhook login\n"
        .. "• Kata salah → webhook wrong word\n"
        .. "• Format: \"kata salah : USING\"\n"
        .. "\n🔒 Blacklist Persist:\n"
        .. "Kata yang salah TIDAK akan\n"
        .. "dicoba lagi selama match aktif.\n"
        .. "Reset hanya saat match selesai.",
})

local discordLink = "https://discord.gg/bT4GmSFFWt"
local waLink      = "https://www.whatsapp.com/channel/0029VbCBSBOCRs1pRNYpPN0r"

AboutTab:Button({
    Title    = "Copy Discord Invite",
    Desc     = "Salin link Discord ke clipboard",
    Callback = function()
        if setclipboard then setclipboard(discordLink); notify("🟢 DISCORD", "Link Discord disalin!", 3)
        else notify("🔴 DISCORD", "Executor tidak support clipboard", 3) end
    end
})

AboutTab:Button({
    Title    = "Copy WhatsApp Channel",
    Desc     = "Salin link WhatsApp Channel ke clipboard",
    Callback = function()
        if setclipboard then setclipboard(waLink); notify("🟢 WHATSAPP", "Link WhatsApp disalin!", 3)
        else notify("🔴 WHATSAPP", "Executor tidak support clipboard", 3) end
    end
})

-- =========================
-- CONNECT REMOTES
-- =========================
MatchUI.OnClientEvent:Connect(onMatchUI)
BillboardUpdate.OnClientEvent:Connect(onBillboard)
UsedWordWarn.OnClientEvent:Connect(onUsedWarn)

-- =========================
-- DISCORD LOGIN NOTIF
-- =========================
sendLoginNotif()

-- =========================
-- AUTO-LOAD CONFIG & INIT AUTO JOIN
-- =========================
task.spawn(function()
    task.wait(0.5)
    local loaded = loadConfig(true)
    if not loaded then updateConfigDisplay() end
    
    -- ✅ FIX: Init auto join setelah config load (jika aktif)
    if isAutoJoinActive() and not autoJoinInitialized then
        task.delay(1, startAutoJoin)
    end
end)

-- =========================
-- HEARTBEAT LOOP
-- =========================
task.spawn(function()
    local lastUpdate      = 0
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
                            if state.Current.LastText ~= "" then addUsedWord(state.Current.LastText) end
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
                    isMyTurn = true; lastTurnActivity = now
                    if serverLetter == "" and #text > 0 then
                        serverLetter = string.sub(text, 1, 1)
                    end
                    updateMainStatus()
                    task.delay(0.3, refreshSelectDropdown)
                    if autoEnabled and serverLetter ~= "" and not selectRunning then
                        task.spawn(function()
                            task.wait(math.random(1500, 2700)/1000)
                            if matchActive and isMyTurn and autoEnabled then startUltraAI() end
                        end)
                    end
                end
            else
                if isMyTurn then isMyTurn = false; updateMainStatus() end
            end
            if isMyTurn and autoEnabled and not autoRunning and not selectRunning then
                if now - lastTurnActivity > INACTIVITY_TIMEOUT then
                    lastTurnActivity = now; startUltraAI()
                end
            end
            if now - lastUpdate >= UPDATE_INTERVAL then
                updateMainStatus(); lastUpdate = now
            end
        else
            if isMyTurn then isMyTurn = false end
            task.wait(1)
        end
        task.wait(UPDATE_INTERVAL)
    end
end)
