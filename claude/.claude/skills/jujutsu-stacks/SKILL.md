---
name: jujutsu-stacks
description: "**REQUIRED** - Activate whenever work spans MORE THAN ONE commit in a Jujutsu (jj) repo: building a stack of commits, amending/reordering/splitting/dropping commits in a range, fixing up an earlier commit, reviewing or pushing `trunk()..@`. Use together with the `jujutsu` skill (which covers single-commit basics). Teaches the squash workflow — the safe, non-interactive way for an agent to work across a range of commits."
allowed-tools: Bash(jj *)
---

# Jujutsu: Working on Ranges of Commits (Squash Workflow)

This skill covers multi-commit work in jj: building, refining, reordering, and
landing a **stack** — a linear range of commits, usually `trunk()..@`.

Read the `jujutsu` skill first for the basics (working copy is a commit, change
IDs, `--no-pager`, `-m`). This skill assumes them.

**Verified against jj v0.43.0.** Flags below were checked against `jj <cmd> --help`
on that version. If `jj --version` differs, re-check before relying on a flag —
`jj rebase` in particular changed (`-o/--onto` is now primary, `-d` is an alias,
and one of `-o`/`-A`/`-B` is now **required**).

## The Core Idea: `@` is Your Index

The squash workflow is the officially recommended jj pattern
([tutorial](https://docs.jj-vcs.dev/latest/tutorial/), [Steve Klabnik's
tutorial](https://steveklabnik.github.io/jujutsu-tutorial/real-world-workflows/the-squash-workflow.html)).
It works like this:

1. A **described** commit holds the logical change you're building.
2. An **empty, undescribed** commit sits on top of it as `@` — your scratch space.
3. You edit files; they land in the scratch commit.
4. `jj squash` moves them down into the described commit.

The scratch commit plays the role of git's index, but it's a real commit — you can
diff it, test it, and split it. This is strictly better than `jj edit`-ing the
target commit directly, because you can always review exactly what you're about to
fold in with `jj --no-pager diff --git` before committing to it.

**Never `jj edit` a commit in the middle of a stack to amend it.** Use the squash
workflow instead. `jj edit` mixes new work into an existing commit with no review
step, and if you forget you're mid-stack you'll silently pollute an older commit.

## Agent Safety Rules for Multi-Commit Work

These matter far more in a stack than in single-commit work, because a hang or a
bad rewrite affects every descendant.

1. **`jj squash` will open an editor if BOTH source and destination have non-empty
   descriptions** — it asks you to confirm the combined message, which hangs a
   non-interactive agent. Avoid this in one of two ways:
   - Keep the scratch commit **undescribed** (the normal squash workflow), or
   - Pass `-u` / `--use-destination-message` to keep the destination's message, or
   - Pass `-m "message"` to set the combined message inline.

2. **Never use `-i` / `--interactive` or `--tool`** on `squash`, `split`, or
   `diffedit`. They open a TUI and hang. Use path arguments instead — both
   `jj squash <paths>` and `jj split <paths>` are fully non-interactive when given
   filesets.

3. **Verify after every rewrite.** A stack rewrite silently rebases descendants and
   can introduce conflicts several commits away:

   ```bash
   jj --no-pager log -r 'trunk()..@'
   ```

   Check for `conflict` markers in the output, not just the commit you touched.

4. **`jj undo` reverses exactly one operation.** After a multi-step stack surgery,
   prefer `jj op log` + `jj op restore <op-id>` to get back to a known-good state.

## Inspecting a Stack

```bash
# The whole stack: everything between trunk and the working copy
jj --no-pager log -r 'trunk()..@'

# Stack with per-commit patches (verbose — prefer per-commit review below)
jj --no-pager log -r 'trunk()..@' -p --git

# One commit's diff
jj --no-pager show --git <change-id>

# What is still mutable (safe to rewrite)
jj --no-pager log -r 'mutable()'

# History of one change across rewrites — the recovery tool
jj --no-pager evolog -r <change-id>
```

Useful revsets for ranges:

| Revset | Meaning |
|--------|---------|
| `trunk()..@` | Your stack: commits on top of trunk, up to `@` |
| `@-` / `@--` | Parent / grandparent of the working copy |
| `<id>::@` | From `<id>` up to `@`, inclusive |
| `::<id>` | `<id>` and all its ancestors |
| `mutable()` | Everything you are allowed to rewrite |
| `roots(trunk()..@)` | The bottom commit of the stack |
| `heads(trunk()..@)` | The top commit of the stack |

## Building a Stack, Front to Back

Describe first, then code — one described commit per logical step:

```bash
# 1. Bottom of the stack: describe the intent before writing code
jj desc -m "feat(api): Add user lookup endpoint"

# 2. Scratch commit on top — leave it undescribed
jj new

# ... edit files ...

# 3. Review, then fold down
jj --no-pager diff --git
jj squash

# 4. Next step in the stack: describe, scratch, edit, squash
jj new -m "feat(api): Add rate limiting to user lookup"
jj new
# ... edit files ...
jj squash
```

After `jj squash`, `@` becomes a fresh empty commit on top of the destination, so
you are immediately ready for the next scratch round.

**Each commit in the stack must build and pass tests on its own.** That's the whole
point of a stack. Verify per commit before moving on — see "Testing Each Commit".

## Amending a Commit Mid-Stack

This is the operation the squash workflow exists for. Three approaches, in order of
preference:

### 1. `jj absorb` — when the fix touches lines an ancestor already changed

```bash
# ... make the fix in the working copy ...
jj absorb
jj --no-pager log -r 'trunk()..@'
```

`jj absorb` splits your working-copy changes and moves each hunk to the **closest
mutable ancestor that last modified those lines**. It is the best tool for
"I noticed a typo/bug in an earlier commit of my own stack." Anything it can't
place unambiguously is left behind in `@`, so always check `jj st` afterwards for
leftovers.

Scope it when the stack is large:

```bash
jj absorb src/api/users.rs           # only these paths
jj absorb --into 'trunk()..@-'       # only into these candidate commits
```

### 2. `jj squash --into` — when you know the target commit

```bash
# ... make the fix in the working copy ...
jj --no-pager diff --git             # review first
jj squash --into <change-id> -u
```

`--into` (alias `--to`) moves changes from `@` into any ancestor; descendants are
rebased automatically. `-u` keeps the destination's description so no editor opens.

Move only some paths, leaving the rest in `@`:

```bash
jj squash --into <change-id> -u src/api/users.rs src/api/mod.rs
```

### 3. Scratch-on-target — when the fix is substantial

For a bigger change, get a clean scratch commit sitting directly on the target so
you can iterate and test in isolation:

```bash
jj new <change-id>                   # empty scratch commit as a child of the target
# ... edit and test ...
jj --no-pager diff --git
jj squash                            # folds into <change-id>; descendants rebase
```

Note this scratch commit is a **sibling** of the target's existing children until
you squash. That's fine and intentional — the stack reassembles on squash.

### Moving changes between two arbitrary commits

`--from` and `--into` both accept revsets, so you can move changes without them
ever touching the working copy:

```bash
jj squash --from <src-id> --into <dst-id> -u
jj squash --from <src-id> --into <dst-id> -u path/to/file
```

If `--from` becomes empty it is abandoned; pass `-k` / `--keep-emptied` to keep it.

## Restructuring a Stack

### Insert a new commit in the middle

```bash
jj new --insert-after <change-id> -m "fix(db): Add missing index"
# ... edit ...
```

`--insert-after` (`-A`) rebases the target's existing children onto the new commit,
so the stack stays linear. `--insert-before` (`-B`) does the mirror image.

### Reorder commits

```bash
# Move commit M to sit directly after J
jj rebase -r <M> -A <J>

# Move commit M to sit directly before L
jj rebase -r <M> -B <L>
```

`-r` rebases **only** that revision, filling the hole by rebasing its descendants
onto its former parent — exactly the "move this line in `git rebase -i`" operation,
but without an editor. Reordering fails cleanly (as a conflict, not a lost commit)
if the commits genuinely depend on each other.

### Drop a commit

```bash
jj abandon <change-id>
```

Descendants are rebased onto the abandoned commit's parent.

### Split a commit — non-interactively

The existing `jujutsu` skill warns that `jj split` is interactive. On v0.43 that's
only true when you give it **no** filesets. With paths it is safe for agents:

```bash
# Move the listed files into a new commit below <change-id>
jj split -r <change-id> -m "refactor(api): Extract request parsing" src/api/parse.rs
```

The selected files go into the first (lower) commit; the remainder stays in the
original, which keeps its description. Use `-A`/`-B`/`-o` to extract the selected
changes to a different position in the stack instead.

### Rebase the whole stack onto updated trunk

```bash
jj git fetch
jj rebase -s 'roots(trunk()..@)' -o trunk()
```

`-s` moves a commit **and all its descendants**, so rebasing the stack's root moves
the entire stack. `jj rebase -b @ -o trunk()` is the looser equivalent when you
don't want to name a root. Conflicts are recorded in the commits rather than
halting the rebase — nothing is left half-done, and there is no `--continue`.

### Reword any commit in place

```bash
jj desc -r <change-id> -m "feat(api): Add user lookup endpoint"
```

## Conflicts Across a Stack

jj commits conflicts rather than blocking on them, which changes the strategy:

- A conflict introduced in a mid-stack commit **propagates to every descendant**.
  `jj --no-pager log -r 'trunk()..@'` marks each affected commit.
- **Always resolve at the earliest conflicted commit.** Fixing a descendant leaves
  the ancestor broken, and the conflict reappears on the next rewrite.

```bash
# 1. Find the earliest conflicted commit in the stack
jj --no-pager log -r 'trunk()..@ & conflicts()'

# 2. Put a scratch commit on it and fix the markers by editing files directly
jj new <earliest-conflicted-id>
# ... edit files to remove conflict markers ...
jj squash

# 3. Confirm the whole stack is clean again
jj --no-pager log -r 'trunk()..@'
```

Do not use `jj resolve` — it is interactive and will hang.

## Testing Each Commit

A stack is only useful if every commit is independently good. To check one commit
without disturbing the stack, create a throwaway scratch commit on it:

```bash
jj new <change-id>       # working copy now reflects that commit's tree
# ... run build/tests ...
jj abandon @             # discard the scratch commit; stack untouched
```

For the whole stack, loop over `jj --no-pager log -r 'trunk()..@' --no-graph -T 'change_id.short() ++ "\n"'`
and repeat the above per commit. Report which commits fail, don't just fix the tip.

## Pushing a Stack

```bash
# Point a bookmark at the top of the stack and push
jj bookmark move my-feature --to @-
jj git push -b my-feature

# Or push each commit as its own bookmark/PR (stacked PRs)
jj git push -c <change-id>
```

Bookmarks do **not** auto-advance in jj. After any stack rewrite, re-check that
every bookmark still points where you expect:

```bash
jj --no-pager log -r 'bookmarks()'
```

Only push when the user has explicitly asked.

## Pitfalls

- **`jj squash` destroys the source's change ID.** When the source commit is
  abandoned after squashing, its change ID is gone — refer to the *destination's*
  change ID afterwards. Re-read `jj log` after every squash rather than reusing IDs
  from earlier in the session.
- **Immutable commits.** Anything in `trunk()` or already pushed may be immutable;
  jj refuses to rewrite it. Check with `jj --no-pager log -r 'mutable()'`. Do not
  reach for `--ignore-immutable` without asking the user first.
- **Empty commits linger.** `jj squash` abandons an emptied source, but `jj rebase`
  keeps commits that rebasing emptied unless you pass `--skip-emptied`.
- **Change IDs shift meaning, not identity.** Change IDs survive rewrites (commit
  IDs don't), so always reference commits by change ID in a multi-step operation.

## Quick Reference

| Action | Command |
|--------|---------|
| View the stack | `jj --no-pager log -r 'trunk()..@'` |
| Start a scratch commit | `jj new` |
| Fold scratch into parent | `jj squash` |
| Fold into a specific commit | `jj squash --into <id> -u` |
| Fold only some paths | `jj squash --into <id> -u <paths>` |
| Move changes commit→commit | `jj squash --from <a> --into <b> -u` |
| Auto-distribute fixes | `jj absorb` |
| Insert a commit mid-stack | `jj new -A <id> -m "message"` |
| Reorder a commit | `jj rebase -r <id> -A <target>` |
| Drop a commit | `jj abandon <id>` |
| Split by path | `jj split -r <id> -m "message" <paths>` |
| Reword a commit | `jj desc -r <id> -m "message"` |
| Restack onto trunk | `jj rebase -s 'roots(trunk()..@)' -o trunk()` |
| Find conflicts in stack | `jj --no-pager log -r 'trunk()..@ & conflicts()'` |
| Inspect a rewrite history | `jj --no-pager evolog -r <id>` |
| Recover from surgery | `jj op log` then `jj op restore <op-id>` |

## Best Practices Summary

1. **Describe before coding** — one described commit per logical step.
2. **Scratch commit as index** — `jj new`, edit, review with `jj diff --git`, `jj squash`.
3. **Never `jj edit` mid-stack** — squash into the target instead.
4. **`absorb` for small fixes, `squash --into` when you know the target.**
5. **Resolve conflicts at the earliest affected commit**, never at the tip.
6. **Verify the whole range after every rewrite**, not just the commit you touched.
7. **Each commit builds and tests green on its own** — otherwise it isn't a stack.

## Sources

- [Jujutsu tutorial — squash vs edit workflow](https://docs.jj-vcs.dev/latest/tutorial/)
- [Jujutsu for Git experts](https://docs.jj-vcs.dev/latest/git-experts/)
- [Jujutsu CLI reference](https://docs.jj-vcs.dev/latest/cli-reference/)
- [Steve Klabnik — The Squash Workflow](https://steveklabnik.github.io/jujutsu-tutorial/real-world-workflows/the-squash-workflow.html)
- [Working with GitHub — Jujutsu docs](https://docs.jj-vcs.dev/latest/github/)
