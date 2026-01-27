-- 基础设置
vim.g.mapleader = " "             -- 空格键是核心前缀键
vim.opt.number = true             -- 显示行号
--vim.opt.relativenumber = true     -- 相对行号
vim.opt.mouse = "a"               -- 允许鼠标
vim.opt.clipboard = ""            -- 共享系统剪贴板
vim.keymap.set({ "n", "v" }, "y", '"+y')
vim.keymap.set("n", "yy", '"+yy')
vim.opt.tabstop = 4               -- Tab 宽度
vim.opt.shiftwidth = 4            -- 缩进宽度
vim.opt.expandtab = true          -- 将 Tab 转为空格
vim.opt.ignorecase = true         -- 搜索忽略大小写
vim.opt.smartcase = true          -- 智能大小写
-- 折叠基础设置
vim.opt.foldcolumn = '1'          -- 在行号左侧显示一列折叠提示符
vim.opt.foldlevel = 99            -- 打开文件时默认展开所有代码
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- 快捷键
vim.keymap.set('n', 'gd', vim.lsp.buf.declaration, opts)    -- 跳转函数声明
vim.keymap.set('n', 'gD', vim.lsp.buf.definition, opts)     -- 调到函数定义

vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float) -- 弹窗显示报错
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist) -- 列出所有报错
vim.keymap.set('n', '<leader>h', function()
    -- 获取当前 buffer 的 LSP 客户端
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
    local clangd_client = nil

    -- 检查 clangd 是否在运行
    for _, client in pairs(clients) do
        if client.name == "clangd" then
            clangd_client = client
            break
        end
    end

    if not clangd_client then
        return vim.notify("Clangd 未启动，无法切换头文件", vim.log.levels.WARN)
    end

    -- 发送切换请求给 clangd
    vim.lsp.buf_request(bufnr, 'textDocument/switchSourceHeader', {
        uri = vim.uri_from_bufnr(bufnr)
    }, function(err, result)
        if err then return vim.notify("LSP 报错: " .. tostring(err), vim.log.levels.ERROR) end
        if not result then return vim.notify("没找到对应的头文件/源文件", vim.log.levels.INFO) end

        -- 如果找到了，就打开它
        vim.cmd.edit(vim.uri_to_fname(result))
    end)
end, { desc = "切换 C/H 文件" })

-- 自动安装插件管理器 Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath
    })
end
vim.opt.rtp:prepend(lazypath)

-- 插件列表
require("lazy").setup({
    -- UI 主题
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",              -- 默认为 mocha，也可以改为 "macchiato" 或 "latte"
                transparent_background = false, -- 是否透明背景
            })
            vim.cmd.colorscheme "catppuccin"
        end
    },

    -- 状态栏
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function() require('lualine').setup() end
    },

    -- 文件管理器（空格 + e）
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
        keys = {
            { "<leader>e", ":Neotree toggle reveal<CR>", desc = "打开/关闭文件树(定位)" },
        },
    },

    -- 模糊搜索（空格 + f 搜索文件 / 空格 + g 搜索文字）
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.5',
        dependencies = {
            'nvim-lua/plenary.nvim',
            { "nvim-telescope/telescope-live-grep-args.nvim", version = "^1.0.0" },
        },
        config = function()
            require("telescope").load_extension("live_grep_args")
        end,
        keys = {
            { "<leader>f", "<cmd>Telescope find_files<cr>", desc = "搜索文件名" },
            { "<leader>g", ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", desc = "搜索文件内容" },
        },
    },

    -- 语法高亮（让代码颜色更准确）
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        branch = "master",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "c", "cpp", "lua", "python", "bash", "markdown", "markdown_inline", "vim", "vimdoc" },
                highlight = { enable = true },
            })
        end
    },

    -- 自动补全
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
        config = function()
            local cmp = require("cmp")
            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                mapping = cmp.mapping.preset.insert({
                    ['<C-n>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
                    ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
                    ['<CR>'] = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = false
                    })
                }),
                snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                }, {
                    { name = 'buffer' },
                    { name = 'path' },
                })
            })
        end
    },

    -- LSP 管理器（Mason - 自动安装 C++/Python 等语言服务）
    {
        "williamboman/mason.nvim",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
            "neovim/nvim-lspconfig",
        },
        config = function()
            require("mason").setup()

            local capabilities = require('cmp_nvim_lsp').default_capabilities()
            local lspconfig = require('lspconfig')

            require('mason-lspconfig').setup({
                ensure_installed = {
                    "clangd", "lua_ls",
                    "html", "cssls", "ts_ls", "jsonls"
                },
                handlers = {
                    function(server_name)
                        require("lspconfig")[server_name].setup({
                            capabilities = capabilities
                        })
                    end,
                }
            })
        end
    },

    -- 自动成对符号（括号自动闭合）
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        opts = {}
    },

    -- Markdown 预览和美化
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        ft = { "markdown" },
        build = function() vim.fn["mkdp#util#install"]() end,
    },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        ft = { "markdown" },
        opts = {},
    },

    -- 代码折叠插件
    {
        "kevinhwang91/nvim-ufo",
        dependencies = {
            "kevinhwang91/promise-async",
            "nvim-treesitter/nvim-treesitter"
        },
        event = "BufRead",
        config = function()
            require('ufo').setup({
                provider_selector = function(buffnr, filetype, buftype)
                    return { 'treesitter', 'indent' }
                end
            })
        end
    },

    -- 显示当前所在的函数体
    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            require("treesitter-context").setup({
                enable = true
            })
            vim.api.nvim_set_hl(0, "TreesitterContext", { bg = "#313244" })
            vim.api.nvim_set_hl(0, "TreesitterContextBottom", { underline = true, sp = "#f5c2e7" })
            vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { bg = "#2d2d2d", fg = "#f5c2e7" })
        end
    },

    -- Web 开发：自动闭合/重命名 HTML 标签
    {
        "windwp/nvim-ts-autotag",
        config = function()
            require('nvim-ts-autotag').setup()
        end
    },

    -- Web 开发：显示 CSS 颜色代码 (如 #ffffff)
    {
        "NvChad/nvim-colorizer.lua",
        event = "BufReadPre",
        opts = {
            user_default_options = {
                tailwind = true, -- 如果以后用 tailwindcss 很有用
                css = true,
            },
        },
    },

    -- 炫酷的 UI 界面（命令行、弹窗、通知）
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        opts = {
            -- 这里的配置会让你的 LSP 悬浮框自动带上圆角
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.set_formatting_op"] = true,
                    ["formatting.hover"] = true,
                },
            },
            presets = {
                bottom_search = true,         -- 使用底部搜索栏
                command_palette = true,       -- 命令行面板居中
                long_message_to_split = true, -- 长消息放在 split 中
                inc_rename = false,           -- 是否启用增量重命名
                lsp_doc_border = true,        -- 给 LSP 文档加上边框！
            },
        },
        dependencies = {
            "MunifTanjim/nui.nvim",
            -- 可选：通知增强插件
            {
                "rcarriga/nvim-notify",
                config = function()
                    require("notify").setup({
                        background_colour = "#000000", -- 避免透明度导致的文字重叠
                        render = "wrapped-compact",
                    })
                    vim.notify = require("notify")
                end
            },
        }
    },
})
