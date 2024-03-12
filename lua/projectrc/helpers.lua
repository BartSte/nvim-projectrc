local M = {}

--- Similar to `join`, but now for module names, which are separated by a dot.
---@param parent string The module name. For example `helpers`.
---@vararg string The parts of the module name to join. For example `path` and
--join
---@return string module The joined module name. For example
--`helpers.path.join`.
M.module_join = function(parent, ...)
  local parts = { ... }
  local module = parent .. "." .. table.concat(parts, ".")
  module = module:gsub("%.+$", ""):gsub("%.lua$", "")
  return module
end

--- Merge the `opts` table with the defaults `opts` table, where the `opts`
--- table takes precedence.
---@param opts table | nil The options to merge with the defaults `opts` table.
---@param defaults table The defaults `opts` table.
---@return table result The merged options table.
M.merge_opts = function(opts, defaults)
  if opts == nil then
    return defaults
  else
    return vim.tbl_extend("force", defaults, opts)
  end
end

--- If the `obj` is a function, call it and return the result. If it is not a
--- function, return the `obj`.
---@param obj any an object to call or return.
M.call_or_return = function(obj)
  if type(obj) == "function" then
    return obj()
  else
    return obj
  end
end


return M
