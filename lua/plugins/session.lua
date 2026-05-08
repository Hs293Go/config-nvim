return {
    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        opts = {
            -- Wipe terminal and overseer buffers before mksession runs so they
            -- don't get restored as empty no-name buffers next launch.
            pre_save = function()
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_valid(buf) then
                        local bt = vim.bo[buf].buftype
                        local ft = vim.bo[buf].filetype
                        if bt == "terminal" or ft:match("^[Oo]verseer") then
                            pcall(vim.api.nvim_buf_delete, buf, { force = true })
                        end
                    end
                end
            end,
        },
        keys = {
            {
                "<leader>qs",
                function()
                    require("persistence").load()
                end,
                desc = "Restore session for cwd",
            },
            {
                "<leader>ql",
                function()
                    require("persistence").load({ last = true })
                end,
                desc = "Restore last session",
            },
            {
                "<leader>qd",
                function()
                    require("persistence").stop()
                end,
                desc = "Don't save current session",
            },
        },
    },
}
