import { describe, expect, mock, test } from 'claude-code/testing'
import type { Engine } from 'claude-code/testing'
import type { On } from 'claude-code'

import { PALETTE, atField, battlefield, magiHex, syncWave, toBase64 } from './hooks/art'

// The test stands for the engine beneath the plugin: a turn that echoes its id, tool calls
// that are refused after the plugin has seen them, and a band the engine would leave empty.
const band = ($: Engine, isWorking = false) =>
  $.ui.mount({
    plugin: 'nerv-magi',
    surface: 'terminal',
    component: 'AbovePrompt',
    props: {
      hasSurvey: false,
      isWorking,
      maxRows: 8,
      bodyColumns: 100,
      scroll: { offset: 0, bodyRows: 8 },
    } as never,
  })

type Drawing = {
  findAll: (query: { type: string }) => Promise<readonly { text?: string }[]>
  unmount: () => Promise<void>
}

// The drawn texts, one per line; unmounts so the same requestId can be mounted again.
const seats = async (ui: Drawing) => {
  const texts = (await ui.findAll({ type: 'Text' })).map(t => t.text).join('\n')
  await ui.unmount()

  return texts
}

const pane = ($: Engine, surface: 'terminal' | 'desktop' = 'terminal', bodyRows = 40) =>
  $.ui.mount({
    plugin: 'nerv-magi',
    surface,
    component: 'Pane',
    requestId: 'magi',
    props: {
      title: 'MAGI',
      isFocused: false,
      bodyColumns: 50,
      placement: 'dock',
      scroll: { offset: 0, bodyRows },
      view: {},
    } as never,
  })

const finish = (
  $: Engine,
  turnId: string,
  durationMs: number,
  agentId?: string,
  reason: 'answer' | 'aborted' = 'answer',
) =>
  $.turn.complete({
    answer: '',
    durationMs,
    isAborted: reason === 'aborted',
    turnId,
    reason,
    ...(agentId === undefined ? {} : { agentId }),
  } as never)

