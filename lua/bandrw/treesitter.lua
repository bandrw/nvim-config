local ok, configs = pcall(require, "nvim-treesitter.configs")
if not ok then
	ok, configs = pcall(require, "nvim-treesitter.config")
end

if not ok then
	vim.notify("nvim-treesitter config module not found", vim.log.levels.WARN)
	return
end

configs.setup({
	ensure_installed = {
		"javascript",
		"typescript",
		"tsx",
		"python",
		"markdown",
		"markdown_inline",
		"vimdoc",
	},
	sync_install = false,
	highlight = {
		enable = true,
		disable = function(_, buf)
			return vim.bo[buf].buftype == "nofile"
		end,
		additional_vim_regex_highlighting = false,
	},
	indent = {
		enable = true,
		disable = { "javascript", "typescript", "tsx" },
	},
})
