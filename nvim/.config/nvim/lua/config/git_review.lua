local ignored_extensions = {
  -- Unity metadata & serialized assets
  ["meta"] = true,
  ["prefab"] = true,
  ["unity"] = true,
  ["mat"] = true,
  ["asset"] = true,
  ["anim"] = true,
  ["controller"] = true,
  ["overridecontroller"] = true,
  ["physicmaterial"] = true,
  ["physicsmaterial2d"] = true,
  ["guiskin"] = true,
  ["fontsettings"] = true,
  ["lighting"] = true,
  ["cubemap"] = true,
  ["rendertexture"] = true,
  ["mask"] = true,
  ["terrainlayer"] = true,
  ["brush"] = true,
  ["flare"] = true,

  -- Media / Textures / Images
  ["png"] = true,
  ["jpg"] = true,
  ["jpeg"] = true,
  ["tga"] = true,
  ["psd"] = true,
  ["bmp"] = true,
  ["tif"] = true,
  ["tiff"] = true,
  ["hdr"] = true,
  ["exr"] = true,
  ["ico"] = true,

  -- Audio
  ["mp3"] = true,
  ["wav"] = true,
  ["ogg"] = true,
  ["flac"] = true,
  ["aif"] = true,
  ["aiff"] = true,

  -- 3D Models
  ["fbx"] = true,
  ["obj"] = true,
  ["blend"] = true,
  ["dae"] = true,
  ["3ds"] = true,
  ["glb"] = true,
  ["gltf"] = true,

  -- Fonts
  ["ttf"] = true,
  ["otf"] = true,
  ["woff"] = true,
  ["woff2"] = true,

  -- Binary / Build / Cache
  ["dll"] = true,
  ["exe"] = true,
  ["so"] = true,
  ["a"] = true,
  ["dylib"] = true,
  ["pdb"] = true,
  ["mdb"] = true,
  ["pidb"] = true,
  ["csproj"] = true,
  ["sln"] = true,
  ["zip"] = true,
  ["tar"] = true,
  ["gz"] = true,
  ["7z"] = true,
  ["rar"] = true,
  ["unitypackage"] = true,
}

local function is_code_file(path)
  local filename = vim.fs.basename(path)
  if filename:match("%.meta$") then
    return false
  end

  local ext = vim.fn.fnamemodify(path, ":e"):lower()
  if ignored_extensions[ext] then
    return false
  end

  return true
end

local function switch_to_existing_file_window(path)
  local real_path = vim.fs.normalize(path)
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
      local bufnr = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(bufnr) then
        local buf_name = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
        if buf_name == real_path then
          vim.api.nvim_set_current_tabpage(tabpage)
          vim.api.nvim_set_current_win(win)
          return true
        end
      end
    end
  end
  return false
end

local function open_file(path, target)
  target = target or "current"
  if target == "current" and switch_to_existing_file_window(path) then
    return
  end

  if target == "tab" then
    vim.cmd("tabnew")
  elseif target == "split" then
    vim.cmd("rightbelow vsplit")
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
end

local function get_git_status_items(opts)
  opts = opts or {}
  local code_only = opts.code_only ~= false

  local buf_path = vim.api.nvim_buf_get_name(0)
  local search_dir = (buf_path ~= "" and vim.fs.dirname(buf_path)) or vim.fn.getcwd()
  local git_root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(search_dir) .. " rev-parse --show-toplevel")[1]

  if vim.v.shell_error ~= 0 or not git_root or git_root == "" then
    git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    if vim.v.shell_error ~= 0 or not git_root or git_root == "" then
      vim.notify("Không tìm thấy Git repository", vim.log.levels.WARN)
      return nil
    end
  end

  local lines = vim.fn.systemlist("git -C " .. vim.fn.shellescape(git_root) .. " status --porcelain -u")
  if vim.v.shell_error ~= 0 then
    vim.notify("Lỗi khi chạy git status", vim.log.levels.ERROR)
    return nil
  end

  local items = {}
  local ignored_count = 0
  for _, line in ipairs(lines) do
    if #line >= 4 then
      local raw_status = line:sub(1, 2)
      local worktree_status = line:sub(2, 2)
      local rel_path = line:sub(4)
      if rel_path:match('^"(.*)"$') then
        rel_path = rel_path:match('^"(.*)"$'):gsub('\\"', '"')
      end
      local full_path = vim.fs.joinpath(git_root, rel_path)

      local needs_review = (raw_status == "??") or (worktree_status ~= " ")

      if needs_review then
        if code_only and not is_code_file(rel_path) then
          ignored_count = ignored_count + 1
        else
          local display_status = (raw_status == "??") and "??" or worktree_status
          table.insert(items, {
            status = display_status,
            rel_path = rel_path,
            full_path = full_path,
          })
        end
      end
    end
  end

  return items, git_root, ignored_count
end

