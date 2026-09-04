---
name: jujutsu-workspaces
description: "**REQUIRED** - Activate when work in a Jujutsu (jj) repo is split across PARALLEL agents or isolated working directories: a workflow that fans out subagents onto separate features, an agent that must branch off and work without disturbing the main checkout, or an integrator agent that collects finished branches and merges them back. Use with the `jujutsu` skill (single-commit basics) and `jujutsu-stacks` (multi-commit work). Teaches workspace setup, the feature-agent contract, the integration protocol, and the stale/divergent recovery paths."
allowed-tools: Bash(jj *)
---

# Jujutsu: Parallel Work with Workspaces

This skill shows how several agents work at the same time in one jj repo. Each
agent gets a **workspace**: its own working directory and its own working-copy
commit (`@`). All workspaces share one repo, one commit graph, and one set of
bookmarks.

Read the `jujutsu` skill first for the basics: the working copy is a commit,
change IDs, `--no-pager`, and `-m`. If a feature needs more than one commit, read
`jujutsu-stacks`. This skill assumes both.

**The commands below work with jj v0.43.0.** Every command and behavior in this
skill was tested with that version. If `jj --version` shows a different version,
read `jj <cmd> --help` before you use a flag.

## The Mental Model: One Graph, Many Working Copies

A jj workspace is the equivalent of `git worktree`. The two differ in how much
they share:

| | git worktree and branches | jj workspace |
|---|---|---|
| Sees another working copy's commits | Only after a fetch or a merge | Immediately |
| Integration cost | A merge or a rebase across refs | A rebase inside one graph |
| Shared state | Refs only | Commits, bookmarks, operation log |

**This difference changes how you orchestrate agents.** A feature agent in
`../ws-feat-a` writes commits. An integrator in the main workspace sees those
commits on its next `jj log`. There is no push, no fetch, and no remote. The
integrator does not import the work. The work is already there.

Two results follow from this model:

1. **A handoff is a name, not a payload.** A feature agent reports one bookmark
   name. The integrator resolves that name in the shared graph.
2. **Any workspace can rewrite the commits of any other workspace.** Nothing is
   private. This fact is the source of every hazard in this skill.

Changes propagate at command boundaries. Each jj command snapshots the current
workspace and reads the operation log. There is no filesystem watcher.

## Roles

Give each agent one role. Do not mix them.

| Role | Workspace | Can do | Must not do |
|---|---|---|---|
| **Coordinator** | main (`default`) | Create workspaces, assign features, clean up | Edit feature commits |
| **Feature agent** | its own | Commit, describe, bookmark, rebase **its own** stack | Touch the commits or bookmarks of another agent |
| **Integrator** | main or a dedicated one | Rebase, merge, resolve conflicts, move `main` | Start new feature work |

A workflow that fans out N feature agents and then runs one integrator maps
directly onto this table.

## Phase 1: The Coordinator Creates Workspaces

Create one workspace for each feature, before the agents start.

```bash
# From the main workspace
jj workspace add --name feat-auth -r main -m "feat(auth): Add token refresh" ../ws-feat-auth
jj workspace add --name feat-cache -r main -m "feat(cache): Add LRU eviction" ../ws-feat-cache
```

Three flags matter here:

- `--name <name>` — the workspace name in `jj log` and `jj workspace list`. Always
  set it. The default name is the basename of the path, which is easy to confuse.
- `-r <revset>` — the parents of the new `@`. **Always pass `-r`, and choose the
  base on purpose.** The next section gives the four cases.
- `-m "<message>"` — describes the new `@` immediately. The feature agent can
  then edit files at once, with the describe-first rule already satisfied.

### Choose the base

| Base | Use it for |
|---|---|
| `-r main`, `-r trunk()` | An independent feature. This is the common case. |
| `-r @` | A subfeature on top of your current work. |
| `-r <bookmark>`, `-r <change-id>` | A subfeature on top of finished work. |
| (no `-r`) | A sibling of the current `@`, with the same parents. Rarely correct. |

If you omit `-r`, the new `@` does **not** branch off `@`. It gets the *parents*
of the current workspace's `@`. To branch off your current work, pass `-r @`.

### Subfeature workspaces

`-r @` is the correct base for a subfeature that builds on work in progress. One
result follows from it: the base commit still changes.

