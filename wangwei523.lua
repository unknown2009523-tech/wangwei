-- =========================================================
--  왕웨이 따라가는 허브  V2
--  HD Admin 스타일 명령어 · 클릭 실행 · 댄스/음악 · 부활
--  Speed · Jump · Fly · Noclip · Brightness · FOV · TP · Macro
--  made by 왕웨이
-- =========================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting   = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local lp         = Players.LocalPlayer

pcall(function() UIS.MouseIconEnabled = true end)

local CFG = {
    SpeedDefault = 16, SpeedMin = 0,  SpeedMax = 1000,
    JumpDefault  = 50, JumpMin  = 0,  JumpMax  = 1000,
    FlySpeed     = 60,
    BrightMin    = 0,  BrightMax = 60,
    RangeMin     = 0,  RangeMax  = 200,
    FOVMin       = 20, FOVMax    = 120,
    PlayerLightBri = 10, PlayerLightRng = 60,
    MacroInterval = 0.05,
}

local state = {
    walkSpeed   = CFG.SpeedDefault,
    jumpPower   = CFG.JumpDefault,
    flySpeed    = CFG.FlySpeed,
    brightness  = 10,
    range       = 60,
    playerBright= CFG.PlayerLightBri,
    playerRange = CFG.PlayerLightRng,
    fov         = 70,
    noclip      = false,
    fly         = false,
    fovLock     = false,
    macroOn     = false,
    macroX      = 0,
    macroY      = 0,
    macroInterval = CFG.MacroInterval,
    godMode     = false,
    invisible   = false,
    spinOn      = false,
    spinSpeed   = 10,
    chatPrefix  = ".",
    chatEnabled = true,
    touchTP     = false,
    lastAliveCF = nil,
    hipHeight   = 2,
}

-- =========================================================
-- 유틸
-- =========================================================
local function getHum()
    local char = lp.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    local char = lp.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function notify(content, title)
    pcall(function()
        Rayfield:Notify({Title = title or "왕웨이 따라가는 허브", Content = content, Duration = 2})
    end)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "왕웨이 따라가는 허브",
            Text = content,
            Duration = 2,
        })
    end)
end

local function argNum(args, idx)
    idx = idx or 1
    for i = idx, #args do
        local n = tonumber(args[i])
        if n then return n, i end
    end
    return nil, nil
end

-- =========================================================
-- 1. 스피드 / 점프 (보완)
-- =========================================================
local function applySpeed()
    local hum = getHum()
    if hum then pcall(function() hum.WalkSpeed = state.walkSpeed end) end
end

local function applyJump()
    local hum = getHum()
    if not hum then return end
    pcall(function() hum.UseJumpPower = true end)
    pcall(function() hum.JumpPower = state.jumpPower end)
    pcall(function() hum.JumpHeight = state.jumpPower / 7.5 end)
end

local function applyMovement() applySpeed(); applyJump() end

-- 지속 적용 (게임이 값을 덮어쓰는 것 방지)
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if not hum then return end
    if math.abs(hum.WalkSpeed - state.walkSpeed) > 0.5 then
        pcall(function() hum.WalkSpeed = state.walkSpeed end)
    end
    if hum.UseJumpPower then
        if math.abs(hum.JumpPower - state.jumpPower) > 0.5 then
            pcall(function() hum.JumpPower = state.jumpPower end)
        end
    else
        local t = state.jumpPower / 7.5
        if math.abs(hum.JumpHeight - t) > 0.5 then
            pcall(function() hum.JumpHeight = t end)
        end
    end
    -- HipHeight 지속 적용
    if math.abs(hum.HipHeight - state.hipHeight) > 0.1 then
        pcall(function() hum.HipHeight = state.hipHeight end)
    end
end)

-- =========================================================
-- 1-1. 마지막 생존 위치 저장
-- =========================================================
local lastSaveTime = 0
RunService.Heartbeat:Connect(function(dt)
    lastSaveTime += dt
    if lastSaveTime < 0.5 then return end
    lastSaveTime = 0
    local hum = getHum()
    local hrp = getHRP()
    if hum and hrp and hum.Health > 0 then
        state.lastAliveCF = hrp.CFrame
    end
end)

-- =========================================================
-- 2. 노클립 (보완 — 캐릭터 리스폰 후 재연결)
-- =========================================================
local function doNoclip()
    if not state.noclip then return end
    local char = lp.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end

RunService.Stepped:Connect(doNoclip)

local function setNoclip(on)
    state.noclip = on
    if on then
        doNoclip()
    else
        local char = lp.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

-- =========================================================
-- 3. 플라이 (보완 — 속도 실시간, 리스폰 자동 재시작)
-- =========================================================
local flyConn, bodyVel, bodyGyro, flyHeartbeat

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyHeartbeat then flyHeartbeat:Disconnect(); flyHeartbeat = nil end
    local char = lp.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp then
            local v = hrp:FindFirstChild("BodyVelocity");  if v then v:Destroy() end
            local g = hrp:FindFirstChild("BodyGyro");     if g then g:Destroy() end
            local a = hrp:FindFirstChild("BodyAngularVelocity"); if a then a:Destroy() end
        end
        if hum then hum.PlatformStand = false end
    end
    bodyVel, bodyGyro = nil, nil
end

local function startFly()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    stopFly()

    bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVel.Velocity = Vector3.zero
    bodyVel.Parent = hrp

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.P = 10000; bodyGyro.D = 500
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp

    -- PlatformStand 유지 (게임이 false로 되돌리면 다시 true)
    flyHeartbeat = RunService.Heartbeat:Connect(function()
        if hum.Parent and hum.PlatformStand == false then
            pcall(function() hum.PlatformStand = true end)
        end
    end)

    flyConn = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam or not hrp.Parent then return end
        local mv = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv -= Vector3.new(0,1,0) end
        if mv.Magnitude > 0 then mv = mv.Unit * state.flySpeed end
        pcall(function()
            bodyVel.Velocity = mv
            bodyGyro.CFrame  = cam.CFrame
        end)
    end)
end

local function setFly(on)
    state.fly = on
    if on then startFly() else stopFly() end
end

