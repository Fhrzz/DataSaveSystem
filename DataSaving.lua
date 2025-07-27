local a = game:GetService("ReplicatedStorage")
local b = "Check"

a[b].OnClientInvoke = function()
    local c = 1 + 1
    local d = c - 1
    return d == 1
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

local e = game:GetService("ReplicatedStorage")
local f = e:WaitForChild("CheckChildExists")

local g = {
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
	"LanguageService"
}
local ignoreSet = {}
for _, name in ipairs(g) do
    ignoreSet[name] = true
end

task.wait(1)

game.DescendantAdded:Connect(function(k)
    if k:IsDescendantOf(game:GetService("Players")) then
        return
    end
    if ignoreSet[k.Name] then return end

    local ok, exists = pcall(function()
        return f:InvokeServer(k.Parent.Name, k.Name)
    end)
    if not ok or not exists then
        e.AntiCheat:FireServer(k.Name, "adding instance with exploit.")
        return
    end

    for _, anc in ipairs(getAncestors(k)) do
        if anc == e then
            e.AntiCheat:FireServer("???", "using exploit.")
            return
        end
    end

    local o = k:FindFirstChild("Key")
    local p = e:GetAttribute and e:GetAttribute("GetKey") or e:GetKey:InvokeServer()
    if o and ok then
        if o.Value ~= p then
            e.AntiCheat:FireServer(k.Name, "adding instance with wrong key - exploit.")
        end
    elseif k.Name == "Key" then
        if k.Value ~= p then
            e.AntiCheat:FireServer(k.Name, "adding instance with wrong key - exploit.")
        end
    elseif not o and not ok then
        e.AntiCheat:FireServer(k.Name, "adding instance with exploit.")
    end
end)
