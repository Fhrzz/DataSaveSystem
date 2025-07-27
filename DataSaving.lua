local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local AntiCheatRemote   = ReplicatedStorage:WaitForChild("AntiCheat")
local CheckChildExists  = ReplicatedStorage:WaitForChild("CheckChildExists")
local GetKey            = ReplicatedStorage:WaitForChild("GetKey")

-- 1) Daftar nama metrics/service yang di‑ignore
local ignoreNames = {
    "FrameRateManager",
	"DeviceFeatureLevel",
	"DeviceShadingLanguage",
	"AverageQualityLevel",
	"AutoQuality",
	"NumberOfSettles",
	"AverageSwitches",
	"FramebufferWidth",
	"FramebufferHeight",
	"Batches",
	"Indices",
	"MaterialChanges",
	"VideoMemoryInMB",
	"AverageFPS",
	"FrameTimeVariance",
	"FrameSpikeCount",
	"RenderAverage",
	"PrepareAverage",
	"PerformAverage",
	"AveragePresent",
	"AverageGPU",
	"RenderThreadAverage",
	"TotalFrameWallAverage",
	"PerformVariance",
	"PresentVariance",
	"GpuVariance",
	"MsFrame0",
	"MsFrame1",
	"MsFrame2",
	"MsFrame3",
	"MsFrame4",
	"MsFrame5",
	"MsFrame6",
	"MsFrame7",
	"MsFrame8",
	"MsFrame9",
	"MsFrame10",
	"MsFrame11",
	"Render",
	"Memory",
	"Video",
	"CursorImage",
	"LanguageService",
    "UIDragDetectorService",
    "MemStorageConnection"
}
local ignoreSet = {}
for _, n in ipairs(ignoreNames) do
    ignoreSet[n] = true
end

-- Helper: apakah inst atau salah satu parent‑nya adalah Character model?
local function isCharacter(inst)
    return inst:IsA("Model") and Players:GetPlayerFromCharacter(inst) ~= nil
end
local function isInCharacter(inst)
    local cur = inst
    while cur do
        if isCharacter(cur) then
            return true
        end
        cur = cur.Parent
    end
    return false
end

-- Helper: ambil semua ancestor untuk cek ReplicatedStorage
local function getAncestors(inst)
    local t, p = {}, inst.Parent
    while p do
        table.insert(t, p)
        p = p.Parent
    end
    return t
end

-- delay biar world ter‑load
task.wait(1)

game.DescendantAdded:Connect(function(k)
    -- **NEW**: Abaikan apa pun di bawah game.Players (StarterGear, Backpack, player Instances, dll.)
    if k:IsDescendantOf(Players) then
        return
    end

    -- 1) Abaikan apa pun di dalam Character model
    if isInCharacter(k) then
        return
    end

    -- 2) Abaikan StringValue "Key" (rotasi server side)
    if k:IsA("StringValue") and k.Name == "Key" then
        return
    end

    -- 3) Abaikan metrics/service tertentu
    if ignoreSet[k.Name] then
        return
    end

    -- 4) Cek di server apakah child sah
    local ok, exists = pcall(function()
        return CheckChildExists:InvokeServer(k.Parent.Name, k.Name)
    end)
    if not ok or not exists then
        AntiCheatRemote:FireServer(k.Name, "adding instance with exploit.")
        return
    end

    -- 5) Pastikan tidak ditanam di ReplicatedStorage
    for _, anc in ipairs(getAncestors(k)) do
        if anc == ReplicatedStorage then
            AntiCheatRemote:FireServer("???", "using exploit.")
            return
        end
    end

    -- 6) Ambil dan bandingkan Key
    local instKey   = k:FindFirstChild("Key") and k.Key.Value
    local serverKey = GetKey:InvokeServer()
    if instKey then
        if instKey ~= serverKey then
            AntiCheatRemote:FireServer(k.Name, "adding instance with wrong key - exploit.")
        end
    elseif k.Name == "Key" then
        if k.Value ~= serverKey then
            AntiCheatRemote:FireServer(k.Name, "adding instance with wrong key - exploit.")
        end
    else
        AntiCheatRemote:FireServer(k.Name, "adding instance with exploit.")
    end
end)