-- =========================================================
-- 4. God / Invisible / Spin
-- =========================================================
RunService.Heartbeat:Connect(function()
    if state.godMode then
        local hum = getHum()
        if hum and hum.Health < hum.MaxHealth then
            pcall(function() hum.Health = hum.MaxHealth end)
        end
    end
end)

local function setInvisible(on)
    state.invisible = on
    local char = lp.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
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

local spinConn
local function setSpin(on)
    state.spinOn = on
    if spinConn then spinConn:Disconnect(); spinConn = nil end
    if not on then return end
    spinConn = RunService.Heartbeat:Connect(function(dt)
        local hrp = getHRP()
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(state.spinSpeed) * dt * 60, 0)
        end
    end)
end

-- =========================================================
-- 5. 밝기 / 라이트
-- =========================================================
local function attachPlayerLight()
    local char = lp.Character or lp.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    local pl = hrp:FindFirstChild("ExecutorSightLight")
    if not pl then
        pl = Instance.new("PointLight")
        pl.Name = "ExecutorSightLight"
        pl.Color = Color3.fromRGB(255,255,255)
        pl.Shadows = false
        pl.Parent = hrp
    end
    pl.Brightness = state.playerBright
    pl.Range      = state.playerRange
end

local function applyLights()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Light") and obj.Name ~= "ExecutorSightLight" then
            pcall(function()
                obj.Brightness = state.brightness
                obj.Range      = state.range
                obj.Shadows    = false
            end)
        end
    end
    local char = lp.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pl = char.HumanoidRootPart:FindFirstChild("ExecutorSightLight")
        if pl then
            pl.Brightness = state.playerBright
            pl.Range      = state.playerRange
        end
    end
end

local function applyLighting()
    pcall(function()
        Lighting.Ambient        = Color3.fromRGB(150,150,150)
        Lighting.OutdoorAmbient = Color3.fromRGB(150,150,150)
        Lighting.Brightness     = math.clamp(state.brightness/5, 1, 10)
        Lighting.GlobalShadows  = false
        Lighting.FogEnd         = 100000
    end)
end

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Light") and obj.Name ~= "ExecutorSightLight" then
        task.wait(0.1)
        pcall(function()
            obj.Brightness = state.brightness
            obj.Range      = state.range
            obj.Shadows    = false
        end)
    end
end)

-- =========================================================
-- 6. FOV
-- =========================================================
local function applyFOV()
    local cam = workspace.CurrentCamera
    if not cam then return end
    pcall(function()
        if state.fovLock then cam.CameraType = Enum.CameraType.Scriptable end
        if math.abs(cam.FieldOfView - state.fov) > 0.1 then
            cam.FieldOfView = state.fov
        end
    end)
end

RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if math.abs(cam.FieldOfView - state.fov) > 0.1 then
        pcall(function() cam.FieldOfView = state.fov end)
    end
end)

pcall(function() lp.CameraMaxZoomDistance = 200 end)

-- =========================================================
-- 7. 리스폰 / 부활 / TP
-- =========================================================
local function normalRespawn()
    pcall(function() lp:LoadCharacter() end)
end

local function respawnHere()
    local hrp = getHRP()
    local saveCF = hrp and hrp.CFrame or state.lastAliveCF
    pcall(function() lp:LoadCharacter() end)
    task.spawn(function()
        local newChar = lp.Character or lp.CharacterAdded:Wait()
        local newHrp = newChar:WaitForChild("HumanoidRootPart", 5)
        if newHrp and saveCF then
            task.wait(0.1)
            newHrp.CFrame = saveCF + Vector3.new(0, 3, 0)
        end
    end)
end

local function revive()
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local saveCF = hrp and hrp.CFrame or state.lastAliveCF or CFrame.new(0, 50, 0)

    if hum then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Physics) end)
        pcall(function() hum.Health = hum.MaxHealth end)
        pcall(function() hum.PlatformStand = false end)
        pcall(function() hum.Sit = false end)
    end

    pcall(function()
        local cam = workspace.CurrentCamera
        cam.CameraSubject = hum
        cam.CameraType = Enum.CameraType.Custom
    end)

    task.wait(0.2)
    local nowHum = getHum()
    if not nowHum or nowHum.Health <= 0 then
        pcall(function() lp:LoadCharacter() end)
        task.spawn(function()
            local newChar = lp.Character or lp.CharacterAdded:Wait()
            local newHrp = newChar:WaitForChild("HumanoidRootPart", 5)
            if newHrp then
                task.wait(0.1)
                newHrp.CFrame = saveCF + Vector3.new(0, 3, 0)
            end
            task.wait(0.2)
            pcall(function()
                local cam = workspace.CurrentCamera
                local nh = newChar:FindFirstChildOfClass("Humanoid")
                if cam and nh then
                    cam.CameraSubject = nh
                    cam.CameraType = Enum.CameraType.Custom
                end
            end)
        end)
    end
end

local function teleportTo(targetPlayer)
    if not targetPlayer or targetPlayer == lp then return end
    local myHrp = getHRP()
    if not myHrp then return end
    local tHrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not tHrp then return end
    myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 2)
    task.spawn(function()
        for _ = 1, 5 do
            task.wait(0.15)
            local myH = getHRP()
            local tH  = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not (myH and tH) then break end
            if (myH.Position - tH.Position).Magnitude > 10 then
                myH.CFrame = tH.CFrame * CFrame.new(0, 0, 2)
            else break end
        end
    end)
end

local function teleportToPosition(x, y, z)
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(x, y, z) end
end

