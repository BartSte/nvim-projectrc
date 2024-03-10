local helpers = require("projectrc.helpers")

local M = {}

M.defaults = {
  env = "PROJECTRC",
  fallback_file = "default",
  fallback_value = {},
  callback = nil,
}

--- Try to require the module: "{parent}.{file}". If it fails, return the
--- value or the retun value of the `default` parameter.
---@param parent string The parent directory of the module to require.
---@param file string The file in the parent directory to require.
---@param default any The value to return if no module can be required. If it
--- is a function, call it and return the result. If it is not a function, return
--- the value.
---@return any result The required module or the value of `return_value`.
M.try_require = function(parent, file, default)
  if file ~= "" then
    local module = helpers.module_join(parent, file)
    local ok, result = pcall(require, module)
    if ok then
      return result
    end
  end
  return helpers.call_or_return(default)
end

--- Get the value of `env`. If it is not set, return the value of the default
--- variable: require("projectrc").defaults.env. If an environment variable is
--- not set, return an empty string.
---@param env string | nil The environment variable to get the value of.
---@return string name The value of the environment variable.
M.get_name = function(env)
  env = env or M.defaults.env
  local name = vim.fn.getenv(env)
  if name == vim.NIL then
    return ""
  else
    return name
  end
end

---@param parent string The require path of the parent module.
---@param opts table | nil The options to use when requiring the module. These
--- are the same options as the global `opts` table, but now they are only
--- applied in this function.
---@return any result The required module or the value that is returned by the
--- `opts.callback` function.
M.require = function(parent, opts)
  opts = helpers.merge_opts(opts, M.defaults)

  local file = M.get_name(opts.env)
  local default = function()
    return opts.callback(parent, opts.fallback_file, opts.fallback_value)
  end

  return M.try_require(parent, file, default)
end

M.defaults.callback = M.try_require

--- Change the default options for the whole module.
---@param opts table | nil The options to change the default options to.
M.setup = function(opts)
  M.defaults = helpers.merge_opts(opts, M.defaults)
end

return M