Every jj command in the parent workspace snapshots the files and rewrites that
commit. jj then rebases the descendants. The `@` of your subfeature workspace is
one of those descendants. Your workspace thus goes stale each time the parent
agent edits a file.

This behavior is normal, and no work is lost. Run `jj workspace update-stale`.
Your own changes stay, and the new content of the base appears.

To make this happen less often, branch off a commit that stops moving:

```bash
jj workspace add --name sub -r <bookmark> -m "feat: Subfeature" ../ws-sub
jj workspace add --name sub -r @- -m "feat: Subfeature" ../ws-sub
```

Make sure that the result is correct:

```bash
jj --no-pager workspace list
jj --no-pager log
```

In `jj log`, the working-copy commit of each workspace has the mark `<name>@`:

```
@  smzloulw ... default@ b7654e81
│  (empty) (no description set)
│ ○  wtxkzwqw ... feat-auth@ 5c339b49
├─╯  (empty) feat(auth): Add token refresh
○  ksszzyvy ... main 45dc5c1e
```

### Where to put the directory

Put each workspace beside the repo, not inside it: `../ws-<feature>`.

A nested workspace does not corrupt jj. jj skips nested workspace roots, so
`jj st` in the outer workspace stays clean. The problem is every other tool.
Build tools, test globs, linters, and file searches walk a second copy of the
full source tree. Keep the workspaces as siblings of the repo.

### Names

Use one prefix for the whole run, so that cleanup is a single glob:

- Directory: `../ws-<feature>`
- Workspace name: `<feature>`
- Bookmark: `<feature>` or `<run-id>/<feature>`

## Phase 2: The Feature Agent Contract

Give every feature agent these rules word for word in its prompt.

### The contract

1. **Work only in your directory.** Your workspace root is `<path>`. Do not `cd`
   into another workspace. Do not point `-R` at one.
2. **Never `jj edit` a commit that you did not create.** The `@` of another
   workspace looks like an ordinary commit, and jj gives no warning. Read
   "Hazard 2: Divergent Commits".
3. **Never rebase or abandon a commit outside your own stack.** Your stack is
   `main..@`. Every other commit belongs to another agent.
4. **Never move a bookmark that you did not create**, and never move `main`. The
   integrator moves `main`.
5. **Create one bookmark at the top of your finished work**, then report its name.
6. **Do not push.** Only the integrator pushes. The user must ask for it first.
7. **If a command reports a stale working copy, run `jj workspace update-stale`.**
   Then read `jj log` again. Your change IDs are stable, but your commit IDs moved.

### The working pattern

Describe first, then write code. The coordinator already described `@` with `-m`:

```bash
jj st                                  # make sure of the workspace and its @
# ... edit files ...                   # changes land in the described commit
jj --no-pager diff --git               # review
```

For more than one commit, use the squash workflow from `jujutsu-stacks`:

```bash
jj new -m "feat(auth): Add refresh endpoint tests"
jj new                                 # undescribed scratch commit
# ... edit ...
jj squash
```

### The finish

```bash
# 1. Review the full stack
jj --no-pager log -r 'main..@'

# 2. Bookmark the top commit of the finished work
jj bookmark create feat-auth -r @-     # @- when @ is an empty scratch commit
jj bookmark create feat-auth -r @      # @ when @ holds the last real change

# 3. Leave a fresh empty commit for the work that comes after
jj new
```

Make sure that the bookmark is correct before you report it:

```bash
jj --no-pager log -r 'main..feat-auth'
```

**Report these five items** to the coordinator or the integrator:

- the bookmark name,
- the number of commits in `main..<bookmark>`,
- the files that changed,
- the result of the build and the tests,
- each conflict that remains in the stack.

Do not report a change ID as the handoff key. A rebase keeps change IDs, but the
integrator must look them up. The bookmark is the stable handle.

## Phase 3: Integration

When the agents finish, the integrator sees every feature. There is no import step.

### Look first

```bash
# What bookmarks exist?
jj --no-pager bookmark list

# What is in one feature?
jj --no-pager log -r 'main..feat-auth'

# The full feature as one diff
jj --no-pager diff --git --from 'fork_point(main | feat-auth)' --to feat-auth

# All work not yet on main, from all agents
jj --no-pager log -r 'main..'

# Which commits already have conflicts?
jj --no-pager log -r 'main.. & conflicts()'
```

