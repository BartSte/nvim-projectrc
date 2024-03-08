local M = {}

--- Similar to `join`, but now for module names, which are separated by a dot.
---@param module string The module name. For example `helpers`.
---@vararg string The parts of the module name to join. For example `path` and
--join
---@return string module The joined module name. For example
--`helpers.path.join`.
M.module_join = function(module, ...)
  local parts = { ... }
  return module .. "." .. table.concat(parts, ".")
end


--- Check if the `opts` table has keys that are not in the `defaults` table. If it
--- does, raise an error.
---@param opts table The options to check.
---@param defaults table The table to check the options against.
M.check_keys = function(opts, defaults)
  for key, _ in pairs(opts) do
    if not defaults[key] then
      error("invalid option: " .. key)
    end
  end
end

--- Raise an error if the `opts` table: has keys that are not in the defaults
--- `opts` table, if it is not a table. If it does not raise an error.
---@param opts table The options to check.
M.check_opts = function(opts, defaults)
  if type(opts) ~= "table" then
    error("opts must be a table")
  end
  M.check_keys(opts, defaults)
end

--- Merge the `opts` table with the defaults `opts` table. If the `opts` table has
--- keys that are not in the defaults `opts` table, raise an error. If the `opts`
--- table is not a table, raise an error. `nil` values is allowed in the `opts`
--- table as it will be replaced by the defaults `opts` table.
---@param opts table | nil The options to merge with the defaults `opts` table.
---@param defaults table The defaults `opts` table.
---@return table result The merged options table.
M.merge_opts = function(opts, defaults)
  if opts == nil then
    return defaults
  end
  M.check_opts(opts, defaults)
  return vim.tbl_extend("force", defaults, opts)
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
