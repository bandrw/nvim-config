local ok, configs = pcall(require, "nvim-treesitter.configs")
if not ok then
	ok, configs = pcall(require, "nvim-treesitter.config")
end

if not ok then
	vim.notify("nvim-treesitter config module not found", vim.log.levels.WARN)
	return
end

-- Neovim 0.12 can provide quantified captures as node lists in query directives.
-- nvim-treesitter's legacy directives assume a single TSNode and may crash.
do
	-- Ensure upstream directives are registered first, then override them safely.
	pcall(require, "nvim-treesitter.query_predicates")

	local query = vim.treesitter.query
	local directive_opts = vim.fn.has("nvim-0.10") == 1 and { force = true, all = false } or true

	local function is_tsnode(value)
		if type(value) ~= "userdata" then
			return false
		end
		return pcall(function()
			value:range()
		end)
	end

	local function first_tsnode(value)
		if is_tsnode(value) then
			return value
		end
		if type(value) == "table" then
			for _, candidate in ipairs(value) do
				if is_tsnode(candidate) then
					return candidate
				end
			end
		end
		return nil
	end

	local function get_node_text(value, bufnr, opts)
		local node = first_tsnode(value)
		if not node then
			return ""
		end
		return vim.treesitter.get_node_text(node, bufnr, opts) or ""
	end

	local html_script_type_languages = {
		["importmap"] = "json",
		["module"] = "javascript",
		["application/ecmascript"] = "javascript",
		["text/ecmascript"] = "javascript",
	}

	local non_filetype_match_injection_language_aliases = {
		ex = "elixir",
		pl = "perl",
		sh = "bash",
		uxn = "uxntal",
		ts = "typescript",
	}

	local function get_parser_from_markdown_info_string(injection_alias)
		local match = vim.filetype.match({ filename = "a." .. injection_alias })
		return match or non_filetype_match_injection_language_aliases[injection_alias] or injection_alias
	end

	query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
		local type_attr_value = get_node_text(match[pred[2]], bufnr)
		if type_attr_value == "" then
			return
		end
		local configured = html_script_type_languages[type_attr_value]
		if configured then
			metadata["injection.language"] = configured
		else
			local parts = vim.split(type_attr_value, "/", {})
			metadata["injection.language"] = parts[#parts]
		end
	end, directive_opts)

	query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
		local injection_alias = get_node_text(match[pred[2]], bufnr):lower()
		if injection_alias == "" then
			return
		end
		metadata["injection.language"] = get_parser_from_markdown_info_string(injection_alias)
	end, directive_opts)

	query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
		local id = pred[2]
		local text = get_node_text(match[id], bufnr, { metadata = metadata[id] })
		if not metadata[id] then
			metadata[id] = {}
		end
		metadata[id].text = string.lower(text)
	end, directive_opts)
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
			local bt = vim.bo[buf].buftype
			if bt ~= "nofile" then
				return false
			end

			local ft = vim.bo[buf].filetype
			if ft == "TelescopePrompt" then
				return true
			end

			-- Keep treesitter enabled for nofile buffers backed by real paths
			-- (such as Telescope previews), and disable only scratch-style buffers.
			return vim.api.nvim_buf_get_name(buf) == ""
		end,
		additional_vim_regex_highlighting = false,
	},
	indent = {
		enable = true,
		disable = { "javascript", "typescript", "tsx" },
	},
})
