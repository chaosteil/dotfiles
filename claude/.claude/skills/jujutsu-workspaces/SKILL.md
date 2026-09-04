---
name: jujutsu-workspaces
description: "**REQUIRED** - Activate when work in a Jujutsu (jj) repo is split across PARALLEL agents or isolated working directories: a workflow that fans out subagents onto separate features, an agent that must work without disturbing the main checkout, or an integrator that collects finished branches. Use with the `jujutsu` skill (single commits) and `jujutsu-stacks` (ranges of commits)."
allowed-tools: Bash(jj *)
---

# Jujutsu: Parallel Work with Workspaces

A workspace is one working directory with its own working-copy commit (`@`).
All workspaces share one repo, one commit graph, and one set of bookmarks.

Read the `jujutsu` and `jujutsu-stacks` skills first.

Commands verified with jj 0.44.0. If `jj --version` prints another version, read
`jj <cmd> --help` before you use a flag.

## What Makes This Different from git worktree

Every workspace sees the commits of every other workspace at once. There is no
push, no fetch, and no import step. Two results follow:

1. A handoff is a bookmark name, not a payload.
2. Any workspace can rewrite the commits of any other workspace. Nothing is
   private. This fact is the source of both hazards below.

## Roles

Give each agent one role.

| Role | Workspace | Owns | Must not do |
|---|---|---|---|
| Coordinator | `default` | Create workspaces, assign features, clean up | Edit feature commits |
| Feature agent | its own | Its own stack and its own bookmark | Touch another agent's commits or bookmarks |
| Integrator | `default` or its own | Rebase, merge, conflicts, `main`, push | Start new feature work |

## Phase 1: Create the Workspaces

```bash
jj workspace add --name feat-auth -r main -m "feat(auth): Add token refresh" ../ws-feat-auth
jj workspace add --name feat-cache -r main -m "feat(cache): Add LRU eviction" ../ws-feat-cache
```

Always pass all three flags:

- `--name` sets the name in `jj log` and `jj workspace list`.
- `-r` sets the parent of the new `@`. Without `-r`, jj uses the *parents* of the
  current `@`, which makes a sibling, not a child.
- `-m` describes the new `@`, so the agent can edit files at once.

Choose the base:

| Base | Use it for |
|---|---|
| `-r main`, `-r trunk()` | An independent feature. This is the common case. |
| `-r @` | A subfeature on top of your work in progress. |
| `-r <bookmark>`, `-r @-` | A subfeature on top of a commit that stops moving. |

If you use `-r @`, expect the subfeature workspace to go stale often. Every jj
command in the parent workspace rewrites that commit and rebases the descendants.

Put each workspace beside the repo, at `../ws-<feature>`, never inside it. jj
handles a nested workspace, but every build tool, linter, and test glob then
walks a second copy of the source tree.

Make sure that the result is correct:

```bash
jj --no-pager workspace list
jj --no-pager log                    # each workspace @ carries a "<name>@" mark
```

## Phase 2: The Feature Agent Contract

Put these rules in the prompt of each feature agent, word for word.

1. Work only in your directory. Your workspace root is `<path>`. Do not `cd` into
   another workspace. Do not point `-R` at one.
2. Never run `jj edit` on a commit that you did not create. The `@` of another
   workspace looks like an ordinary commit, and jj prints no warning. This is the
   one rule that prevents divergent commits.
3. Never rebase or abandon a commit outside `main..@`.
4. Never move a bookmark that you did not create. Never move `main`.
5. Create one bookmark on the top commit of your finished work. Report its name.
6. Do not push.
7. If a command reports a stale working copy, run `jj workspace update-stale`.
   Then read `jj log` again.

The finish:

```bash
jj --no-pager log -r 'main..@'         # review the stack
jj bookmark create feat-auth -r @-     # @- when @ is an empty scratch commit
jj new                                 # leave a fresh empty commit
jj --no-pager log -r 'main..feat-auth' # make sure that the bookmark is correct
```

Report five items: the bookmark name, the number of commits in
`main..<bookmark>`, the changed files, the build and test result, and every
conflict that remains.

## Phase 3: Integration

The integrator sees all the work at once.

```bash
jj --no-pager bookmark list
jj --no-pager log -r 'main..'                    # all unintegrated work
jj --no-pager log -r 'main.. & conflicts()'      # conflicted commits
jj --no-pager log -r 'main..feat-auth'           # one feature
jj --no-pager diff --git --from 'fork_point(main | feat-auth)' --to feat-auth
```

### Linear integration (use this first)

```bash
jj rebase -s 'roots(main..feat-auth)' -o main        # first feature onto main
jj rebase -s 'roots(main..feat-cache)' -o feat-auth  # second onto the first
jj --no-pager log -r 'main.. & conflicts()'          # must print nothing
jj bookmark move main --to feat-cache
```

`-s` moves a commit and all its descendants, so rebasing the root of a stack
moves the whole stack.

### Merge commit

```bash
jj new feat-auth feat-cache -m "chore: Integrate auth and cache"
jj bookmark move main --to @
jj new
```

`jj new` with more than one revision creates a merge commit. If the features
change the same lines, the merge records the conflict and continues.

### Conflicts

Resolve the earliest conflicted commit. That clears the descendants too.