### Option A: Linear integration (default)

Stack the features one after the other. Then move `main` to the top. Integrate
one feature at a time, and stop at the first conflict.

```bash
# 1. First feature onto the current main
jj rebase -s 'roots(main..feat-auth)' -o main

# 2. Second feature onto the tip of the first
jj rebase -s 'roots(main..feat-cache)' -o feat-auth

# 3. Make sure the range is clean before you move the bookmark
jj --no-pager log -r 'main..'
jj --no-pager log -r 'main.. & conflicts()'

# 4. Move main to the top
jj bookmark move main --to feat-cache
```

`-s` moves a commit **and all its descendants**. A rebase of the root of a stack
thus moves the full stack. `roots(main..<bookmark>)` finds that root for you.

Use this option first. It gives a linear history, and each commit stays
reviewable.

### Option B: Merge commit

If the features are independent, you can record that they landed together:

```bash
jj new feat-auth feat-cache -m "chore: Integrate auth and cache"
jj bookmark move main --to @
jj new
```

`jj new` with more than one revision creates a merge commit. If the features
change the same lines, the merge commit records the conflict. It does not stop.

### Conflicts belong to the integrator

jj records a conflict in the commit. It does not stop the rebase. No step is
left half-done, and there is no `--continue`. The rebase prints the result:

```
Rebased 2 commits to destination
New conflicts appeared in 1 commits:
  wvpwltnl 8db62f1b feat-cache | (conflict) feat(cache): Add LRU eviction
```

Resolve the **earliest** conflicted commit first. A conflict there propagates to
every descendant. A fix in a descendant leaves the ancestor broken.

```bash
# 1. Find the earliest conflicted commit
jj --no-pager log -r 'main.. & conflicts()'

# 2. Put a scratch commit on it. The markers appear in your working directory.
jj new <earliest-conflicted-id>

# 3. Edit the files directly to delete the markers. Then:
jj --no-pager diff --git
jj squash

# 4. Make sure that the range has no conflicts
jj --no-pager log -r 'main.. & conflicts()'
```

Do not use `jj resolve`. It is interactive, and it hangs an agent.

**CAUTION: Tell the feature agent before you resolve a conflict in its stack.**
The resolution rewrites the commits of that agent. Its workspace goes stale at
once. That agent must then run `jj workspace update-stale`.

### How to read a conflict marker

jj markers are not git markers. They name the commit on each side:

```
<<<<<<< conflict 1 of 1
%%%%%%% diff from: ksszzyvy 45dc5c1e "chore: Unrelated trunk change" (parents of rebased revision)
\\\\\\\        to: qtrtropn 3fe02bfc "feat(auth): Add refresh endpoint" (rebase destination)
+feature a
+++++++ wvpwltnl e4e98d28 "feat(cache): Add LRU eviction" (rebased revision)
feature b conflicting
>>>>>>> conflict 1 of 1 ends
```

The `%%%%%%%` section is a **diff** that the rebase tried to apply. The `+++++++`
section is the **content** of the rebased side. Write the correct result over the
full block, markers included.

### Tests before you move `main`

Each commit must build on its own. To test one commit without a change to the
stack, use a scratch commit:

```bash
jj new <change-id>       # the working copy shows the tree of that commit
# ... run the build and the tests ...
jj abandon @             # delete the scratch commit. The stack does not change.
```

Move `main` only after the range has no conflicts and all tests pass.

## How to Operate on Another Workspace Without `cd`

`jj -R <workspace-path>` operates **as** that workspace. In that command, `@`
resolves to the working-copy commit of that workspace.

```bash
# From anywhere: what is feat-auth working on?
jj -R ../ws-feat-auth --no-pager st
jj -R ../ws-feat-auth --no-pager log -r 'main..@'
```

**CAUTION: Do not run a mutating command with `-R` against a workspace that
another agent uses.** The `-R` flag snapshots the files of that workspace. Use
`-R` for reads. To read repo state without a snapshot, add
`--ignore-working-copy`:

```bash
jj -R ../ws-feat-auth --ignore-working-copy --no-pager log
```

