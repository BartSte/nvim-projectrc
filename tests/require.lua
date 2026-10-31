-- Run from the repository root: nvim --headless -u NONE -l tests/require.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
local directory = vim.fn.tempname()
vim.fn.mkdir(directory .. "/lua/projectrc_test", "p")
vim.opt.runtimepath:append(directory)

local projectrc = require("projectrc")
local defaults = vim.deepcopy(projectrc.defaults)
local original_env = vim.env.PROJECTRC
local count = 0

local function module(name, lines)
  vim.fn.mkdir(vim.fn.fnamemodify(directory .. "/lua/projectrc_test/" .. name, ":h"), "p")
  vim.fn.writefile(lines, directory .. "/lua/projectrc_test/" .. name .. ".lua")
end

local function reset()
  projectrc.defaults = vim.deepcopy(defaults)
  vim.env.PROJECTRC = nil
  for name in pairs(package.loaded) do
    if name:match("^projectrc_test%.") then
      package.loaded[name] = nil
    end
  end
end

local function test(name, fn)
  reset()
  local ok, err = pcall(fn)
  assert(ok, name .. ": " .. tostring(err))
  count = count + 1
end

local function expect_error(fn, message)
  local ok, err = pcall(fn)
  assert(not ok, "expected an error")
  assert(type(err) == "string" and err:find(message, 1, true), tostring(err))
end

local ok, err = pcall(function()
  module("default", { "return 'default'" })
  module("project", { "return 'project'" })
  module("runtime_error", { "error('configuration failed')" })
  module("syntax_error", { "return {" })
  module("missing_dependency", { "return require('projectrc_test.absent_dependency')" })
  module("false_value", { "return false" })
  module("directory/init", { "return 'directory module'" })
  module("object_error", { "error({ reason = 'configuration failed' })" })

  test("project takes precedence", function()
    vim.env.PROJECTRC = "project"
    assert(projectrc.require("projectrc_test") == "project")
  end)
  test("unset environment uses default", function()
    assert(projectrc.require("projectrc_test") == "default")
  end)
  test("missing project uses default", function()
    vim.env.PROJECTRC = "absent"
    assert(projectrc.require("projectrc_test") == "default")
  end)
  test("missing default uses fallback value", function()
    assert(projectrc.require("projectrc_test", { fallback_file = "absent", fallback_value = 42 }) == 42)
  end)
  test("missing modules return nil by default", function()
    assert(projectrc.require("projectrc_test.absent_parent") == nil)
  end)
  test("function fallback", function()
    assert(projectrc.try_require("projectrc_test", "absent", function() return 42 end) == 42)
  end)
  test("empty filename uses fallback", function()
    assert(projectrc.try_require("projectrc_test", "", 42) == 42)
  end)
  local errors = {
    runtime_error = "configuration failed",
    syntax_error = "syntax_error.lua",
    missing_dependency = "absent_dependency",
  }
  for name, message in pairs(errors) do
    test(name .. " propagates from project", function()
      vim.env.PROJECTRC = name
      expect_error(function() projectrc.require("projectrc_test") end, message)
    end)
    test(name .. " propagates from default", function()
      expect_error(function()
        projectrc.require("projectrc_test", { fallback_file = name, fallback_value = 42 })
      end, message)
    end)
  end
  test("non-string errors retain identity", function()
    local success, value = pcall(projectrc.try_require, "projectrc_test", "object_error", 42)
    assert(not success and type(value) == "table" and value.reason == "configuration failed")
  end)
  test("false result does not trigger fallback", function()
    vim.env.PROJECTRC = "false_value"
    assert(projectrc.require("projectrc_test") == false)
  end)
  test("directory modules load", function()
    assert(projectrc.try_require("projectrc_test", "directory", 42) == "directory module")
  end)
  test("cached modules load", function()
    package.loaded["projectrc_test.cached"] = "cached"
    assert(projectrc.try_require("projectrc_test", "cached", 42) == "cached")
  end)
  test("custom callback receives fallback arguments", function()
    local result = projectrc.require("projectrc_test", {
      callback = function(parent, file, value)
        assert(parent == "projectrc_test" and file == "default" and value == 42)
        return "callback"
      end,
      fallback_value = 42,
    })
    assert(result == "callback")
  end)
  test("custom callback does not hide errors", function()
    vim.env.PROJECTRC = "runtime_error"
    expect_error(function()
      projectrc.require("projectrc_test", { callback = function() error("callback must not run") end })
    end, "configuration failed")
  end)
end)

vim.env.PROJECTRC = original_env
vim.fn.delete(directory, "rf")
if not ok then error(err) end
print("PASS: " .. count .. " module-loading checks")
