import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Fight, Sortie, Tally } from '../types'
import {
  CROSS_BLAST,
  PALETTE,
  SHOT_FLIGHT,
  SHOT_IMPACT,
  STRIKE_BEAM,
  STRIKE_FIELD,
  atField,
  battlefield,
  magiHex,
  syncWave,
  toBase64,
} from './art'
import type { Bitmap, Seat } from './art'

const EMPTY: Tally = { melchior: 0, balthasar: 0, casper: 0 }

const tally = atom({ plugin: 'nerv-magi', key: 'tally' } as const, EMPTY)
const history = atom({ plugin: 'nerv-magi', key: 'history' } as const, [])
const isActive = atom({ plugin: 'nerv-magi', key: 'isActive' } as const, false)

const FRESH_FIGHT: Fight = { angelHp: 1, evaHp: 1, outcome: 'none' }
const fight = atom({ plugin: 'nerv-magi', key: 'fight' } as const, FRESH_FIGHT)

const PANE = 'magi'

// Melchior observes, Balthasar rewrites, Casper acts: shell, agents, MCP, the rest.
const OBSERVE = new Set(['Read', 'Grep', 'Glob', 'WebFetch', 'WebSearch', 'LSP'])
const REWRITE = new Set(['Edit', 'Write', 'NotebookEdit'])
// Bookkeeping, not work.
const IGNORED = new Set(['TodoWrite', 'ToolSearch'])

const seatFor = (tool: string): keyof Tally | null => {
  if (IGNORED.has(tool)) {
    return null
  }
  if (OBSERVE.has(tool)) {
    return 'melchior'
  }
  if (REWRITE.has(tool)) {
    return 'balthasar'
  }
  return 'casper'
}

// What follows "... for 3s" at the end of a turn, one per message so a redraw keeps its word.
const DONE_WORDS = [
  'Synchronized',
  'Held the A.T. Field',
  'MAGI deliberated',
  'Pressurized LCL',
  'Computed sync ratio',
  'Awaited orders',
  'Did not run away',
  'Held position',
]

const pick = (words: string[], key: string): string => {
  let hash = 0
  for (const char of key) {
    hash = (hash * 31 + char.charCodeAt(0)) >>> 0
  }
  return words[hash % words.length] ?? ''
}

const clock = (seconds: number): string =>
  seconds < 60 ? `${seconds}s` : `${Math.floor(seconds / 60)}m ${seconds % 60}s`

const gauge = (n: number, peak: number): string => {
  const filled = Math.round((n / peak) * 12)
  return '█'.repeat(filled) + '░'.repeat(12 - filled)
}

// An Image's source for a bitmap.
const pixels = (bmp: Bitmap) => ({
  rgba: toBase64(bmp.rgba),
  width: bmp.width,
  height: bmp.height,
})

// Pixels per terminal cell the artwork is drawn at: the picture is scaled to its box anyway.
const CELL_W = 8
const CELL_H = 16
// The animated A.T. Field is drawn a little coarser, since a new picture is sent every frame.
const FIELD_W = 6
const FIELD_H = 12

// Animation: frames per second is 1000 / FRAME_MS. A tool call sends a ring out through the
// lattice that lives RING_LIFE ms and travels RING_SPEED pixels a second; while a turn works
// the lattice's ripples advance PHASE_RATE radians a millisecond.
const FRAME_MS = 100
const RING_LIFE = 1400
const RING_SPEED = 150
const PHASE_RATE = 0.005

// The battle. Each tool call hits the Angel for 12% of what it has left, down to a floor it
// keeps until the turn ends; a failed tool call costs the Eva 12 points of sync.
const ANGEL_FLOOR = 0.06
const ANGEL_HIT = 0.88
const EVA_FLOOR = 0.15
const EVA_HIT = 0.12
// How long the sortie's ending stays on the field before it goes back to the lattice, in ms.
const HOLD: Record<'cleared' | 'aborted', number> = { cleared: CROSS_BLAST + 600, aborted: 1600 }
const SHOT_LIFE = SHOT_FLIGHT + SHOT_IMPACT
const STRIKE_LIFE = STRIKE_BEAM + STRIKE_FIELD

