local nvm_dir = vim.fn.expand("~/.nvm")
local alias_file = nvm_dir .. "/alias/default"
if vim.uv.fs_stat(alias_file) then
	local version = vim.trim(vim.fn.readfile(alias_file)[1])
	if not version:match("^v") then
		version = "v" .. version
	end
	local node_bin = nvm_dir .. "/versions/node/" .. version .. "/bin"
	if vim.fn.isdirectory(node_bin) == 1 then
		vim.env.PATH = node_bin .. ":" .. vim.env.PATH
	end
end

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.wrap = false

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8

vim.opt.listchars:append({ space = "·" })
vim.opt.list = true

vim.opt.clipboard:append({ "unnamed", "unnamedplus" })

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})
