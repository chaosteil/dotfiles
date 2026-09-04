---
name: jujutsu-stacks
description: "**REQUIRED** - Activate when work in a Jujutsu (jj) repo spans MORE THAN ONE commit: you build a stack, you amend or reorder or split or drop a commit in a range, you fix an earlier commit, or you review or push `trunk()..@`. Use with the `jujutsu` skill, which covers single-commit work."
allowed-tools: Bash(jj *)
---

# Jujutsu: Stacks of Commits

A stack is a linear range of commits, usually `trunk()..@`. Read the `jujutsu`
skill first for the basics.

Commands verified with jj 0.44.0. If `jj --version` prints another version, read
`jj <cmd> --help` before you use a flag.

## Rules

1. Never pass `-i`, `--interactive`, `--tool`, or `--editor` to `squash`, `split`,
   or `diffedit`. Each flag opens a TUI and stops the agent.
2. `jj squash` opens an editor when the source and the destination both have a
   description. Prevent this in one of three ways:
   - Keep the scratch commit undescribed.
   - Pass `-u` to keep the description of the destination.
   - Pass `-m "<message>"` to set the description inline.
3. Never run `jj edit` on a commit inside the stack. Squash into it instead.
4. Never run `jj resolve`. It starts an external merge tool. `jj resolve --list`
   is safe, because it only prints the conflicted paths.
5. After each rewrite, read the whole range with
   `jj --no-pager log -r 'trunk()..@'`. A rewrite changes the descendants too.
6. Name a commit by change ID. A rewrite keeps the change ID and changes the
   commit ID. `jj squash` and `jj split` are the exceptions, so read `jj log`
   again after both.
7. `jj undo` reverses one operation. After more than one step, use `jj op log`
   and then `jj op restore <op-id>`.

## Build a Stack

Describe the commit first. Then write the code.

```bash
jj desc -m "feat(api): Add user lookup endpoint"   # describe the bottom commit
jj new                                             # undescribed scratch commit
# ... edit files ...
jj --no-pager diff --git                           # review
jj squash                                          # fold the scratch commit down
jj new -m "feat(api): Add rate limiting"           # next commit in the stack
jj new                                             # next scratch commit
```

After `jj squash`, `@` is a fresh empty commit on top of the destination.

Every commit in the stack must build and pass its tests alone.

## Amend a Commit in the Stack

Use the first recipe that fits.

### The fix touches lines that an earlier commit changed

```bash
# ... make the fix in the working copy ...
jj absorb
jj st                                    # anything jj cannot place stays in @
```

`jj absorb` moves each hunk to the closest mutable ancestor that last changed
those lines. Scope it with paths, or with `--into 'trunk()..@-'`.

### You know the target commit

```bash
jj --no-pager diff --git
jj squash --into <change-id> -u
jj squash --into <change-id> -u src/api/users.rs      # only these paths
```

### The fix is large

```bash
jj new <change-id>                       # scratch commit on the target
# ... edit and test ...
jj --no-pager diff --git
jj squash
```

### Move changes between two commits

```bash
jj squash --from <src-id> --into <dst-id> -u
jj squash --from <src-id> --into <dst-id> -u path/to/file
```

jj abandons an emptied source. Pass `-k` to keep it.

## Restructure a Stack

```bash
# Insert a commit after <id>. Descendants rebase onto it.
jj new -A <id> -m "fix(db): Add missing index" --no-edit

# Reorder: move <id> after <target>. Use -B for before.
jj rebase -r <id> -A <target>

# Drop a commit. Descendants rebase onto its parent.
jj abandon <id>

# Split by path. The listed files go into the lower commit.
jj split -r <id> -m "refactor(api): Extract request parsing" src/api/parse.rs

# Reword any commit
jj desc -r <id> -m "feat(api): Add user lookup endpoint"

# Rebase the whole stack onto a new trunk
jj git fetch
jj rebase -s 'roots(trunk()..@)' -o trunk()
```

`-r` moves one commit and closes the hole behind it. `-s` moves a commit and all
its descendants. `jj split` gives the change ID of the original commit to the
lower half, and a new change ID to the upper half.

## Conflicts

jj records a conflict in the commit and continues. There is no `--continue`.
A conflict in one commit propagates to every descendant.

Resolve the earliest conflicted commit. That clears the descendants too.

```bash
jj --no-pager log -r 'trunk()..@ & conflicts()'   # find them
jj new <earliest-conflicted-id>                   # markers appear on disk
# ... edit the files and delete the markers ...
jj squash
jj --no-pager log -r 'trunk()..@ & conflicts()'   # must print nothing
```

A jj conflict marker names the commit on each side. The `%%%%%%%` block is a
diff that the rebase tried to apply. The `+++++++` block is the content of the
other side. Write the correct result over the whole block, markers included.

## Test One Commit

```bash
jj new <change-id>       # the working copy shows the tree of that commit
# ... run the build and the tests ...
jj abandon @             # the stack does not change
```

Loop over the stack with:

```bash
jj --no-pager log -r 'trunk()..@' --no-graph -T 'change_id.short() ++ "\n"'
```

Report every commit that fails, not only the top one.

## Push

Only push when the user asks for it.

```bash
jj bookmark move my-feature --to @-
jj git push -b my-feature
jj git push -c <change-id>        # one bookmark for each commit
```

Bookmarks never advance alone. After a rewrite, read
`jj --no-pager log -r 'bookmarks()'`.

## Revsets

| Revset | Meaning |
|---|---|
| `trunk()..@` | The stack |
| `roots(trunk()..@)` | The bottom commit of the stack |
| `heads(trunk()..@)` | The top commit of the stack |
| `<id>::@` | From `<id>` to `@`, inclusive |
| `mutable()` | Every commit that you can rewrite |
| `trunk()..@ & conflicts()` | The conflicted commits of the stack |
| `description(substring:"text")` | Match a description. A bare string is an exact match. |

## Recovery

| Problem | Command |
|---|---|
| One bad rewrite | `jj undo` |
| Several bad rewrites | `jj op log`, then `jj op restore <op-id>` |
| Lost commit after a rewrite | `jj --no-pager evolog -r <change-id>` |
| Empty commits left by a rebase | Add `--skip-emptied` to the rebase |
| jj refuses to rewrite a commit | The commit is immutable. Ask the user first. |

## Sources

- [Jujutsu tutorial](https://docs.jj-vcs.dev/latest/tutorial/)
- [Jujutsu CLI reference](https://docs.jj-vcs.dev/latest/cli-reference/)
- [Steve Klabnik — The Squash Workflow](https://steveklabnik.github.io/jujutsu-tutorial/real-world-workflows/the-squash-workflow.html)
