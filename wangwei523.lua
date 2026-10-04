-- 왕웨이 따라가는 핵패널
-- made by 왕웨이

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local VIM = game:GetService("VirtualInputManager")
local lp = Players.LocalPlayer

pcall(function() UIS.MouseIconEnabled = true end)

local state = {
    ws = nil, jp = nil, flySpeed = 60, bright = nil, range = nil, fov = nil,
    noclip = false, fly = false,
    macroOn = false, mx = 0, my = 0, macroDelay = 0.05,
    god = false, invis = false, spinning = false, spinSpeed = 10,
    prefix = ".", chatOn = true, touchTP = false,
    lastCF = nil, hipHeight = nil,

    aimOn = false, aimFOV = 150, aimSmooth = 0.3, aimTeam = false,
    aimVisible = true, aimPart = "Head", aimCircle = true,
    aimMouseMode = true, aimMoveMouse = true, aimMoveCam = false,
    aimNPC = true, aimActive = false, aimHold = true,

    hbOn = false, hbSize = 10, hbColor = Color3.fromRGB(255, 0, 0),
    hbTrans = 0.5, hbNPC = true,
}

local function hum() local c = lp.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp() local c = lp.Character; return c and c:FindFirstChild("HumanoidRootPart") end

local function notify(t, title)
    pcall(function() Rayfield:Notify({Title = title or "왕웨이 따라가는 핵패널", Content = t, Duration = 2}) end)
end

local function numArg(args, i)
    i = i or 1
    for k = i, #args do local n = tonumber(args[k]); if n then return n, k end end
end

-- 속도 / 점프
local function applyWS()
    if state.ws == nil then return end
    local h = hum(); if h then pcall(function() h.WalkSpeed = state.ws end) end
end

local function applyJP()
    if state.jp == nil then return end
    local h = hum(); if not h then return end
    pcall(function() h.UseJumpPower = true end)
    pcall(function() h.JumpPower = state.jp end)
    pcall(function() h.JumpHeight = state.jp/7.5 end)
end

RunService.Heartbeat:Connect(function()
    local h = hum(); if not h then return end
    if state.ws ~= nil and math.abs(h.WalkSpeed - state.ws) > 0.5 then
        pcall(function() h.WalkSpeed = state.ws end)
    end
    if state.jp ~= nil then
        if h.UseJumpPower then
            if math.abs(h.JumpPower - state.jp) > 0.5 then
                pcall(function() h.JumpPower = state.jp end)
            end
        else
            local t = state.jp/7.5
            if math.abs(h.JumpHeight - t) > 0.5 then
                pcall(function() h.JumpHeight = t end)
            end
        end
    end
    if state.hipHeight ~= nil and math.abs(h.HipHeight - state.hipHeight) > 0.1 then
        pcall(function() h.HipHeight = state.hipHeight end)
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

-- 노클립
local function doNoclip()
    local c = lp.Character; if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then
            pcall(function() p.CanCollide = false end)
        end
    end
end

RunService.Heartbeat:Connect(function()
    if state.noclip then doNoclip() end
end)

local function setNoclip(on)
    state.noclip = on
    if on then
        doNoclip()
        task.spawn(function()
            for _ = 1, 10 do
                task.wait(0.1)
                if not state.noclip then break end
                doNoclip()
            end
        end)
    else
        local c = lp.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
            end
        end
    end
end

-- 플라이
local fConn, fBV, fBG, fHB, fOn

local function stopFly()
    fOn = false
    if fConn then pcall(function() fConn:Disconnect() end); fConn = nil end
    if fHB then pcall(function() fHB:Disconnect() end); fHB = nil end
    local c = lp.Character
    if c then
        local p = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChildOfClass("Humanoid")
        if p then
            for _, n in ipairs({"wBV","wBG","wAV"}) do
                local o = p:FindFirstChild(n); if o then o:Destroy() end
            end
        end
        if h then pcall(function() h.PlatformStand = false end) end
    end
    fBV, fBG = nil, nil
end

local function startFly()
    local c = lp.Character; if not c then return end
    local p = c:FindFirstChild("HumanoidRootPart")
    local h = c:FindFirstChildOfClass("Humanoid")
    if not p or not h then return end

    stopFly()
    fOn = true

    fBV = Instance.new("BodyVelocity")
    fBV.Name = "wBV"
    fBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    fBV.Velocity = Vector3.zero
    fBV.P = 1250
    fBV.Parent = p

    fBG = Instance.new("BodyGyro")
    fBG.Name = "wBG"
    fBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    fBG.P = 10000
    fBG.D = 500
    fBG.CFrame = p.CFrame
    fBG.Parent = p

    local av = Instance.new("BodyAngularVelocity")
    av.Name = "wAV"
    av.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    av.AngularVelocity = Vector3.zero
    av.P = 1250
    av.Parent = p

    fHB = RunService.Heartbeat:Connect(function()
        if not fOn then return end
        if h.Parent and h.PlatformStand == false then
            pcall(function() h.PlatformStand = true end)
        end
    end)

    fConn = RunService.RenderStepped:Connect(function()
        if not fOn then return end
        local cam = workspace.CurrentCamera
        if not cam or not p.Parent then return end

        local mv = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
        if mv.Magnitude > 0 then mv = mv.Unit * state.flySpeed end

        pcall(function()
            fBV.Velocity = mv
            fBG.CFrame = cam.CFrame
        end)
    end)
end

local function setFly(on)
    state.fly = on
    if on then startFly() else stopFly() end
end

-- 무적
RunService.Heartbeat:Connect(function()
    if state.god then
        local h = hum()
        if h and h.Health < h.MaxHealth then
            pcall(function() h.Health = h.MaxHealth end)
        end
    end
end)

-- 투명화
local function setInvis(on)
    state.invis = on
    local c = lp.Character; if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function()
                p.Transparency = on and 1 or 0
                p.LocalTransparencyModifier = on and 1 or 0
            end)
        elseif p:IsA("Decal") then
            pcall(function() p.Transparency = on and 1 or 0 end)
        end
    end
