-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use {
	  'nvim-telescope/telescope.nvim', tag = '0.1.3',
	  -- or                            , branch = '0.1.x',
	  requires = { {'nvim-lua/plenary.nvim'} }
  }

  use {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
  }

  use 'nvim-tree/nvim-web-devicons'

  use 'nvim-tree/nvim-tree.lua'

  use 'folke/tokyonight.nvim'

  use 'lewis6991/gitsigns.nvim'

  use 'tpope/vim-fugitive'

  use 'sindrets/diffview.nvim'

  use 'nvim-lualine/lualine.nvim'

end)