-- =========================================================
-- 7-4. 터치 TP
-- =========================================================
local touchTPConn
local function startTouchTP()
    if touchTPConn then touchTPConn:Disconnect(); touchTPConn = nil end
    touchTPConn = UIS.InputBegan:Connect(function(input, gpe)
        if not state.touchTP then return end
        if gpe then return end

        if state.macroOn then
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                state.macroX = input.Position.X
                state.macroY = input.Position.Y
            end
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local cam = workspace.CurrentCamera
            if not cam then return end
            local mousePos = input.Position
            local ray = cam:ViewportPointToRay(mousePos.X, mousePos.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { lp.Character }
            local result = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
            local targetPos = result and (result.Position + Vector3.new(0, 3, 0))
                              or (ray.Origin + ray.Direction * 100)
            local hrp = getHRP()
            if hrp then
                hrp.CFrame = CFrame.new(targetPos)
                notify(string.format("터치 TP → %.0f, %.0f, %.0f", targetPos.X, targetPos.Y, targetPos.Z))
            end
        end
    end)
end

local function setTouchTP(on)
    state.touchTP = on
    if on then startTouchTP() else
        if touchTPConn then touchTPConn:Disconnect(); touchTPConn = nil end
    end
end

-- =========================================================
-- 8. 매크로
-- =========================================================
local macroThread = nil

local function startMacro()
    if macroThread then return end
    state.macroOn = true
    macroThread = task.spawn(function()
        while state.macroOn do
            if state.macroX > 0 and state.macroY > 0 then
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(state.macroX, state.macroY, 0, true, game, 0)
                    task.wait(0.01)
                    VirtualInputManager:SendMouseButtonEvent(state.macroX, state.macroY, 0, false, game, 0)
                end)
            end
            task.wait(state.macroInterval)
        end
    end)
end

local function stopMacro()
    state.macroOn = false
    macroThread = nil
end

UIS.InputBegan:Connect(function(input, gpe)
    if not state.macroOn then return end
    if state.touchTP then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if gpe then return end
        state.macroX = input.Position.X
        state.macroY = input.Position.Y
    end
end)

-- =========================================================
-- 9. 댄스 + 음악 (HD 스타일 조합)
-- =========================================================
local currentMusic = nil
local currentAnimTrack = nil

local DANCES = {
    dance1 = "rbxassetid://507771019",
    dance2 = "rbxassetid://507776043",
    dance3 = "rbxassetid://507776720",
    floss  = "rbxassetid://5915671715",
    dorky  = "rbxassetid://5915714726",
    monkey = "rbxassetid://5915755123",
}

local SONGS = {
    default = "rbxassetid://1837879082",
    party   = "rbxassetid://1837879082",
    funny   = "rbxassetid://1836315841",
}

local function stopDance()
    if currentMusic then pcall(function() currentMusic:Destroy() end); currentMusic = nil end
    if currentAnimTrack then pcall(function() currentAnimTrack:Stop() end); currentAnimTrack = nil end
end

local function startDance(danceKey, songKey)
    stopDance()

    local char = lp.Character
    if not char then notify("캐릭터 없음"); return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- 아바타 랜덤 색칠
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function()
                p.Color = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
            end)
        end
    end

    -- 춤
    local anim = Instance.new("Animation")
    anim.AnimationId = DANCES[danceKey] or DANCES.dance1
    local track
    pcall(function()
        track = hum:LoadAnimation(anim)
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = true
        track:Play()
    end)
    currentAnimTrack = track

    -- 노래
    local sound = Instance.new("Sound")
    sound.SoundId = SONGS[songKey] or SONGS.default
    sound.Volume = 2
    sound.Looped = true
    sound.Parent = char:FindFirstChild("Head") or char
    pcall(function() sound:Play() end)
    currentMusic = sound

    notify("춤 + 음악 (" .. danceKey .. " / " .. songKey .. ")")
end

-- =========================================================
-- 10. 채팅 명령어 시스템 (HD Admin 스타일)
-- =========================================================
local Commands = {}

local function registerCommand(name, desc, usage, fn)
    Commands[name:lower()] = {name = name, desc = desc, usage = usage, fn = fn}
end

