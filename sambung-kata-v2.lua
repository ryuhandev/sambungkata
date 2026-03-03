-- =========================================================
-- ULTRA SMART AUTO KATA - WindUI Build v5.5
-- by dhann x sazaraaax
-- =========================================================

-- ══════════════════════════════════════════════════════════
-- S1 : LOGGER
-- ══════════════════════════════════════════════════════════
local logBuffer    = {}
local MAX_LOGS     = 80
local logParagraph = nil
local logDirty     = false

local function pushLog(line)
    logBuffer[#logBuffer+1] = line
    if #logBuffer > MAX_LOGS then table.remove(logBuffer,1) end
    logDirty = true
end
local function flushLogUI()
    if not logDirty or not logParagraph then return end
    logDirty = false
    local s, out = math.max(1,#logBuffer-19), {}
    for i=s,#logBuffer do out[#out+1]=logBuffer[i] end
    pcall(function() logParagraph:SetDesc(table.concat(out,"\n")) end)
end
local function log(tag,...)
    local p={"["..tag.."]"}
    for _,v in ipairs({...}) do p[#p+1]=tostring(v) end
    pushLog(table.concat(p," "))
end
local function logerr(tag,...)
    local p={"[ERR]["..tag.."]"}
    for _,v in ipairs({...}) do p[#p+1]=tostring(v) end
    pushLog("[!] "..table.concat(p," "))
end
log("BOOT","Start loaded="..tostring(game:IsLoaded()))

-- ══════════════════════════════════════════════════════════
-- S2 : ANTI DOUBLE EXECUTE
-- ══════════════════════════════════════════════════════════
if _G.AutoKataActive then
    if type(_G.AutoKataDestroy)=="function" then pcall(_G.AutoKataDestroy) end
    task.wait(0.3)
end
_G.AutoKataActive  = true
_G.AutoKataDestroy = nil

-- ══════════════════════════════════════════════════════════
-- S3 : SAFE SPAWN
-- ══════════════════════════════════════════════════════════
local function safeSpawn(fn,...)
    local args={...}
    task.spawn(function()
        local ok,err=xpcall(
            function() fn(table.unpack(args)) end,
            function(e) return tostring(e).."\n"..debug.traceback() end
        )
        if not ok then pushLog("[!][CRASH] "..tostring(err):sub(1,200)) end
    end)
end

-- ══════════════════════════════════════════════════════════
-- S4 : SERVICES
-- ══════════════════════════════════════════════════════════
if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local Workspace         = game:GetService("Workspace")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")
local LocalPlayer       = Players.LocalPlayer

local CAN_SAVE = false
pcall(function()
    writefile("_ak_.tmp","1"); readfile("_ak_.tmp"); delfile("_ak_.tmp")
    CAN_SAVE = true
end)
log("BOOT","CAN_SAVE="..tostring(CAN_SAVE).." Player="..LocalPlayer.Name)

pcall(function() if _G.DestroyDhannRunner then _G.DestroyDhannRunner() end end)
task.delay(0.5,function()
    local g=LocalPlayer:FindFirstChild("PlayerGui"); if not g then return end
    for _,n in ipairs({"DhannUltra","DhannClean"}) do
        local o=g:FindFirstChild(n); if o then o:Destroy() end
    end
end)

-- ══════════════════════════════════════════════════════════
-- S5 : CONSTANTS
-- ══════════════════════════════════════════════════════════
local CONFIG_FILE     = "autokata_config.json"
local ADMIN_FILE      = "autokata_admin.json"
local RANKING_CACHE   = "autokata_ranking_cache.json"
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1478097119079563396/gIxWk9eU5r5erugPGrMR1Y8ad039nSlDl8GP9pFKfZ41asWNjZvejtm1qpJHuESM2Z8j"
local WRONG_WORDS_URL = "https://raw.githubusercontent.com/fay23-dam/sazaraaax-script/refs/heads/main/wordworng/a3x.lua"
local RANKING_URL     = "https://raw.githubusercontent.com/fay23-dam/sazaraaax-script/refs/heads/main/wordworng/ranking_kata%20(1).json"
local INACTIVITY_TIMEOUT = 6
local MAX_RETRY_SUBMIT   = 6

local WORDLIST_LIST = {"Safety Anti Detek (KBBI)","Ranking Kata (Kompetitif)"}
local WORDLIST_URLS = {
    ["Safety Anti Detek (KBBI)"]  = "https://raw.githubusercontent.com/danzzy1we/roblox-script-dump/refs/heads/main/WordListDump/KBBI_Final_Working.lua",
    ["Ranking Kata (Kompetitif)"] = "__RANKING__",
}
local SPEED_PRESETS = {
    Slow={min=1500,max=3000}, Fast={min=500,max=1000}, Superfast={min=100,max=300},
}
local ADMIN_IDS = {}

-- Huruf jebakan untuk compe mode
local TRAP_ENDINGS = {"i","f","x","v","y","w","q","z"}

-- ══════════════════════════════════════════════════════════
-- S6 : CONFIG STATE
-- ══════════════════════════════════════════════════════════
local cfg = {
    minDelay       = 500,
    maxDelay       = 1000,
    aggression     = 20,
    minLength      = 2,
    maxLength      = 12,
    initialDelay   = 0.0,
    submitDelay    = 1.0,
    activeWordlist = "Safety Anti Detek (KBBI)",
    autoEnabled    = false,
    autoClick      = false,
    autoClickDelay = 1.5,
    compeMode      = false,   -- NEW: compe mode (ranking only)
    autoJoinMode   = "off",   -- NEW: "off"|"2P"|"4P"|"8P"
}

-- ══════════════════════════════════════════════════════════
-- S7 : SAVE / LOAD CONFIG
-- ══════════════════════════════════════════════════════════
local function saveConfig()
    if not CAN_SAVE then return end
    local ok,enc = pcall(function() return HttpService:JSONEncode(cfg) end)
    if ok then pcall(writefile,CONFIG_FILE,enc); log("CFG","Saved") end
end

local function loadConfig()
    if not CAN_SAVE then return false end
    local ok,raw = pcall(readfile,CONFIG_FILE)
    if not ok or not raw or raw=="" then return false end
    local ok2,data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data)~="table" then return false end
    for k,v in pairs(data) do
        if cfg[k]~=nil and type(v)==type(cfg[k]) then cfg[k]=v end
    end
    log("CFG","Loaded | autoClick="..tostring(cfg.autoClick)
        .." autoEnabled="..tostring(cfg.autoEnabled)
        .." compeMode="..tostring(cfg.compeMode))
    return true
end

loadConfig()   -- auto-load boot

local uiRef = {
    autoToggle      = nil,
    autoClickToggle = nil,
    compeModeToggle = nil,
    cfgSummaryPara  = nil,
}

local function applyConfigToUI()
    pcall(function() if uiRef.autoToggle      then uiRef.autoToggle:Set(cfg.autoEnabled)   end end)
    pcall(function() if uiRef.autoClickToggle then uiRef.autoClickToggle:Set(cfg.autoClick) end end)
    pcall(function() if uiRef.compeModeToggle then uiRef.compeModeToggle:Set(cfg.compeMode) end end)
    pcall(function()
        if uiRef.cfgSummaryPara then
            uiRef.cfgSummaryPara:SetDesc(table.concat({
                "Wordlist    : "..cfg.activeWordlist,
                "Delay       : "..(cfg.minDelay/1000).."s – "..(cfg.maxDelay/1000).."s",
                "Aggression  : "..cfg.aggression.."%",
                "Jeda Awal   : "..cfg.initialDelay.."s",
                "Jeda Submit : "..cfg.submitDelay.."s",
                "Auto        : "..(cfg.autoEnabled  and "ON" or "OFF"),
                "AutoClick   : "..(cfg.autoClick    and "ON" or "OFF"),
                "CompeMode   : "..(cfg.compeMode    and "ON" or "OFF"),
                "AutoJoin    : "..cfg.autoJoinMode,
            },"\n"))
        end
    end)
    log("CFG","UI synced")
end

-- ══════════════════════════════════════════════════════════
-- S8 : ADMIN SYSTEM
-- ══════════════════════════════════════════════════════════
local MAINTENANCE = false
local BLACKLIST   = {}

local function adminSave()
    local bl={}
    for uid in pairs(BLACKLIST) do bl[#bl+1]=uid end
    local ok,enc=pcall(function()
        return HttpService:JSONEncode({maintenance=MAINTENANCE,blacklist=bl})
    end)
    if ok then pcall(writefile,ADMIN_FILE,enc) end
end

local function adminLoad()
    local ok,raw=pcall(readfile,ADMIN_FILE)
    if not ok or not raw or raw=="" then return end
    local ok2,data=pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or not data then return end
    if type(data.maintenance)=="boolean" then MAINTENANCE=data.maintenance end
    if type(data.blacklist)=="table" then
        for _,uid in ipairs(data.blacklist) do BLACKLIST[tonumber(uid)]=true end
    end
end
adminLoad()

local function isAdmin(player)
    if not player then return false end
    for _,id in ipairs(ADMIN_IDS) do if id==player.UserId then return true end end
    return false
end
local function checkAccess()
    adminLoad()
    if MAINTENANCE and not isAdmin(LocalPlayer) then
        task.wait(0.1); pcall(function() LocalPlayer:Kick("[AutoKata] Maintenance Mode.") end)
        return false
    end
    if BLACKLIST[LocalPlayer.UserId] then
        task.wait(0.1); pcall(function() LocalPlayer:Kick("[AutoKata] Kamu di-blacklist.") end)
        return false
    end
    return true
end

-- ══════════════════════════════════════════════════════════
-- S9 : DISCORD WEBHOOK  (multi-method fallback)
-- ══════════════════════════════════════════════════════════
local function maskStr(s,keep)
    s=tostring(s); keep=keep or 4
    if #s<=keep then return s end
    return s:sub(1,keep)..string.rep("*",#s-keep)
end

local function sendDiscordMsg(contentStr)
    task.spawn(function()
        local ok,payload=pcall(function()
            return HttpService:JSONEncode({content=contentStr,username="DhanxSaza Hub"})
        end)
        if not ok then log("WEBHOOK","JSONEncode gagal"); return end

        -- Method 1: syn.request (Synapse X)
        local sent = false
        if not sent and syn and syn.request then
            local ok2,res=pcall(function()
                return syn.request({
                    Url     = DISCORD_WEBHOOK,
                    Method  = "POST",
                    Headers = {["Content-Type"]="application/json"},
                    Body    = payload,
                })
            end)
            if ok2 and res and (res.StatusCode==200 or res.StatusCode==204) then
                log("WEBHOOK","OK via syn.request"); sent=true
            else log("WEBHOOK","syn.request gagal:",tostring(ok2),tostring(res and res.StatusCode)) end
        end

        -- Method 2: request (global executor function)
        if not sent and request then
            local ok3,res=pcall(function()
                return request({
                    Url     = DISCORD_WEBHOOK,
                    Method  = "POST",
                    Headers = {["Content-Type"]="application/json"},
                    Body    = payload,
                })
            end)
            if ok3 and res and (res.StatusCode==200 or res.StatusCode==204) then
                log("WEBHOOK","OK via request"); sent=true
            else log("WEBHOOK","request gagal:",tostring(ok3),tostring(res and res.StatusCode)) end
        end

        -- Method 3: http.request (Krnl, etc)
        if not sent and http and http.request then
            local ok4,res=pcall(function()
                return http.request({
                    Url     = DISCORD_WEBHOOK,
                    Method  = "POST",
                    Headers = {["Content-Type"]="application/json"},
                    Body    = payload,
                })
            end)
            if ok4 and res and (res.StatusCode==200 or res.StatusCode==204) then
                log("WEBHOOK","OK via http.request"); sent=true
            else log("WEBHOOK","http.request gagal:",tostring(ok4)) end
        end

        -- Method 4: HttpService:PostAsync fallback
        if not sent then
            local ok5,err=pcall(function()
                HttpService:PostAsync(
                    DISCORD_WEBHOOK, payload,
                    Enum.HttpContentType.ApplicationJson, false
                )
            end)
            if ok5 then log("WEBHOOK","OK via PostAsync")
            else log("WEBHOOK","PostAsync gagal:",tostring(err)) end
        end
    end)
end

local function sendLoginNotif()
    local lp=LocalPlayer
    local ok,gn=pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    local gameName=(ok and type(gn)=="string" and gn~="") and gn or tostring(game.PlaceId)
    local timeStr=tostring(os.time())
    pcall(function() timeStr=os.date("!%Y-%m-%d %H:%M:%S") end)
    sendDiscordMsg(
        "✅ **DhanxSaza Hub**  - LOGIN"
        .."\nUser: `"..maskStr(lp.Name,4).."`"
        .."\nUser ID: `"..maskStr(tostring(lp.UserId),3).."`"
        .."\nGame: `"..gameName.."`"
        .."\nTime: `"..timeStr.."`"
        .."\nDhanxSaza Hub"
    )
end

-- ══════════════════════════════════════════════════════════
-- S10 : WORDLIST SYSTEM
-- ══════════════════════════════════════════════════════════
local kataModule    = {}
local wordsByLetter = {}
local wrongWordsSet = {}
local rankingMap    = {}

local function flattenWordlist(result)
    if type(result.words)=="table" then
        local f={} for w in pairs(result.words) do f[#f+1]=tostring(w) end; return f
    end
    if type(result[1])=="string" then return result end
    local f={}
    for _,val in pairs(result) do
        if type(val)=="table" then for _,w in ipairs(val) do f[#f+1]=w end end
    end
    return f
end

local function applyWordlist(flat)
    local seen,unique={},{}
    for _,w in ipairs(flat) do
        local lw=string.lower(tostring(w))
        if not seen[lw] and #lw>1 then seen[lw]=true; unique[#unique+1]=lw end
    end
    if #unique>0 then kataModule=unique; wordsByLetter={}; return true end
    return false
end

local function loadWordlistFromURL(url)
    local ok,resp=pcall(function() return game:HttpGet(url) end)
    if not ok or not resp or resp=="" then logerr("WORDLIST","HttpGet gagal:",url); return false end
    local fn=loadstring(resp)
    if fn then
        local ok2,res=pcall(fn)
        if ok2 and type(res)=="table" and applyWordlist(flattenWordlist(res)) then
            log("WORDLIST","Direct:",#kataModule); return true
        end
    end
    local fixed=resp:gsub("%[\"","{\""):gsub("\"%]","\"}")
                    :gsub("%[","{"):gsub("%]","}")
    local fn2=loadstring(fixed)
    if fn2 then
        local ok3,res2=pcall(fn2)
        if ok3 and type(res2)=="table" and applyWordlist(flattenWordlist(res2)) then
            log("WORDLIST","Fallback:",#kataModule); return true
        end
    end
    logerr("WORDLIST","Gagal:",url); return false
end

local function buildIndex()
    wordsByLetter={}
    for _,w in ipairs(kataModule) do
        local c=w:sub(1,1)
        if wordsByLetter[c] then wordsByLetter[c][#wordsByLetter[c]+1]=w
        else wordsByLetter[c]={w} end
    end
    log("INDEX",#kataModule,"kata")
end

local function downloadWrongWords()
    local ok,raw=pcall(function() return game:HttpGet(WRONG_WORDS_URL) end)
    if not ok or not raw then return end
    local fn=loadstring(raw); if not fn then return end
    local ok2,words=pcall(fn)
    if ok2 and type(words)=="table" then
        for _,w in ipairs(words) do
            if type(w)=="string" then wrongWordsSet[w:lower()]=true end
        end
        log("WRONGWORD",#words)
    end
end

local function loadRanking()
    table.clear(rankingMap)
    if CAN_SAVE then
        local ok,raw=pcall(readfile,RANKING_CACHE)
        if ok and raw and #raw>100 then
            local ok2,data=pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and type(data)=="table" then
                for _,v in ipairs(data) do
                    if type(v)=="table" and type(v.word)=="string" then
                        rankingMap[v.word:lower()]=tonumber(v.score) or 0
                    end
                end
                if next(rankingMap) then log("RANKING","Cache"); return end
            end
        end
    end
    local ok,raw=pcall(function() return game:HttpGet(RANKING_URL) end)
    if not ok or not raw or raw=="" then log("RANKING","Gagal download"); return end
    local ok2,data=pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data)~="table" then return end
    local count=0
    for _,v in ipairs(data) do
        if type(v)=="table" and type(v.word)=="string" then
            local w=v.word:lower()
            if w:match("^[a-z]+$") then rankingMap[w]=tonumber(v.score) or 0; count=count+1 end
        end
    end
    log("RANKING","Loaded:",count)
    if CAN_SAVE and count>0 then
        local arr={}
        for w,s in pairs(rankingMap) do arr[#arr+1]={word=w,score=s} end
        local ok3,enc=pcall(function() return HttpService:JSONEncode(arr) end)
        if ok3 then pcall(writefile,RANKING_CACHE,enc) end
    end
end

do
    local url=WORDLIST_URLS[cfg.activeWordlist]
    if url=="__RANKING__" then url=WORDLIST_URLS["Safety Anti Detek (KBBI)"] end
    if not loadWordlistFromURL(url) or #kataModule==0 then
        logerr("BOOT","Wordlist gagal!"); return
    end
    log("WORDLIST","Boot:",cfg.activeWordlist,"|",#kataModule)
end

-- ══════════════════════════════════════════════════════════
-- S11 : BOOT SCRIPTS
-- ══════════════════════════════════════════════════════════
local function safeLoadstring(url)
    local ok,raw=pcall(function() return game:HttpGet(url) end)
    if not ok or not raw or raw=="" then return end
    local fn=loadstring(raw); if fn then pcall(fn) end
end
safeLoadstring("https://raw.githubusercontent.com/danzzy1we/gokil2/refs/heads/main/copylinkgithub.lua")
safeLoadstring("https://raw.githubusercontent.com/fay23-dam/sazaraaax-script/refs/heads/main/runner.lua")

-- ══════════════════════════════════════════════════════════
-- S12 : LOAD WINDUI
-- ══════════════════════════════════════════════════════════
log("WINDUI","Loading..."); task.wait(3)
local _raw=""
pcall(function() _raw=game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua") end)
if _raw=="" then logerr("WINDUI","Gagal"); return end
local _fn,_fe=loadstring(_raw)
if not _fn then logerr("WINDUI","loadstring gagal:",_fe); return end
local _ok2,WindUI=pcall(_fn)
if not _ok2 or not WindUI then logerr("WINDUI","Init gagal:",WindUI); return end
log("WINDUI","OK")

-- ══════════════════════════════════════════════════════════
-- S13 : REMOTES
-- ══════════════════════════════════════════════════════════
local remotes=ReplicatedStorage:WaitForChild("Remotes")
local function waitR(name,timeout)
    local r
    if timeout then pcall(function() r=remotes:WaitForChild(name,timeout) end)
    else r=remotes:WaitForChild(name) end
    if r then log("REMOTE","OK:",name) end
    return r
end

local MatchUI         = waitR("MatchUI")
local SubmitWord      = waitR("SubmitWord")
local BillboardUpdate = waitR("BillboardUpdate")
local BillboardEnd    = waitR("BillboardEnd",3)
local TypeSound       = waitR("TypeSound")
local UsedWordWarn    = waitR("UsedWordWarn")
local JoinTable       = waitR("JoinTable")
local LeaveTable      = waitR("LeaveTable")
local PlayerHit       = waitR("PlayerHit",3)
local PlayerCorrect   = waitR("PlayerCorrect",3)

local function fireBillboardEnd()
    if BillboardEnd then pcall(function() BillboardEnd:FireServer() end)
    else pcall(function() BillboardUpdate:FireServer("") end) end
end

-- ══════════════════════════════════════════════════════════
-- S14 : MATCH STATE
-- ══════════════════════════════════════════════════════════
local matchActive        = false
local isMyTurn           = false
local serverLetter       = ""
local usedWords          = {}
local opponentStreamWord = ""
local autoRunning        = false
local lastAttemptedWord  = ""
local lastRejectWord     = ""
local blacklistedWords   = {}
local lastTurnActivity   = 0

local function isUsed(w)    return usedWords[w:lower()]==true end
local function addUsed(w)   usedWords[w:lower()]=true end
local function resetUsed()  usedWords={} end
local function blacklist(w) blacklistedWords[w:lower()]=true end
local function isBL(w)      return blacklistedWords[w:lower()]==true end

-- ══════════════════════════════════════════════════════════
-- S15 : SMART WORD SELECTOR  +  COMPE MODE
-- ══════════════════════════════════════════════════════════
-- Compe mode: pilih kata ranking yang BERAKHIRAN huruf jebakan
-- Fallback ke ranking biasa jika tidak ada
local function getCompeWords(prefix)
    if not next(rankingMap) then return {} end
    local lp=prefix:lower()
    -- kumpulkan semua kandidat yang cocok prefix
    local cands={}
    local bucket=wordsByLetter[lp:sub(1,1)]
    local pool=bucket or kataModule
    for _,word in ipairs(pool) do
        if word:sub(1,#lp)==lp and #word>#lp
            and not isUsed(word) and not wrongWordsSet[word] and not blacklistedWords[word]
        then
            cands[#cands+1]=word
        end
    end
    -- Pisahkan: trap (berakhiran huruf jebakan) vs normal
    local trap,normal={},{}
    for _,word in ipairs(cands) do
        local last=word:sub(-1)
        local isTrap=false
        for _,te in ipairs(TRAP_ENDINGS) do
            if last==te then isTrap=true; break end
        end
        local sc=rankingMap[word] or -1
        if isTrap then
            trap[#trap+1]={word=word,score=sc}
        else
            normal[#normal+1]={word=word,score=sc}
        end
    end
    -- Sort by score desc
    table.sort(trap,   function(a,b) return a.score>b.score end)
    table.sort(normal, function(a,b) return a.score>b.score end)
    -- Gabung: trap dulu, lalu normal
    local result={}
    for _,v in ipairs(trap)   do result[#result+1]=v.word end
    for _,v in ipairs(normal) do result[#result+1]=v.word end
    return result
end

local function getSmartWords(prefix)
    if #kataModule==0 or prefix=="" then return {} end
    local lp=prefix:lower()

    -- Compe mode hanya jika ranking kata aktif
    if cfg.compeMode and cfg.activeWordlist=="Ranking Kata (Kompetitif)" then
        local r=getCompeWords(prefix)
        if #r>0 then return r end
    end

    local bucket=(next(wordsByLetter)~=nil) and wordsByLetter[lp:sub(1,1)] or kataModule
    if not bucket then return {} end
    local bestWord,bestScore=nil,-math.huge
    local results,fallback={},{}
    for _,word in ipairs(bucket) do
        if word:sub(1,#lp)==lp and #word>#lp
            and not isUsed(word) and not wrongWordsSet[word] and not blacklistedWords[word]
        then
            local sc=rankingMap[word]
            if sc and sc>bestScore then bestScore=sc; bestWord=word end
            fallback[#fallback+1]=word
            local len=#word
            if len>=cfg.minLength and len<=cfg.maxLength then results[#results+1]=word end
        end
    end
    if bestWord then return {bestWord} end
    if #results==0 then results=fallback end
    table.sort(results,function(a,b) return #a>#b end)
    return results
end

-- ══════════════════════════════════════════════════════════
-- S16 : VIRTUAL INPUT
-- FIX DOUBLE INPUT:
--   Gunakan HANYA BillboardUpdate untuk sinkronisasi kata di server.
--   TextBox diisi via direct property assignment (tb.Text), BUKAN sendKey.
--   sendKey hanya dipanggil untuk game yang benar-benar butuh keyboard event.
--   Sebelum mengetik, hapus dulu isi TextBox sampai bersih ke startLetter.
-- ══════════════════════════════════════════════════════════
local VIM=nil
pcall(function() VIM=game:GetService("VirtualInputManager") end)

local KC={a=Enum.KeyCode.A,b=Enum.KeyCode.B,c=Enum.KeyCode.C,d=Enum.KeyCode.D,
          e=Enum.KeyCode.E,f=Enum.KeyCode.F,g=Enum.KeyCode.G,h=Enum.KeyCode.H,
          i=Enum.KeyCode.I,j=Enum.KeyCode.J,k=Enum.KeyCode.K,l=Enum.KeyCode.L,
          m=Enum.KeyCode.M,n=Enum.KeyCode.N,o=Enum.KeyCode.O,p=Enum.KeyCode.P,
          q=Enum.KeyCode.Q,r=Enum.KeyCode.R,s=Enum.KeyCode.S,t=Enum.KeyCode.T,
          u=Enum.KeyCode.U,v=Enum.KeyCode.V,w=Enum.KeyCode.W,x=Enum.KeyCode.X,
          y=Enum.KeyCode.Y,z=Enum.KeyCode.Z}
local SC={a=65,b=66,c=67,d=68,e=69,f=70,g=71,h=72,i=73,j=74,
          k=75,l=76,m=77,n=78,o=79,p=80,q=81,r=82,s=83,t=84,
          u=85,v=86,w=87,x=88,y=89,z=90}

local function findTextBox()
    local g=LocalPlayer:FindFirstChild("PlayerGui"); if not g then return nil end
    local function find(p)
        for _,c in ipairs(p:GetChildren()) do
            if c:IsA("TextBox") then return c end
            local r=find(c); if r then return r end
        end
    end
    return find(g)
end

local function focusTB()
    local tb=findTextBox()
    if tb then pcall(function() tb:CaptureFocus() end) end
end

-- FIX: set teks TextBox secara langsung, bukan ketik satu-satu
-- Ini menghilangkan double input karena tidak ada keyboard event yang bisa doubly-fire
local function setTBText(text)
    local tb=findTextBox()
    if tb then
        pcall(function() tb:CaptureFocus() end)
        pcall(function() tb.Text=text end)
    end
end

local function getTBText()
    local tb=findTextBox(); return tb and (tb.Text or "") or ""
end

-- Untuk game yang HANYA bisa menerima keyboard event (jarang), pakai ini
local function sendKey(char)
    local c=char:lower()
    if VIM then
        local kc=KC[c]
        if kc then pcall(function()
            VIM:SendKeyEvent(true,kc,false,game); task.wait(0.02)
            VIM:SendKeyEvent(false,kc,false,game)
        end) end
    elseif keypress and keyrelease then
        local sc=SC[c]; if sc then keypress(sc); task.wait(0.02); keyrelease(sc) end
    end
end

local function sendBackspace()
    if VIM then
        pcall(function()
            VIM:SendKeyEvent(true,Enum.KeyCode.Backspace,false,game); task.wait(0.025)
            VIM:SendKeyEvent(false,Enum.KeyCode.Backspace,false,game)
        end)
    elseif keypress and keyrelease then
        keypress(8); task.wait(0.02); keyrelease(8)
    else
        pcall(function()
            local tb=findTextBox()
            if tb and #tb.Text>0 then tb.Text=tb.Text:sub(1,-2) end
        end)
    end
end

-- FIX: hapus kata satu-satu via BillboardUpdate, lalu clear TextBox
-- Urutan hapus: apia → api → ap → a  (bukan langsung clear)
local function clearToLetter(targetLetter)
    -- Hapus lewat BillboardUpdate satu karakter per langkah
    local current=getTBText()
    if current=="" then current=lastAttemptedWord end
    if current=="" then current=targetLetter end

    -- Hapus dari akhir sampai tinggal targetLetter
    while #current>#targetLetter do
        current=current:sub(1,-2)
        pcall(function() BillboardUpdate:FireServer(current) end)
        pcall(function() TypeSound:FireServer() end)
        task.wait(0.06)
    end
    -- Bersihkan TextBox ke targetLetter
    setTBText(targetLetter)
    task.wait(0.05)
    fireBillboardEnd()
    lastAttemptedWord=""
    log("INPUT","clearToLetter selesai → '"..targetLetter.."'")
end

local function humanDelay()
    local mn=cfg.minDelay; local mx=cfg.maxDelay
    if mn>mx then mn=mx end
    task.wait(math.random(mn,mx)/1000)
end

-- ══════════════════════════════════════════════════════════
-- S17 : AUTO CLICK (pure backend)
-- ══════════════════════════════════════════════════════════
local function doAutoClick()
    if not cfg.autoClick then return end
    task.wait(cfg.autoClickDelay)
    log("AUTOCLICK","Backend...")
    local g=LocalPlayer:FindFirstChild("PlayerGui")
    if g then
        for _,obj in ipairs(g:GetDescendants()) do
            if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
                local name=obj.Name:lower()
                local text=(obj:IsA("TextButton") and obj.Text:lower()) or ""
                if name:find("play") or name:find("lagi") or name:find("again")
                   or name:find("continue") or name:find("close") or name:find("ok")
                   or text:find("main lagi") or text:find("play again") or text:find("lanjut")
                then
                    pcall(function()
                        if VIM then
                            local ap=obj.AbsolutePosition; local as=obj.AbsoluteSize
                            local cx=ap.X+as.X/2; local cy=ap.Y+as.Y/2
                            VIM:SendMouseMoveEvent(cx,cy,game);               task.wait(0.05)
                            VIM:SendMouseButtonEvent(cx,cy,0,true, game,1); task.wait(0.05)
                            VIM:SendMouseButtonEvent(cx,cy,0,false,game,1)
                        else obj.Activated:Fire() end
                    end)
                    log("AUTOCLICK","Klik:",obj.Name); return
                end
            end
        end
    end
    pcall(function()
        local vp=Workspace.CurrentCamera.ViewportSize
        if VIM then
            VIM:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,true, game,1); task.wait(0.08)
            VIM:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,false,game,1)
        end
    end)
    log("AUTOCLICK","Fallback tengah")
end

-- ══════════════════════════════════════════════════════════
-- S18 : SEAT MONITORING
-- ══════════════════════════════════════════════════════════
local currentTableName=nil
local tableTarget=nil
local seatStates={}

local function getSeatPlayer(seat)
    if seat and seat.Occupant then
        local char=seat.Occupant.Parent
        if char then return Players:GetPlayerFromCharacter(char) end
    end
end

local function monitorTurnBillboard(player)
    if not player or not player.Character then return nil end
    local head=player.Character:FindFirstChild("Head"); if not head then return nil end
    local bb=head:FindFirstChild("TurnBillboard");      if not bb   then return nil end
    local tl=bb:FindFirstChildOfClass("TextLabel");     if not tl   then return nil end
    return {Billboard=bb,TextLabel=tl,LastText="",Player=player}
end

local function setupSeatMonitoring()
    seatStates={}; tableTarget=nil
    if not currentTableName then return end
    local tf=Workspace:FindFirstChild("Tables"); if not tf then return end
    tableTarget=tf:FindFirstChild(currentTableName); if not tableTarget then return end
    local sc=tableTarget:FindFirstChild("Seats"); if not sc then return end
    for _,seat in ipairs(sc:GetChildren()) do
        if seat:IsA("Seat") then seatStates[seat]={Current=nil} end
    end
    log("SEAT","Setup:",currentTableName)
end

local _startUltraAI  -- forward decl

safeSpawn(function()
    while _G.AutoKataActive do
        task.wait(1/6)
        if matchActive and tableTarget then
            if isMyTurn and cfg.autoEnabled and tick()-lastTurnActivity>INACTIVITY_TIMEOUT then
                lastTurnActivity=tick(); autoRunning=false
                safeSpawn(function() _startUltraAI() end)
            end
            for seat,state in pairs(seatStates) do
                local plr=getSeatPlayer(seat)
                if plr and plr~=LocalPlayer then
                    if not state.Current or state.Current.Player~=plr then
                        state.Current=monitorTurnBillboard(plr)
                    end
                    if state.Current then
                        local tl=state.Current.TextLabel
                        if tl then state.Current.LastText=tl.Text end
                        if not state.Current.Billboard or not state.Current.Billboard.Parent then
                            if state.Current.LastText~="" then addUsed(state.Current.LastText) end
                            state.Current=nil
                        end
                    end
                else state.Current=nil end
            end
        end
    end
end)

LocalPlayer.AttributeChanged:Connect(function(attr)
    if attr~="CurrentTable" then return end
    currentTableName=LocalPlayer:GetAttribute("CurrentTable")
    if currentTableName then setupSeatMonitoring() else seatStates={}; tableTarget=nil end
end)
currentTableName=LocalPlayer:GetAttribute("CurrentTable")
if currentTableName then setupSeatMonitoring() end

-- ══════════════════════════════════════════════════════════
-- S19 : AUTO ENGINE
-- FIX DOUBLE INPUT:
--   1. Sebelum mengetik, pastikan TextBox KOSONG / hanya ada startLetter
--      dengan setTBText(startLetter) — tidak pakai keyboard event
--   2. Kemudian bangun kata dengan langsung set tb.Text=targetSoFar
--      setiap iterasi, PLUS fire BillboardUpdate
--   3. Saat kata di-reject, clearToLetter(startLetter) dulu, baru retry
-- ══════════════════════════════════════════════════════════
local function submitAndRetry(startLetter)
    for attempt=1,MAX_RETRY_SUBMIT do
        if not matchActive or not cfg.autoEnabled then return false end
        if attempt>1 then task.wait(0.25) end

        local words={}
        for _,w in ipairs(getSmartWords(startLetter)) do
            if not isBL(w) then words[#words+1]=w end
        end
        if #words==0 then return false end

        local sel=words[1]
        if #words>1 and cfg.aggression<100 then
            local topN=math.min(math.max(1,math.floor(#words*(1-cfg.aggression/100))),#words)
            sel=words[math.random(1,topN)]
        end

        log("INPUT","Attempt "..attempt.." kata='"..sel.."' start='"..startLetter.."'")

        -- FIX: Pastikan TextBox bersih dulu (hanya startLetter)
        -- Ini mencegah Imanmajinasi-bug
        setTBText(startLetter)
        task.wait(0.08)

        -- Ketik karakter satu per satu lewat direct property, bukan keyboard event
        -- Setiap langkah: set Text = kata terbentuk sejauh ini + fire Billboard
        local aborted=false
        local cur=startLetter
        for i=#startLetter+1, #sel do
            if not matchActive or not cfg.autoEnabled then aborted=true; break end
            cur=sel:sub(1,i)
            -- Direct text set (tidak ada keyboard event = tidak ada double)
            setTBText(cur)
            pcall(function() TypeSound:FireServer() end)
            pcall(function() BillboardUpdate:FireServer(cur) end)
            humanDelay()
        end

        if aborted or not matchActive or not cfg.autoEnabled then return false end
        if cfg.submitDelay>0 then task.wait(cfg.submitDelay) end
        if not matchActive or not cfg.autoEnabled then return false end

        lastRejectWord=""; lastAttemptedWord=sel
        pcall(function() SubmitWord:FireServer(sel) end)
        task.wait(0.4)

        if lastRejectWord==sel:lower() then
            log("INPUT","Reject '"..sel.."' → hapus & retry")
            -- FIX: hapus satu-satu via BillboardUpdate baru kembali ke startLetter
            clearToLetter(startLetter)
            blacklist(sel)
            task.wait(0.15)
        else
            addUsed(sel); lastAttemptedWord=""; fireBillboardEnd()
            log("INPUT","Submit OK '"..sel.."'")
            return true
        end
    end
    blacklistedWords={}; fireBillboardEnd(); return false
end

_startUltraAI=function()
    if autoRunning or not cfg.autoEnabled or not matchActive or not isMyTurn then return end
    if serverLetter=="" then
        local w=0
        while serverLetter=="" and w<5 do task.wait(0.1); w=w+0.1 end
        if serverLetter=="" then return end
    end
    if autoRunning then return end
    autoRunning=true; lastTurnActivity=tick()
    if cfg.initialDelay>0 then
        task.wait(cfg.initialDelay)
        if not matchActive or not isMyTurn then autoRunning=false; return end
    end
    humanDelay()
    pcall(function() submitAndRetry(serverLetter) end)
    autoRunning=false
end

-- ══════════════════════════════════════════════════════════
-- S20 : AUTO JOIN / TELEPORT TABLE
-- Redesign: pakai dropdown (2P / 4P / 8P / off)
-- Cara kerja:
--   1. Pilih mode → monitor HANYA meja sesuai mode
--   2. Scan loop: cari meja target yang butuh 1 seat lagi → teleport/prompt
--   3. Setelah duduk, pantau lawan. Jika lawan keluar → kita leave juga
--   4. Saat matchActive → hentikan scan sementara
--   5. Saat match selesai → resume scan segera
-- ══════════════════════════════════════════════════════════
local autoJoinLoop    = nil
local joinedTableName = nil   -- nama meja yang kita duduki sekarang
local SCAN_INTERVAL   = 1.2

local function getHumanoid()
    local char=LocalPlayer.Character; if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function isSeated()
    local h=getHumanoid(); return h~=nil and h.SeatPart~=nil
end

-- Paksa berdiri: hapus SeatWeld dan set Sit=false
local function forceLeaveSeat()
    local h=getHumanoid(); if not h then return end
    if h.SeatPart then
        for _,v in ipairs(h.SeatPart:GetChildren()) do
            if (v:IsA("Weld") or v:IsA("Motor6D")) then
                local p=v.Part0 or v.Part1
                if p and p:IsDescendantOf(LocalPlayer.Character) then
                    pcall(function() v:Destroy() end)
                end
            end
        end
        h.Sit=false
    end
    local w=0
    while h.SeatPart~=nil and w<2 do task.wait(0.1); w=w+0.1 end
    log("JOIN","forceLeaveSeat | isSeated="..tostring(isSeated()))
end

-- Hitung kursi terisi di model
local function getOccupied(model)
    local sf=model:FindFirstChild("Seats"); if not sf then return 0 end
    local seats={}
    for _,s in ipairs(sf:GetChildren()) do if s:IsA("Seat") then seats[s]=true end end
    local n=0
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local h=plr.Character:FindFirstChildOfClass("Humanoid")
            if h and h.SeatPart and seats[h.SeatPart] then n=n+1 end
        end
    end
    return n
end

-- Jumlah kursi total
local function getCapacity(model)
    local sf=model:FindFirstChild("Seats"); if not sf then return 0 end
    local n=0
    for _,s in ipairs(sf:GetChildren()) do if s:IsA("Seat") then n=n+1 end end
    return n
end

local function pressPrompt(model)
    local part=model:FindFirstChild("TablePart"); if not part then return false end
    local prompt=part:FindFirstChildOfClass("ProximityPrompt"); if not prompt then return false end
    log("JOIN","Trigger prompt:",model.Name)
    if fireproximityprompt then fireproximityprompt(prompt)
    else prompt:InputHoldBegin(); task.wait(0.3); prompt:InputHoldEnd() end
    return true
end

local function stopAutoJoin()
    if autoJoinLoop then task.cancel(autoJoinLoop); autoJoinLoop=nil end
    joinedTableName=nil
    log("JOIN","Stopped")
end

local function startAutoJoin(mode)
    -- mode = "2P" / "4P" / "8P"
    stopAutoJoin()
    if mode=="off" or mode==nil then return end

    local capacity=({["2P"]=2,["4P"]=4,["8P"]=8})[mode]
    if not capacity then return end

    log("JOIN","Start mode="..mode.." capacity="..capacity)

    autoJoinLoop=task.spawn(function()
        while cfg.autoJoinMode~="off" and _G.AutoKataActive do
            pcall(function()
                -- Saat match berlangsung, tidak scan
                if matchActive then return end

                local tf=Workspace:FindFirstChild("Tables"); if not tf then return end

                -- MODE: Sudah duduk → monitor lawan
                if joinedTableName then
                    local model=tf:FindFirstChild(joinedTableName)
                    if not model then
                        -- Meja hilang
                        forceLeaveSeat(); joinedTableName=nil; return
                    end
                    -- Cek apakah kita masih duduk
                    if not isSeated() then
                        log("JOIN","Ternyata sudah berdiri, reset")
                        joinedTableName=nil; return
                    end
                    -- Monitor: jika lawan keluar (occupied turun ke 1 = hanya kita), kita leave juga
                    local occ=getOccupied(model)
                    if occ<=1 then
                        log("JOIN","Lawan keluar (occ="..occ.."), leave seat")
                        -- Fire LeaveTable jika perlu
                        pcall(function() LeaveTable:FireServer() end)
                        forceLeaveSeat()
                        joinedTableName=nil
                    end
                    return
                end

                -- MODE: Belum duduk → pastikan berdiri dulu
                if isSeated() then
                    log("JOIN","Masih duduk saat scan, paksa berdiri")
                    forceLeaveSeat(); task.wait(0.3); return
                end

                -- Scan semua meja sesuai mode
                for _,model in ipairs(tf:GetChildren()) do
                    if model:IsA("Model") and model.Name:find(mode) then
                        local cap=getCapacity(model)
                        local occ=getOccupied(model)
                        log("JOIN","Scan",model.Name,"cap="..cap,"occ="..occ)
                        -- Butuh tepat 1 kursi lagi (ada pemain tapi belum penuh)
                        if occ>=1 and occ==cap-1 then
                            if pressPrompt(model) then
                                joinedTableName=model.Name
                                log("JOIN","Joined:",joinedTableName)
                                -- Tunggu konfirmasi duduk
                                local waited=0
                                while not isSeated() and waited<3 do
                                    task.wait(0.3); waited=waited+0.3
                                end
                                if not isSeated() then
                                    log("JOIN","Gagal duduk, reset")
                                    joinedTableName=nil
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

-- ══════════════════════════════════════════════════════════
-- S21 : WINDUI WINDOW
-- ══════════════════════════════════════════════════════════
local Window=WindUI:CreateWindow({
    Title         = "Sambung-kata",
    Icon          = "zap",
    Author        = "by dhann x sazaraaax",
    Folder        = "SambungKata",
    Size          = UDim2.fromOffset(580,490),
    Theme         = "Dark",
    Resizable     = true,
    HideSearchBar = true,
    User = {
        Enabled   = true,
        Anonymous = false,
        Callback  = function()
            WindUI:Notify({
                Title   = LocalPlayer.Name,
                Content = "ID: "..LocalPlayer.UserId.." | Age: "..LocalPlayer.AccountAge.." hari",
                Duration=4, Icon="user",
            })
        end,
    },
})

if not checkAccess() then return end

local function notify(title,content,duration)
    WindUI:Notify({Title=title,Content=content,Duration=duration or 2.5,Icon="bell"})
end

_G.AutoKataDestroy=function()
    cfg.autoEnabled=false; autoRunning=false; matchActive=false; isMyTurn=false
    stopAutoJoin()
    pcall(function() Window:Destroy() end)
    _G.AutoKataActive=false; _G.AutoKataDestroy=nil
end

-- ══════════════════════════════════════════════════════════
-- TAB MAIN
-- ══════════════════════════════════════════════════════════
local MainTab=Window:Tab({Title="Main",Icon="home"})

local getWordsToggle
local compeModeBtn  -- referensi tombol compe mode

uiRef.autoToggle=MainTab:Toggle({
    Title="Aktifkan Auto",Desc="Aktifkan mode auto play",Icon="zap",
    Value=cfg.autoEnabled,
    Callback=function(v)
        cfg.autoEnabled=v
        if v then
            if getWordsToggle then getWordsToggle:Set(false) end
            notify("[ZAP] AUTO","Auto ON - "..cfg.activeWordlist,3)
            if matchActive and isMyTurn and serverLetter~="" then safeSpawn(_startUltraAI) end
        else
            autoRunning=false
            notify("[ZAP] AUTO","Auto OFF",3)
        end
        safeSpawn(saveConfig)
    end,
})

-- Wordlist dropdown
local wordlistDrop
wordlistDrop=MainTab:Dropdown({
    Title="Opsi Wordlist",Desc="Pilih kamus kata",Icon="database",
    Values=WORDLIST_LIST, Value=cfg.activeWordlist, Multi=false,
    Callback=function(sel)
        if not sel or sel==cfg.activeWordlist then return end
        cfg.activeWordlist=sel
        -- Lock/unlock compe mode sesuai wordlist
        if sel=="Ranking Kata (Kompetitif)" then
            pcall(function() if compeModeBtn then compeModeBtn:Unlock() end end)
        else
            cfg.compeMode=false
            pcall(function() if uiRef.compeModeToggle then uiRef.compeModeToggle:Set(false) end end)
            pcall(function() if compeModeBtn then compeModeBtn:Lock() end end)
        end
        notify("[PKG] WORDLIST","Loading "..sel.."...",3)
        safeSpawn(function()
            if WORDLIST_URLS[sel]=="__RANKING__" then
                if not next(rankingMap) then
                    local w=0
                    while not next(rankingMap) and w<15 do task.wait(0.5); w=w+0.5 end
                end
                local words={}
                for word in pairs(rankingMap) do words[#words+1]=word end
                kataModule=words; buildIndex(); resetUsed()
                notify("[OK] RANKING",#kataModule.." kata kompetitif",4)
            else
                if loadWordlistFromURL(WORDLIST_URLS[sel]) then
                    buildIndex(); resetUsed()
                    notify("[OK] WORDLIST",sel.." | "..#kataModule.." kata",4)
                else notify("[X] WORDLIST","Gagal load!",4) end
            end
            saveConfig()
        end)
    end,
})

MainTab:Slider({
    Title="Aggression",Desc="Agresivitas pemilihan kata",Icon="trending-up",
    Value={Min=0,Max=100,Default=cfg.aggression,Decimals=0,Suffix="%"},
    Callback=function(v) cfg.aggression=v; safeSpawn(saveConfig) end,
})

-- COMPE MODE — hanya unlock jika Ranking kata aktif
compeModeBtn=MainTab:Toggle({
    Title="Compe Mode",
    Desc="Filter kata berakhiran jebakan (i,f,x,v,y,w) | Hanya aktif di Ranking Kata",
    Icon="trophy",
    Value=cfg.compeMode,
    Callback=function(v)
        cfg.compeMode=v
        if v then
            notify("[🏆] COMPE","Compe mode ON — kata jebakan aktif",3)
        else
            notify("[🏆] COMPE","Compe mode OFF",3)
        end
        safeSpawn(saveConfig)
    end,
})
uiRef.compeModeToggle=compeModeBtn
-- Lock jika bukan ranking
if cfg.activeWordlist~="Ranking Kata (Kompetitif)" then
    pcall(function() compeModeBtn:Lock() end)
end

local detikMode=false
local minInput,maxInput,speedDrop

local function parseNum(str)
    if type(str)~="string" then return nil end
    return tonumber(str:gsub(",","."):match("^%s*(.-)%s*$"))
end

MainTab:Toggle({
    Title="Detik Mode",Desc="ON=input manual | OFF=preset speed",Icon="clock",Value=false,
    Callback=function(v)
        detikMode=v
        if v then
            pcall(function() minInput:Unlock() end); pcall(function() maxInput:Unlock() end)
            pcall(function() speedDrop:Lock() end)
        else
            pcall(function() minInput:Lock() end); pcall(function() maxInput:Lock() end)
            pcall(function() speedDrop:Unlock() end)
        end
    end,
})

minInput=MainTab:Input({
    Title="Min Delay (detik)",Desc="Delay min (maks 5,0)",Icon="timer",Placeholder="0,5",
    Callback=function(raw)
        local n=parseNum(raw); if not n then notify("[X]","Bukan angka",3); return end
        n=math.max(0,math.min(n,5)); if n>cfg.maxDelay/1000 then n=cfg.maxDelay/1000 end
        cfg.minDelay=math.floor(n*1000)
        notify("[OK] MIN",n.."s",2); safeSpawn(saveConfig)
    end,
})
pcall(function() minInput:Lock() end)

maxInput=MainTab:Input({
    Title="Max Delay (detik)",Desc="Delay max (maks 5,0)",Icon="timer",Placeholder="1,5",
    Callback=function(raw)
        local n=parseNum(raw); if not n then notify("[X]","Bukan angka",3); return end
        n=math.max(0,math.min(n,5)); if n<cfg.minDelay/1000 then n=cfg.minDelay/1000 end
        cfg.maxDelay=math.floor(n*1000)
        notify("[OK] MAX",n.."s",2); safeSpawn(saveConfig)
    end,
})
pcall(function() maxInput:Lock() end)

speedDrop=MainTab:Dropdown({
    Title="Kecepatan",Desc="Preset kecepatan",Icon="gauge",
    Values={"Slow","Fast","Superfast"},Value="Fast",Multi=false,
    Callback=function(sel)
        if not sel then return end
        local p=SPEED_PRESETS[sel]
        if p then cfg.minDelay=p.min; cfg.maxDelay=p.max end
        notify("[ZAP] SPEED",sel,2)
    end,
})

MainTab:Input({
    Title="Jeda Awal (detik)",Desc="Jeda sebelum mulai ngetik (maks 3,0)",Icon="hourglass",Placeholder="1,5",
    Callback=function(raw)
        local n=parseNum(raw); if not n then notify("[X]","Tidak valid",3); return end
        cfg.initialDelay=math.max(0,math.min(n,3))
        notify("[OK] JEDA AWAL",cfg.initialDelay.."s",2); safeSpawn(saveConfig)
    end,
})

MainTab:Input({
    Title="Jeda Submit (detik)",Desc="Jeda sebelum submit (maks 5,0)",Icon="timer",Placeholder="1,0",
    Callback=function(raw)
        local n=parseNum(raw); if not n then notify("[X]","Tidak valid",3); return end
        cfg.submitDelay=math.max(0,math.min(n,5))
        notify("[OK] JEDA SUBMIT",cfg.submitDelay.."s",2); safeSpawn(saveConfig)
    end,
})

MainTab:Slider({
    Title="Min Word Length",Desc="Panjang kata minimum",Icon="type",
    Value={Min=2,Max=20,Default=cfg.minLength,Decimals=0},
    Callback=function(v) cfg.minLength=v; safeSpawn(saveConfig) end,
})

MainTab:Slider({
    Title="Max Word Length",Desc="Panjang kata maksimum",Icon="type",
    Value={Min=5,Max=20,Default=cfg.maxLength,Decimals=0},
    Callback=function(v) cfg.maxLength=v; safeSpawn(saveConfig) end,
})

local statusPara=MainTab:Paragraph({Title="Status",Desc="Menunggu..."})

local function updateStatus()
    if not matchActive then
        pcall(function() statusPara:SetDesc("Match tidak aktif | - | -") end); return
    end
    local name,turn="-","Menunggu..."
    if isMyTurn then
        name="Anda"; turn="Giliran Anda"
    else
        for _,st in pairs(seatStates) do
            if st.Current and st.Current.Billboard and st.Current.Billboard.Parent then
                name=st.Current.Player.Name; turn="Giliran "..name; break
            end
        end
    end
    pcall(function()
        statusPara:SetDesc(name.." | "..turn.." | "..(serverLetter~="" and serverLetter or "-"))
    end)
end

-- ══════════════════════════════════════════════════════════
-- TAB SELECT WORD
-- ══════════════════════════════════════════════════════════
local SelectTab=Window:Tab({Title="Select Word",Icon="search"})

local getWordsEnabled=false
local maxWordsShow=50
local selectedWord=nil
local wordDrop=nil

local function refreshWordDrop()
    if not wordDrop then return end
    if not getWordsEnabled or not isMyTurn or serverLetter=="" then
        pcall(function() wordDrop:Refresh({}) end); selectedWord=nil; return
    end
    local words,limited=getSmartWords(serverLetter),{}
    for i=1,math.min(#words,maxWordsShow) do limited[#limited+1]=words[i] end
    if #limited==0 then pcall(function() wordDrop:Refresh({}) end); selectedWord=nil; return end
    pcall(function() wordDrop:Refresh(limited) end)
    selectedWord=limited[1]; pcall(function() wordDrop:Set(limited[1]) end)
end

getWordsToggle=SelectTab:Toggle({
    Title="Get Words",Desc="Tampilkan daftar kata tersedia",Icon="book-open",Value=false,
    Callback=function(v)
        getWordsEnabled=v
        if v then
            if uiRef.autoToggle then uiRef.autoToggle:Set(false) end
            notify("[ON] SELECT","Get Words ON",3)
        else notify("[OFF] SELECT","OFF",3) end
        refreshWordDrop()
    end,
})

SelectTab:Slider({
    Title="Max Words",Icon="hash",
    Value={Min=1,Max=100,Default=50,Decimals=0},
    Callback=function(v) maxWordsShow=v; refreshWordDrop() end,
})

wordDrop=SelectTab:Dropdown({
    Title="Pilih Kata",Desc="Kata untuk diketik",Icon="chevrons-up-down",
    Values={},Value=nil,Multi=false,
    Callback=function(opt) selectedWord=opt or nil end,
})

SelectTab:Button({
    Title="Ketik Kata Terpilih",Desc="Ketik ke game",Icon="send",
    Callback=function()
        if not getWordsEnabled or not isMyTurn or not selectedWord or serverLetter=="" then return end
        local word=selectedWord
        -- FIX: set langsung ke TextBox, build satu karakter per delay
        for i=1,#word do
            if not matchActive or not isMyTurn then return end
            local partial=word:sub(1,i)
            setTBText(partial)
            pcall(function() TypeSound:FireServer() end)
            pcall(function() BillboardUpdate:FireServer(partial) end)
            humanDelay()
        end
        humanDelay()
        pcall(function() SubmitWord:FireServer(word) end)
        addUsed(word); humanDelay(); fireBillboardEnd()
    end,
})

-- ══════════════════════════════════════════════════════════
-- TAB PLAYER
-- ══════════════════════════════════════════════════════════
local PlayerTab=Window:Tab({Title="Player",Icon="user"})

PlayerTab:Paragraph({
    Title="Save & Load Config",
    Desc="Simpan semua setting ke satu file.\nSaat script dijalankan, config otomatis di-load.",
})

uiRef.cfgSummaryPara=PlayerTab:Paragraph({Title="Config Tersimpan",Desc="(belum ada)"})

local function refreshCfgSummary()
    local exists=false
    if CAN_SAVE then exists=pcall(function() readfile(CONFIG_FILE) end) end
    if not exists then
        pcall(function() uiRef.cfgSummaryPara:SetDesc("(belum ada config tersimpan)") end); return
    end
    pcall(function()
        uiRef.cfgSummaryPara:SetDesc(table.concat({
            "Wordlist    : "..cfg.activeWordlist,
            "Delay       : "..(cfg.minDelay/1000).."s – "..(cfg.maxDelay/1000).."s",
            "Aggression  : "..cfg.aggression.."%",
            "Jeda Awal   : "..cfg.initialDelay.."s",
            "Jeda Submit : "..cfg.submitDelay.."s",
            "Auto        : "..(cfg.autoEnabled  and "ON" or "OFF"),
            "AutoClick   : "..(cfg.autoClick    and "ON" or "OFF"),
            "CompeMode   : "..(cfg.compeMode    and "ON" or "OFF"),
            "AutoJoin    : "..cfg.autoJoinMode,
        },"\n"))
    end)
end

PlayerTab:Button({
    Title="💾 Save Config",Desc="Simpan semua setting sekarang",Icon="save",
    Callback=function()
        saveConfig(); refreshCfgSummary()
        notify("[OK] SAVE","Config disimpan!",3)
    end,
})

PlayerTab:Button({
    Title="📂 Load Config",Desc="Muat config dan terapkan ke UI",Icon="folder-open",
    Callback=function()
        local ok=loadConfig()
        if ok then
            applyConfigToUI(); refreshCfgSummary()
            notify("[OK] LOAD","Config di-load & diterapkan!",3)
        else
            notify("[X] LOAD","File config tidak ditemukan",3)
        end
    end,
})

PlayerTab:Button({
    Title="🗑️ Reset Config",Desc="Hapus file config (kembali default)",Icon="trash-2",
    Callback=function()
        if CAN_SAVE then pcall(delfile,CONFIG_FILE) end
        refreshCfgSummary()
        notify("[OK] RESET","Config dihapus",3)
    end,
})

PlayerTab:Paragraph({Title="Auto Click",Desc="Klik otomatis di background setelah match selesai"})

uiRef.autoClickToggle=PlayerTab:Toggle({
    Title="Auto Click (Backend)",Desc="Klik tombol otomatis saat match selesai",Icon="mouse-pointer",
    Value=cfg.autoClick,
    Callback=function(v)
        cfg.autoClick=v
        notify(v and "[ON] AUTO CLICK" or "[OFF] AUTO CLICK",
               v and "Auto click aktif" or "Nonaktif",2)
        safeSpawn(saveConfig)
    end,
})

PlayerTab:Slider({
    Title="Delay Auto Click",Desc="Jeda sebelum klik otomatis",Icon="timer",
    Value={Min=0,Max=5,Default=cfg.autoClickDelay,Decimals=1,Suffix="s"},
    Callback=function(v) cfg.autoClickDelay=v; safeSpawn(saveConfig) end,
})

refreshCfgSummary()

-- ══════════════════════════════════════════════════════════
-- TAB SETTINGS
-- ══════════════════════════════════════════════════════════
local SettingsTab=Window:Tab({Title="Settings",Icon="settings"})

-- AUTO JOIN dropdown (2P / 4P / 8P / off)
SettingsTab:Dropdown({
    Title="Auto Join Mode",
    Desc="Pilih tipe meja yang dimonitor. OFF untuk nonaktif.",
    Icon="users",
    Values={"off","2P","4P","8P"},
    Value=cfg.autoJoinMode,
    Multi=false,
    Callback=function(sel)
        if not sel then return end
        cfg.autoJoinMode=sel
        if sel=="off" then
            stopAutoJoin()
            notify("[AUTO JOIN]","Nonaktif",2)
        else
            startAutoJoin(sel)
            notify("[AUTO JOIN]","Aktif mode "..sel,2)
        end
        safeSpawn(saveConfig)
    end,
})

SettingsTab:Dropdown({
    Title="Tema",Desc="Pilih warna GUI",Icon="palette",
    Values={"Dark","Rose","Midnight"},Value="Dark",Multi=false,
    Callback=function(sel)
        if not sel then return end
        local ok,err=pcall(function() WindUI:SetTheme(sel) end)
        if ok then notify("[ART]",sel,2)
        else notify("[X]",tostring(err),3) end
    end,
})

SettingsTab:Paragraph({Title="Anti Lag",Desc="Turunkan grafis untuk FPS stabil"})

local origGfx={gs=Lighting.GlobalShadows,fe=Lighting.FogEnd,br=Lighting.Brightness}
SettingsTab:Toggle({
    Title="Potato Mode",Desc="Grafis minimum",Icon="cpu",Value=false,
    Callback=function(v)
        if v then
            pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
            Lighting.GlobalShadows=false; Lighting.FogEnd=100000; Lighting.Brightness=1
            for _,c in ipairs(Lighting:GetChildren()) do if c:IsA("PostEffect") then c.Enabled=false end end
            notify("[CPU] POTATO","Grafis minimum",3)
        else
            pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Automatic end)
            Lighting.GlobalShadows=origGfx.gs; Lighting.FogEnd=origGfx.fe; Lighting.Brightness=origGfx.br
            for _,c in ipairs(Lighting:GetChildren()) do if c:IsA("PostEffect") then c.Enabled=true end end
            notify("[FX] NORMAL","Grafis normal",3)
        end
    end,
})

SettingsTab:Paragraph({Title="Server"})

SettingsTab:Button({
    Title="Rejoin",Desc="Masuk ulang ke server sama",Icon="refresh-cw",
    Callback=function()
        notify("[RLD]","Rejoining...",2); task.wait(0.8)
        TeleportService:Teleport(game.PlaceId,LocalPlayer)
    end,
})

SettingsTab:Paragraph({Title="Job ID",Desc=tostring(game.JobId)})

SettingsTab:Button({
    Title="Copy Job ID",Icon="copy",
    Callback=function()
        if setclipboard then
            setclipboard(tostring(game.JobId))
            notify("[CPY]",tostring(game.JobId):sub(1,20).."...",3)
        else notify("[X]","Tidak support",3) end
    end,
})

local currentKeybind=Enum.KeyCode.X
Window:SetToggleKey(currentKeybind)
SettingsTab:Keybind({
    Title="Toggle UI Keybind",Value="X",
    Callback=function(key)
        local ke=(typeof(key)=="EnumItem") and key
                or (typeof(key)=="string" and Enum.KeyCode[key])
        if ke then currentKeybind=ke; Window:SetToggleKey(ke); notify("[KEY]",ke.Name,2) end
    end,
})

-- ══════════════════════════════════════════════════════════
-- TAB ADMIN
-- ══════════════════════════════════════════════════════════
if isAdmin(LocalPlayer) then
    local AdminTab=Window:Tab({Title="Admin",Icon="shield"})
    local function blCount() local n=0; for _ in pairs(BLACKLIST) do n=n+1 end; return n end
    local admPara=AdminTab:Paragraph({
        Title="Admin Panel",
        Desc="UID:"..LocalPlayer.UserId.." | Maint:"..(MAINTENANCE and "ON" or "OFF").." | BL:"..blCount()
    })
    local function refreshAdm()
        pcall(function()
            admPara:SetDesc("UID:"..LocalPlayer.UserId.." | Maint:"..(MAINTENANCE and "ON" or "OFF").." | BL:"..blCount())
        end)
    end
    AdminTab:Toggle({
        Title="Maintenance Mode",Icon="lock",Value=MAINTENANCE,
        Callback=function(v) MAINTENANCE=v; adminSave(); refreshAdm()
            notify(v and "[ON] MAINT" or "[OFF] MAINT","",3) end,
    })
    AdminTab:Input({Title="Blacklist UID",Icon="user-x",Placeholder="123456789",
        Callback=function(i)
            local uid=tonumber(i); if not uid then notify("[X]","Angka saja",3); return end
            if uid==LocalPlayer.UserId then notify("[X]","Tidak bisa BL diri",3); return end
            BLACKLIST[uid]=true; adminSave()
            for _,p in ipairs(Players:GetPlayers()) do
                if p.UserId==uid then pcall(function() p:Kick("[AutoKata] Blacklisted.") end) end
            end
            refreshAdm(); notify("[BAN]","UID "..uid,3)
        end,
    })
    AdminTab:Input({Title="Hapus Blacklist",Icon="user-check",Placeholder="123456789",
        Callback=function(i)
            local uid=tonumber(i); if not uid then notify("[X]","Angka saja",3); return end
            if BLACKLIST[uid] then
                BLACKLIST[uid]=nil; adminSave(); refreshAdm()
                notify("[OK]","UID "..uid.." dihapus",3)
            else notify("[!]","UID tidak ada",3) end
        end,
    })
    AdminTab:Button({Title="Lihat Blacklist",Icon="list",
        Callback=function()
            local l={} for uid in pairs(BLACKLIST) do l[#l+1]=tostring(uid) end
            notify("[BL]",#l==0 and "Kosong" or table.concat(l,", "),5)
        end,
    })
    AdminTab:Button({Title="Kick Semua Non-Admin",Icon="zap",
        Callback=function()
            local n=0
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and not isAdmin(p) then
                    pcall(function() p:Kick("[AutoKata] Kicked by admin.") end); n=n+1
                end
            end
            notify("[ZAP]",n.." di-kick",3)
        end,
    })
end

-- ══════════════════════════════════════════════════════════
-- TAB ABOUT
-- ══════════════════════════════════════════════════════════
local AboutTab=Window:Tab({Title="About",Icon="info"})
AboutTab:Paragraph({
    Title="Auto Kata v5.5",
    Desc="by dhann x sazaraaax\nAuto play, compe mode, ranking kata, save config",
})
AboutTab:Paragraph({
    Title="Cara Pakai",
    Desc="1. Pilih wordlist di Main\n2. Aktifkan Auto\n3. Compe Mode (Ranking only)\n4. Atur delay & aggression\n5. Pilih Auto Join mode di Settings\n6. Simpan config di Player",
})
local function copyBtn(title,url)
    AboutTab:Button({Title=title,Icon="link",
        Callback=function()
            if setclipboard then setclipboard(url); notify("[CPY]",title.." disalin!",3)
            else notify("[X]","Tidak support",3) end
        end,
    })
end
copyBtn("Copy Discord Invite",  "https://discord.gg/bT4GmSFFWt")
copyBtn("Copy WhatsApp Channel","https://www.whatsapp.com/channel/0029VbCBSBOCRs1pRNYpPN0r")

-- ══════════════════════════════════════════════════════════
-- S22 : DISCORD NOTIF  (setelah UI selesai)
-- ══════════════════════════════════════════════════════════
sendLoginNotif()

-- ══════════════════════════════════════════════════════════
-- S23 : REMOTE EVENT HANDLERS
-- ══════════════════════════════════════════════════════════
MatchUI.OnClientEvent:Connect(function(cmd,value)
    log("REMOTE",cmd,tostring(value))

    if cmd=="ShowMatchUI" then
        matchActive=true; isMyTurn=false; serverLetter=""
        autoRunning=false; blacklistedWords={}
        resetUsed(); setupSeatMonitoring(); updateStatus(); refreshWordDrop()

    elseif cmd=="HideMatchUI" then
        matchActive=false; isMyTurn=false; serverLetter=""
        autoRunning=false; blacklistedWords={}
        resetUsed(); seatStates={}; updateStatus(); refreshWordDrop()
        -- Resume auto join scan setelah match selesai
        if cfg.autoJoinMode~="off" then
            safeSpawn(function()
                task.wait(0.5)
                if not matchActive then
                    forceLeaveSeat()
                    joinedTableName=nil
                    log("JOIN","Post-match: reset + siap scan lagi")
                end
            end)
        end
        safeSpawn(doAutoClick)

    elseif cmd=="StartTurn" then
        isMyTurn=true; lastTurnActivity=tick()
        if type(value)=="string" and value~="" then serverLetter=value end
        if cfg.autoEnabled then
            safeSpawn(function()
                task.wait(math.random(200,400)/1000)
                if matchActive and isMyTurn and cfg.autoEnabled then _startUltraAI() end
            end)
        end
        updateStatus(); refreshWordDrop()

    elseif cmd=="EndTurn" then
        isMyTurn=false; updateStatus(); refreshWordDrop()

    elseif cmd=="UpdateServerLetter" then
        serverLetter=value or ""
        updateStatus(); refreshWordDrop()
        if isMyTurn and cfg.autoEnabled and not autoRunning and serverLetter~="" then
            safeSpawn(_startUltraAI)
        end

    elseif cmd=="Mistake" then
        if type(value)=="table" and value.userId==LocalPlayer.UserId then
            if cfg.autoEnabled and matchActive and isMyTurn then
                safeSpawn(function()
                    clearToLetter(serverLetter); task.wait(0.3)
                    if matchActive and isMyTurn then _startUltraAI() end
                end)
            end
        end
    end
end)

BillboardUpdate.OnClientEvent:Connect(function(word)
    if matchActive and not isMyTurn then opponentStreamWord=word or "" end
end)

UsedWordWarn.OnClientEvent:Connect(function(word)
    if not word then return end
    lastRejectWord=word:lower(); addUsed(word)
    if cfg.autoEnabled and matchActive and isMyTurn and not autoRunning then
        safeSpawn(function()
            clearToLetter(serverLetter); task.wait(0.3)
            if matchActive and isMyTurn then _startUltraAI() end
        end)
    end
end)

JoinTable.OnClientEvent:Connect(function(tableName)
    log("TABLE","JoinTable:",tableName)
    currentTableName=tableName
    if cfg.autoJoinMode~="off" then joinedTableName=tableName end
    setupSeatMonitoring(); updateStatus()
end)

LeaveTable.OnClientEvent:Connect(function()
    log("TABLE","LeaveTable")
    currentTableName=nil; matchActive=false; isMyTurn=false
    serverLetter=""; autoRunning=false; blacklistedWords={}
    resetUsed(); seatStates={}; updateStatus()
    joinedTableName=nil
    if cfg.autoJoinMode~="off" then
        safeSpawn(function()
            task.wait(0.8); forceLeaveSeat()
            log("JOIN","Post-LeaveTable ready")
        end)
    end
    safeSpawn(doAutoClick)
end)

if PlayerHit then
    PlayerHit.OnClientEvent:Connect(function(player)
        if player~=LocalPlayer then return end
        if cfg.autoEnabled and matchActive and isMyTurn then
            safeSpawn(function()
                clearToLetter(serverLetter); task.wait(0.4)
                if matchActive and isMyTurn then _startUltraAI() end
            end)
        end
    end)
end

if PlayerCorrect then
    PlayerCorrect.OnClientEvent:Connect(function(player)
        if player==LocalPlayer then log("MATCH","PlayerCorrect OK") end
    end)
end

-- ══════════════════════════════════════════════════════════
-- S24 : BACKGROUND LOOPS
-- ══════════════════════════════════════════════════════════
safeSpawn(function()
    while _G.AutoKataActive do
        task.wait(0.3); if matchActive then updateStatus() end
    end
end)

safeSpawn(function()
    while _G.AutoKataActive do task.wait(1); flushLogUI() end
end)

safeSpawn(buildIndex)
safeSpawn(downloadWrongWords)
safeSpawn(function()
    loadRanking()
    if cfg.activeWordlist=="Ranking Kata (Kompetitif)" and next(rankingMap) then
        local words={}
        for w in pairs(rankingMap) do words[#words+1]=w end
        kataModule=words; buildIndex()
        log("WORDLIST","Ranking mode:",#kataModule)
    end
end)

-- Resume auto join jika config tersimpan dengan mode aktif
if cfg.autoJoinMode~="off" then
    task.delay(1, function()
        startAutoJoin(cfg.autoJoinMode)
        log("JOIN","Auto-resume mode="..cfg.autoJoinMode)
    end)
end

log("BOOT","═══════════════════════════════════════")
log("BOOT","AutoKata v5.5 loaded OK")
log("BOOT","Wordlist:"..cfg.activeWordlist.."|"..#kataModule.."kata")
log("BOOT","autoClick="..tostring(cfg.autoClick).." autoEnabled="..tostring(cfg.autoEnabled))
log("BOOT","compeMode="..tostring(cfg.compeMode).." autoJoin="..cfg.autoJoinMode)
log("BOOT","═══════════════════════════════════════")
