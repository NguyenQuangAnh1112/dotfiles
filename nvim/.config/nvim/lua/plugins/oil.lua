local hidden_extensions = {
  meta = true, prefab = true, unity = true, mat = true, asset = true,
  anim = true, controller = true, overrideController = true,
  png = true, jpg = true, jpeg = true, bmp = true, psd = true,
  mp3 = true, wav = true, ogg = true, flac = true,
  fbx = true, obj = true, blend = true, glb = true, gltf = true,
  dll = true, exe = true, so = true, a = true, pdb = true,
  zip = true, tar = true, gz = true, ["7z"] = true,
}

return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open Oil (buffer)" },
      { "<leader>v", function() require("oil").open_float() end, desc = "Open Oil (float)" },
    },
    opts = {
      default_file_explorer = true,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      keymaps = {
        ["q"] = "actions.close",
        ["<Esc>"] = "actions.close",
      },
      view_options = {
        show_hidden = false,
        is_hidden_file = function(name)
          if name:sub(1, 1) == "." then
            return true
          end
          local ext = name:match("%.([^%.]+)$")
          return ext and hidden_extensions[ext:lower()] or false
        end,
      },
      float = {
        padding = 2,
        max_width = 90,
        max_height = 30,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },
    },
  },
}
