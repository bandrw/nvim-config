local cmp = require("cmp")
local cmp_nvim_lsp = require("cmp_nvim_lsp")
local luasnip = require("luasnip")
local capabilities = cmp_nvim_lsp.default_capabilities()

local function goto_definitions()
	if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
		vim.notify("No LSP attached in this buffer", vim.log.levels.WARN)
		return
	end

	local ok, telescope_builtin = pcall(require, "telescope.builtin")
	if ok then
		telescope_builtin.lsp_definitions({ reuse_win = true })
		return
	end

	vim.lsp.buf.definition()
end

local function set_lsp_keymaps(bufnr)
	local opts = { noremap = true, silent = true, buffer = bufnr }

	vim.keymap.set("n", "gd", goto_definitions, opts)
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
	vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
	vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
end

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	sources = {
		{ name = "nvim_lsp" },
	},
	mapping = cmp.mapping.preset.insert({
		["<C-f>"] = cmp.mapping(function()
			if luasnip.jumpable(1) then
				luasnip.jump(1)
			end
		end, { "i", "s" }),
		["<C-b>"] = cmp.mapping(function()
			if luasnip.jumpable(-1) then
				luasnip.jump(-1)
			end
		end, { "i", "s" }),
		["<C-k>"] = cmp.mapping.select_prev_item({ behavior = "select" }),
		["<C-j>"] = cmp.mapping.select_next_item({ behavior = "select" }),
		["<C-p>"] = cmp.mapping(function()
			if cmp.visible() then
				cmp.select_prev_item({ behavior = "insert" })
			else
				cmp.complete()
			end
		end),
		["<C-n>"] = cmp.mapping(function()
			if cmp.visible() then
				cmp.select_next_item({ behavior = "insert" })
			else
				cmp.complete()
			end
		end),
		["<CR>"] = cmp.mapping.confirm({ select = false }),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-u>"] = cmp.mapping.scroll_docs(-4),
		["<C-d>"] = cmp.mapping.scroll_docs(4),
	}),
})

local function on_attach(_, bufnr)
	set_lsp_keymaps(bufnr)
end

local pyright_settings = {
	python = {
		analysis = {
			autoSearchPaths = true,
			useLibraryCodeForTypes = true,
			diagnosticMode = "workspace",
		},
	},
}

vim.lsp.config("*", {
	capabilities = capabilities,
	on_attach = on_attach,
})

vim.lsp.config("eslint", {
	workspace_required = true,
})

vim.lsp.config("pyright", {
	capabilities = capabilities,
	on_attach = on_attach,
	root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
	settings = pyright_settings,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("bandrw-lsp-keys", { clear = true }),
	callback = function(args)
		set_lsp_keymaps(args.buf)
	end,
})

local can_install_pyright = vim.fn.executable("npm") == 1
require("mason").setup({})
require("mason-lspconfig").setup({
	ensure_installed = can_install_pyright and { "pyright" } or {},
	automatic_enable = true,
})

vim.keymap.set("n", "<C-O>", function()
	vim.diagnostic.open_float(0, { scope = "line" })
end)
vim.keymap.set("n", "<C-I>", function()
	vim.diagnostic.goto_prev()
end)
vim.keymap.set("n", "<C-P>", function()
	vim.diagnostic.goto_next()
end)
