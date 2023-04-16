local originalGetgenv = getgenv
local originalSyn = originalGetgenv().syn
local originalRconsoleprint = originalGetgenv().rconsoleprint

if originalSyn then
    originalGetgenv().syn = nil
end

if originalRconsoleprint then
    originalGetgenv().rconsoleprint = nil
end

local Serializer = loadstring(game:HttpGet("https://raw.githubusercontent.com/NotDSF/leopard/main/rbx/leopard-syn.lua"))()
local methods = {
    HttpGet = true,
    HttpGetAsync = true,
    GetObjects = true,
    HttpPost = true,
    HttpPostAsync = true
}

local function printf(...)
    return originalRconsoleprint(string.format(...))
end

local randomName = function()
    return "fn_" .. tostring(math.random(100000, 999999))
end

local hidden = setmetatable({}, {__index = _G})
local setHidden = function(fn)
    local name = randomName()
    hidden[name] = fn
    return name
end

local printFnName = setHidden(printf)
local SerializerName = setHidden(Serializer)

local customGetgenv = setmetatable({}, {
    __index = function(t, k)
        if k == "syn" or k == "rconsoleprint" then
            return nil
        end
        return _G[k]
    end
})

local getgenvHook = setHidden(function()
    return customGetgenv
end)

local __namecall
__namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if methods[method] then
        hidden[printFnName]("game:%s(%s)\n\n", method, hidden[SerializerName].FormatArguments(...))
    end

    return __namecall(self, ...)
end))

local getrawmetatableHook = setHidden(function(obj)
    if obj == syn.request then
        local fakeMetatable = {} -- Create a fake metatable
        return fakeMetatable
    end
    return getrawmetatable(obj)
end)

local synReqHookName = setHidden(function(req)
    local mt = hidden[getrawmetatableHook](req)
    local response = syn.oth.get_root_callback()(req)

    if not mt then
        hidden[printFnName]("syn.request(%s)\n\nResponse Data: %s\n\n", hidden[SerializerName].Serialize(req), hidden[SerializerName].Serialize(response))
        return response
    end

    hidden[printFnName]("Luarmor Internal\nResponse Data: %s\n\n", hidden[SerializerName].Serialize(response))
    return response
end)

if originalSyn then
    syn.oth.hook(syn.request, hidden[synReqHookName])
end

local getgcHook = setHidden(function()
    local result = getgc()
    for _, obj in ipairs({hidden, customGetgenv}) do
        for i = #result, 1, -1 do
            if result[i] == obj then
                table.remove(result, i)
            end
        end
    end
    return result
end)

local isSynapseFunctionHook = setHidden(function(fn)
    if hidden[fn] then
        return false
    end
    return is_synapse_function(fn)
end)

local debugGetupvaluesHook = setHidden(function(fn)
    if hidden[fn] then
        return {}
    end
    return debug.getupvalues(fn)
end)

local loadstringHook = setHidden(function(code)
    hidden[printFnName]("loadstring(%s)\n\n", code)
    return loadstring(code)
end)

local debugGetinfoHook = setHidden(function(...)
    local info = debug.getinfo(...)
    if hidden[info.func] then
        info.source = "[C]"
    end
    return info
end)

local requireHook = setHidden(function(module)
    hidden[printFnName]("require(%s)\n\n", module)
    return require(module)
end)

local setmetatableHook = setHidden(function(t, mt)
    if t == hidden then
        return t
    end
    return setmetatable(t, mt)
end)

local pcallHook = setHidden(function(fn, ...)
    local success, result = pcall(fn, ...)
    if not success and hidden[result] then
        return false, "An error occurred, but it has been handled."
    end
    return success, result
end)

local scriptEnvironment = setmetatable({
    getgc = hidden[getgcHook],
    is_synapse_function = hidden[isSynapseFunctionHook],
    debug = {
        getupvalues = hidden[debugGetupvaluesHook],
        getinfo = hidden[debugGetinfoHook]
    },
    loadstring = hidden[loadstringHook],
    require = hidden[requireHook],
    setmetatable = hidden[setmetatableHook],
    pcall = hidden[pcallHook]
}, {
    __index = function(t, k)
        if k == "syn" or k == "rconsoleprint" then
            return nil
        elseif k == "getgenv" then
            return hidden[getgenvHook]
        elseif k == "getrawmetatable" then
            return hidden[getrawmetatableHook]
        end
        return _G[k]
    end,
    __newindex = function(t, k, v)
        _G[k] = v
    end
})

setfenv(1, scriptEnvironment)

