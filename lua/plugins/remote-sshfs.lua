return {
  {
    "uhs-robert/sshfs.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    cmd = {
      "SSHConnect",
      "SSHDisconnect",
      "SSHDisconnectAll",
      "SSHFiles",
      "SSHGrep",
      "SSHLiveGrep",
      "SSHTerminal",
      "SSHExplore",
      "SSHConfig",
      "SSHReload",
    },
    keys = {
      { "<leader>rc", "<cmd>SSHConnect<cr>", desc = "SSHFS: Connect" },
      { "<leader>rd", "<cmd>SSHDisconnect<cr>", desc = "SSHFS: Disconnect" },
      { "<leader>rf", "<cmd>SSHFiles<cr>", desc = "SSHFS: Find Files" },
      { "<leader>rg", "<cmd>SSHLiveGrep<cr>", desc = "SSHFS: Live Grep" },
    },
    opts = {
      mounts = {
        base_dir = "/tmp/sshfs",
      },
      hooks = {
        on_mount = {
          auto_change_to_dir = true, -- Automatically run tcd (tab-scoped CWD)
          auto_run = function()
            -- Mark tab as remote workspace so <leader>rl can switch back
            local ok_ws, workspace = pcall(require, "util.workspace")
            if ok_ws then
              local mount_dir = vim.g.LastSSHMountDir
              local host_name = vim.g.LastSSHHostName
              if mount_dir then
                vim.t.workspace_is_remote = true
                vim.t.workspace_mount_path = mount_dir
                vim.t.workspace_host_name = host_name
                vim.t.workspace_remote_path = "~"
                workspace.save_current_state_once()
              end
            end

            -- Wipe out current tab buffers to start a fresh remote session
            vim.cmd("silent! %bd!")

            -- Open/Refresh NvimTree in the new remote directory
            vim.defer_fn(function()
              pcall(vim.cmd, "NvimTreeOpen")
            end, 100)

            -- Restore remote session buffers
            pcall(function()
              require("persistence").load()
              require("persistence").start()
            end)

            -- Prompt to restore pinned folder if one exists
            if ok_ws then
              local mount_dir = vim.g.LastSSHMountDir
              local host_name = vim.g.LastSSHHostName
              if mount_dir then
                workspace.prompt_restore(mount_dir, host_name)
              end
            end
          end,
        },
        on_exit = {
          auto_unmount = true, -- Auto-disconnect mounts on exit
        },
      },
    },
    config = function(_, opts)
      require("sshfs").setup(opts)

      -- Monkeypatch connect to reuse active mounts instead of warning
      local ok_session, session = pcall(require, "sshfs.session")
      if ok_session then
        local original_connect = session.connect
        session.connect = function(host)
          local ok_ws, workspace = pcall(require, "util.workspace")
          if ok_ws then
            workspace.save_current_state_once()
          end

          -- Save current session before switching context
          pcall(function()
            require("persistence").save()
            require("persistence").stop()
          end)

          local MountPoint = require("sshfs.lib.mount_point")
          local Config = require("sshfs.config")
          local config_tbl = Config.get()

          -- Replicate get_unique_mount_dir logic for "~"
          local remote_path_suffix = "~"
          local sanitized_path = remote_path_suffix:gsub("^/", ""):gsub("/$", ""):gsub("/", "_")
          local suffix = (sanitized_path ~= "") and ("_" .. sanitized_path) or ""
          local mount_dir = config_tbl.mounts.base_dir .. "/" .. host.name .. suffix

          -- Stash for hooks.on_mount auto_run
          vim.g.LastSSHMountDir = mount_dir
          vim.g.LastSSHHostName = host.name

          if MountPoint.is_active(mount_dir) then
            vim.notify("Reusing active mount: " .. host.name, vim.log.levels.INFO)
            local Hooks = require("sshfs.ui.hooks")
            Hooks.on_mount(mount_dir, host.name, remote_path_suffix, config_tbl)
            return
          end

          return original_connect(host)
        end
      end
    end,
  },
}