end

-- 회전
local spinConn
local function setSpin(on)
    state.spinning = on
    if spinConn then spinConn:Disconnect(); spinConn = nil end
    if not on then return end
    spinConn = RunService.Heartbeat:Connect(function(dt)
        local p = hrp()
        if p then
            p.CFrame = p.CFrame * CFrame.Angles(0, math.rad(state.spinSpeed)*dt*60, 0)
        end
    end)
end

-- 밝기
local function applyLights()
    if state.bright == nil then return end
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Light") then
            pcall(function()
                o.Brightness = state.bright
                if state.range then o.Range = state.range end
                o.Shadows = false
            end)
        end
    end
end

local function applyLighting()
    if state.bright == nil then return end
    pcall(function()
        Lighting.Ambient = Color3.fromRGB(150,150,150)
        Lighting.OutdoorAmbient = Color3.fromRGB(150,150,150)
        Lighting.Brightness = math.clamp(state.bright/5, 1, 10)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    end)
end

-- FOV
local function applyFOV()
    if state.fov == nil then return end
    local c = workspace.CurrentCamera; if not c then return end
    pcall(function()
        if math.abs(c.FieldOfView - state.fov) > 0.1 then c.FieldOfView = state.fov end
    end)
end

RunService.RenderStepped:Connect(function()
    if state.fov == nil then return end
    local c = workspace.CurrentCamera; if not c then return end
    if math.abs(c.FieldOfView - state.fov) > 0.1 then
        pcall(function() c.FieldOfView = state.fov end)
    end
end)

-- 리스폰
local function respawnNormal()
    pcall(function() lp:LoadCharacter() end)
end

local function respawnHere()
    local p = hrp()
    local cf = p and p.CFrame or state.lastCF
    pcall(function() lp:LoadCharacter() end)
    task.spawn(function()
        local c = lp.Character or lp.CharacterAdded:Wait()
        local np = c:WaitForChild("HumanoidRootPart", 5)
        if np and cf then
            task.wait(0.1)
            np.CFrame = cf + Vector3.new(0, 3, 0)
        end
    end)
end

local function revive()
    local c = lp.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local p = c and c:FindFirstChild("HumanoidRootPart")
    local cf = p and p.CFrame or state.lastCF or CFrame.new(0, 50, 0)
    if h then
        pcall(function() h:ChangeState(Enum.HumanoidStateType.Physics) end)
        pcall(function() h.Health = h.MaxHealth end)
        pcall(function() h.PlatformStand = false end)
        pcall(function() h.Sit = false end)
    end
    pcall(function()
        local cam = workspace.CurrentCamera
        cam.CameraSubject = h
        cam.CameraType = Enum.CameraType.Custom
    end)
    task.wait(0.2)
    local h2 = hum()
    if not h2 or h2.Health <= 0 then
        pcall(function() lp:LoadCharacter() end)
        task.spawn(function()
            local nc = lp.Character or lp.CharacterAdded:Wait()
            local np = nc:WaitForChild("HumanoidRootPart", 5)
            if np then
                task.wait(0.1)
                np.CFrame = cf + Vector3.new(0, 3, 0)
            end
        end)
    end
end

-- TP
local function tpTo(plr)
    if not plr or plr == lp then return end
    local mp = hrp(); if not mp then return end
    local tp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not tp then return end
    mp.CFrame = tp.CFrame * CFrame.new(0, 0, 2)
end

local function tpPos(x, y, z)
    local p = hrp(); if p then p.CFrame = CFrame.new(x, y, z) end
end

local touchConn
local function startTouchTP()
    if touchConn then touchConn:Disconnect(); touchConn = nil end
    touchConn = UIS.InputBegan:Connect(function(input, gpe)
        if not state.touchTP then return end
        if gpe then return end
        if state.macroOn then
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                state.mx = input.Position.X
                state.my = input.Position.Y
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
            if p then p.CFrame = CFrame.new(pos); notify("TP") end
        end
    end)
