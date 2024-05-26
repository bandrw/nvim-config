local conform = require("conform")

conform.setup({
    formatters_by_ft = {
        javascript = {"prettier"},
        typescript = {"prettier"},
        javascriptreact = {"prettier"},
        typescriptreact = {"prettier"},
        css = {"prettier"},
        html = {"prettier"},
        json = {"prettier"},
        yaml = {"prettier"},
        markdown = {"prettier"},
        lua = {"stylua"},
        python = {"isort", "black"},
    },
    format_on_save = {
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
    },
})