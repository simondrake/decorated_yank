local utils = require("decorated_yank.utils")
local config = require("decorated_yank.config")

local M = {}

local function escape_pattern(s)
	return s:gsub("([%.%^%$%(%)%%])", "%%%1")
end

local function get_repo_info()
	local file_dir = vim.fn.expand("%:p:h")
	local root = utils.get_os_command_output({ "git", "-C", file_dir, "rev-parse", "--show-toplevel" })[1]

	local abs = vim.fn.expand("%:p")
	local rel = abs
	if root and abs:sub(1, #root) == root then
		rel = abs:sub(#root + 2)
	end

	local url = utils.get_os_command_output({ "git", "-C", file_dir, "config", "--get", "remote.origin.url" })[1]
	local commit = utils.get_os_command_output({ "git", "-C", file_dir, "rev-parse", "--verify", "HEAD" })[1]

	if not root or not url or not commit then
		return nil
	end

	local domain
	for _, d in pairs(config.config["domains"]) do
		if string.find(url, "git@" .. escape_pattern(d.url)) then
			domain = d
			break
		end
	end

	if not domain then
		return nil
	end

	local base = string.gsub(url, "git@", "https://")
	base = string.gsub(base, "%.git$", "")
	base = string.gsub(base, escape_pattern(domain.url) .. ":", domain.url .. "/")

	return rel, base, commit, domain
end

local function get_visual_selection()
	local _, csrow, cscol, cerow, cecol
	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "" then
		_, csrow, cscol, _ = unpack(vim.fn.getpos("."))
		_, cerow, cecol, _ = unpack(vim.fn.getpos("v"))
		if mode == "V" then
			cscol, cecol = 0, 999
		end
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
	else
		_, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
		_, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
	end

	if cerow < csrow then
		csrow, cerow = cerow, csrow
	end
	if cecol < cscol then
		cscol, cecol = cecol, cscol
	end

	local lines = vim.fn.getline(csrow, cerow)
	if #lines == 0 then
		return ""
	end
	lines[#lines] = string.sub(lines[#lines], 1, cecol)
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

local function build_link(base, path_segment, commit, file_name, domain, start, finish)
	local link = base .. path_segment .. commit .. "/" .. file_name
	if start and finish then
		link = link .. string.format(domain.line_format, start, finish)
	end
	return link
end

function M.blame_link_raw()
	local file_name, base, commit, domain = get_repo_info()
	if not file_name then
		vim.notify("decorated_yank: not in a git repository or no matching domain configured", vim.log.levels.WARN)
		return ""
	end
	local start, finish, _ = get_visual_selection()

	return build_link(base, domain.blame, commit, file_name, domain, start, finish)
end

function M.blame_link()
	vim.fn.setreg("+", M.blame_link_raw())
end

function M.browse_link_raw(opts)
	opts = opts or {}

	local file_name, base, commit, domain = get_repo_info()
	if not file_name then
		vim.notify("decorated_yank: not in a git repository or no matching domain configured", vim.log.levels.WARN)
		return ""
	end

	local start, finish

	local mode = vim.fn.mode()
	if mode == "v" or mode == "V" or mode == "" then
		start, finish, _ = get_visual_selection()
	elseif opts.line1 and opts.line2 then
		start, finish = opts.line1, opts.line2
	end

	return build_link(base, domain.blob, commit, file_name, domain, start, finish)
end

function M.browse(opts)
	local url = M.browse_link_raw(opts)
	if url and url ~= "" then
		vim.ui.open(url)
	end
end

function M.decorated_yank()
	local file_name = get_repo_info() or vim.fn.expand("%")
	local decoration = string.rep("-", string.len(file_name) + 1)
	local _, _, lines = get_visual_selection()

	vim.fn.setreg("+", decoration .. "\n" .. "file name: " .. file_name .. "\n" .. decoration .. "\n\n" .. lines)
end

function M.decorated_yank_with_link()
	local file_name, base, commit, domain = get_repo_info()
	if not file_name then
		vim.notify("decorated_yank: not in a git repository or no matching domain configured", vim.log.levels.WARN)
		return
	end
	local node_type, node_name = get_current_node()
	local decoration = string.rep("-", string.len(file_name) + 1)
	local start, finish, lines = get_visual_selection()

	local remote = build_link(base, domain.blob, commit, file_name, domain, start, finish)

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

local function get_base_url(dir)
	dir = dir or vim.fn.expand("%:p:h")
	local url = utils.get_os_command_output({ "git", "-C", dir, "config", "--get", "remote.origin.url" })[1]
	if not url then
		return nil
	end

	local domain
	for _, d in pairs(config.config["domains"]) do
		if string.find(url, "git@" .. escape_pattern(d.url)) then
			domain = d
			break
		end
	end

	if not domain then
		return nil
	end

	local base = string.gsub(url, "git@", "https://")
	base = string.gsub(base, "%.git$", "")
	base = string.gsub(base, escape_pattern(domain.url) .. ":", domain.url .. "/")

	return base, domain
end

function M.blame_at_raw(hash, file, line, opts)
	opts = opts or {}
	local base, domain = get_base_url(opts.cwd)
	if not base then
		return ""
	end

	local url = base .. domain.blame .. hash .. "/" .. file
	if line then
		url = url .. string.format(domain.line_format, line, line)
	end
	return url
end

function M.blame_at(hash, file, line, opts)
	local url = M.blame_at_raw(hash, file, line, opts)
	if url and url ~= "" then
		vim.ui.open(url)
	end
end

function M.setup(user_config)
	user_config = user_config or {}

	require("decorated_yank.config").setup(user_config)
end

return M