```bash
jj --no-pager log -r 'main.. & conflicts()'
jj new <earliest-conflicted-id>
# ... edit the files and delete the markers ...
jj squash
jj --no-pager log -r 'main.. & conflicts()'      # must print nothing
```

Never run `jj resolve`. It starts an external merge tool. `jj resolve --list` is
safe, because it only prints the conflicted paths.

A jj conflict marker names the commit on each side. The `%%%%%%%` block is a
diff that the rebase tried to apply. The `+++++++` block is the content of the
other side. Write the correct result over the whole block, markers included.

CAUTION: Tell a feature agent before you resolve a conflict in its stack. The
resolution rewrites its commits, and its workspace goes stale at once.

### Test before you move `main`

```bash
jj new <change-id>       # the working copy shows the tree of that commit
# ... run the build and the tests ...
jj abandon @             # the stack does not change
```

Move `main` only after the range has no conflicts and all tests pass.

## Read Another Workspace

```bash
jj -R ../ws-feat-auth --ignore-working-copy --no-pager log -r 'main..@'
```

CAUTION: Never run a mutating command with `-R` against a workspace that another
agent uses. Without `--ignore-working-copy`, `-R` snapshots the files of that
workspace.

## Hazard 1: The Stale Working Copy

This is the most common failure in parallel work. It is normal, and it destroys
nothing.

Cause: another workspace rewrote the `@` of this workspace, or you stopped a
command with `^C`.

Symptom: every jj command in that workspace stops with

```
Error: The working copy is stale (not updated since operation 7b8cbd332d04).
Hint: Run `jj workspace update-stale` to update it.
```

Recovery:

```bash
jj workspace update-stale
jj st
```

The change IDs survive. The commit IDs do not, so read `jj log` again. The
command is safe when the working copy is not stale: it prints a message and
stops.

Integration rewrites feature commits by design, so expect this after every
integration pass.

## Hazard 2: Divergent Commits

Cause: two workspaces have the same change as their `@`, and both write to it.
`jj edit <id>` permits this with no warning.

Symptom: one change ID exists two times, with `/0` and `/1` suffixes.

```
@  ltstnwmk/1 ... default@ 6744c62e (divergent)
○  ltstnwmk/0 ... 8ed65615 (divergent)
```

CAUTION: Look at both sides before you abandon one. If a workspace was already
stale when you changed files in it, jj never snapshotted those changes.
`update-stale` rescues them into the `/0` side and puts the `/1` side on disk.
The `/0` commit is then the only copy of that work.

Recovery. A squash keeps the work of both sides:

```bash
jj --no-pager log -r 'divergent()'                    # list them by commit ID
jj --no-pager show --git <commit-id-0>                # read both sides
jj --no-pager show --git <commit-id-1>
jj squash --from <commit-id-0> --into <commit-id-1> -u
jj --no-pager log -r 'divergent()'                    # must print nothing
```

Use commit IDs here. The change ID is ambiguous while the commits diverge.

If both sides changed the same lines, the squash records a conflict and
continues. Files that only one side changed come across cleanly.

## Phase 4: Cleanup

```bash
jj workspace forget feat-auth feat-cache
rm -rf ../ws-feat-auth ../ws-feat-cache
```

`jj workspace forget` stops the tracking. It does not delete files, so do both
steps. With no argument, it forgets the current workspace, so always name the
target.

`forget` never destroys work, but it can leave stray commits. An empty `@` with
no descendants is abandoned. An `@` that holds changes stays in the graph.

```bash
jj --no-pager log -r 'main..'      # find strays
jj abandon <change-id>             # drop the scrap ones
```

## Recovery

| Problem | Command |
|---|---|
| Stale working copy | `jj workspace update-stale` |
| Divergent change ID | `jj squash --from <cid-0> --into <cid-1> -u` |
| One bad rebase | `jj undo` |
| Bad multi-step integration | `jj op log`, then `jj op restore <op-id>` |
| Lost commit after a rewrite | `jj --no-pager evolog -r <change-id>` |
| Directory deleted, entry remains | `jj workspace forget <name>` |

CAUTION: `jj op restore` restores the whole repo, every workspace included. Warn
every active agent before you use it.

## Pitfalls

- `jj workspace add` without `-r` makes a sibling of `@`, not a child.
- Bookmarks never advance alone. Read `jj --no-pager log -r 'bookmarks()'` before
  you integrate.
- `-s` carries descendants, and that includes the `@` of another workspace. That
  workspace goes stale.
- `jj squash` opens an editor when the source and the destination both have a
  description. Pass `-u` or `-m "<message>"`.
- A commit in `trunk()`, or a pushed commit, can be immutable. Ask the user
  before you use `--ignore-immutable`.
- Two agents with one bookmark name collide. Assign all names centrally.
- In a revset, a bare string is an exact match. Use
  `description(substring:"text")` to match part of a description.

## Sources

- [Working copy and workspaces](https://docs.jj-vcs.dev/latest/working-copy/#workspaces)
- [Stale working copy](https://docs.jj-vcs.dev/latest/working-copy/#stale-working-copy)
- [CLI reference: `jj workspace`](https://docs.jj-vcs.dev/latest/cli-reference/#jj-workspace)
- [Conflicts](https://docs.jj-vcs.dev/latest/conflicts/)
