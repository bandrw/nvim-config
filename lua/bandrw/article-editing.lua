local M = {}

local MAX_WIDTH = 160
local group = vim.api.nvim_create_augroup("bandrw-article-editing", { clear = true })
local window_states = {}
local movement_keys = {
	h = "h",
	j = "gj",
	k = "gk",
	l = "l",
}

local function enable_buffer_mappings(buf)
	if vim.b[buf].article_editing_mappings_enabled then
		return
	end

	for lhs, rhs in pairs(movement_keys) do
		vim.keymap.set("n", lhs, rhs, { buffer = buf, noremap = true, silent = true })
	end

	vim.b[buf].article_editing_mappings_enabled = true
end

local function disable_buffer_mappings(buf)
	if not vim.b[buf].article_editing_mappings_enabled then
		return
	end

	for lhs, _ in pairs(movement_keys) do
		pcall(vim.keymap.del, "n", lhs, { buffer = buf })
	end

	vim.b[buf].article_editing_mappings_enabled = nil
end

local function enable_buffer_settings(buf)
	local refcount = vim.b[buf].article_editing_refcount or 0

	if refcount == 0 then
		vim.b[buf].article_editing_buffer_settings = {
			textwidth = vim.bo[buf].textwidth,
			formatoptions = vim.bo[buf].formatoptions,
		}

		vim.bo[buf].textwidth = MAX_WIDTH
		if not vim.bo[buf].formatoptions:find("t", 1, true) then
			vim.bo[buf].formatoptions = vim.bo[buf].formatoptions .. "t"
		end

		enable_buffer_mappings(buf)
	end

	vim.b[buf].article_editing_refcount = refcount + 1
end

local function disable_buffer_settings(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local refcount = vim.b[buf].article_editing_refcount or 0
	if refcount <= 1 then
		local saved = vim.b[buf].article_editing_buffer_settings
		if saved then
			vim.bo[buf].textwidth = saved.textwidth
			vim.bo[buf].formatoptions = saved.formatoptions
		end

		vim.b[buf].article_editing_buffer_settings = nil
		vim.b[buf].article_editing_refcount = nil
		disable_buffer_mappings(buf)
		return
	end

	vim.b[buf].article_editing_refcount = refcount - 1
end

function M.open()
	local win = vim.api.nvim_get_current_win()
	if window_states[win] then
		return
	end

	local buf = vim.api.nvim_get_current_buf()

	window_states[win] = {
		buf = buf,
		wrap = vim.wo[win].wrap,
		linebreak = vim.wo[win].linebreak,
		breakindent = vim.wo[win].breakindent,
		list = vim.wo[win].list,
		colorcolumn = vim.wo[win].colorcolumn,
	}

	enable_buffer_settings(buf)

	vim.wo[win].wrap = true
	vim.wo[win].linebreak = true
	vim.wo[win].breakindent = true
	vim.wo[win].list = false
	vim.wo[win].colorcolumn = tostring(MAX_WIDTH)
end

function M.close()
	local win = vim.api.nvim_get_current_win()
	local saved = window_states[win]
	if not saved then
		return
	end

	disable_buffer_settings(saved.buf)

	vim.wo[win].wrap = saved.wrap
	vim.wo[win].linebreak = saved.linebreak
	vim.wo[win].breakindent = saved.breakindent
	vim.wo[win].list = saved.list
	vim.wo[win].colorcolumn = saved.colorcolumn

	window_states[win] = nil
end

function M.toggle()
	if window_states[vim.api.nvim_get_current_win()] then
		M.close()
		return
	end

	M.open()
end

function M.setup()
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(args)
			local win = tonumber(args.match)
			local saved = window_states[win]
			if not saved then
				return
			end

			disable_buffer_settings(saved.buf)
			window_states[win] = nil
		end,
	})
end

return M