## Hazard 1: The Stale Working Copy

This failure is the most common one in parallel work. It is normal. It is not
damage.

**Cause.** Another workspace rewrote the `@` of this workspace, through
`rebase`, `squash`, `abandon`, or a conflict resolution. It also happens after
you interrupt a command with `^C`.

**Symptom.** Every jj command in that workspace stops:

```
Error: The working copy is stale (not updated since operation 7b8cbd332d04).
Hint: Run `jj workspace update-stale` to update it.
```

**Recovery.**

```bash
jj workspace update-stale
jj st
```

`update-stale` updates the files on disk to the rewritten commit, and it keeps
the changes that it can. After it runs, read `jj log` again. The change IDs
survived. The commit IDs did not.

Integration rewrites feature commits by design. Expect a stale working copy
after every integration pass. Give each feature agent the recovery command at
the start.

## Hazard 2: Divergent Commits

**Cause.** Two workspaces have the same change as their `@`, and both write to
it. `jj edit <id>` permits this state with no warning.

**Symptom.** After `update-stale`, one change ID exists two times:

```
Concurrent modification detected, resolving automatically.
Working copy  (@) now at: ltstnwmk/1 6744c62e (divergent) shared change
```

```
@  ltstnwmk/1 ... default@ dv@ 6744c62e (divergent)
○  ltstnwmk/0 ... 8ed65615 (divergent)
```

The `/0` and `/1` suffixes number the divergent copies. Nothing is lost. Each
copy holds the work of one side.

The `jujutsu` skill shows this state as `xyz??`. That notation is from an older
jj. Version 0.43 and later print `xyz/0` and `xyz/1`. To find the commits, use
`jj --no-pager log -r 'divergent()'`.

**CAUTION: Look at both sides before you abandon one.** If a workspace was
already stale when you changed files in it, jj never snapshotted those changes.
`update-stale` rescues them into the `/0` side. It also replaces the files on
disk with the `/1` side. The `/0` commit is then the only copy of that work, and
an abandon deletes it.

**Recovery: converge the two sides.** A squash keeps the work of both:

```bash
# 1. List them
jj --no-pager log -r 'divergent()'

# 2. Look at both sides by COMMIT id. The change id is ambiguous here.
jj --no-pager show --git <commit-id-0>
jj --no-pager show --git <commit-id-1>

# 3. Squash one side into the other. Use commit IDs. -u keeps one description.
jj squash --from <commit-id-0> --into <commit-id-1> -u
```

The change ID then points to one commit again, and `divergent()` is empty.

If both sides changed the same lines, the squash records a conflict in the
result. It does not stop. Resolve it as in "Conflicts belong to the integrator".
Files that only one side changed come across cleanly.

Abandon a side only after you looked at it and it holds no work that you want:

```bash
jj abandon <commit-id-0>
```

**Prevention: never let two workspaces hold the same change.** This hazard is
the reason for rule 2 of the feature-agent contract.

## Phase 4: Cleanup

The `jj workspace forget` command stops the repo from tracking a workspace. It
does **not** delete files. Delete the directory yourself.

```bash
jj workspace forget feat-auth
rm -rf ../ws-feat-auth
```

The order does not matter, but do both steps. A deleted directory with a tracked
workspace leaves a stale entry in `jj workspace list`.

You can forget more than one workspace in one command:

```bash
jj workspace forget feat-auth feat-cache
```

The state of `@` at that moment decides what happens to it:

| `@` state at forget time | Result |
|---|---|
| Empty, no descendants | jj abandons it. It leaves the graph. |
| Holds changes | It stays in the graph as an unreferenced commit. |

`forget` thus never destroys work, but it can leave stray commits. Look for them
afterwards:

```bash
jj --no-pager log -r 'main..'
```

Abandon each commit that is scrap: `jj abandon <change-id>`.

## Failure Recovery

| Situation | Action |
|---|---|
| Stale working copy | `jj workspace update-stale` |
| Divergent change ID | `jj squash --from <cid-0> --into <cid-1> -u` to converge the two sides |
| One bad rebase | `jj undo` |
| Bad multi-step integration | `jj op log`, then `jj op restore <op-id>` |
| Lost commit after a rewrite | `jj --no-pager evolog -r <change-id>` |
| Directory deleted, entry remains | `jj workspace forget <name>` |
| Feature agent rewrote the wrong stack | `jj op restore <op-id>`, then repeat the contract |

