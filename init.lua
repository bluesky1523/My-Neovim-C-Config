-- 基础设置
vim.g.mapleader = " "			-- 空格键是核心前缀键
vim.opt.number = true			-- 显示行号
vim.opt.relativenumber = true		-- 相对行号
vim.opt.mouse = "a"			-- 允许鼠标
vim.opt.clipboard = "unnamedplus"	-- 共享系统剪贴板
vim.opt.tabstop = 4			-- Tab 宽度
vim.opt.shiftwidth = 4			-- 缩进宽度
vim.opt.expandtab = true		-- 将 Tab 转为空格
vim.opt.ignorecase = true		-- 搜索忽略大小写
vim.opt.smartcase = true		-- 智能大小写

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
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function() vim.cmd([[colorscheme tokyonight]])end
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
			{ "<leader>e", ":Neotree toggle<CR>", desc = "打开/关闭文件树" },
		},
	},

	-- 模糊搜索（空格 + f 搜索文件 / 空格 + g 搜索文字）
	{
		'nvim-telescope/telescope.nvim', tag = '0.1.5',
		dependencies = { 'nvim-lua/plenary.nvim' },
		keys = {
			{ "<leader>f", "<cmd>Telescope find_files<cr>", desc = "搜索文件名" },
			{ "<leader>g", "<cmd>Telescope live_grep<cr>", desc = "搜索文件内容" },
		},
	},

	-- 语法高亮（让代码颜色更准确）
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "c", "cpp", "lua", "python", "bash", "markdown" },
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
				snippet = { expand = function(args) require("luasnip").lsp_expand(args.body) end },
				mapping = cmp.mapping.preset.insert({
					['<C-b>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
					['<CR>'] = cmp.mapping.confirm({ select = true }),
					['<Tab>'] = cmp.mapping.select_next_item(),
				}),
				sources = cmp.config.sources({
					{ name = 'nvim_lsp' },
					{ name = 'luasnip' },
				},{
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
                ensure_installed = { "clangd", "lua_ls" },
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
})
