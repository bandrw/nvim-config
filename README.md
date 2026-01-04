# nvim config

Personal Neovim config that boots from `init.lua` into `lua/bandrw/`.
Uses packer for plugins, lsp-zero for LSP, and focuses on a minimal set of
daily drivers (telescope, nvim-tree, treesitter, gitsigns, diffview, lualine).

## layout
- `init.lua` -> loads `lua/bandrw/init.lua`
- `lua/bandrw/` -> core modules (plugins, keymaps, UI, LSP, tooling)
- `after/` -> filetype/after overrides
- `plugin/` -> runtime plugin configs

## bootstrap
1) Install packer: `git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim`
2) Open Neovim and run `:PackerSync`

## notable modules
- `lua/bandrw/packer.lua` -> plugin list
- `lua/bandrw/lsp.lua` -> LSP setup (lsp-zero + mason)
- `lua/bandrw/formatting.lua` / `lua/bandrw/linting.lua` -> conform + nvim-lint
- `lua/bandrw/codex.lua` -> Codex integration
