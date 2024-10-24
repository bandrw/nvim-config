local lint = require("lint")

lint.linters_by_ft = {
	-- javascript = { "eslint_d" },
	-- typescript = { "eslint_d" },
	-- javascriptreact = { "eslint_d" },
	-- typescriptreact = { "eslint_d" },
	python = { "pylint" },
}

local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
	group = lint_augroup,
	callback = function()
		lint.try_lint()
	end,
})

vim.g.python3_host_prog = ".venv/bin/python"
vim.g.ale_python_pylint_executable = vim.fn.expand(".venv/bin/pylint")

vim.keymap.set("n", "<leader>ll", "mF:%!eslint_d --stdin --fix-to-stdout --stdin-filename %<CR>`F")
vim.keymap.set("v", "<leader>ll", ":!eslint_d --stdin --fix-to-stdout<CR>gv")
