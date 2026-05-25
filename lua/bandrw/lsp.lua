local cmp = require("cmp")
local cmp_nvim_lsp = require("cmp_nvim_lsp")
local luasnip = require("luasnip")

local base_capabilities = vim.lsp.protocol.make_client_capabilities()
local capabilities = vim.tbl_deep_extend("force", base_capabilities, cmp_nvim_lsp.default_capabilities())

local default_hover_handler = vim.lsp.handlers.hover
vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
	if result and type(result.contents) == "table" and result.contents.kind == "plaintext" then
		local value = result.contents.value or ""
		if value:find("```", 1, true) then
			local markdown_result = vim.deepcopy(result)
			markdown_result.contents = { kind = "markdown", value = value }
			return default_hover_handler(err, markdown_result, ctx, config)
		end
	end

	return default_hover_handler(err, result, ctx, config)
end

local function get_location_uri(location)
	return location.uri or location.targetUri
end

local function get_location_start(location)
	if location.range and location.range.start then
		return location.range.start
	end

	if location.targetSelectionRange and location.targetSelectionRange.start then
		return location.targetSelectionRange.start
	end

	if location.targetRange and location.targetRange.start then
		return location.targetRange.start
	end

	return nil
end

local function is_node_modules_location(location)
	local uri = get_location_uri(location)
	if not uri then
		return false
	end

	local path = vim.uri_to_fname(uri)
	return path:find("/node_modules/", 1, true) ~= nil
end

local function get_position_encoding(bufnr)
	local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/definition" })
	if #clients == 0 then
		clients = vim.lsp.get_clients({ bufnr = bufnr })
	end

	return clients[1] and clients[1].offset_encoding or "utf-16"
end

local function collect_definition_locations(bufnr)
	local params = vim.lsp.util.make_position_params(0, get_position_encoding(bufnr))
	local responses = vim.lsp.buf_request_sync(bufnr, "textDocument/definition", params, 1000) or {}
	local entries = {}
	local seen = {}

	for client_id, response in pairs(responses) do
		local result = response and response.result
		local client = vim.lsp.get_client_by_id(client_id)
		local locations = {}

		if result then
			if vim.islist(result) then
				locations = result
			else
				locations = { result }
			end
		end

		for _, location in ipairs(locations) do
			local uri = get_location_uri(location)
			local start = get_location_start(location)
			if uri and start then
				local key = string.format("%s:%d:%d", uri, start.line, start.character)
				if not seen[key] then
					seen[key] = true
					table.insert(entries, {
						location = location,
						offset_encoding = client and client.offset_encoding or "utf-16",
					})
				end
			end
		end
	end

	return entries
end

local function entries_to_qf_items(entries)
	local items = {}
	local grouped_locations = {}

	for _, entry in ipairs(entries) do
		local key = entry.offset_encoding
		if not grouped_locations[key] then
			grouped_locations[key] = {}
		end
		table.insert(grouped_locations[key], entry.location)
	end

	for offset_encoding, locations in pairs(grouped_locations) do
		vim.list_extend(items, vim.lsp.util.locations_to_items(locations, offset_encoding))
	end

	return items
end

local function goto_definitions()
	local bufnr = vim.api.nvim_get_current_buf()
	if #vim.lsp.get_clients({ bufnr = bufnr }) == 0 then
		vim.notify("No LSP attached in this buffer", vim.log.levels.WARN)
		return
	end

	local entries = collect_definition_locations(bufnr)
	if #entries == 0 then
		vim.notify("No definition found", vim.log.levels.INFO)
		return
	end

	local preferred = {}
	local fallback = {}

	for _, entry in ipairs(entries) do
		if is_node_modules_location(entry.location) then
			table.insert(fallback, entry)
		else
			table.insert(preferred, entry)
		end
	end

	local active_entries = #preferred > 0 and preferred or fallback

	if #active_entries == 1 then
		vim.lsp.util.jump_to_location(active_entries[1].location, active_entries[1].offset_encoding, true)
		return
	end

	local items = entries_to_qf_items(active_entries)
	vim.fn.setqflist({}, " ", { title = "LSP definitions", items = items })

	local ok, telescope_builtin = pcall(require, "telescope.builtin")
	if ok then
		telescope_builtin.quickfix({ reuse_win = true })
		return
	end

	vim.cmd("copen")
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

local eslint_root_markers = {
	"eslint.config.js",
	"eslint.config.cjs",
	"eslint.config.mjs",
	"eslint.config.ts",
	".eslintrc",
	".eslintrc.js",
	".eslintrc.cjs",
	".eslintrc.json",
	"configs/eslint.config.mjs",
}

local function resolve_eslint_root(bufnr)
	if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
		return nil
	end

	local filename = vim.api.nvim_buf_get_name(bufnr)
	if filename == "" then
		return nil
	end

	local project_root = vim.fs.root(bufnr, {
		{ "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" },
		{ ".git" },
	}) or vim.fs.root(bufnr, { ".git" })

	if not project_root then
		return nil
	end

	local config_file = vim.fs.find(eslint_root_markers, {
		path = filename,
		type = "file",
		limit = 1,
		upward = true,
		stop = vim.fs.dirname(project_root),
	})[1]

	if config_file then
		return project_root
	end

	local nested_config = vim.fs.joinpath(project_root, "configs", "eslint.config.mjs")
	if vim.uv.fs_stat(nested_config) then
		return project_root
	end

	return nil
end

vim.lsp.config("*", {
	capabilities = capabilities,
	on_attach = on_attach,
})

vim.lsp.config("eslint", {
	workspace_required = true,
	root_dir = function(bufnr, on_dir)
		local root = resolve_eslint_root(bufnr)
		if root then
			on_dir(root)
		end
	end,
	before_init = function(_, config)
		local root_dir = config.root_dir
		if not root_dir then
			return
		end

		config.settings = config.settings or {}
		config.settings.workspaceFolder = {
			uri = root_dir,
			name = vim.fn.fnamemodify(root_dir, ":t"),
		}

		local nested_config = vim.fs.joinpath(root_dir, "configs", "eslint.config.mjs")
		if vim.uv.fs_stat(nested_config) then
			config.settings.experimental = config.settings.experimental or {}
			config.settings.experimental.useFlatConfig = true
			config.settings.options = config.settings.options or {}
			config.settings.options.overrideConfigFile = nested_config
		end
	end,
})

vim.lsp.config("pyright", {
	capabilities = capabilities,
	on_attach = on_attach,
	root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
	settings = pyright_settings,
})

vim.lsp.enable("eslint")
vim.lsp.enable("pyright")

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("bandrw-lsp-keys", { clear = true }),
	callback = function(args)
		set_lsp_keymaps(args.buf)
	end,
})

local can_install_node_servers = vim.fn.executable("npm") == 1
require("mason").setup({})
require("mason-lspconfig").setup({
	ensure_installed = can_install_node_servers and { "pyright", "eslint" } or {},
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
