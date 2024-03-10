# README - nvim-projectrc

A minimal approach to manage your project specific settings in Neovim.

## Introduction

`nvim-projectrc` is a plugin for Neovim that allows you to manage your project
specific settings in a simple, yet effective way.

I build this plugin because I have only small differences between my projects,
e.g., different textwidths, linters, and language servers. I did not want to
create a new configuration file for each project, and I surely did not want to
place if statements all over my configuration. As such, `nvim-projectrc` is
based on the following requirements:

- One global configuration file is used where each project makes its own
  modifications to.
- It is easy to integrate in an existing configuration.
- The project identifier can be set from outside of Neovim, using an environment
  variable.

See the [usage](#usage) section for more information.

## Installation

Install the plugin using your favorite plugin manager. For example, using lazy:

```lua
return {
    "BartSte/nvim-projectrc",
    priority = 100,
    lazy = false
}
```

Lazy loading is not recommended as you need this plugin to load the configuration
of other plugins.

## Usage

This plugin exposes the following 2 components that are of key interest:

- `PROJECTRC` environment variable
- `require("projectrc").require`

Here, the `PROJECTRC` must be set before calling `require("projectrc").require`.
How you set the `PROJECTRC` is up to you. For example, you can set it to the
basename of the current working directory using the following bash alias:

```bash
alias nvim='export PROJECTRC=$(basename $(pwd)); nvim'
```

The `require("projectrc").require` function takes a path to a directory
containing multiple configuration files. Here it will first try to source the
file with the name that corresponds to the `PROJECTRC` environment variable. If
this fails, it will try to source the file `default.lua`. If this fails, the
function returns an empty table.

Lets illustrate this with some examples.

### Example - require

- `PROJECTRC` is set to `myproject`.

Now when you call `require("projectrc").require("/some/path")` the following
will happen:

- It will try to source the file `/some/path/myproject.lua`.
- If this fails, it will try to source the file `/some/path/default.lua`.
- If this fails, the function returns an empty table.

### Example - directory structure

Lets assume you have the following directory structure:

```ascii
nvim/
├── lua/
│   ├── config/lsp/
│   │   ├── init.lua      -> servers you always need.
│   │   ├── default.lua   -> default servers, no specific project settings.
│   │   └── myproject.lua -> specific servers for myproject.
│   │
... more files
```

In you config, when you want to source you lsp configuration, you would call:

- `require("projectrc").require("config.lsp")`

If you `PROJECTRC` is set to `foo`, the following will happen:

- `config/lsp/init.lua` will always be sourced.
- it will try to source `config/lsp/foo.lua`, but this file does not exist.
- as a fallback, it will source `config/lsp/default.lua`.

Now if you `PROJECTRC` is set to `myproject`, the following will happen:

- `config/lsp/init.lua` will always be sourced.
- it will try to source `config/lsp/myproject.lua`, and this file exists.

Note that in the last case, the `default.lua` file is not sourced.

### Example - using lazy

In the example above, you would call the `require("projectrc").require` function
using the package manager [lazy](www.github.com/folke/lazy.nvim) as is explained
below.

Lets assume you have the following project structure:

```ascii
nvim/
├── lua/
│   ├── config/lsp/
│   │   ├── init.lua      -> servers you always need.
│   │   ├── default.lua   -> default servers, no specific project settings.
│   │   └── myproject.lua -> specific servers for myproject.
│   └── plugins/lsp.lua   -> containing the plugin spec.
... more files
```

where the `plugins` directory is added to the `lazy.setup` function:
`lazy.setup("plugins", {})`. The `plugins/lsp.lua` may look as follows:

```lua
return {
    "neovim/nvim-lspconfig",
    config = function()
        require("projectrc").require("config.lsp")
    end
}
```

Similarly to the previous example, the `config/lsp/init.lua` will always be
sourced. The `myproject.lua` file will be sourced if `PROJECTRC` is set to
`myproject`, and the `default.lua` file will be sourced otherwise.

### Example - ftplugin

Sometimes you want your project specific settings to be sourced when you enter a
file of a certain filetype. Lets say you want a textwidth of 100 for your
`myproject` config, and a textwidth of 80 otherwise. Furthermore, this only
needs to happen for `python` files. You can do this as follows.

We have the following directory structure:

```ascii
nvim/
├── lua/
│   ├── after/ftplugin/
│   │   ├── python/
│   │   │   ├── init.lua      -> always sourced.
│   │   │   ├── default.lua   -> default settings.
│   │   │   └── myproject.lua -> specific settings.
... more files
```

where the `lua/after` directory needs to be appended to the `runtimepath` using
the following command:

```lua
vim.opt.rtp:append("lua/after")
```

or when you use [lazy](www.github.com/folke/lazy.nvim) you should use the opts:

```lua
lazy.setup("plugins", { performance = { rtp = { paths = { "lua/after" } } } })
```

now you can add the following to the `init.lua` file:

```lua
require("projectrc").require("after.ftplugin.python").setup()
```

make sure you wrap your configuration in a function as all files in a filetype
directory are sourced, as is explained in `:h ftplugin`:

```lua
local M = {}

M.setup = function()
    -- your configuration here
end

return M
```

Now the following will happen:

- Set your `PROJECTRC` to `myproject`.
- Open a python file.
- The `after/ftplugin/python/init.lua` file will always be sourced.
- It will try to source `after/ftplugin/python/myproject.lua`, and this file
  exists. It will return a table with the `setup` function.
- You call the `setup` function, which will set your configuration.

## Configuration

The plugin can be configured on a global level but also on a function level.

### Global configuration

The following global configuration options are available with their defaults:

````lua
require("projectrc").setup({
    -- The name of the environment variable that holds the project identifier.
    env = "PROJECTRC",
    -- The name of the file that is sourced when the project config is not found.
    fallback_file = "default.lua",
    -- The value that is returned when the `fallback_file` is not found.
    fallback_value = {},
    -- Callback function that is called when the project config is not found.
    callback = require("projectrc").try_require
})
```

TODO: explain the configuration options above.

### Function level configuration

## Troubleshooting

If you encounter any issues, please report them on the issue tracker at:
[projectrc issues](https://github.com/BartSte/nvim-projectrc/issues)

## Contributing

Contributions are welcome! Please see [CONTRIBUTING](./CONTRIBUTING.md) for
more information.

## License

Distributed under the [MIT License](./LICENCE).
````