end

local function setTouchTP(on)
    state.touchTP = on
    if on then startTouchTP() else
        if touchConn then touchConn:Disconnect(); touchConn = nil end
    end
end

-- 매크로
local macroThread
local function sendClick(x, y)
    local ok = pcall(function()
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.01)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
    if not ok then
        pcall(function()
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

local function stopMacro()
    state.macroOn = false
    macroThread = nil
end

UIS.InputBegan:Connect(function(input, gpe)
    if not state.macroOn or state.touchTP then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if gpe then return end
        state.mx = input.Position.X
        state.my = input.Position.Y
        notify(string.format("매크로 위치 %.0f, %.0f", input.Position.X, input.Position.Y))
    end
end)

-- FOV 원
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "wFov"
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true
pcall(function() fovGui.Parent = game:GetService("CoreGui") end)
if not fovGui.Parent then fovGui.Parent = lp:WaitForChild("PlayerGui") end

local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = fovGui

Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Thickness = 1.5
fovStroke.Color = Color3.fromRGB(0, 255, 100)
fovStroke.Transparency = 0.2

local function updateCircle()
    fovCircle.Size = UDim2.fromOffset(state.aimFOV, state.aimFOV)
    fovCircle.Visible = state.aimOn and state.aimCircle
end
updateCircle()

local function mousePos()
    local m = lp:GetMouse()
    if m then return Vector2.new(m.X, m.Y) end
    return Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)
end

RunService.RenderStepped:Connect(function()
    if not state.aimCircle then fovCircle.Visible = false; return end
    fovCircle.Visible = state.aimOn
    if not state.aimOn then return end
    if state.aimMouseMode then
        local mp = mousePos()
        fovCircle.Position = UDim2.fromOffset(mp.X, mp.Y)
    else
        local vp = workspace.CurrentCamera.ViewportSize
        fovCircle.Position = UDim2.fromOffset(vp.X/2, vp.Y/2)
    end
end)

-- 타겟 탐색
local function isEnemy(plr)
    if plr == lp then return false end
    if not state.aimTeam and plr.Team and lp.Team and plr.Team == lp.Team then return false end
    return true
end

local function getPart(char)
    if not char then return nil end
    if state.aimPart == "Head" then return char:FindFirstChild("Head") end
    if state.aimPart == "HumanoidRootPart" then return char:FindFirstChild("HumanoidRootPart") end
    if state.aimPart == "UpperTorso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

local npcCache = {}
local npcCacheTime = 0

