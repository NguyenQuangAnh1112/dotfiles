local state_file = vim.fn.stdpath("data") .. "/oil-hidden-state"

local hidden_extensions = {
  -- Unity metadata & serialized assets
  meta = true, prefab = true, unity = true, mat = true, asset = true,
  anim = true, controller = true, overrideController = true,
  physicMaterial = true, physicsMaterial2D = true, guiskin = true,
  fontsettings = true, lighting = true, cubemap = true,
  renderTexture = true, mask = true, terrainlayer = true,
  brush = true, flare = true,

  -- Images / Textures
  png = true, jpg = true, jpeg = true, tga = true, psd = true,
  bmp = true, tif = true, tiff = true, hdr = true, exr = true, ico = true,

  -- Audio
  mp3 = true, wav = true, ogg = true, flac = true, aif = true, aiff = true,

  -- 3D Models
  fbx = true, obj = true, blend = true, dae = true,
  ["3ds"] = true, glb = true, gltf = true,

  -- Fonts
  ttf = true, otf = true, woff = true, woff2 = true,

  -- Binary / Build
  dll = true, exe = true, so = true, a = true, dylib = true,
  pdb = true, mdb = true, pidb = true,
  csproj = true, sln = true, slnx = true,
  zip = true, tar = true, gz = true, ["7z"] = true, rar = true,
  unitypackage = true,
}

local function read_state()
  local f = io.open(state_file, "r")
  if not f then return false end -- default: false = hide non-code files
  local content = f:read("*a")
  f:close()
  return content == "show"
end

local function write_state(show_all)
  local f = io.open(state_file, "w")
  if f then
    f:write(show_all and "show" or "hide")
    f:close()
  end
end

-- show_hidden = false: ẩn hoàn toàn file bị is_hidden_file đánh dấu
-- show_hidden = true:  hiện tất cả
local initial_show = read_state()

local function toggle_oil_sidebar()
  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_win_get_buf(cur_win)

  -- Find existing oil sidebar in current tabpage
  local sidebar_win = nil
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.w[win].is_oil_sidebar and vim.api.nvim_win_is_valid(win) then
      sidebar_win = win
      break
    end
  end

  if sidebar_win then
    -- Case 1: Sidebar is open, cursor in sidebar -> switch focus to editor window
    if cur_win == sidebar_win then
      local target_win = vim.w[sidebar_win].oil_editor_win
      if not (target_win and vim.api.nvim_win_is_valid(target_win) and target_win ~= sidebar_win) then
        target_win = nil
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if win ~= sidebar_win and vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype ~= "oil" then
              target_win = win
              break
            end
          end
        end
      end

      if target_win then
        local target_buf = vim.api.nvim_win_get_buf(target_win)
        local target_file = vim.api.nvim_buf_get_name(target_buf)
        if target_file ~= "" and vim.bo[target_buf].buftype == "" and vim.fn.filereadable(target_file) == 1 then
          local target_basename = vim.fs.basename(target_file)
          local target_dir = vim.fs.dirname(target_file)
          local oil = require("oil")
          local target_url = oil.get_url_for_path(target_dir)
          local sidebar_buf = vim.api.nvim_win_get_buf(sidebar_win)
          local sidebar_url = vim.api.nvim_buf_get_name(sidebar_buf)

          if sidebar_url == target_url then
            local line_count = vim.api.nvim_buf_line_count(sidebar_buf)
            for lnum = 1, line_count do
              local entry = oil.get_entry_on_line(sidebar_buf, lnum)
              if entry and entry.name == target_basename then
                local line = vim.api.nvim_buf_get_lines(sidebar_buf, lnum - 1, lnum, true)[1]
                local col = line and line:find(target_basename, 1, true) or 1
                pcall(vim.api.nvim_win_set_cursor, sidebar_win, { lnum, col - 1 })
                break
              end
            end
          else
            require("oil.view").set_last_cursor(target_url, target_basename)
            oil.open(target_dir)
          end
        end

        vim.api.nvim_set_current_win(target_win)
      end
      return
    end

    -- Case 2: Sidebar is open, cursor in editor window -> switch back to sidebar
    vim.w[sidebar_win].oil_editor_win = cur_win

    local cur_file = vim.api.nvim_buf_get_name(cur_buf)
    local is_real_file = cur_file ~= ""
      and vim.bo[cur_buf].buftype == ""
      and vim.fn.filereadable(cur_file) == 1

    local oil = require("oil")
    local sidebar_buf = vim.api.nvim_win_get_buf(sidebar_win)
    local sidebar_url = vim.api.nvim_buf_get_name(sidebar_buf)

    vim.api.nvim_set_current_win(sidebar_win)

    if is_real_file then
      local cur_dir = vim.fs.dirname(cur_file)
      local basename = vim.fs.basename(cur_file)
      local target_url = oil.get_url_for_path(cur_dir)

      if sidebar_url == target_url then
        -- Same directory: just move cursor to current file
        local line_count = vim.api.nvim_buf_line_count(sidebar_buf)
        for lnum = 1, line_count do
          local entry = oil.get_entry_on_line(sidebar_buf, lnum)
          if entry and entry.name == basename then
            local line = vim.api.nvim_buf_get_lines(sidebar_buf, lnum - 1, lnum, true)[1]
            local col = line and line:find(basename, 1, true) or 1
            pcall(vim.api.nvim_win_set_cursor, sidebar_win, { lnum, col - 1 })
            break
          end
        end
      else
        -- Different directory: navigate sidebar to cur_dir and focus basename
        require("oil.view").set_last_cursor(target_url, basename)
        oil.open(cur_dir, {}, function()
          vim.schedule(function()
            if not vim.api.nvim_win_is_valid(sidebar_win) then
              return
            end
            local line_count = vim.api.nvim_buf_line_count(0)
            for lnum = 1, line_count do
              local entry = oil.get_entry_on_line(0, lnum)
              if entry and entry.name == basename then
                local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
                local col = line and line:find(basename, 1, true) or 1
                pcall(vim.api.nvim_win_set_cursor, sidebar_win, { lnum, col - 1 })
                break
              end
            end
          end)
        end)
      end
    end
    return
  end

  -- Case 3: Sidebar is NOT open -> open it
  local cur_file = vim.api.nvim_buf_get_name(cur_buf)
  local is_real_file = cur_file ~= ""
    and vim.bo[cur_buf].buftype == ""
    and vim.fn.filereadable(cur_file) == 1
  local cur_dir = is_real_file and vim.fs.dirname(cur_file) or nil
  local basename = is_real_file and vim.fs.basename(cur_file) or nil
  local prev_win = cur_win

  vim.cmd("topleft 35vsplit")
  vim.cmd("vertical resize 35")
  sidebar_win = vim.api.nvim_get_current_win()
  vim.w[sidebar_win].is_oil_sidebar = true
  vim.w[sidebar_win].oil_editor_win = prev_win
  vim.wo[sidebar_win].winfixwidth = true

  local oil = require("oil")
  if cur_dir and basename then
    local parent_url = oil.get_url_for_path(cur_dir)
    require("oil.view").set_last_cursor(parent_url, basename)
    oil.open(cur_dir, {}, function()
      vim.schedule(function()
        if not vim.api.nvim_win_is_valid(sidebar_win) then
          return
        end
        local line_count = vim.api.nvim_buf_line_count(0)
        for lnum = 1, line_count do
          local entry = oil.get_entry_on_line(0, lnum)
          if entry and entry.name == basename then
            local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, true)[1]
            local col = line and line:find(basename, 1, true) or 1
            pcall(vim.api.nvim_win_set_cursor, sidebar_win, { lnum, col - 1 })
            break
          end
        end
      end)
    end)
  else
    oil.open()
  end
