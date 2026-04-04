local ok, configs = pcall(require, "nvim-treesitter.configs")
if not ok then
    ok, configs = pcall(require, "nvim-treesitter.config")
end

if not ok then
    vim.notify("nvim-treesitter config module not found", vim.log.levels.WARN)
    return
end

configs.setup({
    ensure_installed = { "javascript", "typescript", "tsx", "python" },
    sync_install = false,
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = true,
    },
    indent = { enable = true },
})