// Things the hooks saw that the animation has not stamped with a time yet.
type Pending =
  | { kind: 'shot'; seat: Seat }
  | { kind: 'strike' }
  | { kind: 'outcome'; outcome: 'cleared' | 'aborted' }

const sum = (t: Tally): number => t.melchior + t.balthasar + t.casper

// Tool calls of every finished sortie, plus the current turn's while it runs.
const activityOf = (sorties: readonly Sortie[], live: Tally, isLive: boolean): number =>
  sorties.reduce((n, s) => n + sum(s), isLive ? sum(live) : 0)

// The A.T. Field's animation state. Module variables are fine here: a reload only restarts it.
const anim = {
  box: { cols: 0, rows: 0 },
  phase: 0,
  lastFrameAt: 0,
  // What the hooks saw since the last frame, and what is still on the field with its birth time.
  pending: [] as Pending[],
  births: [] as number[],
  shots: [] as { seat: Seat; born: number }[],
  strikes: [] as number[],
  outcome: null as { kind: 'cleared' | 'aborted'; born: number } | null,
  // The last frame drawn was an animation frame, so one more settles the field.
  isRunning: false,
  isBusy: false,
  isPaneUp: false,
  paneCheckedAt: -Infinity,
  backoffUntil: 0,
  hasWarned: false,
}

// Whether the field shows the battle: while a turn works, and while its ending plays out.
const isBattle = (now: number, isLive: boolean): boolean =>
  isLive || (anim.outcome !== null && now - anim.outcome.born < HOLD[anim.outcome.kind])

// The picture for the top of the pane: the battle, or the lattice when nothing is going on.
const fieldFrame = (now: number, isLive: boolean, calls: number, state: Fight) => {
  const width = anim.box.cols * FIELD_W
  const height = anim.box.rows * FIELD_H

  if (isBattle(now, isLive)) {
    return pixels(
      battlefield(width, height, {
        time: now,
        angelHp: state.angelHp,
        evaHp: state.evaHp,
        shots: anim.shots.map(shot => ({ seat: shot.seat, age: now - shot.born })),
        strikes: anim.strikes.map(born => now - born),
        outcome: anim.outcome?.kind ?? 'none',
        outcomeAge: anim.outcome === null ? 0 : now - anim.outcome.born,
      }),
    )
  }

  const rings = anim.births
    .map(born => ({
      radius: ((now - born) / 1000) * RING_SPEED,
      strength: 1 - (now - born) / RING_LIFE,
    }))
    .filter(ring => ring.strength > 0)
  const energy = isLive
    ? Math.min(1, 0.5 + 0.2 * Math.sin(now / 480) + calls * 0.04)
    : Math.min(0.35, 0.12 + calls * 0.01)

  return pixels(atField(width, height, { energy, phase: anim.phase, rings }))
}

const findPane = async ($: EngineInterface) =>
  (await $.ui.panes()).some(pane => pane.id === PANE && pane.isPlaced)

