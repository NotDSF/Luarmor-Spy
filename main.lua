local Serializer = loadstring(game:HttpGet("https://raw.githubusercontent.com/NotDSF/leopard/main/rbx/leopard-syn.lua"))();
local methods = {
    HttpGet = true,
    HttpGetAsync = true,
    GetObjects = true,
    HttpPost = true,
    HttpPostAsync = true
}

local function printf(...) 
    return rconsoleprint(string.format(...));
end;

local __namecall;
__namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...) 
    local method = getnamecallmethod();

    if methods[method] then
        printf("game:%s(%s)\n\n", method, Serializer.FormatArguments(...));
    end;

    return __namecall(self, ...);
end));

syn.oth.hook(syn.request, function(req) 
    local mt = getrawmetatable(req);
    local response = syn.oth.get_root_callback()(req);

    if not mt then
        printf("syn.request(%s)\n\nResponse Data: %s\n\n", Serializer.Serialize(req), Serializer.Serialize(response));
        return response;
    end;

    printf("Luarmor Internal\nResponse Data: %s\n\n", Serializer.Serialize(response));
    return response;
end);
