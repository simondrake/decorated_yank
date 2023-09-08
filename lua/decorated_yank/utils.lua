local Job = require("plenary.job")

local M = {}

function M.get_os_command_output(cmd, cwd)
    if type(cmd) ~= "table" then
        print("decorated_yank: [get_os_command_output]: cmd has to be a table")
        return {}
    end
    local command = table.remove(cmd, 1)
    local stderr = {}
    local stdout, ret = Job
        :new({
            command = command,
            args = cmd,
            cwd = cwd,
            on_stderr = function(_, data)
                table.insert(stderr, data)
            end,
        })
        :sync()
    return stdout, ret, stderr
end

return M
