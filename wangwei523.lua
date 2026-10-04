-- =========================================================
--  왕웨이 따라가는 허브  V3
--  AimBot · FOV Circle · Hitbox ESP
--  Speed · Jump · Fly · Noclip · TP · Macro · Dance
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
local cam        = workspace.CurrentCamera

pcall(function() UIS.MouseIconEnabled = true end)

local CFG = {
    SpeedDefault = 16, SpeedMin = 0,  SpeedMax = 1000,
    JumpDefault  = 50, JumpMin  = 0,  JumpMax  = 1000,
    FlySpeed     = 60,
    BrightMin    = 0,  BrightMax = 60,
    RangeMin     = 0,  RangeMax  = 200,
    FOVMin       = 20, FOVMax    = 120,
    MacroInterval = 0.05,
    AimFOVMin    = 20, AimFOVMax = 800,
    HitboxMin    = 1,  HitboxMax = 50,
}

-- 초기값: 게임 원래 값 유지 (아무것도 강제 적용 안 함)
local state = {
    walkSpeed   = nil,      -- nil이면 건드리지 않음
    jumpPower   = nil,
    flySpeed    = CFG.FlySpeed,
    brightness  = nil,
    range       = nil,
    fov         = nil,
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
    hipHeight   = nil,

    -- 에임봇
    aimbotOn      = false,
    aimbotFOV     = 150,
    aimbotSmooth  = 1,
    aimbotTeam    = false,
    aimbotVisible = true,
    aimbotPart    = "Head",   -- Head / HumanoidRootPart / UpperTorso
    aimbotFOVCircle = true,
    aimbotLockKey = Enum.UserInputType.MouseButton2, -- 우클릭
    aimbotTarget  = nil,
    aimbotActive  = false,

    -- 히트박스
    hitboxOn    = false,
    hitboxSize  = 10,
    hitboxColor = Color3.fromRGB(255, 0, 0),
    hitboxTrans = 0.5,
    hitboxOriginals = {},  -- [part] = originalSize
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
-- 1. 스피드 / 점프 (설정했을 때만 적용)
-- =========================================================
local function applySpeed()
    if state.walkSpeed == nil then return end
    local hum = getHum()
    if hum then pcall(function() hum.WalkSpeed = state.walkSpeed end) end
end

local function applyJump()
    if state.jumpPower == nil then return end
    local hum = getHum()
    if not hum then return end
    pcall(function() hum.UseJumpPower = true end)
    pcall(function() hum.JumpPower = state.jumpPower end)
    pcall(function() hum.JumpHeight = state.jumpPower / 7.5 end)
end

local function applyMovement() applySpeed(); applyJump() end

RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if not hum then return end
    if state.walkSpeed ~= nil and math.abs(hum.WalkSpeed - state.walkSpeed) > 0.5 then
        pcall(function() hum.WalkSpeed = state.walkSpeed end)
    end
    if state.jumpPower ~= nil then
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
    end
    if state.hipHeight ~= nil and math.abs(hum.HipHeight - state.hipHeight) > 0.1 then
        pcall(function() hum.HipHeight = state.hipHeight end)
    end
end)

