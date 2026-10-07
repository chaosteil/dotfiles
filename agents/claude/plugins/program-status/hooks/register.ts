import type { EngineInterface, Register } from 'claude-code'

// Reports the session to the terminal through the program-status command.
// https://www.superlogical.com/rex/docs/build/program-status
// The session is the record "claude". Each subagent is a record below it.

type State = 'idle' | 'working' | 'done' | 'blocked' | 'error' | 'clear'
type Kind = 'permission' | 'question' | 'auth'
type Report = { state: State; kind?: Kind; msg?: string }
type Input = Record<string, unknown>

const ROOT = 'claude'

const clip = (text: string, max = 200) => {
  const line = text.trim().split('\n')[0] ?? ''
  return line.length > max ? `${line.slice(0, max - 1)}…` : line
}

const basename = (path: string) => path.split('/').filter(Boolean).pop() ?? path

const host = (url: string) => {
  try {
    return new URL(url).host
  } catch {
    return url
  }
}

const str = (input: Input, key: string) => (typeof input[key] === 'string' ? (input[key] as string) : '')

// One line about what a tool call does.
const activity = (tool: string, input: Input): string => {
  switch (tool) {
    case 'Bash':
      return clip(str(input, 'description') || str(input, 'command'))
    case 'Read':
    case 'Edit':
    case 'MultiEdit':
    case 'Write':
      return `${tool} ${basename(str(input, 'file_path'))}`
    case 'NotebookEdit':
      return `Edit ${basename(str(input, 'notebook_path'))}`
    case 'Grep':
    case 'Glob':
      return clip(`Search ${str(input, 'pattern')}`)
    case 'WebFetch':
      return `Fetch ${host(str(input, 'url'))}`
    case 'WebSearch':
      return clip(`Search the web: ${str(input, 'query')}`)
    case 'Agent':
    case 'Task':
      return clip(`Agent: ${str(input, 'description')}`)
    case 'Skill':
      return `Skill ${str(input, 'skill')}`
    case 'AskUserQuestion': {
      const questions = input.questions as { question?: string }[] | undefined
      return clip(questions?.[0]?.question ?? 'Question')
    }
    case 'ExitPlanMode':
      return 'Review the plan'
  }
  if (tool.startsWith('mcp__')) {
    const [, server, name] = tool.split('__')
    return `${server}: ${name}`
  }
  return tool
}

// The tools that wait for an answer, not for permission.
const QUESTIONS = new Set(['AskUserQuestion', 'ExitPlanMode'])

const state = {
  isEnabled: false,
  title: '',
  main: undefined as Report | undefined,
  // Subagent record ids and their agent types.
  agents: new Map<string, string>(),
  tail: Promise.resolve(),
}

// Runs program-status. The calls run in order, so the last report wins.
function send($: EngineInterface, id: string, report: Report, extra: string[] = []): Promise<void> {
  if (!state.isEnabled) return Promise.resolve()
  const argv = ['program-status', report.state, `id=${id}`, ...extra]
  if (report.kind) argv.push(`kind=${report.kind}`)
  if (report.msg) argv.push(`msg=${report.msg}`)
  state.tail = state.tail
    .then(() => $.process.run(argv, { timeoutMs: 5000 }))
    .then(
      () => undefined,
      () => undefined,
    )
  return state.tail
}

// Reports the session record when it changes.
function report($: EngineInterface, next: Report): Promise<void> {
  const { main } = state
  if (main?.state === next.state && main.kind === next.kind && main.msg === next.msg) {
    return Promise.resolve()
  }
  state.main = next
  return send($, ROOT, next, ['app=claude', `title=${state.title}`])
}