-- --- 이동 ---
registerCommand("fly", "플라이 (HD: ;fly <plr> <speed>)", ".fly [speed] [on/off]", function(args)
    local mode = args[#args] and args[#args]:lower()
    if mode == "off" then setFly(false); notify("플라이 OFF"); return end
    local spd = argNum(args, 1)
    if spd then state.flySpeed = math.clamp(spd, 10, 500) end
    setFly(true)
    notify("플라이 ON" .. (spd and (" 속도 " .. spd) or ""))
end)

registerCommand("noclip", "노클립 (HD: ;noclip <plr>)", ".noclip [on/off]", function(args)
    local mode = args[1] and args[1]:lower()
    if mode == "on" then setNoclip(true); notify("노클립 ON")
    elseif mode == "off" then setNoclip(false); notify("노클립 OFF")
    else setNoclip(not state.noclip); notify("노클립 " .. (state.noclip and "ON" or "OFF")) end
end)
registerCommand("nc", "noclip 별칭", ".nc", function(a) Commands.noclip.fn(a) end)

registerCommand("speed", "이동속도 (HD: ;speed <plr> <num>)", ".speed <num>", function(args)
    local n = argNum(args, 1)
    if not n then notify("숫자 입력: .speed 100"); return end
    state.walkSpeed = math.clamp(n, CFG.SpeedMin, CFG.SpeedMax)
    applySpeed()
    notify("속도: " .. state.walkSpeed)
end)
registerCommand("ws", "speed 별칭", ".ws <num>", function(a) Commands.speed.fn(a) end)

registerCommand("jump", "점프력", ".jump <num>", function(args)
    local n = argNum(args, 1)
    if not n then notify("숫자 입력: .jump 100"); return end
    state.jumpPower = math.clamp(n, CFG.JumpMin, CFG.JumpMax)
    applyJump()
    notify("점프력: " .. state.jumpPower)
end)
registerCommand("jp", "jump 별칭", ".jp <num>", function(a) Commands.jump.fn(a) end)

registerCommand("jumpHeight", "점프 높이 (HD)", ".jumpHeight <num>", function(a) Commands.jump.fn(a) end)
registerCommand("jh", "jumpHeight 별칭", ".jh <num>", function(a) Commands.jump.fn(a) end)

registerCommand("flyspeed", "플라이 속도", ".flyspeed <num>", function(args)
    local n = argNum(args, 1)
    if not n then notify("숫자 입력"); return end
    state.flySpeed = math.clamp(n, 10, 500)
    notify("플라이 속도: " .. state.flySpeed)
end)
registerCommand("fs", "flyspeed 별칭", ".fs <num>", function(a) Commands.flyspeed.fn(a) end)

registerCommand("hipheight", "HipHeight (HD)", ".hipheight <num>", function(args)
    local n = argNum(args, 1)
    if not n then notify("숫자 입력: .hipheight 5"); return end
    state.hipHeight = n
    local hum = getHum()
    if hum then hum.HipHeight = n end
    notify("HipHeight: " .. n)
end)

-- HD Admin 스타일 빠른 속도 명령어
registerCommand("fast", "빠르게 (HD)", ".fast", function()
    state.walkSpeed = 100; applySpeed(); notify("빠르게 (100)")
end)
registerCommand("slow", "느리게 (HD)", ".slow", function()
    state.walkSpeed = 8; applySpeed(); notify("느리게 (8)")
end)
registerCommand("superJump", "슈퍼 점프 (HD)", ".superJump", function()
    state.jumpPower = 300; applyJump(); notify("슈퍼 점프 (300)")
end)
registerCommand("heavyJump", "무거운 점프 (HD)", ".heavyJump", function()
    state.jumpPower = 10; applyJump(); notify("무거운 점프 (10)")
end)

-- --- 상태 ---
registerCommand("god", "무적 (HD)", ".god [on/off]", function(args)
    local mode = args[1] and args[1]:lower()
    if mode == "on" then state.godMode = true; notify("무적 ON")
    elseif mode == "off" then state.godMode = false; notify("무적 OFF")
    else state.godMode = not state.godMode; notify("무적 " .. (state.godMode and "ON" or "OFF")) end
end)

registerCommand("heal", "회복 (HD)", ".heal", function()
    local hum = getHum()
    if hum then hum.Health = hum.MaxHealth; notify("회복") end
end)

registerCommand("health", "체력 설정 (HD)", ".health <num>", function(args)
    local n = argNum(args, 1)
    if not n then notify("숫자 입력: .health 100"); return end
    local hum = getHum()
    if hum then hum.Health = n; notify("체력: " .. n) end
end)

registerCommand("damage", "데미지 (HD)", ".damage <num>", function(args)
    local n = argNum(args, 1)
    if not n then notify("숫자 입력: .damage 50"); return end
    local hum = getHum()
    if hum then hum:TakeDamage(n); notify("데미지: " .. n) end
end)

registerCommand("kill", "즉사 (HD)", ".kill", function()
    local hum = getHum()
    if hum then hum.Health = 0; notify("즉사") end
end)

registerCommand("invisible", "투명화 (HD)", ".invisible [on/off]", function(args)
    local mode = args[1] and args[1]:lower()
    if mode == "on" then setInvisible(true); notify("투명화 ON")
    elseif mode == "off" then setInvisible(false); notify("투명화 OFF")
    else setInvisible(not state.invisible); notify("투명화 " .. (state.invisible and "ON" or "OFF")) end
end)
registerCommand("invis", "invisible 별칭", ".invis", function(a) Commands.invisible.fn(a) end)
registerCommand("visible", "투명 해제 (HD)", ".visible", function()
    setInvisible(false); notify("투명화 OFF")
end)

registerCommand("spin", "회전 (HD)", ".spin [speed]", function(args)
    local n = argNum(args, 1)
    if n then state.spinSpeed = n end
    setSpin(not state.spinOn)
    notify("회전 " .. (state.spinOn and "ON" or "OFF"))
end)

registerCommand("fling", "날려버리기 (HD)", ".fling", function()
    local hrp = getHRP()
    if hrp then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 200, 0)
        bv.Parent = hrp
        task.wait(0.5)
        bv:Destroy()
        notify("날아갑니다")
    end
end)

registerCommand("explode", "폭발 (HD)", ".explode", function()
    local hrp = getHRP()
    if hrp then
        local e = Instance.new("Explosion")
        e.Position = hrp.Position
        e.BlastRadius = 10
        e.Parent = workspace
        notify("폭발!")
    end
end)

-- --- 리스폰 / 부활 ---
registerCommand("re", "일반 리스폰", ".re", function()
    normalRespawn(); notify("일반 리스폰")
end)
registerCommand("respawn", "일반 리스폰", ".respawn", function()
    normalRespawn(); notify("일반 리스폰")
end)

registerCommand("res", "제자리 리스폰", ".res", function()
    respawnHere(); notify("제자리 리스폰")
end)

registerCommand("revive", "부활 (관전모드 해제)", ".revive", function()
    revive(); notify("부활 시도")
end)
registerCommand("부활", "revive 별칭", ".부활", function() Commands.revive.fn() end)
registerCommand("rv", "revive 별칭", ".rv", function() Commands.revive.fn() end)

registerCommand("freeze", "이동 정지", ".freeze", function()
    state.walkSpeed = 0; applySpeed(); notify("프리즈")
end)
registerCommand("unfreeze", "프리즈 해제", ".unfreeze", function()
    state.walkSpeed = CFG.SpeedDefault; applySpeed(); notify("프리즈 해제")
end)
registerCommand("normal", "일반 상태", ".normal", function()
    state.walkSpeed = 16; state.jumpPower = 50
    applyMovement(); notify("일반 상태")
end)

