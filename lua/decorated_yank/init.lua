local utils = require("decorated_yank.utils")
local config = require("decorated_yank.config")

local M = {}

local function tbl_length(T)
	local count = 0
	for _ in pairs(T) do
		count = count + 1
	end
	return count
end

local function get_visual_selection()
	-- this will exit visual mode
	-- use 'gv' to reselect the text
	local _, csrow, cscol, cerow, cecol
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "" then
		-- if we are in visual mode use the live position
		_, csrow, cscol, _ = unpack(vim.fn.getpos("."))
		_, cerow, cecol, _ = unpack(vim.fn.getpos("v"))
		if mode == "V" then
			-- visual line doesn't provide columns
			cscol, cecol = 0, 999
		end
		-- exit visual mode
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
	else
		-- otherwise, use the last known visual position
		_, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
		_, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
	end
	-- swap vars if needed
	if cerow < csrow then
		csrow, cerow = cerow, csrow
	end
	if cecol < cscol then
		cscol, cecol = cecol, cscol
	end

	local lines = vim.fn.getline(csrow, cerow)
	-- local n = cerow-csrow+1
	local n = tbl_length(lines)
	if n <= 0 then
		return ""
	end
	lines[n] = string.sub(lines[n], 1, cecol)
	lines[1] = string.sub(lines[1], cscol)

	local tmp_lines = {}
	local idx = csrow
	for _, line in ipairs(lines) do
		table.insert(tmp_lines, idx .. " " .. line)
		idx = idx + 1
	end

	return csrow, cerow, table.concat(tmp_lines, "\n")
end

local function get_current_node()
	-- Only continue if treesitter has an active parser
	-- avoids the "no parser for language error"
	local buf = vim.api.nvim_get_current_buf()
	local highlighter = require("vim.treesitter.highlighter")

	if not highlighter.active[buf] then
		return ""
	end

	local current_node = vim.treesitter.get_node()

	if not current_node then
		return ""
	end

	local expr = current_node

	while expr do
		if
			expr:type() == "type_spec"
			or expr:type() == "function_declaration"
			or expr:type() == "method_declaration"
		then
			break
		end
		expr = expr:parent()
	end

	if not expr then
		return ""
	end

	if #expr:field("name") == 0 then
		return ""
	end

	return expr:type(), vim.treesitter.get_node_text(expr:field("name")[1], 0)
end

function M.blame_link()
	local project_root = vim.fn.finddir(".git/..", vim.fn.expand("%:p:h") .. ";")
	vim.fn.chdir(project_root)

	local file_name = vim.fn.expand("%")
	local start, finish, _ = get_visual_selection()

	local url = utils.get_os_command_output({
		"git",
		"config",
		"--get",
		"remote.origin.url",
	})[1]

	local commit = utils.get_os_command_output({
		"git",
		"rev-parse",
		"--verify",
		"HEAD",
	})[1]

	local remote = ""

	for _, domain in pairs(config.config["domains"]) do
		if string.find(url, "git@" .. domain.url) then
			remote = string.gsub(url, "git@", "https://")
			remote = string.gsub(remote, ".git$", "")
			remote = string.gsub(remote, domain.url .. ":", domain.url .. "/")
			remote = remote
				.. domain.blame
				.. commit
				.. "/"
				.. file_name
				.. string.format(domain.line_format, start, finish)
		end
	end

	vim.fn.setreg("+", remote)
end

function M.decorated_yank()
	local project_root = vim.fn.finddir(".git/..", vim.fn.expand("%:p:h") .. ";")
	vim.fn.chdir(project_root)

	local file_name = vim.fn.expand("%")
	local decoration = string.rep("-", string.len(file_name) + 1)
	local _, _, lines = get_visual_selection()

	vim.fn.setreg("+", decoration .. "\n" .. "file name: " .. file_name .. "\n" .. decoration .. "\n\n" .. lines)
end

function M.decorated_yank_with_link()
	local project_root = vim.fn.finddir(".git/..", vim.fn.expand("%:p:h") .. ";")
	vim.fn.chdir(project_root)

	local file_name = vim.fn.expand("%")
	local node_type, node_name = get_current_node()
	local decoration = string.rep("-", string.len(file_name) + 1)
	local start, finish, lines = get_visual_selection()

	local url = utils.get_os_command_output({
		"git",
		"config",
		"--get",
		"remote.origin.url",
	})[1]

	local commit = utils.get_os_command_output({
		"git",
		"rev-parse",
		"--verify",
		"HEAD",
	})[1]

	local remote = ""

	for _, domain in pairs(config.config["domains"]) do
		if string.find(url, "git@" .. domain.url) then
			remote = string.gsub(url, "git@", "https://")
			remote = string.gsub(remote, ".git$", "")
			remote = string.gsub(remote, domain.url .. ":", domain.url .. "/")
			remote = remote
				.. domain.blob
				.. commit
				.. "/"
				.. file_name
				.. string.format(domain.line_format, start, finish)
		end
	end

	if node_type == "type_spec" then
		node_type = "type name: "
	elseif node_type == "function_declaration" then
		node_type = "function name: "
	elseif node_type == "method_declaration" then
		node_type = "method name: "
	end

	local out = decoration .. "\n" .. "file name: " .. file_name .. "\n\n"

	if node_type and node_name then
		out = out .. node_type .. node_name .. "\n\n"
	end

	out = out .. "link: " .. remote .. "\n" .. decoration .. "\n\n" .. lines

	vim.fn.setreg("+", out)
end

function M.setup(user_config)
	user_config = user_config or {}

	require("decorated_yank.config").setup(user_config)
end

return M