const agentId = (id: string) => `${ROOT}/${id.replace(/[^A-Za-z0-9_.-]/g, '').slice(0, 32)}`

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    state.isEnabled = e.isInteractive
    state.title = basename(e.cwd)
    state.main = undefined
    await report($, { state: 'idle' })
    return next(e)
  })

  on('session.end', async ($, e, next) => {
    state.main = undefined
    state.agents.clear()
    await send($, ROOT, { state: 'clear' })
    // A /clear goes on with a new conversation in the same process.
    if (e.reason === 'clear') await report($, { state: 'idle' })
    return next(e)
  })

  on('turn.start', async ($, e, next) => {
    await report($, { state: 'working', msg: 'Thinking' })
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    // Subagents and the engine's own forks have an agentId.
    if (e.agentId === undefined) {
      // No answer: the person dismissed a question or a permission prompt.
      if (e.reason === 'answer') await report($, e.answer.trim() ? { state: 'done', msg: clip(e.answer) } : { state: 'idle' })
      else if (e.reason === 'aborted') await report($, { state: 'idle', msg: 'Interrupted' })
      else if (e.reason === 'refusal') await report($, { state: 'error', msg: 'The model refused' })
      else if (state.main?.state !== 'error') await report($, { state: 'error', msg: 'The turn failed' })
    }
    return next(e)
  })

  on('classic.StopFailure', async ($, e, next) => {
    await report($, { state: 'error', msg: clip(e.error_details ?? String(e.error)) })
    return next(e)
  })

  on('tool.call', async ($, e, next) => {
    const input = e as unknown as Input
    const msg = activity(e.tool, input)
    let started: Promise<void>
    if (e.agentId !== undefined) {
      const id = agentId(e.agentId)
      const type = state.agents.get(id)
      started = type === undefined ? Promise.resolve() : send($, id, { state: 'working', msg }, [`title=${type}`])
    } else if (QUESTIONS.has(e.tool)) {
      started = report($, { state: 'blocked', kind: 'question', msg })
    } else {
      started = report($, { state: 'working', msg })
    }
    const result = await next(e)
    await started
    if (state.main?.state === 'blocked') {
      await report($, { state: 'working', msg: 'Thinking' })
    }
    return result
  })

  on('classic.PermissionRequest', async ($, e, next) => {
    const input = (e.tool_input ?? {}) as Input
    const kind: Kind = QUESTIONS.has(e.tool_name) ? 'question' : 'permission'
    const msg = kind === 'question' ? activity(e.tool_name, input) : clip(`Allow ${activity(e.tool_name, input)}?`)
    await report($, { state: 'blocked', kind, msg })
    return next(e)
  })

  // The background hint shows only while an approved command runs.
  on('ui.render', { component: 'ToolProgress' }, async ($, e, next) => {
    if (state.main?.state === 'blocked' && state.main.kind === 'permission') {
      await report($, { state: 'working', msg: 'Running' })
    }
    return next(e)
  })

  on('classic.Notification', async ($, e, next) => {
    if (state.main?.state !== 'blocked') {
      if (e.notification_type === 'permission_prompt') {
        await report($, { state: 'blocked', kind: 'permission', msg: clip(e.message) })
      } else if (e.notification_type === 'elicitation_dialog') {
        await report($, { state: 'blocked', kind: 'question', msg: clip(e.message) })
      }
    }
    return next(e)
  })

  on('classic.Elicitation', async ($, e, next) => {
    const kind: Kind = e.mode === 'url' ? 'auth' : 'question'
    await report($, { state: 'blocked', kind, msg: clip(`${e.mcp_server_name}: ${e.message}`) })
    return next(e)
  })

  on('classic.ElicitationResult', async ($, e, next) => {
    await report($, { state: 'working', msg: 'Thinking' })
    return next(e)
  })

  on('classic.PreCompact', async ($, e, next) => {
    await report($, { state: 'working', msg: 'Compacting' })
    return next(e)
  })

  on('classic.PostCompact', async ($, e, next) => {
    // A manual /compact runs at the prompt. An automatic one runs in a turn.
    await report($, e.trigger === 'manual' ? { state: 'idle' } : { state: 'working', msg: 'Thinking' })
    return next(e)
  })

  on('classic.SubagentStart', async ($, e, next) => {
    const id = agentId(e.agent_id)
    state.agents.set(id, e.agent_type)
    await send($, id, { state: 'working' }, [`title=${e.agent_type}`])
    return next(e)
  })

  on('classic.SubagentStop', async ($, e, next) => {
    const id = agentId(e.agent_id)
    state.agents.delete(id)
    await send($, id, { state: 'clear' })
    return next(e)
  })
}