local function git_status(target, code_only)
  target = target or "current"
  if code_only == nil then
    code_only = true
  end

  local items, _, ignored_count = get_git_status_items({ code_only = code_only })
  if not items then
    return
  end

  if #items == 0 then
    if ignored_count and ignored_count > 0 then
      vim.notify(
        ("Không có file code nào bị sửa đổi (đã ẩn %d file non-code/.meta, dùng <leader>ga hoặc <leader>gs để xem tất cả)"):format(ignored_count),
        vim.log.levels.INFO
      )
    else
      vim.notify("Tất cả file đã được review xong (đã stage hết)!", vim.log.levels.INFO)
    end
    return
  end

  local prompt = ("Cần Review (%d)"):format(#items)
  if code_only and ignored_count and ignored_count > 0 then
    prompt = ("Cần Review Code (%d) [+%d ẩn]"):format(#items, ignored_count)
  end

  vim.ui.select(items, {
    prompt = prompt,
    format_item = function(item)
      return ("%-5s %s"):format("[" .. item.status .. "]", item.rel_path)
    end,
  }, function(item)
    if item then
      if item.status:find("D") and vim.fn.filereadable(item.full_path) == 0 then
        vim.notify("File đã bị xoá: " .. item.rel_path, vim.log.levels.WARN)
        return
      end
      open_file(item.full_path, target)
    end
  end)
end

local function open_modified_in_tabs(code_only)
  if code_only == nil then
    code_only = true
  end

  local items, _, ignored_count = get_git_status_items({ code_only = code_only })
  if not items then
    return
  end

  local files = {}
  for _, item in ipairs(items) do
    if not item.status:find("D") and vim.fn.filereadable(item.full_path) == 1 then
      table.insert(files, item.full_path)
    end
  end

  if #files == 0 then
    if ignored_count and ignored_count > 0 then
      vim.notify(
        ("Không có file code nào cần mở tab (đã bỏ qua %d file non-code/.meta, dùng <leader>ta để mở tất cả)"):format(ignored_count),
        vim.log.levels.INFO
      )
    else
      vim.notify("Không còn file nào cần review (đã stage hết)!", vim.log.levels.INFO)
    end
    return
  end

  if #files > 8 then
    local choice = vim.fn.confirm(
      ("Có %d file %sbị sửa đổi, bạn có chắc muốn mở tất cả vào %d tabs không?"):format(
        #files,
        code_only and "code " or "",
        #files
      ),
      "&Yes\n&No",
      1
    )
    if choice ~= 1 then
      return
    end
  end

  local existing_tab_files = {}
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
      local bufnr = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(bufnr) then
        local name = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
        if name ~= "" then
          existing_tab_files[name] = tabpage
        end
      end
    end
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  local is_cur_empty = vim.api.nvim_buf_get_name(cur_buf) == ""
    and vim.api.nvim_buf_line_count(cur_buf) <= 1
    and vim.api.nvim_buf_get_lines(cur_buf, 0, 1, false)[1] == ""

  local first_tab
  for i, file in ipairs(files) do
    local norm = vim.fs.normalize(file)
    if existing_tab_files[norm] then
      if not first_tab then
        first_tab = existing_tab_files[norm]
      end
    else
      if i == 1 and is_cur_empty then
        vim.cmd.edit(vim.fn.fnameescape(file))
        first_tab = vim.api.nvim_get_current_tabpage()
      else
        vim.cmd("tabnew " .. vim.fn.fnameescape(file))
        if not first_tab then
          first_tab = vim.api.nvim_get_current_tabpage()
        end
      end
    end
  end

  if first_tab and vim.api.nvim_tabpage_is_valid(first_tab) then
    vim.api.nvim_set_current_tabpage(first_tab)
  end

  local notify_msg = ("Đã mở %d file %svào các tab"):format(#files, code_only and "code " or "")
  if code_only and ignored_count and ignored_count > 0 then
    notify_msg = notify_msg .. (" (bỏ qua %d file non-code/.meta)"):format(ignored_count)
  end
  vim.notify(notify_msg, vim.log.levels.INFO)
end

local keymap = vim.keymap.set

keymap("n", "<leader>gm", function() git_status("current", true) end, { desc = "Git modified code files" })
keymap("n", "<leader>gs", function() git_status("current", false) end, { desc = "Git status (all modified files)" })
keymap("n", "<leader>ga", function() git_status("current", false) end, { desc = "Git all modified files" })
keymap("n", "<leader>tgm", function() git_status("tab", true) end, { desc = "New tab and git modified code files" })
keymap("n", "<leader>sgm", function() git_status("split", true) end, { desc = "Vsplit and git modified code files" })
keymap("n", "<leader>to", function() open_modified_in_tabs(true) end, { desc = "Open modified code files in tabs" })
keymap("n", "<leader>ta", function() open_modified_in_tabs(false) end, { desc = "Open all modified files in tabs (including non-code)" })
