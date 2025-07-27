local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local AntiCheatRemote   = ReplicatedStorage:WaitForChild("AntiCheat")
local CheckChildExists  = ReplicatedStorage:WaitForChild("CheckChildExists")
local GetKey            = ReplicatedStorage:WaitForChild("GetKey")

-- Daftar nama metrics/service yang di‑ignore
local ignoreNames = {
    "FrameRateManager","DeviceFeatureLevel","DeviceShadingLanguage",
    "AverageQualityLevel","AutoQuality","NumberOfSettles","AverageSwitches",
    "FramebufferWidth","FramebufferHeight","Batches","Indices","MaterialChanges",
    "VideoMemoryInMB","AverageFPS","FrameTimeVariance","FrameSpikeCount",
    "RenderAverage","PrepareAverage","PerformAverage","AveragePresent",
    "AverageGPU","RenderThreadAverage","TotalFrameWallAverage","PerformVariance",
    "PresentVariance","GpuVariance","MsFrame0","MsFrame1","MsFrame2","MsFrame3",
    "MsFrame4","MsFrame5","MsFrame6","MsFrame7","MsFrame8","MsFrame9",
    "MsFrame10","MsFrame11","Render","Memory","Video","CursorImage","LanguageService"
}
local ignoreSet = {}
for _, n in ipairs(ignoreNames) do
    ignoreSet[n] = true
end

local function getAncestors(inst)
    local t = {}
    local p = inst.Parent
    while p do
        table.insert(t, p)
        p = p.Parent
    end
    return t
end

-- delay biar world ter‑load
task.wait(1)

game.DescendantAdded:Connect(function(k)
    -- 1) Abaikan semua di bawah Players
    if k:IsDescendantOf(Players) then
        return
    end

    -- 2) Abaikan nama metrics/service
    if ignoreSet[k.Name] then
        return
    end

    -- 3) Cek di server apakah child sah
    local ok, exists = pcall(function()
        return CheckChildExists:InvokeServer(k.Parent.Name, k.Name)
    end)
    if not ok or not exists then
        AntiCheatRemote:FireServer(k.Name, "adding instance with exploit.")
        return
    end

    -- 4) Pastikan tidak ditanam di ReplicatedStorage
    for _, anc in ipairs(getAncestors(k)) do
        if anc == ReplicatedStorage then
            AntiCheatRemote:FireServer("???", "using exploit.")
            return
        end
    end

    -- 5) **Ambil key yang benar** dan bandingkan
    local instKey   = k:FindFirstChild("Key") and k.Key.Value
    local serverKey = GetKey:InvokeServer()    -- <<-- perbaikan di sini

    if instKey then
        if instKey ~= serverKey then
            AntiCheatRemote:FireServer(k.Name, "adding instance with wrong key - exploit.")
        end
    elseif k.Name == "Key" then
        -- stringvalue Key baru saja dibuat
        if k.Value ~= serverKey then
            AntiCheatRemote:FireServer(k.Name, "adding instance with wrong key - exploit.")
        end
    else
        -- tidak ada Key sama sekali
        AntiCheatRemote:FireServer(k.Name, "adding instance with exploit.")
    end
end)
