local ok, codex = pcall(require, "codex")
if not ok then
	return
end

codex.setup({
	keymaps = {
		toggle = nil,
		quit = "<C-q>",
	},
	border = "rounded",
	width = 0.8,
	height = 0.8,
	model = nil,
	autoinstall = true,
	panel = false,
	use_buffer = false,
})

vim.keymap.set({ "n", "t" }, "<leader>cc", function()
	codex.toggle()
end, { desc = "Toggle Codex popup or side-panel" })