end

local function select_in_oil()
  local oil = require("oil")
  local cur_win = vim.api.nvim_get_current_win()

  if not vim.w[cur_win].is_oil_sidebar then
    oil.select()
    return
  end

  local entry = oil.get_cursor_entry()
  if not entry then
    return
  end

  if entry.type == "directory" then
    oil.select()
  else
    local main_win = nil
    local rem_win = vim.w[cur_win].oil_editor_win
    if rem_win and vim.api.nvim_win_is_valid(rem_win) and rem_win ~= cur_win then
      main_win = rem_win
    else
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if win ~= cur_win and not vim.w[win].is_oil_sidebar and vim.api.nvim_win_is_valid(win) then
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].filetype ~= "oil" then
            main_win = win
            break
          end
        end
      end
    end

    if not main_win then
      vim.cmd("rightbelow vsplit")
      main_win = vim.api.nvim_get_current_win()
    end

    local dir = oil.get_current_dir()
    if not dir then
      oil.select()
      return
    end

    local path = vim.fs.joinpath(dir, entry.name)
    vim.w[cur_win].oil_editor_win = main_win
    vim.api.nvim_set_current_win(main_win)
    vim.cmd.edit(vim.fn.fnameescape(path))
  end
end

return {
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      {
        "-",
        "<cmd>Oil<CR>",
        desc = "Open Oil (buffer)",
      },
      {
        "<leader>v",
        toggle_oil_sidebar,
        desc = "Toggle Oil sidebar",
      },
    },
    opts = {
      default_file_explorer = true,
      keymaps = {
        ["<CR>"] = {
          callback = select_in_oil,
          desc = "Select entry (opens in editor window if in sidebar)",
        },
        ["q"] = {
          callback = function()
            local cur_win = vim.api.nvim_get_current_win()
            if vim.w[cur_win].is_oil_sidebar then
              vim.api.nvim_win_close(cur_win, true)
            else
              require("oil").close()
            end
          end,
          desc = "Close Oil",
        },
        ["g."] = {
          callback = function()
            local config = require("oil.config")
            local currently_showing = config.view_options.show_hidden
            local next_state = not currently_showing

            config.view_options.show_hidden = next_state
            write_state(next_state)
            vim.cmd("edit")

            vim.notify(
              next_state and "Oil: hiện tất cả" or "Oil: chỉ hiện code",
              vim.log.levels.INFO
            )
          end,
          desc = "Toggle hidden files",
        },
      },
      view_options = {
        show_hidden = initial_show,
        is_hidden_file = function(name)
          if name:sub(1, 1) == "." then
            return true
          end

          local ext = name:match("%.([^%.]+)$")
          return ext and hidden_extensions[ext] or false
        end,
      },
      float = {
        border = "rounded",
      },
    },
  },
}
