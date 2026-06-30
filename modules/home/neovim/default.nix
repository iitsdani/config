{ pkgs, inputs, colorscheme, ... }:

with inputs.nix-colors.lib-contrib { inherit pkgs; };

let
  goSettings = builtins.readFile ./go.lua;
  themePlugin = vimThemeFromScheme { scheme = colorscheme; };
  kotlinLsp = pkgs.callPackage ./kotlin-lsp.nix { };
  kotlinNvim = pkgs.callPackage ./kotlin-nvim.nix { };
in
{
  home.packages = with pkgs; [
    tree-sitter
    fd
    shfmt
    shellcheck
    nixd
    nixpkgs-fmt
    stylua
    tofu-ls
    opentofu
    tflint
    typescript
    typescript-language-server
    prettier
    buf
  ];

  programs.nixvim = {
    enable = true;
    viAlias = false;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;

    # NOTE(ar3s3ru): for some reason there is a pulled-in dependency for vimplugin-cmp-emoji which is unfree.
    nixpkgs.config.allowUnfree = true;

    extraPlugins = with pkgs.vimPlugins; [
      themePlugin
      vim-nix
      vim-visual-multi
      vim-better-whitespace
      vim-vsnip
      markdown-preview-nvim
      kotlinNvim
    ];

    extraConfigLua = ''
      vim.cmd.colorscheme("nix-${colorscheme.slug}")

      vim.filetype.add({
        extension = {
          gotmpl = "gotmpl",
          gowork = "gowork",
          tfvars = "terraform-vars";
          tofuvars = "terraform-vars";
        },
        filename = {
          ["go.work"] = "gowork";
          [".tofu.hcl"] = "terraform";
        },
      })

      -- markdown-preview.nvim
      vim.g.mkdp_auto_close = 0
      vim.g.mkdp_theme = "dark"

      ${goSettings}

      -- kotlin.nvim: point at the Nix-built kotlin-lsp store path.
      -- $out/share contains both bin/intellij-server and lib/, the layout
      -- the plugin's resolve_kotlin_lsp_dir() expects.
      vim.env.KOTLIN_LSP_DIR = "${kotlinLsp}/share"

      require("kotlin").setup({
        inlay_hints = { enabled = true },
        jvm_args = { "-Xmx4g" },
        -- LSP-driven folding off; treesitter folding is also disabled in
        -- this config, so we rely on default vim folding.
        folding = { enabled = false },
      })

      -- Disable all indent logic for Kotlin; treesitter indent is buggy
      -- and LSP onTypeFormatting doesn't work reliably. Fall back to
      -- simple autoindent (copy indent from previous line).
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "kotlin",
        callback = function()
          vim.bo.indentexpr = ""
          vim.bo.autoindent = true
          vim.bo.cindent = false
          vim.bo.smartindent = false
        end,
      })

      -- Format-on-save for Kotlin via :KotlinFormat (kotlin.nvim wraps the
      -- server's IDEA-style formatter). conform-nvim has no LSP-command
      -- formatter, so we hook BufWritePre directly.
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.kt",
        callback = function()
          local clients = vim.lsp.get_clients({ bufnr = 0, name = "kotlin_ls" })
          if #clients == 0 then return end
          vim.cmd("KotlinFormat")
        end,
      })
    '';

    globals.mapleader = " ";

    editorconfig.enable = true;

    opts = {
      autoread = true;
      lazyredraw = true;
      shell = "fish";
      shadafile = "NONE";
      termguicolors = true;
      guifont = "VictorMono Nerd Font:h10";
      undofile = true;
      autoindent = true;
      smartindent = false;
      tabstop = 2;
      shiftwidth = 2;
      shiftround = true;
      expandtab = true;
      scrolloff = 3;
      clipboard = "unnamedplus";
      mouse = "a";
      cursorline = true;
      number = true;
      viminfo = "";
      viminfofile = "NONE";
      ignorecase = true;
      ttimeoutlen = 5;
      shortmess = "atI";
      wrap = false;
      writebackup = false;
      errorbells = false;
      swapfile = false;
      showmode = false;
      laststatus = 3;
      pumheight = 6;
      splitright = true;
      splitbelow = true;
      completeopt = "menuone,noselect";
    };

    keymaps = [
      { mode = "n"; key = "<C-f>"; action = "<cmd>Telescope live_grep<CR>"; options.silent = true; }
      { mode = "n"; key = "<C-p>"; action = "<cmd>Telescope find_files<CR>"; options.silent = true; }
      { mode = "n"; key = "<C-b>"; action = "<cmd>NvimTreeToggle<CR>"; options.silent = true; }

      {
        mode = [ "n" "x" ];
        key = "<leader>oa";
        action.__raw = ''function() require("opencode").ask("@this: ", { submit = true }) end'';
        options.desc = "Ask opencode";
      }
      {
        mode = [ "n" "x" ];
        key = "<leader>os";
        action.__raw = ''function() require("opencode").select() end'';
        options.desc = "Opencode select action";
      }
      {
        mode = "n";
        key = "<leader>ot";
        action.__raw = ''function() require("opencode").toggle() end'';
        options.desc = "Toggle opencode";
      }
      {
        mode = "n";
        key = "<leader>op";
        action.__raw = ''function() require("opencode").command("session.half.page.up") end'';
        options.desc = "Opencode scroll up";
      }
      {
        mode = "n";
        key = "<leader>on";
        action.__raw = ''function() require("opencode").command("session.half.page.down") end'';
        options.desc = "Opencode scroll down";
      }
      {
        mode = [ "n" "x" ];
        key = "go";
        action.__raw = ''function() return require("opencode").operator("@this ") end'';
        options.desc = "Send range to opencode";
        options.expr = true;
      }
      {
        mode = "n";
        key = "goo";
        action.__raw = ''function() return require("opencode").operator("@this ") .. "_" end'';
        options.desc = "Send line to opencode";
        options.expr = true;
      }

      # markdown-preview.nvim
      { mode = "n"; key = "<leader>mp"; action = "<cmd>MarkdownPreview<CR>"; options.desc = "Markdown preview start"; }
      { mode = "n"; key = "<leader>ms"; action = "<cmd>MarkdownPreviewStop<CR>"; options.desc = "Markdown preview stop"; }
      { mode = "n"; key = "<leader>mt"; action = "<cmd>MarkdownPreviewToggle<CR>"; options.desc = "Markdown preview toggle"; }

      # Diagnostic navigation (LSP errors/warnings)
      {
        mode = "n";
        key = "[d";
        action.__raw = ''function() vim.diagnostic.goto_prev() end'';
        options.desc = "Previous diagnostic";
      }
      {
        mode = "n";
        key = "]d";
        action.__raw = ''function() vim.diagnostic.goto_next() end'';
        options.desc = "Next diagnostic";
      }
      {
        mode = "n";
        key = "<leader>cd";
        action.__raw = ''function() vim.diagnostic.open_float() end'';
        options.desc = "Show diagnostic at cursor";
      }

      {
        mode = "n";
        key = "<leader>lr";
        action.__raw = ''
          function()
            local clients = vim.lsp.get_clients({ bufnr = 0 })
            if #clients == 0 then
              vim.notify("No LSP clients attached", vim.log.levels.WARN)
              return
            end
            local names = {}
            for _, c in ipairs(clients) do
              table.insert(names, c.name)
              c:stop(true)
            end
            -- Re-trigger FileType so configured servers re-attach.
            vim.cmd("edit")
            vim.notify("Restarted LSP: " .. table.concat(names, ", "))
          end
        '';
        options.desc = "Restart LSP (current buffer)";
      }

      # Buffer management (window-preserving via snacks.bufdelete)
      {
        mode = "n";
        key = "<leader>bd";
        action.__raw = ''function() Snacks.bufdelete() end'';
        options.desc = "Delete buffer (keep window)";
      }
      {
        mode = "n";
        key = "<leader>bD";
        action.__raw = ''function() Snacks.bufdelete({ force = true }) end'';
        options.desc = "Force delete buffer";
      }
      {
        mode = "n";
        key = "<leader>bo";
        action.__raw = ''function() Snacks.bufdelete.other() end'';
        options.desc = "Delete other buffers";
      }
      {
        mode = "n";
        key = "<leader>bb";
        action = "<cmd>Telescope buffers<CR>";
        options.desc = "Pick buffer";
        options.silent = true;
      }

      # Buffer cycling (Shift+Arrow); honors bufferline visual order
      { mode = "n"; key = "<S-Right>"; action = "<cmd>BufferLineCycleNext<CR>"; options.silent = true; options.desc = "Next buffer"; }
      { mode = "n"; key = "<S-Left>"; action = "<cmd>BufferLineCyclePrev<CR>"; options.silent = true; options.desc = "Previous buffer"; }

      # Protobuf / buf manual actions (auto-format-on-save and auto-lint
      # are already wired via conform-nvim and nvim-lint).
      {
        mode = "n";
        key = "<leader>pbf";
        action.__raw = ''function() require("conform").format({ async = true, lsp_format = "fallback" }) end'';
        options.desc = "buf format (current file)";
      }
      {
        mode = "n";
        key = "<leader>pbl";
        action.__raw = ''function() require("lint").try_lint() end'';
        options.desc = "buf lint (current file)";
      }

      # Kotlin (kotlin.nvim). Globally bound; commands no-op when no kotlin_ls
      # client is attached to the current buffer.
      { mode = "n"; key = "<leader>kf"; action = "<cmd>KotlinFormat<CR>"; options.silent = true; options.desc = "Kotlin format buffer"; }
      { mode = "n"; key = "<leader>ko"; action = "<cmd>KotlinOrganizeImports<CR>"; options.silent = true; options.desc = "Kotlin organize imports"; }
      { mode = "n"; key = "<leader>kh"; action = "<cmd>KotlinInlayHintsToggle<CR>"; options.silent = true; options.desc = "Kotlin toggle inlay hints"; }
      { mode = "n"; key = "<leader>kc"; action = "<cmd>KotlinCodeActions<CR>"; options.silent = true; options.desc = "Kotlin code actions"; }
      { mode = "n"; key = "<leader>kt"; action = "<cmd>KotlinTypeDefinition<CR>"; options.silent = true; options.desc = "Kotlin go to type definition"; }
    ];

    autoGroups.CursorLine = { clear = true; };

    autoCmd = [
      {
        event = [ "VimEnter" "WinEnter" "BufWinEnter" ];
        group = "CursorLine";
        command = "setlocal cursorline";
      }
      {
        event = "WinLeave";
        group = "CursorLine";
        command = "setlocal nocursorline";
      }
      {
        event = [ "FocusGained" "BufEnter" "CursorHold" "CursorHoldI" ];
        pattern = "*";
        command = "if mode() != 'c' | checktime | endif";
      }
      {
        event = "FileChangedShellPost";
        pattern = "*";
        command = "echohl WarningMsg | echo 'File changed on disk. Buffer reloaded.' | echohl None";
      }
    ];

    userCommands = {
      OpencodeAsk.command.__raw = ''function() require("opencode").ask("@this: ", { submit = true }) end'';
      OpencodeSelect.command.__raw = ''function() require("opencode").select() end'';
      OpencodeToggle.command.__raw = ''function() require("opencode").toggle() end'';
    };

    dependencies.opencode.package = pkgs.llm-agents.opencode;

    plugins = {
      opencode.enable = true;
      web-devicons.enable = true;
      lualine.enable = true;
      gitsigns.enable = true;
      indent-blankline.enable = true;
      nvim-tree = {
        enable = true;
        settings = {
          update_focused_file = {
            enable = true;
            update_root = false; # keep tree root stable across buffer jumps
          };
          renderer = {
            highlight_opened_files = "name"; # mark all open buffers in tree
            group_empty = true; # collapse chains of single-child folders (e.g. src/java/main/com/example)
            indent_markers.enable = true; # show indent guides for clarity with collapsed chains
          };
          filters.git_ignored = false; # show gitignored files
        };
      };

      telescope = {
        enable = true;
        settings.pickers = {
          find_files.follow = true;
          live_grep.additional_args = [ "-L" ];
        };
      };

      bufferline = {
        enable = true;
        # Use Snacks.bufdelete so closing a tab via mouse (x button or
        # right-click) preserves the window/split layout.
        settings.options = {
          close_command.__raw = ''function(n) Snacks.bufdelete(n) end'';
          right_mouse_command.__raw = ''function(n) Snacks.bufdelete(n) end'';
        };
      };

      # snacks.nvim - collection of QoL micro-plugins. Note: outer 'enable'
      # is the nixvim option; inner '<module>.enabled' is the snacks lua opt.
      snacks = {
        enable = true;
        settings = {
          bufdelete.enabled = true; # delete buffer, keep window/split
          bigfile.enabled = true; # auto-disable heavy stuff on large files
          quickfile.enabled = true; # render file before plugins finish loading
          words.enabled = true; # auto-highlight LSP refs + ]]/[[ jump
          notifier.enabled = true; # nicer vim.notify with history
          rename.enabled = true; # LSP-aware file rename
          input.enabled = true;
          picker.enabled = true;
        };
      };

      treesitter = {
        enable = true;
        settings.highlight.enable = true;
        settings.indent.enable = true;
        folding.enable = false;
      };

      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            lua = [ "stylua" ];
            nix = [ "nixpkgs_fmt" ];
            sh = [ "shfmt" ];
            bash = [ "shfmt" ];
            javascript = [ "prettier" ];
            javascriptreact = [ "prettier" ];
            typescript = [ "prettier" ];
            typescriptreact = [ "prettier" ];
            json = [ "prettier" ];
            yaml = [ "prettier" ];
            html = [ "prettier" ];
            css = [ "prettier" ];
            markdown = [ "prettier" ];
            toml = [ "prettier" ];
            proto = [ "buf" ];
            terraform = [ "tofu_fmt" ];
            "terraform-vars" = [ "tofu_fmt" ];
            tofu = [ "tofu_fmt" ];
          };
          format_on_save = {
            timeout_ms = 1000;
            lsp_format = "fallback";
          };
        };
      };

      lint = {
        enable = true;
        lintersByFt = {
          sh = [ "shellcheck" ];
          bash = [ "shellcheck" ];
          proto = [ "buf_lint" ];
          terraform = [ "tflint" ];
          "terraform-vars" = [ "tflint" ];
          tofu = [ "tflint" ];
        };
        autoCmd.event = [ "BufWritePost" "BufReadPost" "InsertLeave" ];
      };

      lsp = {
        enable = true;
        servers = {
          gopls.enable = true;
          buf_ls.enable = true;
          # Kotlin LSP is configured via kotlin.nvim (see extraConfigLua),
          # not via nixvim's plugins.lsp.servers — the plugin spawns its
          # own `kotlin_ls` client with the workspace/configuration handler
          # that v262.4739.0+ needs for completion to fully activate.
          terraformls = {
            enable = true;
            package = pkgs.tofu-ls;
            filetypes = [ "terraform" "terraform-vars" "tofu" ];
          };
          nixd = {
            enable = true;
            settings.formatting.command = [ "nixpkgs-fmt" ];
          };
          rust_analyzer = {
            enable = true;
            installRustc = false;
            installCargo = false;
            settings = {
              cargo.features = "all";
              checkOnSave.command = "clippy";
            };
          };
          ts_ls = {
            enable = true;
            filetypes = [ "javascript" "javascriptreact" "typescript" "typescriptreact" ];
            extraOptions = {
              init_options = {
                tsserver = {
                  path = "${pkgs.typescript}/bin/tsserver";
                };
              };
            };
          };
        };
        # LSP keymaps. Neovim 0.12 ships built-in global maps for most LSP
        # actions (see :help lsp-defaults), so we only add explicit aliases
        # for the most universal "go to" shortcuts. Defaults provide:
        #   K   -> hover            gra -> code_action
        #   grr -> references       gri -> implementation
        #   grn -> rename           grt -> type_definition
        #   gO  -> document_symbol  <C-]> -> definition (via tagfunc)
        keymaps.lspBuf = {
          "gd" = "definition";
          "gD" = "declaration";
        };
        onAttach = ''
          if client.name == "ts_ls" then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        '';
      };

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          snippet.expand = ''
            function(args) vim.fn["vsnip#anonymous"](args.body) end
          '';
          mapping = {
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.abort()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Down>" = "cmp.mapping.select_next_item()";
            "<Up>" = "cmp.mapping.select_prev_item()";
          };
          sources = [
            { name = "nvim_lsp"; }
            { name = "nvim_lsp_signature_help"; }
            { name = "vsnip"; }
            { name = "buffer"; }
            { name = "path"; }
            { name = "emoji"; }
          ];
        };
      };
    };
  };
}
