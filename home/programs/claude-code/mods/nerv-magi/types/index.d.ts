export type Tally = { melchior: number; balthasar: number; casper: number }

// The current sortie's fight: the Angel's health and the Eva's sync (both 0..1), and how it ended.
export type Fight = { angelHp: number; evaHp: number; outcome: 'none' | 'cleared' | 'aborted' }

// One finished turn of the main loop.
export type Sortie = Tally & { seconds: number; isAborted: boolean }

declare module 'claude-code' {
  interface PluginState {
    'nerv-magi': {
      // Tool calls of the current (or last) turn.
      tally: Tally
      // Turns finished since the session started or was cleared.
      history: Sortie[]
      // True between a turn's start and its end.
      isActive: boolean
      fight: Fight
    }
  }
}