RunService.Heartbeat:Connect(function()
    if tick() - npcCacheTime < 0.5 then return end
    npcCacheTime = tick()
    if not state.aimNPC then npcCache = {}; return end
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

local function closest()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local center = state.aimMouseMode and mousePos() or Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    local best, bestD = nil, state.aimFOV/2

    for _, p in ipairs(Players:GetPlayers()) do
        if isEnemy(p) then
            local c = p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            local pt = getPart(c)
            if h and h.Health > 0 and pt then
                local sp, on = cam:WorldToViewportPoint(pt.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= bestD and visible(pt.Position, c) then
                        best = {part = pt, char = c, dist = d}; bestD = d
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
                    if d <= bestD and visible(pt.Position, m) then
                        best = {part = pt, char = m, dist = d}; bestD = d
                    end
                end
            end
        end
    end
    return best
end

-- 마우스 이동
local function moveMouse(sx, sy)
    local m = lp:GetMouse(); if not m then return end
    local dx = sx - m.X
    local dy = sy - m.Y
    if math.abs(dx) < 1 and math.abs(dy) < 1 then return end
    pcall(function() mousemoverel(dx, dy) end)
end

-- 타겟 좌표 스무딩
local smoothPos = nil

RunService.RenderStepped:Connect(function(dt)
    if not state.aimOn or not state.aimActive then
        smoothPos = nil
        return
    end

    local t = closest()
    if not t or not t.part or not t.part.Parent then
        smoothPos = nil
        return
    end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local targetPos = t.part.Position
    if smoothPos then
        smoothPos = smoothPos:Lerp(targetPos, math.clamp(dt * 20, 0, 1))
    else
        smoothPos = targetPos
    end

    if state.aimMoveMouse then
        local sp, on = cam:WorldToViewportPoint(smoothPos)
        if on then moveMouse(sp.X, sp.Y) end
    end

    if state.aimMoveCam then
        local myPos = cam.CFrame.Position
        local dir = (smoothPos - myPos).Unit
        local tcf = CFrame.lookAt(myPos, myPos + dir)
        local k = math.clamp(dt * 10 * state.aimSmooth, 0, 1)
        cam.CFrame = cam.CFrame:Lerp(tcf, k)
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 and state.aimOn then
        if state.aimHold then
            state.aimActive = true
        else
            state.aimActive = not state.aimActive
        end
    end
end)

UIS.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if state.aimHold then state.aimActive = false end
    end
end)

-- 히트박스
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
            hbData[model][p] = {
                size = p.Size, trans = p.Transparency, col = p.Color,
                mat = p.Material, col2 = p.CanCollide,
            }
        end
    end
end

local function applyHb(model)
    if not model or model == lp.Character then return end
    if state.hbOn then
        saveHb(model)
        for _, p in ipairs(model:GetDescendants()) do
            if isHbPart(p) then
                pcall(function()
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
                    pcall(function()
                        p.Size = i.size
                        p.Transparency = i.trans
                        p.Color = i.col
                        p.Material = i.mat
                        p.CanCollide = i.col2
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
        for _, o in ipairs(npcCache) do
            if o and o.Parent then applyHb(o) end
        end
    end
end

local function setHb(on)
    state.hbOn = on
    applyHbAll()
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if state.hbOn then applyHbAll() end
    end
end)

-- 댄스
local curMusic, curTrack

local DANCES = {
    dance1 = "rbxassetid://507771019",
    dance2 = "rbxassetid://507776043",
    dance3 = "rbxassetid://507776720",
    floss = "rbxassetid://5915671715",
    dorky = "rbxassetid://5915714726",
    monkey = "rbxassetid://5915755123",
    robot = "rbxassetid://507776879",
}

local SONGS = {
    default = "rbxassetid://1837879082",
    party = "rbxassetid://1837879082",
    funny = "rbxassetid://1836315841",
    epic = "rbxassetid://1836190483",
}

local function stopDance()
    if curMusic then pcall(function() curMusic:Destroy() end); curMusic = nil end
    if curTrack then pcall(function() curTrack:Stop() end); curTrack = nil end
end

local function dance(key, song)
    stopDance()
    local c = lp.Character; if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid"); if not h then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p.Color = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255)) end)
        end
    end
    local anim = Instance.new("Animation")
    anim.AnimationId = DANCES[key] or DANCES.dance1
    pcall(function()
        curTrack = h:LoadAnimation(anim)
        curTrack.Priority = Enum.AnimationPriority.Action
        curTrack.Looped = true
        curTrack:Play()
    end)
    local s = Instance.new("Sound")
    s.SoundId = SONGS[song] or SONGS.default
    s.Volume = 2
    s.Looped = true
    s.Parent = c:FindFirstChild("Head") or c
    pcall(function() s:Play() end)
    curMusic = s
    notify("춤 재생")
end

-- 명령어
local Cmds = {}
local function cmd(name, desc, fn) Cmds[name:lower()] = {name = name, desc = desc, fn = fn} end

cmd("fly", "플라이", function(a)
    local mode = a[#a] and a[#a]:lower()
    if mode == "off" then setFly(false); notify("플라이 OFF"); return end
    local n = numArg(a, 1); if n then state.flySpeed = math.clamp(n, 10, 500) end
    setFly(true); notify("플라이 ON")
end)

cmd("noclip", "노클립", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setNoclip(true); notify("노클립 ON")
    elseif mode == "off" then setNoclip(false); notify("노클립 OFF")
    else setNoclip(not state.noclip); notify("노클립 " .. (state.noclip and "ON" or "OFF")) end
end)

cmd("speed", "속도", function(a)
    local n = numArg(a, 1); if not n then notify(".speed 100"); return end
    state.ws = math.clamp(n, 0, 1000); applyWS(); notify("속도 " .. state.ws)
end)

cmd("jump", "점프력", function(a)
    local n = numArg(a, 1); if not n then notify(".jump 100"); return end
    state.jp = math.clamp(n, 0, 1000); applyJP(); notify("점프 " .. state.jp)
end)

cmd("hipheight", "HipHeight", function(a)
    local n = numArg(a, 1); if not n then notify(".hipheight 5"); return end
    state.hipHeight = n
    local h = hum(); if h then h.HipHeight = n end
    notify("HipHeight " .. n)
end)

cmd("fast", "빠르게", function()
    state.ws = 100; applyWS(); notify("빠르게")
end)

cmd("slow", "느리게", function()
    state.ws = 8; applyWS(); notify("느리게")
end)

cmd("superjump", "슈퍼점프", function()
    state.jp = 300; applyJP(); notify("슈퍼점프")
end)

cmd("heavyjump", "무거운 점프", function()
    state.jp = 10; applyJP(); notify("무거운 점프")
end)

cmd("god", "무적", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then state.god = true; notify("무적 ON")
    elseif mode == "off" then state.god = false; notify("무적 OFF")
    else state.god = not state.god; notify("무적 " .. (state.god and "ON" or "OFF")) end
end)

cmd("heal", "회복", function()
    local h = hum(); if h then h.Health = h.MaxHealth; notify("회복") end
end)

cmd("health", "체력 설정", function(a)
    local n = numArg(a, 1); if not n then notify(".health 100"); return end
    local h = hum(); if h then h.Health = n; notify("체력 " .. n) end
end)

cmd("damage", "데미지", function(a)
    local n = numArg(a, 1); if not n then notify(".damage 50"); return end
    local h = hum(); if h then h:TakeDamage(n); notify("데미지 " .. n) end
end)

cmd("kill", "즉사", function()
    local h = hum(); if h then h.Health = 0; notify("즉사") end
end)

cmd("invis", "투명화", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setInvis(true); notify("투명화 ON")
    elseif mode == "off" then setInvis(false); notify("투명화 OFF")
    else setInvis(not state.invis); notify("투명화 " .. (state.invis and "ON" or "OFF")) end
end)

cmd("visible", "투명 해제", function()
    setInvis(false); notify("투명 OFF")
end)

cmd("spin", "회전", function(a)
    local n = numArg(a, 1); if n then state.spinSpeed = n end
    setSpin(not state.spinning); notify("회전 " .. (state.spinning and "ON" or "OFF"))
end)

cmd("fling", "날려버리기", function()
    local p = hrp()
    if p then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 200, 0)
        bv.Parent = p
        task.wait(0.5)
        bv:Destroy()
    end
end)

cmd("explode", "폭발", function()
    local p = hrp()
    if p then
        local e = Instance.new("Explosion")
        e.Position = p.Position
        e.BlastRadius = 10
        e.Parent = workspace
    end
end)

cmd("re", "리스폰", function() respawnNormal(); notify("리스폰") end)
cmd("res", "제자리 리스폰", function() respawnHere(); notify("제자리") end)
cmd("revive", "부활", function() revive(); notify("부활") end)
cmd("rv", "부활", function() revive(); notify("부활") end)

cmd("freeze", "정지", function()
    state.ws = 0; applyWS(); notify("정지")
end)

cmd("unfreeze", "정지 해제", function()
    state.ws = 16; applyWS(); notify("해제")
end)

cmd("normal", "일반 상태", function()
    state.ws = 16; state.jp = 50; applyWS(); applyJP(); notify("일반")
end)

cmd("tp", "플레이어 TP", function(a)
    local n = a[1]; if not n then notify(".tp 이름"); return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Name:lower():sub(1, #n) == n:lower() then
            tpTo(p); notify(p.Name .. "에게 TP"); return
        end
    end
    notify("없음")
end)

cmd("tppos", "좌표 TP", function(a)
    local x, y, z = tonumber(a[1]), tonumber(a[2]), tonumber(a[3])
    if not (x and y and z) then notify(".tppos 0 50 0"); return end
    tpPos(x, y, z); notify("TP")
end)

cmd("touchtp", "터치 TP", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setTouchTP(true); notify("터치 TP ON")
    elseif mode == "off" then setTouchTP(false); notify("터치 TP OFF")
    else setTouchTP(not state.touchTP); notify("터치 TP " .. (state.touchTP and "ON" or "OFF")) end
end)

cmd("aim", "에임봇", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then state.aimOn = true; notify("에임 ON")
    elseif mode == "off" then state.aimOn = false; notify("에임 OFF")
    else state.aimOn = not state.aimOn; notify("에임 " .. (state.aimOn and "ON" or "OFF")) end
    updateCircle()
end)

cmd("aimfov", "에임 FOV", function(a)
    local n = numArg(a, 1); if not n then notify(".aimfov 200"); return end
    state.aimFOV = math.clamp(n, 20, 800); updateCircle(); notify("FOV " .. state.aimFOV)
end)

cmd("aimsmooth", "에임 부드러움", function(a)
    local n = numArg(a, 1); if not n then notify(".aimsmooth 0.3"); return end
    state.aimSmooth = math.clamp(n, 0.05, 1); notify("부드러움 " .. state.aimSmooth)
end)

cmd("aimwall", "벽 뒤 무시", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then state.aimVisible = true; notify("벽 뒤 무시 ON")
    elseif mode == "off" then state.aimVisible = false; notify("벽 뚫기 ON")
    else state.aimVisible = not state.aimVisible; notify("벽 뒤 무시 " .. (state.aimVisible and "ON" or "OFF")) end
end)

cmd("aimpart", "조준 부위", function(a)
    local p = a[1]
    if p == "head" then state.aimPart = "Head"
    elseif p == "hrp" then state.aimPart = "HumanoidRootPart"
    elseif p == "torso" then state.aimPart = "UpperTorso"
    else notify(".aimpart head/hrp/torso"); return end
    notify("조준 " .. state.aimPart)
end)

cmd("aimhold", "우클릭 유지/토글", function(a)
    state.aimHold = not state.aimHold
    notify("에임 모드 " .. (state.aimHold and "홀드" or "토글"))
end)

cmd("hb", "히트박스", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then setHb(true); notify("히트박스 ON")
    elseif mode == "off" then setHb(false); notify("히트박스 OFF")
    else setHb(not state.hbOn); notify("히트박스 " .. (state.hbOn and "ON" or "OFF")) end
end)

cmd("hbsize", "히트박스 크기", function(a)
    local n = numArg(a, 1); if not n then notify(".hbsize 10"); return end
    state.hbSize = math.clamp(n, 1, 50); applyHbAll(); notify("크기 " .. state.hbSize)
end)

cmd("dance", "춤", function(a)
    dance(a[1] or "dance1", a[2] or "party")
end)

cmd("stopdance", "춤 정지", function() stopDance(); notify("정지") end)
cmd("floss", "플로스", function() dance("floss", "party") end)
cmd("dorky", "도키", function() dance("dorky", "funny") end)
cmd("monkey", "몽키", function() dance("monkey", "party") end)
cmd("robot", "로봇", function() dance("robot", "epic") end)

cmd("macro", "매크로", function(a)
    local mode = a[1] and a[1]:lower()
    if mode == "on" then startMacro(); notify("매크로 ON")
    elseif mode == "off" then stopMacro(); notify("매크로 OFF")
    else
        if state.macroOn then stopMacro(); notify("매크로 OFF")
        else startMacro(); notify("매크로 ON") end
    end
end)

cmd("bright", "밝기", function(a)
    local n = numArg(a, 1); if not n then notify(".bright 30"); return end
    state.bright = math.clamp(n, 0, 60); applyLights(); applyLighting(); notify("밝기 " .. state.bright)
end)

cmd("fov", "FOV", function(a)
    local n = numArg(a, 1); if not n then notify(".fov 70"); return end
    state.fov = math.clamp(n, 20, 120); applyFOV(); notify("FOV " .. state.fov)
end)

cmd("zoom", "줌인", function() state.fov = 30; applyFOV(); notify("줌인") end)
cmd("unzoom", "줌아웃", function() state.fov = 70; applyFOV(); notify("줌아웃") end)

cmd("fullbright", "풀브라이트", function()
    state.bright = 60; state.range = 200
    applyLights(); applyLighting(); notify("풀브라이트")
end)

cmd("reset", "리셋", function()
    state.ws = nil; state.jp = nil; state.fov = nil; state.bright = nil; state.hipHeight = nil
    state.god = false
    setFly(false); setNoclip(false); setInvis(false); setSpin(false)
    setTouchTP(false); setHb(false); stopDance()
    state.aimOn = false; updateCircle()
    applyFOV(); applyLights(); applyLighting()
    notify("리셋")
end)

cmd("help", "명령어 목록", function()
    local t = {}
    for k, _ in pairs(Cmds) do table.insert(t, state.prefix .. k) end
    table.sort(t)
    notify(table.concat(t, " "), "명령어 " .. #t .. "개")
end)

cmd("cmds", "명령어 목록", function()
    Cmds.help.fn({})
end)

-- 채팅 훅
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

pcall(function()
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
                        pcall(function() m:Destroy() end)
                        onChat(t)
                    end
                end)
            end
        end
    end
end)

pcall(function() lp.Chatted:Connect(onChat) end)

lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    local wasFly = state.fly
    stopFly()
    if spinConn then spinConn:Disconnect(); spinConn = nil end
    state.spinning = false
    state.invis = false
    applyWS(); applyJP(); applyFOV(); applyLights()
    if state.noclip then task.wait(0.2); doNoclip() end
    if wasFly then task.wait(0.3); startFly() end
end)

-- UI
local Window = Rayfield:CreateWindow({
    Name = "왕웨이 따라가는 핵패널",
    LoadingTitle = "로드중",
    LoadingSubtitle = "by 왕웨이",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false,
    Size = UDim2.fromOffset(1150, 320),
})

-- 에임
local AimTab = Window:CreateTab("에임", 4483362458)

AimTab:CreateSection("에임봇")

AimTab:CreateToggle({
    Name = "에임봇",
    CurrentValue = false, Flag = "aOn",
    Callback = function(v) state.aimOn = v; updateCircle() end
})

AimTab:CreateToggle({
    Name = "토글 모드 (OFF = 우클릭 홀드)",
    CurrentValue = false, Flag = "aHold",
    Callback = function(v) state.aimHold = not v end
})

AimTab:CreateToggle({
    Name = "마우스 위치 FOV",
    CurrentValue = true, Flag = "aMM",
    Callback = function(v) state.aimMouseMode = v end
})

AimTab:CreateSlider({
    Name = "FOV 크기",
    Range = {20, 800}, Increment = 5, Suffix = "px",
    CurrentValue = 150, Flag = "aFov",
    Callback = function(v) state.aimFOV = v; updateCircle() end
})

AimTab:CreateToggle({
    Name = "FOV 원 표시",
    CurrentValue = true, Flag = "aCircle",
    Callback = function(v) state.aimCircle = v; updateCircle() end
})

AimTab:CreateSlider({
    Name = "부드러움",
    Range = {0.05, 1}, Increment = 0.05,
    CurrentValue = 0.3, Flag = "aSm",
    Callback = function(v) state.aimSmooth = v end
})

AimTab:CreateToggle({
    Name = "마우스 커서 이동",
    CurrentValue = true, Flag = "aMoveM",
    Callback = function(v) state.aimMoveMouse = v end
})

AimTab:CreateToggle({
    Name = "카메라 회전",
    CurrentValue = false, Flag = "aMoveC",
    Callback = function(v) state.aimMoveCam = v end
})

AimTab:CreateToggle({
    Name = "벽 뒤 무시 (OFF = 벽 뚫고 조준)",
    CurrentValue = true, Flag = "aVis",
    Callback = function(v) state.aimVisible = v end
})

AimTab:CreateDropdown({
    Name = "조준 부위",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = {"Head"},
    Flag = "aPart",
    Callback = function(o) state.aimPart = o[1] or "Head" end
})

AimTab:CreateToggle({
    Name = "같은 팀 무시",
    CurrentValue = false, Flag = "aTeam",
    Callback = function(v) state.aimTeam = v end
})

AimTab:CreateToggle({
    Name = "더미/NPC 타겟",
    CurrentValue = true, Flag = "aNPC",
    Callback = function(v) state.aimNPC = v end
})

-- 히트박스
local HbTab = Window:CreateTab("히트박스", 4483362458)

HbTab:CreateToggle({
    Name = "히트박스 ON/OFF",
    CurrentValue = false, Flag = "hbOn",
    Callback = function(v) setHb(v) end
})

HbTab:CreateToggle({
    Name = "더미/NPC 적용",
    CurrentValue = true, Flag = "hbNPC",
    Callback = function(v)
        state.hbNPC = v
        if state.hbOn then applyHbAll() end
    end
})

HbTab:CreateSlider({
    Name = "크기",
    Range = {1, 50}, Increment = 1, Suffix = "studs",
    CurrentValue = 10, Flag = "hbSize",
    Callback = function(v)
        state.hbSize = v
        if state.hbOn then applyHbAll() end
    end
})

HbTab:CreateSlider({
    Name = "투명도",
    Range = {0, 1}, Increment = 0.05,
    CurrentValue = 0.5, Flag = "hbTr",
    Callback = function(v)
        state.hbTrans = v
        if state.hbOn then applyHbAll() end
    end
})

HbTab:CreateColorPicker({
    Name = "색상",
    Color = Color3.fromRGB(255, 0, 0), Flag = "hbCol",
    Callback = function(c)
        state.hbColor = c
        if state.hbOn then applyHbAll() end
    end
})

-- 이동
local MTab = Window:CreateTab("이동", 4483362458)

MTab:CreateSection("속도 & 점프")

MTab:CreateSlider({
    Name = "이동 속도",
    Range = {0, 1000}, Increment = 1, Suffix = "studs",
    CurrentValue = 16, Flag = "ws",
    Callback = function(v) state.ws = v; applyWS() end
})

MTab:CreateSlider({
    Name = "점프력",
    Range = {0, 1000}, Increment = 1, Suffix = "power",
    CurrentValue = 50, Flag = "jp",
    Callback = function(v) state.jp = v; applyJP() end
})

MTab:CreateSlider({
    Name = "HipHeight",
    Range = {0, 20}, Increment = 0.5,
    CurrentValue = 2, Flag = "hh",
    Callback = function(v)
        state.hipHeight = v
        local h = hum(); if h then h.HipHeight = v end
    end
})

MTab:CreateSection("플라이 / 노클립")

MTab:CreateSlider({
    Name = "플라이 속도",
    Range = {10, 500}, Increment = 1, Suffix = "studs/s",
    CurrentValue = 60, Flag = "fSpd",
    Callback = function(v) state.flySpeed = v end
})

MTab:CreateToggle({
    Name = "플라이",
    CurrentValue = false, Flag = "fly",
    Callback = function(v) setFly(v) end
})

MTab:CreateToggle({
    Name = "노클립",
    CurrentValue = false, Flag = "nc",
    Callback = function(v) setNoclip(v) end
})

MTab:CreateSection("상태")

MTab:CreateToggle({
    Name = "무적",
    CurrentValue = false, Flag = "god",
    Callback = function(v) state.god = v end
})

MTab:CreateToggle({
    Name = "투명화",
    CurrentValue = false, Flag = "invis",
    Callback = function(v) setInvis(v) end
})

MTab:CreateToggle({
    Name = "회전",
    CurrentValue = false, Flag = "spin",
    Callback = function(v) setSpin(v) end
})

MTab:CreateSection("리스폰")

MTab:CreateButton({Name = "리스폰 (.re)", Callback = function() respawnNormal() end})
MTab:CreateButton({Name = "제자리 리스폰 (.res)", Callback = function() respawnHere() end})
MTab:CreateButton({Name = "부활 (.revive)", Callback = function() revive() end})

-- 시야
local VTab = Window:CreateTab("시야", 4483362458)

VTab:CreateSlider({
    Name = "밝기",
    Range = {0, 60}, Increment = 1,
    CurrentValue = 10, Flag = "br",
    Callback = function(v) state.bright = v; applyLights(); applyLighting() end
})

VTab:CreateSlider({
    Name = "라이트 범위",
    Range = {0, 200}, Increment = 1, Suffix = "studs",
    CurrentValue = 60, Flag = "rng",
    Callback = function(v) state.range = v; applyLights() end
})

VTab:CreateSlider({
    Name = "FOV",
    Range = {20, 120}, Increment = 1,
    CurrentValue = 70, Flag = "fov",
    Callback = function(v) state.fov = v; applyFOV() end
})

VTab:CreateButton({Name = "FOV 리셋", Callback = function() state.fov = 70; applyFOV() end})

-- TP
local TTab = Window:CreateTab("TP", 4483362458)

TTab:CreateToggle({
    Name = "터치 TP",
    CurrentValue = false, Flag = "tTP",
    Callback = function(v) setTouchTP(v) end
})

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
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then table.insert(t, p.Name) end
        end
        return t
    end)(),
    CurrentOption = {"없음"},
    Flag = "selP",
    Callback = function() end
})

