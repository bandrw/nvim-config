-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd([[packadd packer.nvim]])

return require("packer").startup(function(use)
	-- Packer can manage itself
	use("wbthomason/packer.nvim")

	use({
		"nvim-telescope/telescope.nvim",
		tag = "0.1.3",
		-- or                            , branch = '0.1.x',
		requires = { { "nvim-lua/plenary.nvim" } },
	})

	use({
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate",
	})

	use("nvim-tree/nvim-web-devicons")

	use("nvim-tree/nvim-tree.lua")

	use("folke/tokyonight.nvim")

	use("lewis6991/gitsigns.nvim")

	use("tpope/vim-fugitive")

	use("sindrets/diffview.nvim")

	use("nvim-lualine/lualine.nvim")

	use("nvim-lua/plenary.nvim")

	-- LSP
	use({
		"VonHeikemen/lsp-zero.nvim",
		branch = "v3.x",
		requires = {
			{ "williamboman/mason.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },
			{ "neovim/nvim-lspconfig" },
			{ "hrsh7th/nvim-cmp" },
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "L3MON4D3/LuaSnip" },
		},
	})

	use("windwp/nvim-autopairs")
	use("windwp/nvim-ts-autotag")

	use({
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	})

	use("stevearc/conform.nvim")
	use("mfussenegger/nvim-lint")

	use({
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		requires = { { "nvim-lua/plenary.nvim" } },
	})
end)
