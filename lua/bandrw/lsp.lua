local cmp = require("cmp")
local cmp_nvim_lsp = require("cmp_nvim_lsp")
local luasnip = require("luasnip")

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
	local opts = { noremap = true, silent = true, buffer = bufnr }

	vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
	vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
	vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
	vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
	vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
end

vim.lsp.config("*", {
	capabilities = cmp_nvim_lsp.default_capabilities(),
	on_attach = on_attach,
})

vim.lsp.config("eslint", {
	workspace_required = true,
})

require("mason").setup({})
require("mason-lspconfig").setup({
	ensure_installed = {},
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