// One animation frame. Idle (no turn working, no ring travelling) it does nothing at all.
const tick = async ($: EngineInterface) => {
  if (anim.isBusy) {
    return
  }
  anim.isBusy = true

  try {
    const now = await $.clock.now()

    // Stamp what the hooks saw since the last frame with this frame's time.
    for (const event of anim.pending.splice(0)) {
      if (event.kind === 'shot') {
        anim.shots.push({ seat: event.seat, born: now })
        anim.births.push(now)
      } else if (event.kind === 'strike') {
        anim.strikes.push(now)
      } else {
        anim.outcome = { kind: event.outcome, born: now }
      }
    }
    anim.births = anim.births.filter(born => now - born < RING_LIFE).slice(-5)
    anim.shots = anim.shots.filter(shot => now - shot.born < SHOT_LIFE).slice(-12)
    anim.strikes = anim.strikes.filter(born => now - born < STRIKE_LIFE).slice(-4)

    const isLive = await read($, isActive)
    const shouldRun =
      isLive ||
      isBattle(now, isLive) ||
      anim.births.length > 0 ||
      anim.shots.length > 0 ||
      anim.strikes.length > 0

    // The frame after the last ring has gone is drawn too, so the field settles at its idle look.
    if ((!shouldRun && !anim.isRunning) || anim.box.cols === 0 || now < anim.backoffUntil) {
      return
    }

    if (now - anim.paneCheckedAt > 1000) {
      anim.paneCheckedAt = now
      anim.isPaneUp = await findPane($)
    }
    if (!anim.isPaneUp) {
      return
    }

    if (shouldRun) {
      const since = anim.lastFrameAt === 0 ? FRAME_MS : now - anim.lastFrameAt
      anim.phase += Math.min(250, since) * PHASE_RATE
    }
    anim.lastFrameAt = now
    anim.isRunning = shouldRun

    const live = await read($, tally)
    const sorties = await read($, history)
    const state = await read($, fight)
    const calls = isLive ? sum(live) : activityOf(sorties, live, isLive)
    const result = await $.ui.blit({
      requestId: PANE,
      key: 'field',
      source: fieldFrame(now, isLive, calls, state),
    })

    if (result.deny !== undefined) {
      anim.backoffUntil = now + 2000

      // A refusal with the pane open is a real problem (a terminal without images, say): say so once.
      if (!anim.hasWarned && (await findPane($))) {
        anim.hasWarned = true
        $.ui.toast(`MAGI animation paused: ${result.deny}`)
      }
    }
  } finally {
    anim.isBusy = false
  }
}

