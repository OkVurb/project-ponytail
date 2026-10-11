local profiler = require("@src/utility/profiler");
local Feature = {};
Feature.__index = Feature;
function Feature.new(_, id: string, conn: RBXScriptSignal?, func: any?)
    local self = setmetatable({}, Feature);
    self.id = id;
    self.conn = conn;
    self.func = func or function() end;
    self.update = profiler.wrap_no_xpcall(id, self.func);
    self.current_connection = nil;
    self.enabled = false;
    return self;
end;
function Feature:enable()
    self.enabled = true;
    -- The UI/automation normally binds first. Never subscribe twice.
    if self.conn and not self.current_connection then
        self.current_connection = self.conn:Connect(function(...) xpcall(self.update, warn, ...); end);
        if aztup and aztup.maid then aztup.maid:give_task(self.current_connection); end;
    end;
end;
function Feature:disable()
    self.enabled = false;
    if self.current_connection then
        self.current_connection:Disconnect();
        self.current_connection = nil;
    end;
end;
return Feature;
