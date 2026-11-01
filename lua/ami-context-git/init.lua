-- ami-context-git: feed your uncommitted git diff to ami as extra context.
--
-- A context-provider extension: it contributes to ami's "context.extra" collector,
-- so the advisor (and proactive nudges) see what you're actually changing — not just
-- the saved file. Returns the working-tree diff vs HEAD for the active project.
--
--   require("ami").setup({ extensions = { require("ami-chat"), require("ami-context-git") } })
--
-- The reference example of a context-provider extension. The diff is gathered
-- synchronously (a quick `git diff`) during context assembly and capped to
-- `max_bytes`; return nil when there's nothing to add, so a clean tree adds no noise.

local function git(root, args, timeout)
  local cmd = { "git", "-C", root }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, { text = true }):wait(timeout or 2000)
  if res.code ~= 0 then
    return nil
  end
  return res.stdout
end

return {
  name = "context-git",

  config = {
    max_bytes = 4000, -- cap the diff sent (keeps the context budget sane)
    timeout_ms = 2000, -- max time to wait for git per turn
  },

  setup = function(api)
    api.on("context.extra", function(info)
      local root = info.refs and info.refs.project_root
      if not root or root == "" or vim.fn.executable("git") == 0 then
        return nil
      end
      if not git(root, { "rev-parse", "--is-inside-work-tree" }, api.config.timeout_ms) then
        return nil -- not a git repo
      end
      -- All uncommitted changes vs the last commit; fall back to the plain working
      -- diff on an unborn branch (no HEAD yet).
      local diff = git(root, { "diff", "HEAD", "--" }, api.config.timeout_ms)
      if not diff or vim.trim(diff) == "" then
        diff = git(root, { "diff", "--" }, api.config.timeout_ms)
      end
      if not diff or vim.trim(diff) == "" then
        return nil -- clean tree: contribute nothing
      end
      local max = api.config.max_bytes or 4000
      if #diff > max then
        diff = diff:sub(1, max) .. "\n…(diff truncated)…"
      end
      return { title = "Uncommitted changes (git diff vs HEAD)", body = diff }
    end)

    api.health(function(report)
      if vim.fn.executable("git") == 1 then
        report.ok("git found")
      else
        report.error("git not found on PATH — this extension needs it")
      end
      report.info(("max diff: %d bytes · timeout: %dms"):format(api.config.max_bytes, api.config.timeout_ms))
    end)
  end,
}