TTab:CreateButton({
    Name = "선택한 플레이어에게 TP",
    Callback = function()
        local s = Rayfield.Flags.selP
        if not s then notify("선택 안됨"); return end
        local n = type(s) == "table" and s[1] or s
        local t = Players:FindFirstChild(n)
        if t then tpTo(t); notify(n .. "에게 TP") end
    end
})

TTab:CreateButton({Name = "목록 새로고침", Callback = refreshP})

Players.PlayerAdded:Connect(function() task.wait(0.3); refreshP() end)
Players.PlayerRemoving:Connect(function() task.wait(0.3); refreshP() end)

-- 매크로
local McTab = Window:CreateTab("매크로", 4483362458)

McTab:CreateToggle({
    Name = "매크로 ON/OFF",
    CurrentValue = false, Flag = "mOn",
    Callback = function(v)
        if v then state.macroOn = true; notify("매크로 ON")
        else stopMacro(); notify("매크로 OFF") end
    end
})

McTab:CreateSlider({
    Name = "터치 간격 (ms)",
    Range = {1, 100}, Increment = 1, Suffix = "ms",
    CurrentValue = 50, Flag = "mD",
    Callback = function(v) state.macroDelay = v / 1000 end
})

McTab:CreateButton({Name = "매크로 시작", Callback = function() startMacro() end})
McTab:CreateButton({Name = "매크로 중지", Callback = function() stopMacro() end})