// Purely cosmetic: no hook here changes a tool call, a prompt or what the model reads.
export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'magi',
      description: 'Show the MAGI tool-call tally and sortie log in a pane',
    })
    $.clock.every(FRAME_MS, () => tick($))

    return next(e)
  })

  on('command.run', { command: 'magi' }, async $ => {
    await $.ui.open({ id: PANE, title: 'MAGI' })

    return { text: 'MAGI pane opened.' }
  })

  on('turn.start', async ($, e, next) => {
    // A new sortie: a fresh Angel, and whatever the last one left on the field is gone, queued
    // events included (a prompt that starts within a frame of the last turn's end would else
    // inherit its ending).
    anim.pending = []
    anim.outcome = null
    anim.shots = []
    anim.strikes = []
    await update($, tally, () => EMPTY)
    await update($, fight, () => FRESH_FIGHT)
    await update($, isActive, () => true)

    return next(e)
  })

  on('tool.call', async ($, e, next) => {
    const seat = seatFor(e.tool)
    // The fight is the turn's: a background agent still working after the turn has ended
    // neither wounds the fallen Angel nor wakes the field.
    const isLive = seat !== null && (await read($, isActive))

    if (seat !== null) {
      await update($, tally, t => {
        const seats = t ?? EMPTY

        return { ...seats, [seat]: seats[seat] + 1 }
      })
    }
    if (seat !== null && isLive) {
      anim.pending.push({ kind: 'shot', seat })
      await update($, fight, f => {
        const now = f ?? FRESH_FIGHT

        return { ...now, angelHp: Math.max(ANGEL_FLOOR, now.angelHp * ANGEL_HIT) }
      })
    }

    const ran = await next(e)

    // The call failed: the Angel strikes back.
    if (isLive && ran.isError === true) {
      anim.pending.push({ kind: 'strike' })
      await update($, fight, f => {
        const now = f ?? FRESH_FIGHT

        return { ...now, evaHp: Math.max(EVA_FLOOR, now.evaHp - EVA_HIT) }
      })
    }

    return ran
  })

  on('turn.complete', async ($, e, next) => {
    // A subagent's run raises turn.complete too: only the main loop is a sortie.
    if (e.agentId === undefined) {
      const seats = await read($, tally)
      const sortie: Sortie = {
        ...seats,
        seconds: Math.round(e.durationMs / 1000),
        isAborted: e.isAborted,
      }

      // The Angel falls if the model answered; an interrupted or failed turn aborts the sortie.
      const outcome: 'cleared' | 'aborted' = e.reason === 'answer' ? 'cleared' : 'aborted'

      anim.pending.push({ kind: 'outcome', outcome })
      await update($, fight, f => {
        const now = f ?? FRESH_FIGHT

        return { ...now, angelHp: outcome === 'cleared' ? 0 : now.angelHp, outcome }
      })
      await update($, history, list => [...(list ?? []), sortie].slice(-200))
      await update($, isActive, () => false)
    }

    return next(e)
  })

  on('session.end', async ($, e, next) => {
    if (e.reason === 'clear') {
      anim.pending = []
      anim.outcome = null
      anim.shots = []
      anim.strikes = []
      await update($, tally, () => EMPTY)
      await update($, history, () => [])
      await update($, fight, () => FRESH_FIGHT)
      await update($, isActive, () => false)
    }

    return next(e)
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const seats = await read($, tally)
    const total = seats.melchior + seats.balthasar + seats.casper

    if (e.props.hasSurvey || total === 0) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)

    return (
      <Box>
        <Text color="claude" bold>
          ⬢ MAGI
        </Text>
        <Text dimColor>{` ▸ ${e.props.isWorking ? 'SORTIE IN PROGRESS' : 'SORTIE COMPLETE'} ▸ `}</Text>
        <Text color="planMode" dimColor={seats.melchior === 0}>
          {`MELCHIOR ${seats.melchior}`}
        </Text>
        <Text> </Text>
        <Text color="permission" dimColor={seats.balthasar === 0}>
          {`BALTHASAR ${seats.balthasar}`}
        </Text>
        <Text> </Text>
        <Text color="claude" dimColor={seats.casper === 0}>
          {`CASPER ${seats.casper}`}
        </Text>
      </Box>
    )
  })

  // "Baked for 3s" in the transcript becomes "Synchronized for 3s".
  on('ui.render', { component: 'TurnDuration' }, ($, e, next) =>
    next({ ...e, props: { ...e.props, word: pick(DONE_WORDS, e.requestId) } }),
  )

  // A dim line after the hint under the prompt; left alone while typing.
  on('ui.render', { component: 'PromptHint' }, ($, e, next) => {
    if (e.props.isDraft) {
      return next(e)
    }

    const tail = e.props.isWorking ? 'A.T. Field deployed' : 'standing by, Commander'

    return next({ ...e, props: { ...e.props, tail } })
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const sorties = await read($, history)
    const live = await read($, tally)
    const isLive = await read($, isActive)
    const state = await read($, fight)

    const totals = sorties.reduce<Tally>(
      (acc, s) => ({
        melchior: acc.melchior + s.melchior,
        balthasar: acc.balthasar + s.balthasar,
        casper: acc.casper + s.casper,
      }),
      isLive ? live : EMPTY,
    )
    const peak = Math.max(1, totals.melchior, totals.balthasar, totals.casper)
    const rows = e.props.scroll.bodyRows
    const roomy = rows >= 38
    const room = Math.max(1, rows - (roomy ? 31 : 23))
    const first = Math.max(0, sorties.length - room)
    const lines = [
      `SORTIES ${sorties.length}${isLive ? ' + 1 in progress' : ''}`,
      ...(sorties.length === 0 ? ['none completed yet'] : []),
      ...sorties
        .slice(first)
        .map(
          (s, i) =>
            `#${first + i + 1}  ${clock(s.seconds)}  M${s.melchior} B${s.balthasar} C${s.casper}${s.isAborted ? '  aborted' : ''}`,
        )
        .reverse(),
    ]

    if (e.surface !== 'terminal') {
      const { Box, Text } = $.ui.resolve(e)

      return (
        <Box flexDirection="column">
          <Text color="claude" bold>
            ⬢ MAGI SYSTEM
          </Text>
          <Text dimColor>tool calls this session</Text>
          <Text> </Text>
          <Text color="planMode">{`MELCHIOR-1   ${gauge(totals.melchior, peak)} ${totals.melchior}`}</Text>
          <Text color="permission">{`BALTHASAR-2  ${gauge(totals.balthasar, peak)} ${totals.balthasar}`}</Text>
          <Text color="claude">{`CASPER-3     ${gauge(totals.casper, peak)} ${totals.casper}`}</Text>
          <Text> </Text>
          {lines.map(line => (
            <Text dimColor={line.endsWith('aborted') || line.startsWith('none')}>{line}</Text>
          ))}
        </Box>
      )
    }

    // The terminal draws pictures: the A.T. Field, the three MAGI nodes and the sync trace.
    const { Box, Text, Image } = $.ui.resolve(e)
    const cols = Math.max(24, Math.min(e.props.bodyColumns, 56))
    const fieldRows = roomy ? 9 : 5
    const hexRows = roomy ? 6 : 4
    const waveRows = roomy ? 4 : 3
    const hexCols = Math.floor(cols / 3)
    const now = await $.clock.now()
    anim.box = { cols, rows: fieldRows }
    const battle = isBattle(now, isLive)
    const pct = (n: number): string => `${Math.round(n * 100)}%`
    const ending = anim.outcome !== null && now - anim.outcome.born < HOLD[anim.outcome.kind]
    // Two caption lines under the picture whatever is on it, so the pane does not jump.
    const captions = !battle
      ? ['A.T. FIELD  standby', ' ']
      : ending && state.outcome === 'cleared'
        ? ['ANGEL DESTROYED  pattern blue cleared', `EVA-01  SYNC ${pct(state.evaHp)}`]
        : ending && state.outcome === 'aborted'
          ? ['SORTIE ABORTED', `EVA-01  SYNC ${pct(state.evaHp)}`]
          : [`ANGEL  RAMIEL  ${gauge(state.angelHp, 1)} ${pct(state.angelHp)}`, `EVA-01  SYNC  ${gauge(state.evaHp, 1)} ${pct(state.evaHp)}`]
    const trace = [...sorties.slice(-24).map(sum), ...(isLive ? [sum(live)] : [])]
    const seats = [
      { id: 'melchior', name: 'MELCHIOR-1', color: PALETTE.blue, theme: 'planMode', n: totals.melchior },
      { id: 'balthasar', name: 'BALTHASAR-2', color: PALETTE.purple, theme: 'permission', n: totals.balthasar },
      { id: 'casper', name: 'CASPER-3', color: PALETTE.orange, theme: 'claude', n: totals.casper },
    ] as const

    return (
      <Box flexDirection="column">
        <Text color="claude" bold>
          ⬢ MAGI SYSTEM
        </Text>
        <Image
          key="field"
          source={fieldFrame(now, isLive, isLive ? sum(live) : activityOf(sorties, live, isLive), state)}
          columns={cols}
          rows={fieldRows}
          alt={captions[0] ?? '[A.T. FIELD]'}
        />
        <Text color={battle ? 'planMode' : undefined} dimColor={!battle}>
          {captions[0] ?? ' '}
        </Text>
        <Text color={battle ? 'permission' : undefined} dimColor={!battle}>
          {captions[1] ?? ' '}
        </Text>
        <Text> </Text>
        <Box>
          {seats.map(seat => (
            <Box key={seat.id} flexDirection="column" width={hexCols}>
              <Image
                key={`hex-${seat.id}`}
                source={pixels(
                  magiHex(hexCols * CELL_W, hexRows * CELL_H, { color: seat.color, level: seat.n / peak }),
                )}
                columns={hexCols}
                rows={hexRows}
                alt={`[${seat.name}]`}
              />
              <Text color={seat.theme}>{`${seat.name.slice(0, hexCols - 4)} ${seat.n}`}</Text>
            </Box>
          ))}
        </Box>
        <Text color="claude" dimColor>
          {'╱'.repeat(cols)}
        </Text>
        <Image
          key="trace"
          source={pixels(syncWave(cols * CELL_W, waveRows * CELL_H, trace))}
          columns={cols}
          rows={waveRows}
          alt="[sync trace]"
        />
        <Text dimColor>SYNC TRACE  tool calls per sortie</Text>
        <Text> </Text>
        {lines.map(line => (
          <Text dimColor={line.endsWith('aborted') || line.startsWith('none')}>{line}</Text>
        ))}
      </Box>
    )
  })
}
