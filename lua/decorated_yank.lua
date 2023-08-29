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
    for i, line in ipairs(lines) do
      table.insert(tmp_lines, idx .. " " .. line)
      idx = idx + 1
    end

    return table.concat(tmp_lines, "\n")
end


local function decorated_yank()
  local file_name = vim.fn.expand('%')
  local decoration = string.rep('-', string.len(file_name)+1)
  local lines = get_visual_selection()

  vim.fn.setreg('+', decoration .. "\n" .. file_name .. ":\n" .. decoration .. "\n\n" .. lines)
end


return {
  decorated_yank = decorated_yank
}
