import type { On } from 'claude-code'
import { expect, test } from 'claude-code/testing'

// The engine beneath the plugin: it records each program-status call.
const engine = (on: On, duringTool?: () => Promise<unknown>) => {
  const calls: string[][] = []
  on('process.run', (_$, e) => {
    calls.push([...e.argv])
    return { value: { exitCode: 0, stdout: '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  on('session.start', (_$, e) => ({ cwd: e.cwd }))
  on('turn.start', (_$, e) => ({ turnId: e.turnId }))
  on('turn.complete', (_$, e) => ({ text: e.answer }))
  on('tool.call', async () => {
    await duringTool?.()
    return { result: { stdout: '', stderr: '', interrupted: false }, text: '' }
  })
  on('classic.PermissionRequest', () => ({}))
  on('classic.SubagentStart', () => ({}))
  on('classic.SubagentStop', () => ({}))
  return calls
}

const ROOT = ['id=claude', 'app=claude', 'title=dotfiles']
const start = { cwd: '/home/me/dotfiles', surface: 'terminal', isInteractive: true } as const
const complete = { durationMs: 1, isAborted: false, turnId: 't1' } as const

test('a turn goes from idle to working to done', async ($, on) => {
  const calls = engine(on)
  await $.session.start(start)
  await $.turn.start({ text: 'hi', turnId: 't1' })
  await $.tool.call({ tool: 'Bash', command: 'jj st', description: 'Show the status' })
  await $.turn.complete({ ...complete, reason: 'answer', answer: 'All done.\nMore text.' })
  expect(calls).toEqual([
    ['program-status', 'idle', ...ROOT],
    ['program-status', 'working', ...ROOT, 'msg=Thinking'],
    ['program-status', 'working', ...ROOT, 'msg=Show the status'],
    ['program-status', 'done', ...ROOT, 'msg=All done.'],
  ])
})

test('a permission prompt blocks until the tool call ends', async ($, on) => {
  // The engine asks for permission inside the tool call.
  const calls = engine(on, () =>
    $.classic.PermissionRequest({ tool_name: 'Bash', tool_input: { command: 'rm -rf build' } }),
  )
  await $.session.start(start)
  await $.turn.start({ text: 'hi', turnId: 't1' })
  await $.tool.call({ tool: 'Bash', command: 'rm -rf build' })
  expect(calls.slice(2)).toEqual([
    ['program-status', 'working', ...ROOT, 'msg=rm -rf build'],
    ['program-status', 'blocked', ...ROOT, 'kind=permission', 'msg=Allow rm -rf build?'],
    ['program-status', 'working', ...ROOT, 'msg=Thinking'],
  ])
})

test('an interrupted turn goes back to idle', async ($, on) => {
  const calls = engine(on)
  await $.session.start(start)
  await $.turn.start({ text: 'hi', turnId: 't1' })
  await $.turn.complete({ ...complete, isAborted: true, reason: 'aborted', answer: '' })
  expect(calls.at(-1)).toEqual(['program-status', 'idle', ...ROOT, 'msg=Interrupted'])
})

test('a turn with no answer goes back to idle', async ($, on) => {
  const calls = engine(on)
  await $.session.start(start)
  await $.turn.start({ text: 'hi', turnId: 't1' })
  await $.turn.complete({ ...complete, reason: 'answer', answer: '' })
  expect(calls.at(-1)).toEqual(['program-status', 'idle', ...ROOT])
})

test('a subagent has its own record below the session', async ($, on) => {
  const calls = engine(on)
  await $.session.start(start)
  await $.classic.SubagentStart({ agent_id: 'a1b2', agent_type: 'Explore' })
  await $.tool.call({ tool: 'Read', file_path: '/x/notes.md', agentId: 'a1b2' })
  await $.classic.SubagentStop({
    agent_id: 'a1b2',
    agent_type: 'Explore',
    agent_transcript_path: '',
    stop_hook_active: false,
  })
  expect(calls.slice(1)).toEqual([
    ['program-status', 'working', 'id=claude/a1b2', 'title=Explore'],
    ['program-status', 'working', 'id=claude/a1b2', 'title=Explore', 'msg=Read notes.md'],
    ['program-status', 'clear', 'id=claude/a1b2'],
  ])
})

test('a non-interactive run reports nothing', async ($, on) => {
  const calls = engine(on)
  await $.session.start({ ...start, surface: null, isInteractive: false })
  await $.turn.start({ text: 'hi', turnId: 't1' })
  expect(calls).toEqual([])
})