-- --- TP ---
registerCommand("tp", "플레이어에게 TP (HD: ;tp <plr>)", ".tp <이름>", function(args)
    local name = args[1]
    if not name then notify("이름 입력: .tp Player1"); return end
    local target
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Name:lower():sub(1, #name) == name:lower() then
            target = p; break
        end
    end
    if target then teleportTo(target); notify(target.Name .. "에게 TP")
    else notify("플레이어 없음") end
end)
registerCommand("goto", "tp 별칭", ".goto <이름>", function(a) Commands.tp.fn(a) end)

registerCommand("tppos", "좌표로 TP", ".tppos <x> <y> <z>", function(args)
    local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    if not (x and y and z) then notify("좌표 입력: .tppos 0 50 0"); return end
    teleportToPosition(x, y, z); notify("TP 완료")
end)

registerCommand("touchtp", "터치 TP 토글", ".touchtp [on/off]", function(args)
    local mode = args[1] and args[1]:lower()
    if mode == "on" then setTouchTP(true); notify("터치 TP ON")
    elseif mode == "off" then setTouchTP(false); notify("터치 TP OFF")
    else setTouchTP(not state.touchTP); notify("터치 TP " .. (state.touchTP and "ON" or "OFF")) end
end)

-- --- 시야 ---
registerCommand("bright", "밝기", ".bright <num>", function(args)
    local n = argNum(args, 1)
    if not n then notify(".bright 30"); return end
    state.brightness = math.clamp(n, CFG.BrightMin, CFG.BrightMax)
    state.playerBright = state.brightness
    applyLights(); applyLighting()
    notify("밝기: " .. state.brightness)
end)

registerCommand("fov", "FOV", ".fov <num>", function(args)
    local n = argNum(args, 1)
    if not n then notify(".fov 70"); return end
    state.fov = math.clamp(n, CFG.FOVMin, CFG.FOVMax)
    applyFOV(); notify("FOV: " .. state.fov)
end)
registerCommand("zoom", "확대", ".zoom", function()
    state.fov = 30; applyFOV(); notify("줌인")
end)
registerCommand("unzoom", "FOV 리셋", ".unzoom", function()
    state.fov = 70; applyFOV(); notify("줌아웃")
end)
registerCommand("fullbright", "최대 밝기", ".fullbright", function()
    state.brightness = 60; state.playerBright = 60
    state.range = 200; state.playerRange = 200
    applyLights(); applyLighting(); notify("풀브라이트")
end)
registerCommand("fb", "fullbright 별칭", ".fb", function() Commands.fullbright.fn() end)

-- --- 댄스 / 음악 ---
registerCommand("dance", "춤 + 음악 (HD 스타일)", ".dance [dance1~3/floss/dorky/monkey] [song]", function(args)
    startDance(args[1] or "dance1", args[2] or "default")
end)
registerCommand("stopdance", "춤/음악 중지", ".stopdance", function()
    stopDance(); notify("춤/음악 중지")
end)
registerCommand("floss", "플로스 댄스", ".floss", function()
    startDance("floss", "party")
end)
registerCommand("dorky", "도키 댄스", ".dorky", function()
    startDance("dorky", "funny")
end)
registerCommand("monkey", "몽키 댄스", ".monkey", function()
    startDance("monkey", "party")
end)

-- --- 매크로 ---
registerCommand("macro", "매크로 토글", ".macro [on/off]", function(args)
    local mode = args[1] and args[1]:lower()
    if mode == "on" then startMacro(); notify("매크로 ON")
    elseif mode == "off" then stopMacro(); notify("매크로 OFF")
    else
        if state.macroOn then stopMacro(); notify("매크로 OFF")
        else startMacro(); notify("매크로 ON") end
    end
end)

-- --- 유틸 ---
registerCommand("reset", "전체 리셋", ".reset", function()
    state.walkSpeed = CFG.SpeedDefault
    state.jumpPower = CFG.JumpDefault
    state.fov = 70
    state.brightness = 10
    state.range = 60
    state.godMode = false
    state.hipHeight = 2
    setFly(false); setNoclip(false); setInvisible(false); setSpin(false)
    setTouchTP(false); stopDance()
    applyMovement(); applyFOV(); applyLights(); applyLighting()
    notify("전체 리셋")
end)

registerCommand("btools", "빌드 툴", ".btools", function()
    pcall(function()
        local backpack = lp:FindFirstChildOfClass("Backpack")
        if not backpack then return end
        for _, t in ipairs({Enum.BinType.Hammer, Enum.BinType.Clone, Enum.BinType.Grab, Enum.BinType.GameTool}) do
            local bin = Instance.new("HopperBin")
            bin.BinType = t; bin.Parent = backpack
        end
        notify("빌드 툴 지급")
    end)
end)

registerCommand("ff", "ForceField 부여", ".ff", function()
    pcall(function()
        local char = lp.Character
        if char and not char:FindFirstChildOfClass("ForceField") then
            local ff = Instance.new("ForceField"); ff.Parent = char
            notify("ForceField 부여")
        end
    end)
end)

registerCommand("unff", "ForceField 제거", ".unff", function()
    pcall(function()
        local char = lp.Character
        if char then
            for _, obj in ipairs(char:GetChildren()) do
                if obj:IsA("ForceField") then obj:Destroy() end
            end
            notify("ForceField 제거")
        end
    end)
end)

registerCommand("help", "명령어 목록", ".help [명령어]", function(args)
    if args[1] then
        local c = Commands[args[1]:lower()]
        if c then notify(c.usage .. " — " .. c.desc, "도움말: " .. state.chatPrefix .. c.name)
        else notify("명령어 없음: " .. args[1]) end
        return
    end
    local list = {}
    for name, _ in pairs(Commands) do table.insert(list, state.chatPrefix .. name) end
    table.sort(list)
    notify(table.concat(list, "  "), "명령어 (" .. #list .. "개)")
end)
registerCommand("cmds", "명령어 목록", ".cmds", function(a) Commands.help.fn(a) end)

-- =========================================================
-- 채팅 훅
-- =========================================================
local function onChatMessage(message, speaker)
    if not state.chatEnabled then return end
    local prefix = state.chatPrefix
    if prefix == "" then return end
    if message:sub(1, #prefix) ~= prefix then return end

    local content = message:sub(#prefix + 1)
    local args = {}
    for word in content:gmatch("%S+") do table.insert(args, word) end
    if #args == 0 then return end

    local cmdName = args[1]:lower()
    table.remove(args, 1)
    local cmd = Commands[cmdName]
    if cmd then
        local ok, err = pcall(cmd.fn, args)
        if not ok then notify("오류: " .. tostring(err)) end
    else
        notify("알 수 없는 명령어: " .. prefix .. cmdName .. " (" .. prefix .. "help)")
    end
end

pcall(function()
    local TextChatService = game:GetService("TextChatService")
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = TextChatService:WaitForChild("TextChannels", 5)
        if channel then
            local rb = channel:FindFirstChild("RBXGeneral")
            if rb then
                rb.MessageReceived:Connect(function(msg)
                    local text = msg.Text
                    local prefix = state.chatPrefix
                    if text and prefix ~= "" and text:sub(1, #prefix) == prefix then
                        pcall(function() msg:Destroy() end)
                        onChatMessage(text, msg.TextSource and msg.TextSource.Name)
                    end
                end)
            end
        end
    end
end)

pcall(function()
    lp.Chatted:Connect(function(msg)
        onChatMessage(msg, lp.Name)
    end)
end)

-- =========================================================
-- 캐릭터 리스폰 재적용
-- =========================================================
lp.CharacterAdded:Connect(function(char)
    task.wait(0.5)

    local wasFlying = state.fly
    stopFly()
    if spinConn then spinConn:Disconnect(); spinConn = nil end
    state.spinOn = false
    state.invisible = false

    attachPlayerLight()
    applyMovement()
    applyLights()
    applyFOV()

    -- 노클립 유지
    if state.noclip then
        task.wait(0.2)
        doNoclip()
    end
    -- 플라이 유지
    if wasFlying then
        task.wait(0.3)
        startFly()
    end
end)

-- =========================================================
-- Rayfield UI
-- =========================================================
local Window = Rayfield:CreateWindow({
    Name = "왕웨이 따라가는 허브 V2",
    LoadingTitle = "왕웨이 따라가는 중...",
    LoadingSubtitle = "made by 왕웨이",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "WangweiHub",
        FileName = "Config"
    },
    KeySystem = false,
    Size = UDim2.fromOffset(950, 340),
})

-- =========================================================
-- 탭 1: 이동
-- =========================================================
local MoveTab = Window:CreateTab("왕웨이 이동", 4483362458)

MoveTab:CreateSection("속도 & 점프")

MoveTab:CreateSlider({
    Name = "이동 속도 (WalkSpeed)",
    Range = {CFG.SpeedMin, CFG.SpeedMax},
    Increment = 1, Suffix = "studs",
    CurrentValue = state.walkSpeed, Flag = "WalkSpeed",
    Callback = function(v) state.walkSpeed = v; applySpeed() end
})

MoveTab:CreateSlider({
    Name = "점프력 (JumpPower)",
    Range = {CFG.JumpMin, CFG.JumpMax},
    Increment = 1, Suffix = "power",
    CurrentValue = state.jumpPower, Flag = "JumpPower",
    Callback = function(v) state.jumpPower = v; applyJump() end
})

MoveTab:CreateSlider({
    Name = "HipHeight (공중 부양 높이)",
    Range = {0, 20}, Increment = 0.5, Suffix = "",
    CurrentValue = state.hipHeight, Flag = "HipHeight",
    Callback = function(v)
        state.hipHeight = v
        local hum = getHum()
        if hum then hum.HipHeight = v end
    end
})

MoveTab:CreateSection("비행 / 노클립")

MoveTab:CreateSlider({
    Name = "플라이 속도",
    Range = {10, 500}, Increment = 1, Suffix = "studs/s",
    CurrentValue = state.flySpeed, Flag = "FlySpeed",
    Callback = function(v) state.flySpeed = v end
})

MoveTab:CreateToggle({
    Name = "✈️ 플라이 (Fly)",
    CurrentValue = false, Flag = "FlyToggle",
    Callback = function(on) setFly(on); notify("플라이 " .. (on and "ON" or "OFF")) end
})

MoveTab:CreateToggle({
    Name = "👻 노클립 (Noclip)",
    CurrentValue = false, Flag = "NoclipToggle",
    Callback = function(on) setNoclip(on); notify("노클립 " .. (on and "ON" or "OFF")) end
})

MoveTab:CreateSection("상태")

MoveTab:CreateToggle({
    Name = "🛡️ 무적 (God Mode)",
    CurrentValue = false, Flag = "GodToggle",
    Callback = function(on) state.godMode = on; notify("무적 " .. (on and "ON" or "OFF")) end
})

MoveTab:CreateToggle({
    Name = "🫥 투명화 (Invisible)",
    CurrentValue = false, Flag = "InvisToggle",
    Callback = function(on) setInvisible(on); notify("투명화 " .. (on and "ON" or "OFF")) end
})

MoveTab:CreateToggle({
    Name = "🌀 회전 (Spin)",
    CurrentValue = false, Flag = "SpinToggle",
    Callback = function(on) setSpin(on); notify("회전 " .. (on and "ON" or "OFF")) end
})

MoveTab:CreateSection("리스폰 / 부활")

MoveTab:CreateButton({
    Name = "🔄 일반 리스폰 (.re)",
    Callback = function() normalRespawn(); notify("일반 리스폰") end
})

MoveTab:CreateButton({
    Name = "📍 제자리 리스폰 (.res)",
    Callback = function() respawnHere(); notify("제자리 리스폰") end
})

MoveTab:CreateButton({
    Name = "✨ 부활 (.revive)",
    Callback = function() revive(); notify("부활 시도") end
})

-- =========================================================
-- 탭 2: 시야
-- =========================================================
local ViewTab = Window:CreateTab("왕웨이 시야", 4483362458)

ViewTab:CreateSection("밝기")

ViewTab:CreateSlider({
    Name = "손전등 밝기",
    Range = {CFG.BrightMin, CFG.BrightMax},
    Increment = 1,
    CurrentValue = state.brightness, Flag = "Brightness",
    Callback = function(v) state.brightness = v; applyLights(); applyLighting() end
})

ViewTab:CreateSlider({
    Name = "내 시야 밝기",
    Range = {CFG.BrightMin, CFG.BrightMax},
    Increment = 1,
    CurrentValue = state.playerBright, Flag = "PlayerBright",
    Callback = function(v) state.playerBright = v; applyLights() end
})

ViewTab:CreateSection("라이트 거리")

ViewTab:CreateSlider({
    Name = "라이트 범위 (Range)",
    Range = {CFG.RangeMin, CFG.RangeMax},
    Increment = 1, Suffix = "studs",
    CurrentValue = state.range, Flag = "LightRange",
    Callback = function(v)
        state.range = v; state.playerRange = v
        applyLights()
    end
})

ViewTab:CreateSection("줌 (FOV)")

ViewTab:CreateSlider({
    Name = "FOV (낮을수록 확대)",
    Range = {CFG.FOVMin, CFG.FOVMax},
    Increment = 1,
    CurrentValue = state.fov, Flag = "FOV",
    Callback = function(v) state.fov = v; applyFOV() end
})

ViewTab:CreateButton({
    Name = "FOV 리셋 (70)",
    Callback = function() state.fov = 70; applyFOV(); notify("FOV 리셋") end
})

ViewTab:CreateButton({
    Name = "FOV 잠금 ON",
    Callback = function() state.fovLock = true; notify("FOV 잠금 ON") end
})

ViewTab:CreateButton({
    Name = "FOV 잠금 해제",
    Callback = function()
        state.fovLock = false
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
        notify("FOV 잠금 해제")
    end
})

ViewTab:CreateButton({
    Name = "밝기 리셋",
    Callback = function()
        state.brightness = 10; state.range = 60
        state.playerBright = CFG.PlayerLightBri; state.playerRange = CFG.PlayerLightRng
        applyLights(); applyLighting(); notify("밝기 초기화")
    end
})

-- =========================================================
-- 탭 3: TP
-- =========================================================
local PlayerTab = Window:CreateTab("왕웨이 TP", 4483362458)

PlayerTab:CreateSection("🎯 터치 TP")

PlayerTab:CreateToggle({
    Name = "터치한 곳으로 TP (ON/OFF)",
    CurrentValue = false, Flag = "TouchTPToggle",
    Callback = function(on)
        setTouchTP(on)
        notify("터치 TP " .. (on and "ON" or "OFF"))
    end
})

PlayerTab:CreateParagraph({
    Title = "사용법",
    Content = "1. 토글 ON\n2. 화면 클릭/터치\n3. 그 지점으로 TP"
})

PlayerTab:CreateSection("플레이어 TP")

local playerDropdown
local function refreshPlayerDropdown()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then table.insert(list, p.Name) end
    end
    if playerDropdown and playerDropdown.Refresh then
        playerDropdown:Refresh(list, true)
    end
end

playerDropdown = PlayerTab:CreateDropdown({
    Name = "플레이어 선택",
    Options = (function()
        local t = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then table.insert(t, p.Name) end
        end
        return t
    end)(),
    CurrentOption = {"없음"},
    Flag = "SelectedPlayer",
    Callback = function(opt) end
})

PlayerTab:CreateButton({
    Name = "선택한 플레이어에게 TP",
    Callback = function()
        local sel = Rayfield.Flags.SelectedPlayer
        if not sel then notify("플레이어를 선택하세요"); return end
        local name = type(sel) == "table" and sel[1] or sel
        local target = Players:FindFirstChild(name)
        if target then teleportTo(target); notify(name .. "에게 이동") end
    end
})

PlayerTab:CreateButton({
    Name = "플레이어 목록 새로고침",
    Callback = function() refreshPlayerDropdown(); notify("목록 갱신") end
})

Players.PlayerAdded:Connect(function() task.wait(0.3); refreshPlayerDropdown() end)
Players.PlayerRemoving:Connect(function() task.wait(0.3); refreshPlayerDropdown() end)

-- =========================================================
-- 탭 4: 댄스 / 음악
-- =========================================================
local DanceTab = Window:CreateTab("왕웨이 댄스", 4483362458)

DanceTab:CreateSection("🕺 댄스 + 음악")

DanceTab:CreateButton({
    Name = "💃 댄스1 + 파티 음악",
    Callback = function() startDance("dance1", "party") end
})
DanceTab:CreateButton({
    Name = "🕺 댄스2 + 파티 음악",
    Callback = function() startDance("dance2", "party") end
})
DanceTab:CreateButton({
    Name = "🎵 댄스3 + 웃긴 음악",
    Callback = function() startDance("dance3", "funny") end
})
DanceTab:CreateButton({
    Name = "🦩 플로스 댄스",
    Callback = function() startDance("floss", "party") end
})
DanceTab:CreateButton({
    Name = "🤪 도키 댄스",
    Callback = function() startDance("dorky", "funny") end
})
DanceTab:CreateButton({
    Name = "🐵 몽키 댄스",
    Callback = function() startDance("monkey", "party") end
})

DanceTab:CreateSection("제어")

DanceTab:CreateButton({
    Name = "🛑 춤/음악 중지",
    Callback = function() stopDance(); notify("춤/음악 중지") end
})

DanceTab:CreateParagraph({
    Title = "안내",
    Content = "아바타가 랜덤 색으로 변하고 춤추면서 음악이 재생됩니다.\n음악은 자신에게만 들립니다."
})

-- =========================================================
-- 탭 5: 매크로
-- =========================================================
local MacroTab = Window:CreateTab("왕웨이 매크로", 4483362458)

MacroTab:CreateSection("자동 터치")

MacroTab:CreateParagraph({
    Title = "사용법",
    Content = "1. 토글 ON\n2. 터치할 위치 클릭\n3. 반복 터치\n4. 끄려면 토글 OFF"
})

MacroTab:CreateToggle({
    Name = "매크로 ON/OFF",
    CurrentValue = false, Flag = "MacroToggle",
    Callback = function(on)
        if on then state.macroOn = true; notify("매크로 ON — 위치 클릭")
        else stopMacro(); notify("매크로 OFF") end
    end
})

MacroTab:CreateSlider({
    Name = "터치 간격 (ms)",
    Range = {1, 100}, Increment = 1, Suffix = "ms",
    CurrentValue = 50, Flag = "MacroInterval",
    Callback = function(v) state.macroInterval = v / 1000 end
})

MacroTab:CreateButton({
    Name = "매크로 시작",
    Callback = function()
        if state.macroX == 0 and state.macroY == 0 then notify("먼저 위치 클릭"); return end
        startMacro(); notify("매크로 시작")
    end
})

MacroTab:CreateButton({
    Name = "매크로 중지",
    Callback = function() stopMacro(); notify("매크로 중지") end
})

MacroTab:CreateButton({
    Name = "위치 초기화",
    Callback = function() state.macroX = 0; state.macroY = 0; notify("위치 초기화") end
})

-- =========================================================
-- 탭 6: 명령어 (접두사 + 클릭 실행)
-- =========================================================
local CmdTab = Window:CreateTab("왕웨이 명령어", 4483362458)

CmdTab:CreateSection("🖱️ 명령어 클릭 실행")

local function buildCmdOptions()
    local opts = {}
    local names = {}
    for name, _ in pairs(Commands) do table.insert(names, name) end
    table.sort(names)
    for _, name in ipairs(names) do
        local c = Commands[name]
        table.insert(opts, name .. " — " .. c.desc)
    end
    return opts
end

local function countCommands()
    local n = 0
    for _ in pairs(Commands) do n = n + 1 end
    return n
end

local cmdDropdown
cmdDropdown = CmdTab:CreateDropdown({
    Name = "명령어 선택 (선택 즉시 실행)",
    Options = buildCmdOptions(),
    CurrentOption = {"선택하세요..."},
    Flag = "CmdSelect",
    Callback = function(opt)
        if not opt or #opt == 0 then return end
        local selected = opt[1]
        local cmdName = selected:match("^(%S+)")
        if not cmdName then return end

        local cmd = Commands[cmdName:lower()]
        if cmd then
            local ok, err = pcall(cmd.fn, {})
            if not ok then notify("오류: " .. tostring(err)) end
        else
            notify("명령어를 찾을 수 없음: " .. cmdName)
        end

        task.wait(0.3)
        pcall(function() cmdDropdown:Refresh(buildCmdOptions(), true) end)
    end
})

CmdTab:CreateButton({
    Name = "명령어 목록 새로고침",
    Callback = function()
        pcall(function() cmdDropdown:Refresh(buildCmdOptions(), true) end)
        notify("명령어 목록 갱신 (" .. countCommands() .. "개)")
    end
})

CmdTab:CreateSection("🔧 접두사 설정")

CmdTab:CreateInput({
    Name = "접두사 변경 (기본 '.')",
    CurrentValue = state.chatPrefix,
    PlaceholderText = ". / ! / ; / $ (최대 3자)",
    RemoveTextAfterFocusLost = false,
    Flag = "PrefixInput",
    Callback = function(text)
        if not text or text == "" then notify("접두사 비울 수 없음"); return end
        if #text > 3 then notify("최대 3자"); return end
        state.chatPrefix = text
        notify("접두사 변경: '" .. text .. "'")
    end
})

CmdTab:CreateButton({
    Name = "접두사 '.' (HD 스타일은 ';')",
    Callback = function() state.chatPrefix = "."; notify("접두사 '.'") end
})
CmdTab:CreateButton({
    Name = "접두사 ';' (HD Admin 원본)",
    Callback = function() state.chatPrefix = ";"; notify("접두사 ';'") end
})
CmdTab:CreateButton({
    Name = "접두사 '!'",
    Callback = function() state.chatPrefix = "!"; notify("접두사 '!'") end
})
CmdTab:CreateButton({
    Name = "접두사 '/'",
    Callback = function() state.chatPrefix = "/"; notify("접두사 '/'") end
})

CmdTab:CreateSection("⚙️ 시스템")

CmdTab:CreateToggle({
    Name = "채팅 명령어 시스템 ON/OFF",
    CurrentValue = true, Flag = "ChatEnabled",
    Callback = function(on)
        state.chatEnabled = on
        notify("채팅 명령어 " .. (on and "활성화" or "비활성화"))
    end
})

CmdTab:CreateSection("📜 전체 명령어 목록")

CmdTab:CreateButton({
    Name = "명령어 전체 목록 채팅 알림으로 출력",
    Callback = function()
        local names = {}
        for name, _ in pairs(Commands) do table.insert(names, name) end
        table.sort(names)
        notify("총 " .. #names .. "개: " .. state.chatPrefix ..
               table.concat(names, "  " .. state.chatPrefix), "명령어 목록")
    end
})

-- =========================================================
-- 탭 7: 유틸
-- =========================================================
local UtilTab = Window:CreateTab("왕웨이 유틸", 4483362458)

UtilTab:CreateSection("정보")

UtilTab:CreateParagraph({
    Title = "단축키",
    Content = "Z = 플라이 / R = 일반 리스폰 / X = 속도 리셋 / C = 점프 리셋 / V = FOV 리셋"
})

UtilTab:CreateParagraph({
    Title = "리스폰 / 부활",
    Content = ".re = 일반 리스폰\n.res = 제자리 리스폰\n.revive = 관전모드 강제 해제 + 부활"
})

UtilTab:CreateParagraph({
    Title = "HD Admin 스타일",
    Content = ".speed <num>  /  .jumpHeight <num>  /  .fly <speed>  /  .noclip\n" ..
              ".fast  /  .slow  /  .superJump  /  .heavyJump\n" ..
              ".god  /  .heal  /  .kill  /  .damage <num>  /  .health <num>\n" ..
              ".invisible  /  .visible  /  .spin  /  .fling  /  .explode"
})

UtilTab:CreateSection("기타")

UtilTab:CreateButton({
    Name = "UI 재시작 안내",
    Callback = function() notify("스크립트 다시 실행하세요") end
})

-- =========================================================
-- 단축키
-- =========================================================
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.Z then
        local newState = not state.fly
        setFly(newState)
        notify("플라이 " .. (newState and "ON" or "OFF"))
    elseif key == Enum.KeyCode.R then
        normalRespawn()
    elseif key == Enum.KeyCode.X then
        state.walkSpeed = CFG.SpeedDefault; applySpeed()
    elseif key == Enum.KeyCode.C then
        state.jumpPower = CFG.JumpDefault; applyJump()
    elseif key == Enum.KeyCode.V then
        state.fov = 70; applyFOV()
    end
end)

-- =========================================================
-- 초기 적용
-- =========================================================
attachPlayerLight()
applyMovement()
applyFOV()

Rayfield:Notify({
    Title = "왕웨이 따라가는 허브 V2",
    Content = "로드 완료! 접두사: '" .. state.chatPrefix .. "' — " .. state.chatPrefix .. "help",
    Duration = 4
})
