vim.keymap.set("n", "o", function()
	local before = {}
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		before[win] = true
	end

	vim.cmd.normal({ args = { "gO" } })

	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if not before[win] then
			vim.api.nvim_win_call(win, function()
				vim.cmd.wincmd("L")
				vim.api.nvim_win_set_width(0, math.max(1, math.floor(vim.o.columns * 0.75)))
			end)
			break
		end
	end
end, { buffer = true, silent = true, desc = "Fugitive: open on right full height" })