-- 마지막 생존 위치
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
-- 2. 노클립
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
    if on then doNoclip()
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
-- 3. 플라이
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

    flyHeartbeat = RunService.Heartbeat:Connect(function()
        if hum.Parent and hum.PlatformStand == false then
            pcall(function() hum.PlatformStand = true end)
        end
    end)

    flyConn = RunService.RenderStepped:Connect(function()
        local c = workspace.CurrentCamera
        if not c or not hrp.Parent then return end
        local mv = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then mv += c.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= c.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= c.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then mv += c.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then mv += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv -= Vector3.new(0,1,0) end
        if mv.Magnitude > 0 then mv = mv.Unit * state.flySpeed end
        pcall(function()
            bodyVel.Velocity = mv
            bodyGyro.CFrame  = c.CFrame
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
-- 5. 밝기 / 라이트 (설정했을 때만)
-- =========================================================
local function applyLights()
    if state.brightness == nil then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Light") then
            pcall(function()
                obj.Brightness = state.brightness
                if state.range then obj.Range = state.range end
                obj.Shadows = false
            end)
        end
    end
end

local function applyLighting()
    if state.brightness == nil then return end
    pcall(function()
        Lighting.Ambient        = Color3.fromRGB(150,150,150)
        Lighting.OutdoorAmbient = Color3.fromRGB(150,150,150)
        Lighting.Brightness     = math.clamp(state.brightness/5, 1, 10)
        Lighting.GlobalShadows  = false
        Lighting.FogEnd         = 100000
    end)
end

-- =========================================================
-- 6. FOV
-- =========================================================
local function applyFOV()
    if state.fov == nil then return end
    local c = workspace.CurrentCamera
    if not c then return end
    pcall(function()
        if state.fovLock then c.CameraType = Enum.CameraType.Scriptable end
        if math.abs(c.FieldOfView - state.fov) > 0.1 then
            c.FieldOfView = state.fov
        end
    end)
end

RunService.RenderStepped:Connect(function()
    if state.fov == nil then return end
    local c = workspace.CurrentCamera
    if not c then return end
    if math.abs(c.FieldOfView - state.fov) > 0.1 then
        pcall(function() c.FieldOfView = state.fov end)
    end
end)

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
        local c = workspace.CurrentCamera
        c.CameraSubject = hum
        c.CameraType = Enum.CameraType.Custom
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
end

local function teleportToPosition(x, y, z)
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(x, y, z) end
end

-- 터치 TP
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
            local c = workspace.CurrentCamera
            if not c then return end
            local ray = c:ViewportPointToRay(input.Position.X, input.Position.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { lp.Character }
            local result = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
            local targetPos = result and (result.Position + Vector3.new(0, 3, 0))
                              or (ray.Origin + ray.Direction * 100)
            local hrp = getHRP()
            if hrp then
                hrp.CFrame = CFrame.new(targetPos)
                notify("터치 TP")
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
local function stopMacro() state.macroOn = false; macroThread = nil end

UIS.InputBegan:Connect(function(input, gpe)
    if not state.macroOn or state.touchTP then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if gpe then return end
        state.macroX = input.Position.X
        state.macroY = input.Position.Y
    end
end)

-- =========================================================
-- 9. 댄스 + 음악
-- =========================================================
local currentMusic, currentAnimTrack

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
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function()
                p.Color = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
            end)
        end
    end
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
    local sound = Instance.new("Sound")
    sound.SoundId = SONGS[songKey] or SONGS.default
    sound.Volume = 2
    sound.Looped = true
    sound.Parent = char:FindFirstChild("Head") or char
    pcall(function() sound:Play() end)
    currentMusic = sound
    notify("춤 + 음악")
end

-- =========================================================
-- 10. 에임봇 (우클릭 고정 + FOV 원)
-- =========================================================
local aimTarget = nil

-- FOV 원 UI (ScreenGui)
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "WangweiAimFOV"
fovGui.ResetOnSpawn = false
fovGui.IgnoreGuiInset = true
fovGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() fovGui.Parent = game:GetService("CoreGui") end)
if not fovGui.Parent then fovGui.Parent = lp:WaitForChild("PlayerGui") end

local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = fovGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 1
fovStroke.Color = Color3.fromRGB(0, 255, 100)
fovStroke.Transparency = 0.3
fovStroke.Parent = fovCircle

local function updateFOVCircle()
    local size = state.aimbotFOV
    fovCircle.Size = UDim2.fromOffset(size, size)
    fovCircle.Visible = state.aimbotOn and state.aimbotFOVCircle
end
updateFOVCircle()

-- 화면 중심 구하기
local function getScreenCenter()
    local c = workspace.CurrentCamera
    if not c then return Vector2.new(0, 0) end
    return Vector2.new(c.ViewportSize.X / 2, c.ViewportSize.Y / 2)
end

-- 적이 FOV 안에 있는지 체크 + 가장 가까운 적 찾기
local function isEnemy(plr)
    if plr == lp then return false end
    if not state.aimbotTeam and plr.Team and lp.Team and plr.Team == lp.Team then
        return false
    end
    return true
end

local function findClosestTarget()
    local c = workspace.CurrentCamera
    if not c then return nil end
    local center = getScreenCenter()
    local closest = nil
    local closestDist = state.aimbotFOV / 2

    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local part
            if state.aimbotPart == "Head" then
                part = char and char:FindFirstChild("Head")
            elseif state.aimbotPart == "HumanoidRootPart" then
                part = char and char:FindFirstChild("HumanoidRootPart")
            elseif state.aimbotPart == "UpperTorso" then
                part = char and (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"))
            else
                part = char and char:FindFirstChild("Head")
            end

            if hum and hum.Health > 0 and part then
                -- 화면 좌표
                local screenPos, onScreen = c:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist <= closestDist then
                        -- 벽 체크 (옵션)
                        if state.aimbotVisible then
                            local rayParams = RaycastParams.new()
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            rayParams.FilterDescendantsInstances = { lp.Character }
                            local origin = c.CFrame.Position
                            local dir = (part.Position - origin)
                            local hit = workspace:Raycast(origin, dir, rayParams)
                            if hit and hit.Instance and not hit.Instance:IsDescendantOf(char) then
                                -- 벽 뒤에 있음
                                continue
                            end
                        end
                        closest = {player = plr, part = part, dist = dist}
                        closestDist = dist
                    end
                end
            end
        end
    end
    return closest
end

-- 에임봇 실행 (RenderStepped)
local aimConn = RunService.RenderStepped:Connect(function()
    if not state.aimbotOn then
        aimTarget = nil
        return
    end

    -- FOV 원 업데이트
    if fovCircle.Visible then
        fovCircle.Size = UDim2.fromOffset(state.aimbotFOV, state.aimbotFOV)
    end

    -- 우클릭 감지 (aimbotActive)
    if not state.aimbotActive then
        aimTarget = nil
        return
    end

    local target = findClosestTarget()
    if target then
        aimTarget = target
        local myHrp = getHRP()
        if myHrp and target.part and target.part.Parent then
            -- 카메라를 타겟 방향으로 회전
            local c = workspace.CurrentCamera
            if c then
                local myPos = c.CFrame.Position
                local aimPos = target.part.Position
                local dir = (aimPos - myPos).Unit
                local targetCF = CFrame.lookAt(myPos, myPos + dir)
                local smooth = math.clamp(state.aimbotSmooth, 0.05, 1)
                c.CFrame = c.CFrame:Lerp(targetCF, smooth)
            end
        end
    end
end)

-- 우클릭 다운/업 감지
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == state.aimbotLockKey then
        if state.aimbotOn then
            state.aimbotActive = true
        end
    end
end)
UIS.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == state.aimbotLockKey then
        state.aimbotActive = false
    end
end)

