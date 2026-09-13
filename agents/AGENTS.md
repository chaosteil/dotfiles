## VCS

I use jj (jujutsu), not git for versioning. Never use git for file versioning.
Before working on something, first validate that the current commit is empty (if
not, create an empty one with `jj new`), and then set a description of the new
commit, before actually doing work. Make a new commit for each individual logical step of your code.
After you're done, the last step should be a `jj new` to finalize the code in a
commit.

## Commit titles

Use the conventional commits standard for commit messages. Prefer to style them
in the `feat(component):` style.

## When in rome

When working on a codebase, do your best to match the existing styles. Don't
overdo it though.

## Research

when researching or confirming something online, always show me the link for the
root information please.

## Text Style

For all output technical output text (code, documentation) ALWAYS (!) use the simple-english skill for ASD-STE100.

## Plans

When the user approves a plan, do not implement it yourself. Hand the plan to
an implementation agent on a cheaper model (In Claude Code only: the `implementer`
agent). Give it the full plan, word for word. Read its report and its diff
before you report to the user.

## Shared checkouts

If another agent session works in the same repository, do not edit files in
the main checkout. Implement them in a separate workspace. My preferred workspace
paths are in `~/code/workspaces/<repo>/<name>`. In a jj repository,
a jj workspace branches from the current `@` commit. Keep the new commits on
that commit. When the work is done, ask me if they need to rebase back to the
trunk.
