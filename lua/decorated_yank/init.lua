local utils = require("decorated_yank.utils")
local config = require("decorated_yank.config")

local M = {}

local function tbl_length(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local function get_visual_selection()
    -- this will exit visual mode
    -- use 'gv' to reselect the text
    local _, csrow, cscol, cerow, cecol
    local mode = vim.fn.mode()
    if mode == 'v' or mode == 'V' or mode == '' then
      -- if we are in visual mode use the live position
      _, csrow, cscol, _ = unpack(vim.fn.getpos("."))
      _, cerow, cecol, _ = unpack(vim.fn.getpos("v"))
      if mode == 'V' then
        -- visual line doesn't provide columns
        cscol, cecol = 0, 999
      end
      -- exit visual mode
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<Esc>",
          true, false, true), 'n', true)
    else
      -- otherwise, use the last known visual position
      _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
      _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
    end
    -- swap vars if needed
    if cerow < csrow then csrow, cerow = cerow, csrow end
    if cecol < cscol then cscol, cecol = cecol, cscol end

    local lines = vim.fn.getline(csrow, cerow)
    -- local n = cerow-csrow+1
    local n = tbl_length(lines)
    if n <= 0 then return '' end
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

function M.decorated_yank()
  local project_root = vim.fn.finddir('.git/..', vim.fn.expand('%:p:h')..';')
  vim.fn.chdir(project_root)

  local file_name = vim.fn.expand('%')
  local decoration = string.rep('-', string.len(file_name)+1)
  local _, _, lines = get_visual_selection()

  vim.fn.setreg('+', decoration .. "\n" .. "file name: " .. file_name .. "\n" .. decoration .. "\n\n" .. lines)
end

function M.decorated_yank_with_link()
  local project_root = vim.fn.finddir('.git/..', vim.fn.expand('%:p:h')..';')
  vim.fn.chdir(project_root)

  local file_name = vim.fn.expand('%')
  local decoration = string.rep('-', string.len(file_name)+1)
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

  local remote = ''

  for _, domain in pairs(config.config["domains"]) do
    if string.find(url, "git@" .. domain.url) then
      remote = string.gsub(url, "git@", "https://")
      remote = string.gsub(remote, ".git$", "")
      remote = string.gsub(remote, domain.url .. ":", domain.url .. "/")
      remote = remote .. domain.blob .. commit .. "/" .. file_name .. string.format(domain.line_format, start, finish)
    end
  end

  vim.fn.setreg('+', decoration .. "\n" .. "file name: " .. file_name .. "\n\n" .. "link: " .. remote .. "\n" .. decoration .. "\n\n" .. lines)
end

function M.setup(user_config)
    user_config = user_config or {}

    require("decorated_yank.config").setup(user_config)
end

return M
