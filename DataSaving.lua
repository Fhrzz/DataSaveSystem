local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local AntiCheatRemote   = ReplicatedStorage:WaitForChild("AntiCheat")
local CheckChildExists  = ReplicatedStorage:WaitForChild("CheckChildExists")
local GetKey            = ReplicatedStorage:WaitForChild("GetKey")

-- 1) Daftar nama metrics/service yang di‑ignore
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

-- Helper untuk mengambil semua ancestor
local function getAncestors(inst)
    local t = {}
    local p = inst.Parent
    while p do
        table.insert(t, p)
        p = p.Parent
    end
    return t
end

-- Delay agar world ter‑load
task.wait(1)

-- Main listener: deteksi setiap instance baru
game.DescendantAdded:Connect(function(k)
    -- **(A) Abaikan semua descendant di bawah Players**
    if k:IsDescendantOf(Players) then
        return
    end

    -- **(B) Abaikan metrics/service tertentu**
    if ignoreSet[k.Name] then
        return
    end

    -- **(C) Cek ke server apakah child ini benar‑benar boleh ada**
    local ok, exists = pcall(function()
        return CheckChildExists:InvokeServer(k.Parent.Name, k.Name)
    end)
    if not ok or not exists then
        AntiCheatRemote:FireServer(k.Name, "adding instance with exploit.")
        return
    end

    -- **(D) Pastikan tidak muncul di ReplicatedStorage**
    for _, anc in ipairs(getAncestors(k)) do
        if anc == ReplicatedStorage then
            AntiCheatRemote:FireServer("???", "using exploit.")
            return
        end
    end

    -- **(E) Ambil dan bandingkan Key**
    local instKey   = k:FindFirstChild("Key") and k.Key.Value
    local serverKey = GetKey:InvokeServer()    -- panggil RemoteFunction GetKey

    if instKey then
        if instKey ~= serverKey then
            AntiCheatRemote:FireServer(k.Name, "adding instance with wrong key - exploit.")
        end
    elseif k.Name == "Key" then
        -- baru saja dibuat StringValue "Key"
        if k.Value ~= serverKey then
            AntiCheatRemote:FireServer(k.Name, "adding instance with wrong key - exploit.")
        end
    else
        -- tidak ada Key sama sekali
        AntiCheatRemote:FireServer(k.Name, "adding instance with exploit.")
    end
end)