describe('nerv-magi', () => {
  test('counts tool calls under the three seats and resets on the next turn', async ($, on) => {
    on('turn.start', (_$, e) => ({ turnId: e.turnId }))
    on('tool.call', () => ({ deny: 'stub' }))

    await $.turn.start({ text: 'go', turnId: 't1' })
    await $.tool.call({ tool: 'Read', file_path: '/a' })
    await $.tool.call({ tool: 'Read', file_path: '/b' })
    await $.tool.call({ tool: 'Edit', file_path: '/a', old_string: 'a', new_string: 'b' })
    await $.tool.call({ tool: 'Bash', command: 'ls' })
    await $.tool.call({ tool: 'TodoWrite', todos: [] })

    const done = await seats(await band($))
    expect(done).toContain('SORTIE COMPLETE')
    expect(done).toContain('MELCHIOR 2')
    expect(done).toContain('BALTHASAR 1')
    expect(done).toContain('CASPER 1')

    expect(await seats(await band($, true))).toContain('SORTIE IN PROGRESS')

    await $.turn.start({ text: 'again', turnId: 't2' })
    await $.tool.call({ tool: 'Write', file_path: '/b', content: '' })

    const next = await seats(await band($))
    expect(next).toContain('MELCHIOR 0')
    expect(next).toContain('BALTHASAR 1')
  })

  test('forgets the tally on /clear', async ($, on) => {
    on('turn.start', (_$, e) => ({ turnId: e.turnId }))
    on('tool.call', () => ({ deny: 'stub' }))
    on('session.end', (_$, e) => ({ sessionId: e.sessionId }))
    on('ui.render', () => ({ type: 'Text', props: {}, children: ['engine band'] }) as never)

    await $.turn.start({ text: 'go', turnId: 't1' })
    await $.tool.call({ tool: 'Bash', command: 'ls' })
    expect(await seats(await band($))).toContain('CASPER 1')

    await $.session.end({ reason: 'clear', sessionId: 's1', resume: { id: 's1' } } as never)

    expect(await seats(await band($))).toBe('engine band')
  })

  test('logs finished sorties in the pane, main loop only, and totals them', async ($, on) => {
    mock.clock(on)
    on('turn.start', (_$, e) => ({ turnId: e.turnId }))
    on('tool.call', () => ({ deny: 'stub' }))
    on('turn.complete', () => ({ text: '' }))

    await $.turn.start({ text: 'go', turnId: 't1' })
    await $.tool.call({ tool: 'Read', file_path: '/a' })
    await $.tool.call({ tool: 'Bash', command: 'ls' })

    const during = await seats(await pane($))
    expect(during).toContain('SORTIES 0 + 1 in progress')
    expect(during).toContain('MELCHIOR-1')

    await finish($, 't1', 3200)
    // A subagent's turn is not a sortie.
    await finish($, 'sub', 99000, 'agent-1')

    await $.turn.start({ text: 'again', turnId: 't2' })
    await $.tool.call({ tool: 'Edit', file_path: '/a', old_string: 'a', new_string: 'b' })
    await finish($, 't2', 65000)

    const after = await seats(await pane($))
    expect(after).toContain('SORTIES 2')
    expect(after).not.toContain('in progress')
    expect(after).toContain('#1  3s  M1 B0 C1')
    expect(after).toContain('#2  1m 5s  M0 B1 C0')
    expect(after).not.toContain('99')
    // Totals across both sorties.
    expect(after).toContain('MELCHIOR-1 1')
    expect(after).toContain('BALTHASAR-2 1')
  })

  test('words the end-of-turn line and the prompt hint', async ($, on) => {
    on('ui.render', (_$, e) => {
      const props = e.props as { word?: string; hint?: string; tail?: string }

      return {
        type: 'Text',
        props: {},
        children: [e.component === 'TurnDuration' ? `${props.word} for 3s` : `${props.hint}|${props.tail ?? ''}`],
      } as never
    })

    const mountTurn = (requestId: string) =>
      $.ui.mount({
        plugin: 'nerv-magi',
        surface: 'terminal',
        component: 'TurnDuration',
        requestId,
        props: { word: 'Baked', durationMs: 3000 } as never,
      })
    const mountHint = (props: object) =>
      $.ui.mount({
        plugin: 'nerv-magi',
        surface: 'terminal',
        component: 'PromptHint',
        props: { hint: '? for shortcuts', ...props } as never,
      })

    const first = await seats(await mountTurn('message-1'))
    expect(first).toMatch(/ for 3s$/)
    expect(first).not.toContain('Baked')
    // The same message keeps its word across redraws.
    expect(await seats(await mountTurn('message-1'))).toBe(first)

    expect(await seats(await mountHint({ isDraft: false, isWorking: false }))).toBe(
      '? for shortcuts|standing by, Commander',
    )
    expect(await seats(await mountHint({ isDraft: false, isWorking: true }))).toBe(
      '? for shortcuts|A.T. Field deployed',
    )
    expect(await seats(await mountHint({ isDraft: true, isWorking: false }))).toBe('? for shortcuts|')
  })

  test('draws the A.T. Field, three MAGI nodes and the sync trace as images on the terminal', async ($, on) => {
    mock.clock(on)
    on('turn.start', (_$, e) => ({ turnId: e.turnId }))
    on('tool.call', () => ({ deny: 'stub' }))
    on('turn.complete', () => ({ text: '' }))

    await $.turn.start({ text: 'go', turnId: 't1' })
    await $.tool.call({ tool: 'Read', file_path: '/a' })
    await finish($, 't1', 4000)

    const ui = await pane($)
    const images = await ui.findAll({ type: 'Image' })
    expect(images.map(i => i.key)).toEqual(['field', 'hex-melchior', 'hex-balthasar', 'hex-casper', 'trace'])
    expect(await ui.findAll({ type: 'Text', text: /MELCHIOR-1 1/ })).toHaveLength(1)
    await ui.unmount()

    // A short pane still draws, with smaller pictures.
    const short = await pane($, 'terminal', 20)
    expect(await short.findAll({ type: 'Image' })).toHaveLength(5)
    await short.unmount()
  })

  test('a surface without images gets the text gauges', async ($, on) => {
    on('turn.start', (_$, e) => ({ turnId: e.turnId }))
    on('tool.call', () => ({ deny: 'stub' }))

    await $.turn.start({ text: 'go', turnId: 't1' })
    await $.tool.call({ tool: 'Bash', command: 'ls' })

    const ui = await pane($, 'desktop')
    expect(await ui.findAll({ type: 'Image' })).toHaveLength(0)
    expect(await seats(ui)).toMatch(/CASPER-3 +█+░* 1/)
  })

  test('the artwork is sized as asked, deterministic, and burns brighter with energy', () => {
    const red = (bmp: { rgba: Uint8Array }) => {
      let total = 0
      for (let i = 0; i < bmp.rgba.length; i += 4) {
        total += bmp.rgba[i] ?? 0
      }
      return total
    }

    const idle = atField(160, 64, { energy: 0.1, phase: 1 })
    const hot = atField(160, 64, { energy: 1, phase: 1 })

    expect([hot.width, hot.height, hot.rgba.length]).toEqual([160, 64, 160 * 64 * 4])
    expect(red(hot)).toBeGreaterThan(red(idle))
    expect(atField(160, 64, { energy: 1, phase: 1 }).rgba).toEqual(hot.rgba)
    expect(red(magiHex(64, 64, { color: PALETTE.blue, level: 1 }))).toBeGreaterThan(0)
    expect(syncWave(120, 40, []).rgba).toHaveLength(120 * 40 * 4)
    expect(syncWave(120, 40, [4]).rgba).toHaveLength(120 * 40 * 4)

    // Standard padded base64, as an Image source needs.
    expect(toBase64(Uint8Array.of(1, 2, 3, 4))).toBe('AQIDBA==')
  })

  test('the battlefield is sized as asked, shows shots, and flashes when the Angel falls', () => {
    const calm = {
      time: 1000,
      angelHp: 1,
      evaHp: 1,
      shots: [],
      strikes: [],
      outcome: 'none',
      outcomeAge: 0,
    } as const
    const total = (bmp: { rgba: Uint8Array }, channel = -1) => {
      let n = 0
      for (let i = 0; i < bmp.rgba.length; i += 4) {
        n += channel < 0 ? (bmp.rgba[i] ?? 0) + (bmp.rgba[i + 1] ?? 0) + (bmp.rgba[i + 2] ?? 0) : (bmp.rgba[i + channel] ?? 0)
      }
      return n
    }

    const still = battlefield(336, 108, calm)
    expect([still.width, still.height, still.rgba.length]).toEqual([336, 108, 336 * 108 * 4])
    expect(battlefield(336, 108, calm).rgba).toEqual(still.rgba)
    // A smaller picture still draws.
    expect(battlefield(336, 60, calm).rgba).toHaveLength(336 * 60 * 4)

    for (const seat of ['melchior', 'balthasar', 'casper'] as const) {
      const fired = battlefield(336, 108, { ...calm, shots: [{ seat, age: 200 }] })
      expect(total(fired)).toBeGreaterThan(total(still))
    }
    // The Angel turns: the same scene a moment later is a different picture.
    expect(battlefield(336, 108, { ...calm, time: 1400 }).rgba).not.toEqual(still.rgba)

    // The cross of light, and the red of an aborted sortie.
    const blast = battlefield(336, 108, { ...calm, outcome: 'cleared', outcomeAge: 100 })
    expect(total(blast)).toBeGreaterThan(total(still) * 1.2)
    const aborted = battlefield(336, 108, { ...calm, outcome: 'aborted', outcomeAge: 400 })
    expect(total(aborted, 0) / total(still, 0)).toBeGreaterThan(total(aborted, 2) / total(still, 2))
  })

  describe('animation', () => {
    const FRAME_MS = 125

    // The engine beneath the plugin: an open pane, a turn, tool calls, and a terminal that takes
    // (or refuses, with `deny`) the pictures the plugin sends.
    const setUp = async ($: Engine, on: On, deny?: string) => {
      const clock = mock.clock(on)
      const blits: { requestId: string; key: string; source: { rgba: string } }[] = []
      const toasts: string[] = []
      let paneIsOpen = true

      on('turn.start', (_$, e) => ({ turnId: e.turnId }))
      // A tool call that fails when the test says so.
      const control = { failing: false }

      on('tool.call', () => (control.failing ? ({ result: 'boom', isError: true } as never) : { deny: 'stub' }))
      on('turn.complete', () => ({ text: '' }))
      on('session.start', () => ({ cwd: '/tmp' }))
      on('command.register', () => ({ value: undefined }) as never)
      on('ui.toast', (_$, e) => {
        toasts.push(String((e as { text: string }).text))

        return { value: undefined } as never
      })
      on('ui.panes', () => ({
        value: paneIsOpen
          ? [{ id: 'magi', title: 'MAGI', isShown: true, isFocused: false, isPlaced: true }]
          : [],
      }) as never)
      on('ui.blit', (_$, e) => {
        blits.push(e as never)

        return { value: deny === undefined ? {} : { deny } }
      })

      const ui = await pane($)
      await $.session.start({ source: 'startup', cwd: '/tmp' } as never)

      return { clock, blits, toasts, ui, control, closePane: () => (paneIsOpen = false) }
    }

    test('is still while idle, moves while a turn works, and settles when it ends', async ($, on) => {
      const { clock, blits, ui } = await setUp($, on)

      await clock.advance(2000)
      expect(blits).toHaveLength(0)

      await $.turn.start({ text: 'go', turnId: 't1' })
      await clock.advance(FRAME_MS * 6)

      expect(blits.length).toBeGreaterThanOrEqual(5)
      expect(blits.every(b => b.requestId === 'magi' && b.key === 'field')).toBe(true)
      // Every frame is a new picture.
      expect(new Set(blits.map(b => b.source.rgba)).size).toBe(blits.length)

      await $.tool.call({ tool: 'Read', file_path: '/a' })
      await clock.advance(FRAME_MS * 2)
      await finish($, 't1', 1000)
      await clock.advance(3000)

      // The rings have died out and the field has settled: nothing more is sent.
      const settled = blits.length
      await clock.advance(5000)
      expect(blits).toHaveLength(settled)

      // The last frame sent is the picture a fresh redraw of the pane draws, so nothing stale stays.
      await ui.redraw()
      const redrawn = (await ui.find({ key: 'field' }))?.props.source as { rgba: string } | undefined
      expect(redrawn?.rgba).toBe(blits[blits.length - 1]?.source.rgba)

      await ui.unmount()
    })

    test('backs off and says why once when the terminal refuses the pictures', async ($, on) => {
      const { clock, blits, toasts } = await setUp($, on, 'no pictures here')

      await $.turn.start({ text: 'go', turnId: 't1' })
      await clock.advance(FRAME_MS * 10)

      expect(toasts).toEqual(['MAGI animation paused: no pictures here'])
      // Backed off for 2s after the first refusal, not retried every frame.
      expect(blits.length).toBeLessThanOrEqual(2)
    })

    test('does nothing while the pane is closed', async ($, on) => {
      const { clock, blits, closePane } = await setUp($, on)
      closePane()

      await $.turn.start({ text: 'go', turnId: 't1' })
      await clock.advance(FRAME_MS * 10)

      expect(blits).toHaveLength(0)
    })

    // Redraws the open pane and returns what it says, one text per line.
    const said = async (ui: Awaited<ReturnType<typeof pane>>) => {
      await ui.redraw()

      return (await ui.findAll({ type: 'Text' })).map(t => t.text).join('\n')
    }

    test('shows the fight while a turn works: the Angel wears down, a failed call costs the Eva', async ($, on) => {
      const { clock, ui, control } = await setUp($, on)

      expect(await said(ui)).toContain('A.T. FIELD  standby')

      await $.turn.start({ text: 'go', turnId: 't1' })
      const opening = await said(ui)
      expect(opening).toContain('ANGEL  RAMIEL')
      expect(opening).toContain('100%')

      await $.tool.call({ tool: 'Read', file_path: '/a' })
      await $.tool.call({ tool: 'Read', file_path: '/b' })
      await $.tool.call({ tool: 'Bash', command: 'ls' })
      await clock.advance(200)
      // Each hit takes 12% of what the Angel has left: 0.88 ** 3 is 68%.
      const hit = await said(ui)
      expect(hit).toContain('68%')
      expect(hit).toMatch(/EVA-01 {2}SYNC {2}█+ 100%/)

      control.failing = true
      await $.tool.call({ tool: 'Bash', command: 'false' })
      await clock.advance(200)
      expect(await said(ui)).toContain('88%')
    })

    test('ends in the Angel destroyed or the sortie aborted, then goes back to the lattice', async ($, on) => {
      const { clock, ui } = await setUp($, on)

      await $.turn.start({ text: 'win', turnId: 't1' })
      await $.tool.call({ tool: 'Read', file_path: '/a' })
      await finish($, 't1', 2000)
      await clock.advance(200)
      expect(await said(ui)).toContain('ANGEL DESTROYED')

      // The ending plays out, then the field is the idle lattice again.
      await clock.advance(5000)
      const after = await said(ui)
      expect(after).toContain('A.T. FIELD  standby')
      expect(after).not.toContain('ANGEL')

      await $.turn.start({ text: 'stop', turnId: 't2' })
      await $.tool.call({ tool: 'Read', file_path: '/a' })
      await finish($, 't2', 800, undefined, 'aborted')
      await clock.advance(200)
      expect(await said(ui)).toContain('SORTIE ABORTED')

      // A new turn clears the old ending at once.
      await $.turn.start({ text: 'again', turnId: 't3' })
      const fresh = await said(ui)
      expect(fresh).not.toContain('SORTIE ABORTED')
      expect(fresh).toContain('ANGEL  RAMIEL')
    })
  })
})
