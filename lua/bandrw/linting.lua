local lint = require("lint")

local eslint_config_candidates = {
	"eslint.config.js",
	"eslint.config.cjs",
	"eslint.config.mjs",
	"eslint.config.ts",
	"configs/eslint.config.mjs",
}

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

vim.g.python3_host_prog = "./.venv/bin/python"
vim.g.ale_python_pylint_executable = vim.fn.expand("./.venv/bin/pylint")

local function apply_eslint_cli_fix(bufnr)
	local file = vim.api.nvim_buf_get_name(bufnr)
	if file == "" then
		return false
	end

	if vim.bo[bufnr].modified then
		vim.cmd("silent write")
	end

	local eslint_bin = vim.fs.find({ "node_modules/.bin/eslint" }, {
		path = vim.fs.dirname(file),
		upward = true,
	})[1]

	local cmd = nil
	if eslint_bin then
		cmd = { eslint_bin, "--fix", file }
	elseif vim.fn.executable("eslint") == 1 then
		cmd = { "eslint", "--fix", file }
	else
		return false
	end

	local config_file = vim.fs.find(eslint_config_candidates, {
		path = vim.fs.dirname(file),
		type = "file",
		limit = 1,
		upward = true,
	})[1]
	if config_file then
		table.insert(cmd, 3, "--config")
		table.insert(cmd, 4, config_file)
	end

	local result = vim.system(cmd, { text = true }):wait()
	if result.code ~= 0 then
		local err = (result.stderr or ""):gsub("^%s+", ""):gsub("%s+$", "")
		vim.notify(err ~= "" and err or "eslint --fix failed", vim.log.levels.WARN)
		return true
	end

	vim.cmd("checktime")
	vim.notify("Applied ESLint fixes (CLI)", vim.log.levels.INFO)
	return true
end

vim.keymap.set("n", "<C-.>", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "eslint" })
	if #clients > 0 then
		clients[1]:request("workspace/executeCommand", {
			command = "eslint.applyAllFixes",
			arguments = {
				{
					uri = vim.uri_from_bufnr(bufnr),
					version = vim.lsp.util.buf_versions[bufnr],
				},
			},
		}, nil, bufnr)
		return
	end

	if not apply_eslint_cli_fix(bufnr) then
		vim.notify("ESLint LSP not attached and eslint CLI not found", vim.log.levels.WARN)
	end
end)
