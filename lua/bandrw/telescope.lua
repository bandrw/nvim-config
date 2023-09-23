local telescope = require("telescope")

telescope.setup({
    file_ignore_patterns = {"./node_modules/*", "node_modules", "^node_modules/*", "node_modules/*"}
})
