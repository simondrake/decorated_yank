local M = {}

M.config = {
	domains = {
		github = {
			url = "github.com",
			blob = "/blob/",
			blame = "/blame/",
			line_format = "#L%s-L%s",
		},
	},
}

local function check_config(config)
	local err
	return not err
end

function M.setup(config)
	if check_config(config) then
		M.config = vim.tbl_deep_extend("force", M.config, config or {})
	else
		vim.notify("Errors found while loading user config. Using default config.", vim.log.levels.ERROR)
	end
end

return M