-- =========================================================
-- 11. 히트박스핵
-- =========================================================
local hitboxOriginalData = {}  -- [player] = {[part] = {size, transparency}}

local function saveOriginalHitbox(plr)
    if hitboxOriginalData[plr] then return end
    local char = plr.Character
    if not char then return end
    hitboxOriginalData[plr] = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name == "Head" or part.Name == "HumanoidRootPart"
           or part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso") then
            hitboxOriginalData[plr][part] = {
                size = part.Size,
                transparency = part.Transparency,
                canCollide = part.CanCollide,
            }
        end
    end
end

local function applyHitboxToPlayer(plr)
    if plr == lp then return end
    local char = plr.Character
    if not char then return end

    if state.hitboxOn then
        saveOriginalHitbox(plr)
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and (part.Name == "Head" or part.Name == "HumanoidRootPart"
               or part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso") then
                local sz = state.hitboxSize
                pcall(function()
                    part.Size = Vector3.new(sz, sz, sz)
                    part.Transparency = state.hitboxTrans
                    part.Color = state.hitboxColor
                    part.Material = Enum.Material.Neon
                    part.CanCollide = false
                end)
            end
        end
    else
        -- 원래대로
        local data = hitboxOriginalData[plr]
        if data then
            for part, info in pairs(data) do
                if part and part.Parent then
                    pcall(function()
                        part.Size = info.size
                        part.Transparency = info.transparency
                        part.CanCollide = info.canCollide
                        part.Material = Enum.Material.Plastic
                    end)
                end
            end
            hitboxOriginalData[plr] = nil
        end
    end
end

local function applyHitboxAll()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            applyHitboxToPlayer(plr)
        end
    end
end

local function setHitbox(on)
    state.hitboxOn = on
    applyHitboxAll()
end

-- 히트박스 자동 갱신 (캐릭터 리스폰 대응)
task.spawn(function()
    while true do
        task.wait(0.5)
        if state.hitboxOn then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    applyHitboxToPlayer(plr)
                end
            end
        end
    end
end)

-- =========================================================
-- 12. 채팅 명령어
-- =========================================================
local Commands = {}
local function registerCommand(name, desc, usage, fn)
    Commands[name:lower()] = {name = name, desc = desc, usage = usage, fn = fn}
end

-- 이동
registerCommand("fly", "플라이", ".fly [speed] [on/off]", function(args)
    local mode = args[#args] and args[#args]:lower()
    if mode == "off" then setFly(false); notify("플라이 OFF"); return end
    local spd = argNum(args, 1)
    if spd then state.flySpeed = math.clamp(spd, 10, 500) end
    setFly(true)
    notify("플라이 ON" .. (spd and (" 속도 " .. spd) or ""))
end)

registerCommand("noclip", "노클립", ".noclip [on/off]", function(args)
    local mode = args[1] and args[1]:lower()
    if mode == "on" then setNoclip(true); notify("노클립 ON")
    elseif mode == "off" then setNoclip(false); notify("노클립 OFF")
    else setNoclip(not state.noclip); notify("노클립 " .. (state.noclip and "ON" or "OFF")) end
end)
registerCommand("nc", "noclip 별칭", ".nc", function(a) Commands.noclip.fn(a) end)

registerCommand("speed", "속도", ".speed <num>", function(args)
    local n = argNum(args, 1)
    if not n then notify("숫자: .speed 100"); return end
    state.walkSpeed = math.clamp(n, CFG.SpeedMin, CFG.SpeedMax)
    applySpeed(); notify("속도: " .. state.walkSpeed)
end)
registerCommand("ws", "speed 별칭", ".ws <num>", function(a) Commands.speed.fn(a) end)

registerCommand("jump", "점프력", ".jump <num>", function(args)
    local n = argNum(args, 1)
    if not n then notify("숫자: .jump 100"); return end
    state.jumpPower = math.clamp(n, CFG.JumpMin, CFG.JumpMax)
    applyJump(); notify("점프력: " .. state.jumpPower)
end)
registerCommand("jp", "jump 별칭", ".jp <num>", function(a) Commands.jump.fn(a) end)
registerCommand("jumpHeight", "jump 별칭", ".jumpHeight <num>", function(a) Commands.jump.fn(a) end)

-- 상태
registerCommand("god", "무적", ".god [on/off]", function(args)
    local mode = args[1] and args[1]:lower()
    if mode == "on" then state.godMode = true; notify("무적 ON")
    elseif mode == "off" then state.godMode = false; notify("무적 OFF")
    else state.godMode = not state.godMode; notify("무적 " .. (state.godMode and "ON" or "OFF")) end
end)

registerCommand("heal", "회복", ".heal", function()
    local hum = getHum()
    if hum then hum.Health = hum.MaxHealth; notify("회복") end
end)

registerCommand("kill", "즉사", ".kill", function()
    local hum = getHum()
    if hum then hum.Health = 0; notify("즉사") end
end)

registerCommand("invisible", "투명화", ".invisible [on/off]", function(args)
    local mode = args[1] and args[1]:lower()
    if mode == "on" then setInvisible(true); notify("투명화 ON")
    elseif mode == "off" then setInvisible(false); notify("투명화 OFF")
    else setInvisible(not state.invisible); notify("투명화 " .. (state.invisible and "ON" or "OFF")) end
end)
registerCommand("invis", "invisible 별칭", ".invis", function(a) Commands.invisible.fn(a) end)

registerCommand("spin", "회전", ".spin [speed]", function(args)
    local n = argNum(args, 1)
    if n then state.spinSpeed = n end
    setSpin(not state.spinOn)
    notify("회전 " .. (state.spinOn and "ON" or "OFF"))
end)

-- 리스폰
registerCommand("re", "일반 리스폰", ".re", function()
    normalRespawn(); notify("일반 리스폰")
end)
registerCommand("res", "제자리 리스폰", ".res", function()
    respawnHere(); notify("제자리 리스폰")
end)
registerCommand("revive", "부활", ".revive", function()
    revive(); notify("부활")
end)
registerCommand("부활", "revive 별칭", ".부활", function() Commands.revive.fn() end)

-- TP
registerCommand("tp", "플레이어에게 TP", ".tp <이름>", function(args)
    local name = args[1]
    if not name then notify("이름: .tp Player1"); return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Name:lower():sub(1, #name) == name:lower() then
            teleportTo(p); notify(p.Name .. "에게 TP"); return
        end
    end
    notify("플레이어 없음")
end)
registerCommand("tppos", "좌표 TP", ".tppos <x> <y> <z>", function(args)
    local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    if not (x and y and z) then notify("좌표: .tppos 0 50 0"); return end
    teleportToPosition(x, y, z); notify("TP 완료")
end)
registerCommand("touchtp", "터치 TP", ".touchtp [on/off]", function(args)
    local mode = args[1] and args[1]:lower()
    if mode == "on" then setTouchTP(true); notify("터치 TP ON")
    elseif mode == "off" then setTouchTP(false); notify("터치 TP OFF")
    else setTouchTP(not state.touchTP); notify("터치 TP " .. (state.touchTP and "ON" or "OFF")) end
end)

-- 에임봇
registerCommand("aimbot", "에임봇 ON/OFF", ".aimbot [on/off]", function(args)
    local mode = args[1] and args[1]:lower()
    if mode == "on" then state.aimbotOn = true; notify("에임봇 ON")
    elseif mode == "off" then state.aimbotOn = false; notify("에임봇 OFF")
    else state.aimbotOn = not state.aimbotOn; notify("에임봇 " .. (state.aimbotOn and "ON" or "OFF")) end
    updateFOVCircle()
end)

registerCommand("aimfov", "에임 FOV 크기", ".aimfov <num>", function(args)
    local n = argNum(args, 1)
    if not n then notify(".aimfov 200"); return end
    state.aimbotFOV = math.clamp(n, CFG.AimFOVMin, CFG.AimFOVMax)
    updateFOVCircle()
    notify("에임 FOV: " .. state.aimbotFOV)
end)

registerCommand("aimsmooth", "에임 부드러움 (1=즉시)", ".aimsmooth <0.05~1>", function(args)
    local n = tonumber(args[1])
    if not n then notify(".aimsmooth 0.5"); return end
    state.aimbotSmooth = math.clamp(n, 0.05, 1)
    notify("에임 스무스: " .. state.aimbotSmooth)
end)

-- 히트박스
registerCommand("hitbox", "히트박스 ON/OFF", ".hitbox [on/off]", function(args)
    local mode = args[1] and args[1]:lower()
    if mode == "on" then setHitbox(true); notify("히트박스 ON")
    elseif mode == "off" then setHitbox(false); notify("히트박스 OFF")
    else setHitbox(not state.hitboxOn); notify("히트박스 " .. (state.hitboxOn and "ON" or "OFF")) end
end)

registerCommand("hitboxsize", "히트박스 크기", ".hitboxsize <num>", function(args)
    local n = argNum(args, 1)
    if not n then notify(".hitboxsize 10"); return end
    state.hitboxSize = math.clamp(n, CFG.HitboxMin, CFG.HitboxMax)
    applyHitboxAll()
    notify("히트박스 크기: " .. state.hitboxSize)
end)

-- 유틸
registerCommand("reset", "전체 리셋", ".reset", function()
    state.walkSpeed = nil
    state.jumpPower = nil
    state.fov = nil
    state.brightness = nil
    state.hipHeight = nil
    state.godMode = false
    setFly(false); setNoclip(false); setInvisible(false); setSpin(false)
    setTouchTP(false); setHitbox(false); stopDance()
    state.aimbotOn = false
    updateFOVCircle()
    applyMovement(); applyFOV(); applyLights(); applyLighting()
    notify("전체 리셋")
end)

registerCommand("help", "명령어 목록", ".help", function()
    local list = {}
    for name, _ in pairs(Commands) do table.insert(list, state.chatPrefix .. name) end
    table.sort(list)
    notify(table.concat(list, "  "), "명령어 (" .. #list .. "개)")
end)
registerCommand("cmds", "명령어 목록", ".cmds", function(a) Commands.help.fn(a) end)

-- =========================================================
-- 채팅 훅
-- =========================================================
local function onChatMessage(message)
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
        notify("알 수 없는 명령어: " .. prefix .. cmdName)
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
                        onChatMessage(text)
                    end
                end)
            end
        end
    end
end)

pcall(function()
    lp.Chatted:Connect(onChatMessage)
end)

-- =========================================================
-- 캐릭터 리스폰
-- =========================================================
lp.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local wasFlying = state.fly
    stopFly()
    if spinConn then spinConn:Disconnect(); spinConn = nil end
    state.spinOn = false
    state.invisible = false
    applyMovement()
    applyFOV()
    applyLights()
    if state.noclip then task.wait(0.2); doNoclip() end
    if wasFlying then task.wait(0.3); startFly() end
end)

-- =========================================================
-- Rayfield UI
-- =========================================================
local Window = Rayfield:CreateWindow({
    Name = "왕웨이 따라가는 허브 V3",
    LoadingTitle = "왕웨이 따라가는 중...",
    LoadingSubtitle = "made by 왕웨이",
    ConfigurationSaving = {
        Enabled = false,   -- 설정 저장 안 함 (초기값 없음)
    },
    KeySystem = false,
    Size = UDim2.fromOffset(1000, 360),
})

-- =========================================================
-- 탭 1: 에임봇
-- =========================================================
local AimTab = Window:CreateTab("🎯 에임봇", 4483362458)

AimTab:CreateSection("에임봇")

AimTab:CreateToggle({
    Name = "에임봇 ON/OFF (우클릭 시 고정)",
    CurrentValue = false, Flag = "AimbotToggle",
    Callback = function(on)
        state.aimbotOn = on
        updateFOVCircle()
        notify("에임봇 " .. (on and "ON" or "OFF"))
    end
})

AimTab:CreateSlider({
    Name = "에임 FOV 크기 (원 지름)",
    Range = {CFG.AimFOVMin, CFG.AimFOVMax},
    Increment = 5, Suffix = "px",
    CurrentValue = state.aimbotFOV, Flag = "AimFOV",
    Callback = function(v)
        state.aimbotFOV = v
        updateFOVCircle()
    end
})

AimTab:CreateToggle({
    Name = "FOV 원 표시",
    CurrentValue = true, Flag = "FOVCircleToggle",
    Callback = function(on)
        state.aimbotFOVCircle = on
        updateFOVCircle()
    end
})

AimTab:CreateSlider({
    Name = "에임 부드러움 (1 = 즉시 고정)",
    Range = {0.05, 1},
    Increment = 0.05, Suffix = "",
    CurrentValue = state.aimbotSmooth, Flag = "AimSmooth",
    Callback = function(v) state.aimbotSmooth = v end
})

AimTab:CreateSection("타겟 설정")

AimTab:CreateDropdown({
    Name = "조준 부위",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = {"Head"},
    Flag = "AimPart",
    Callback = function(opt)
        state.aimbotPart = opt[1] or "Head"
    end
})

AimTab:CreateToggle({
    Name = "같은 팀 무시",
    CurrentValue = false, Flag = "AimTeam",
    Callback = function(on) state.aimbotTeam = on end
})

AimTab:CreateToggle({
    Name = "벽 뒤 무시 (보이는 적만)",
    CurrentValue = true, Flag = "AimVisible",
    Callback = function(on) state.aimbotVisible = on end
})

AimTab:CreateSection("사용법")

AimTab:CreateParagraph({
    Title = "에임봇 사용법",
    Content = "1. 에임봇 ON\n2. 화면 중앙에 FOV 원 표시됨\n3. FOV 원 안에 적이 들어오면\n4. 우클릭(마우스 오른쪽 버튼) 누르고 있으면 그 적 머리로 카메라 고정\n5. 우클릭 떼면 해제"
})

-- =========================================================
-- 탭 2: 히트박스
-- =========================================================
local HitboxTab = Window:CreateTab("📦 히트박스", 4483362458)

HitboxTab:CreateSection("히트박스핵")

HitboxTab:CreateToggle({
    Name = "히트박스 ON/OFF",
    CurrentValue = false, Flag = "HitboxToggle",
    Callback = function(on)
        setHitbox(on)
        notify("히트박스 " .. (on and "ON" or "OFF"))
    end
})

HitboxTab:CreateSlider({
    Name = "히트박스 크기",
    Range = {CFG.HitboxMin, CFG.HitboxMax},
    Increment = 1, Suffix = "studs",
    CurrentValue = state.hitboxSize, Flag = "HitboxSize",
    Callback = function(v)
        state.hitboxSize = v
        if state.hitboxOn then applyHitboxAll() end
    end
})

HitboxTab:CreateSlider({
    Name = "투명도 (0 = 불투명, 1 = 투명)",
    Range = {0, 1},
    Increment = 0.05, Suffix = "",
    CurrentValue = state.hitboxTrans, Flag = "HitboxTrans",
    Callback = function(v)
        state.hitboxTrans = v
        if state.hitboxOn then applyHitboxAll() end
    end
})

HitboxTab:CreateColorPicker({
    Name = "히트박스 색상",
    Color = state.hitboxColor, Flag = "HitboxColor",
    Callback = function(color)
        state.hitboxColor = color
        if state.hitboxOn then applyHitboxAll() end
    end
})

HitboxTab:CreateSection("안내")

HitboxTab:CreateParagraph({
    Title = "히트박스 안내",
    Content = "히트박스는 다른 플레이어의 몸통/머리를 크게 만들어서 총알이 더 잘 맞게 합니다.\n크기 10~15 정도가 적당."
})

-- =========================================================
-- 탭 3: 이동
-- =========================================================
local MoveTab = Window:CreateTab("왕웨이 이동", 4483362458)

MoveTab:CreateSection("속도 & 점프 (슬라이더 움직여야 적용)")

MoveTab:CreateSlider({
    Name = "이동 속도",
    Range = {CFG.SpeedMin, CFG.SpeedMax},
    Increment = 1, Suffix = "studs",
    CurrentValue = 16, Flag = "WalkSpeed",
    Callback = function(v) state.walkSpeed = v; applySpeed() end
})

MoveTab:CreateSlider({
    Name = "점프력",
    Range = {CFG.JumpMin, CFG.JumpMax},
    Increment = 1, Suffix = "power",
    CurrentValue = 50, Flag = "JumpPower",
    Callback = function(v) state.jumpPower = v; applyJump() end
})

MoveTab:CreateSlider({
    Name = "HipHeight",
    Range = {0, 20}, Increment = 0.5,
    CurrentValue = 2, Flag = "HipHeight",
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
    Name = "✈️ 플라이",
    CurrentValue = false, Flag = "FlyToggle",
    Callback = function(on) setFly(on); notify("플라이 " .. (on and "ON" or "OFF")) end
})

MoveTab:CreateToggle({
    Name = "👻 노클립",
    CurrentValue = false, Flag = "NoclipToggle",
    Callback = function(on) setNoclip(on); notify("노클립 " .. (on and "ON" or "OFF")) end
})

MoveTab:CreateSection("상태")

MoveTab:CreateToggle({
    Name = "🛡️ 무적",
    CurrentValue = false, Flag = "GodToggle",
    Callback = function(on) state.godMode = on; notify("무적 " .. (on and "ON" or "OFF")) end
})

MoveTab:CreateToggle({
    Name = "🫥 투명화",
    CurrentValue = false, Flag = "InvisToggle",
    Callback = function(on) setInvisible(on); notify("투명화 " .. (on and "ON" or "OFF")) end
})

MoveTab:CreateToggle({
    Name = "🌀 회전",
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
    Callback = function() revive(); notify("부활") end
})

-- =========================================================
-- 탭 4: 시야
-- =========================================================
local ViewTab = Window:CreateTab("왕웨이 시야", 4483362458)

ViewTab:CreateSection("밝기 (슬라이더 움직여야 적용)")

ViewTab:CreateSlider({
    Name = "밝기",
    Range = {CFG.BrightMin, CFG.BrightMax},
    Increment = 1,
    CurrentValue = 10, Flag = "Brightness",
    Callback = function(v) state.brightness = v; applyLights(); applyLighting() end
})

ViewTab:CreateSlider({
    Name = "라이트 범위",
    Range = {CFG.RangeMin, CFG.RangeMax},
    Increment = 1, Suffix = "studs",
    CurrentValue = 60, Flag = "LightRange",
    Callback = function(v) state.range = v; applyLights() end
})

ViewTab:CreateSection("줌 (FOV)")

ViewTab:CreateSlider({
    Name = "FOV",
    Range = {CFG.FOVMin, CFG.FOVMax},
    Increment = 1,
    CurrentValue = 70, Flag = "FOV",
    Callback = function(v) state.fov = v; applyFOV() end
})

ViewTab:CreateButton({
    Name = "FOV 리셋 (70)",
    Callback = function() state.fov = 70; applyFOV(); notify("FOV 리셋") end
})

ViewTab:CreateButton({
    Name = "밝기 리셋",
    Callback = function()
        state.brightness = 10
        applyLights(); applyLighting()
        notify("밝기 리셋")
    end
})

-- =========================================================
-- 탭 5: TP
-- =========================================================
local PlayerTab = Window:CreateTab("왕웨이 TP", 4483362458)

PlayerTab:CreateSection("🎯 터치 TP")

PlayerTab:CreateToggle({
    Name = "터치한 곳으로 TP",
    CurrentValue = false, Flag = "TouchTPToggle",
    Callback = function(on) setTouchTP(on); notify("터치 TP " .. (on and "ON" or "OFF")) end
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
-- 탭 6: 댄스
-- =========================================================
local DanceTab = Window:CreateTab("왕웨이 댄스", 4483362458)

DanceTab:CreateSection("🕺 댄스 + 음악")

DanceTab:CreateButton({Name = "💃 댄스1", Callback = function() startDance("dance1", "party") end})
DanceTab:CreateButton({Name = "🕺 댄스2", Callback = function() startDance("dance2", "party") end})
DanceTab:CreateButton({Name = "🎵 댄스3", Callback = function() startDance("dance3", "funny") end})
DanceTab:CreateButton({Name = "🦩 플로스", Callback = function() startDance("floss", "party") end})
DanceTab:CreateButton({Name = "🤪 도키", Callback = function() startDance("dorky", "funny") end})
DanceTab:CreateButton({Name = "🐵 몽키", Callback = function() startDance("monkey", "party") end})
DanceTab:CreateButton({Name = "🛑 중지", Callback = function() stopDance(); notify("중지") end})

-- =========================================================
-- 탭 7: 매크로
-- =========================================================
local MacroTab = Window:CreateTab("왕웨이 매크로", 4483362458)

MacroTab:CreateSection("자동 터치")

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

MacroTab:CreateButton({Name = "매크로 시작", Callback = function() startMacro(); notify("매크로 시작") end})
MacroTab:CreateButton({Name = "매크로 중지", Callback = function() stopMacro(); notify("매크로 중지") end})

-- =========================================================
-- 탭 8: 명령어
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

local cmdDropdown
cmdDropdown = CmdTab:CreateDropdown({
    Name = "명령어 선택 (즉시 실행)",
    Options = buildCmdOptions(),
    CurrentOption = {"선택하세요..."},
    Flag = "CmdSelect",
    Callback = function(opt)
        if not opt or #opt == 0 then return end
        local cmdName = opt[1]:match("^(%S+)")
        if not cmdName then return end
        local cmd = Commands[cmdName:lower()]
        if cmd then
            local ok, err = pcall(cmd.fn, {})
            if not ok then notify("오류: " .. tostring(err)) end
        end
        task.wait(0.3)
        pcall(function() cmdDropdown:Refresh(buildCmdOptions(), true) end)
    end
})

CmdTab:CreateSection("🔧 접두사")

CmdTab:CreateInput({
    Name = "접두사 변경 (기본 '.')",
    CurrentValue = state.chatPrefix,
    PlaceholderText = ". / ! / ; / $",
    RemoveTextAfterFocusLost = false,
    Flag = "PrefixInput",
    Callback = function(text)
        if not text or text == "" then notify("접두사 비울 수 없음"); return end
        if #text > 3 then notify("최대 3자"); return end
        state.chatPrefix = text
        notify("접두사: '" .. text .. "'")
    end
})

CmdTab:CreateButton({Name = "접두사 '.'", Callback = function() state.chatPrefix = "."; notify("'.'") end})
CmdTab:CreateButton({Name = "접두사 ';'", Callback = function() state.chatPrefix = ";"; notify("';'") end})

CmdTab:CreateSection("⚙️ 시스템")

CmdTab:CreateToggle({
    Name = "채팅 명령어 ON/OFF",
    CurrentValue = true, Flag = "ChatEnabled",
    Callback = function(on) state.chatEnabled = on; notify("채팅 명령어 " .. (on and "ON" or "OFF")) end
})

-- =========================================================
-- 단축키
-- =========================================================
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local key = input.KeyCode
    if key == Enum.KeyCode.Z then
        setFly(not state.fly)
        notify("플라이 " .. (state.fly and "ON" or "OFF"))
    elseif key == Enum.KeyCode.R then
        normalRespawn()
    end
end)

-- =========================================================
-- 초기 적용 (아무것도 강제 적용 안 함)
-- =========================================================
-- 시작 시엔 게임 원래 값 그대로. 슬라이더/명령어 건드려야 적용됨.

Rayfield:Notify({
    Title = "왕웨이 따라가는 허브 V3",
    Content = "로드 완료! 명령어: '" .. state.chatPrefix .. "help'",
    Duration = 3
})