-- 명령어 탭
local CTab = Window:CreateTab("명령어", 4483362458)

CTab:CreateSection("명령어 실행")

local function buildList()
    local t = {}
    for k, _ in pairs(Cmds) do table.insert(t, k) end
    table.sort(t)
    return t
end

local function buildOptions()
    local t = buildList()
    local opts = {}
    for _, k in ipairs(t) do
        table.insert(opts, k .. " — " .. (Cmds[k].desc or ""))
    end
    return opts
end

local cmdDropdown
cmdDropdown = CTab:CreateDropdown({
    Name = "명령어 선택 (즉시 실행)",
    Options = buildOptions(),
    CurrentOption = {"선택..."},
    Flag = "cmdSel",
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
        pcall(function() cmdDropdown:Refresh(buildOptions(), true) end)
    end
})

CTab:CreateButton({
    Name = "명령어 목록 새로고침",
    Callback = function()
        pcall(function() cmdDropdown:Refresh(buildOptions(), true) end)
        notify("명령어 " .. #buildList() .. "개")
    end
})

CTab:CreateSection("전체 명령어")

CTab:CreateParagraph({
    Title = "명령어 (" .. #buildList() .. "개)",
    Content = table.concat(buildList(), "  ")
})

CTab:CreateSection("접두사")

CTab:CreateInput({
    Name = "접두사 변경",
    CurrentValue = state.prefix,
    PlaceholderText = ".",
    RemoveTextAfterFocusLost = false,
    Flag = "pxIn",
    Callback = function(t)
        if not t or t == "" then notify("비울 수 없음"); return end
        if #t > 3 then notify("최대 3자"); return end
        state.prefix = t
        notify("접두사 '" .. t .. "'")
    end
})

CTab:CreateButton({Name = "접두사 '.'", Callback = function() state.prefix = "."; notify("'.'") end})
CTab:CreateButton({Name = "접두사 ';'", Callback = function() state.prefix = ";"; notify("';'") end})
CTab:CreateButton({Name = "접두사 '!'", Callback = function() state.prefix = "!"; notify("'!'") end})

CTab:CreateSection("시스템")

CTab:CreateToggle({
    Name = "채팅 명령어 ON/OFF",
    CurrentValue = true, Flag = "chatOn",
    Callback = function(v) state.chatOn = v end
})

-- 단축키
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.Z then
        setFly(not state.fly)
    elseif k == Enum.KeyCode.R then
        respawnNormal()
    end
end)

Rayfield:Notify({Title = "왕웨이 따라가는 핵패널", Content = "로드 완료 / " .. state.prefix .. "help", Duration = 3})