`jj op restore` restores the **full repo**, every workspace included. Warn every
active agent before you use it.

## Pitfalls

- **`jj workspace add` without `-r` does not branch off `@`.** It inherits the
  parents of the current workspace's `@`, which makes a sibling. Pass `-r main`
  for an independent feature, or `-r @` for a subfeature.
- **Bookmarks never advance on their own.** If a feature agent commits after it
  creates its bookmark, the bookmark stays behind. Look at
  `jj --no-pager log -r 'bookmarks()'` before you integrate.
- **`-s` carries descendants, and that includes the `@` of another workspace.**
  This behavior is usually correct, because the feature workspace follows its
  stack. It also makes that workspace stale.
- **If both source and destination have a description, `jj squash` opens an
  editor.** Pass `-u` or `-m "message"`, or keep the scratch commit undescribed.
- **Some commits are immutable.** Any commit in `trunk()`, or any pushed commit,
  can be immutable. Do not use `--ignore-immutable` without a question to the
  user first.
- **Two agents, one bookmark name.** The second `jj bookmark create` fails, or
  one agent moves the bookmark of the other. Assign all names centrally.
- **`jj workspace forget` with no argument forgets the current workspace.**
  Always name the target.

## Quick Reference

| Action | Command |
|---|---|
| Create a feature workspace | `jj workspace add --name <n> -r main -m "<msg>" ../ws-<n>` |
| List workspaces | `jj --no-pager workspace list` |
| Show a workspace root | `jj workspace root --name <n>` |
| Look at another workspace | `jj -R ../ws-<n> --ignore-working-copy --no-pager log` |
| Show the commits of one feature | `jj --no-pager log -r 'main..<bookmark>'` |
| Show one feature as a diff | `jj --no-pager diff --git --from 'fork_point(main \| <bm>)' --to <bm>` |
| Show all unintegrated work | `jj --no-pager log -r 'main..'` |
| Find conflicts | `jj --no-pager log -r 'main.. & conflicts()'` |
| Bookmark finished work | `jj bookmark create <n> -r @-` |
| Integrate linearly | `jj rebase -s 'roots(main..<bm>)' -o <dest>` |
| Integrate as a merge | `jj new <bm-a> <bm-b> -m "<msg>"` |
| Land it | `jj bookmark move main --to <bm>` |
| Correct a stale working copy | `jj workspace update-stale` |
| Find divergent commits | `jj --no-pager log -r 'divergent()'` |
| Converge divergent commits | `jj squash --from <cid-0> --into <cid-1> -u` |
| Delete a workspace | `jj workspace forget <n>`, then `rm -rf ../ws-<n>` |
| Undo an integration | `jj op log`, then `jj op restore <op-id>` |

## Best Practices Summary

1. **One role for each agent** — coordinator, feature agent, or integrator.
2. **Always pass `-r`** when you add a workspace: `-r main` for an independent
   feature, `-r @` for a subfeature on your current work.
3. **Hand off a bookmark name**, never a change ID and never a diff.
4. **Never `jj edit` the `@` of another workspace.** This one rule prevents
   divergent commits.
5. **Converge divergent commits with a squash.** Abandon a side only after you
   read it.
6. **The integrator owns `main`**, all conflicts, and all pushes.
7. **Resolve the earliest conflicted commit**, never the tip.
8. **Expect stale working copies after integration.** They are normal. Correct
   them with `jj workspace update-stale`.
9. **Forget and delete every workspace** at the end of the run.

## Sources

- [Working copy and workspaces — Jujutsu docs](https://docs.jj-vcs.dev/latest/working-copy/#workspaces)
- [Stale working copy — Jujutsu docs](https://docs.jj-vcs.dev/latest/working-copy/#stale-working-copy)
- [Jujutsu CLI reference — `jj workspace`](https://docs.jj-vcs.dev/latest/cli-reference/#jj-workspace)
- [Conflicts — Jujutsu docs](https://docs.jj-vcs.dev/latest/conflicts/)
- [Revsets — Jujutsu docs](https://docs.jj-vcs.dev/latest/revsets/)
