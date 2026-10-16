// Procedural NERV-style pixel art for the /magi pane. Pure functions over an RGBA buffer, no
// engine calls, so the same code can be rendered to a PNG and looked at.

export type Rgb = readonly [number, number, number]
export type Bitmap = { width: number; height: number; rgba: Uint8Array }

// The Evangelion theme's colors (eva-theme.json), as 0-255 channels.
export const PALETTE = {
  bg: [13, 10, 20] as Rgb,
  grid: [74, 61, 99] as Rgb,
  orange: [255, 106, 0] as Rgb,
  purple: [139, 79, 196] as Rgb,
  blue: [111, 183, 255] as Rgb,
  green: [124, 252, 0] as Rgb,
  hot: [255, 196, 140] as Rgb,
}

const SQRT3 = Math.sqrt(3)

const clamp01 = (v: number): number => (v < 0 ? 0 : v > 1 ? 1 : v)

const smooth = (from: number, to: number, x: number): number => {
  const t = clamp01((x - from) / (to - from))

  return t * t * (3 - 2 * t)
}

// Stable pseudo-random 0..1 for a pair of integers: which hex cells light up.
const hash2 = (a: number, b: number): number => {
  let h = Math.imul(a, 374761393) + Math.imul(b, 668265263)
  h = Math.imul(h ^ (h >>> 13), 1274126177)

  return ((h ^ (h >>> 16)) >>> 0) / 4294967295
}

// Flat-top hexagon of circumradius `s` containing the point (x, y), and the point's offset
// from that hexagon's center.
const hexAt = (x: number, y: number, s: number) => {
  const fq = ((2 / 3) * x) / s
  const fr = ((-1 / 3) * x + (SQRT3 / 3) * y) / s
  const fs = -fq - fr
  let q = Math.round(fq)
  let r = Math.round(fr)
  const rs = Math.round(fs)
  const dq = Math.abs(q - fq)
  const dr = Math.abs(r - fr)
  const ds = Math.abs(rs - fs)

  if (dq > dr && dq > ds) {
    q = -r - rs
  } else if (dr > ds) {
    r = -q - rs
  }

  return { q, r, dx: x - s * 1.5 * q, dy: y - s * SQRT3 * (r + q / 2) }
}

// Distance from an offset inside a flat-top hexagon of circumradius `s` to its nearest edge:
// positive inside, negative outside.
const hexEdge = (dx: number, dy: number, s: number): number => {
  const m = Math.max(
    Math.abs(dy),
    Math.abs((dx * SQRT3) / 2 + dy / 2),
    Math.abs((-dx * SQRT3) / 2 + dy / 2),
  )

  return (s * SQRT3) / 2 - m
}

const blank = (width: number, height: number): Bitmap => ({
  width,
  height,
  rgba: new Uint8Array(width * height * 4),
})

// Writes bg plus the sum of (color * amount) for each light, with a faint CRT scanline.
const put = (
  bmp: Bitmap,
  x: number,
  y: number,
  lights: readonly (readonly [Rgb, number])[],
): void => {
  const i = (y * bmp.width + x) * 4
  const scan = y % 3 === 0 ? 0.86 : 1
  const out = [PALETTE.bg[0], PALETTE.bg[1], PALETTE.bg[2]]

  for (const [color, amount] of lights) {
    for (let c = 0; c < 3; c++) {
      out[c] = (out[c] ?? 0) + (color[c] ?? 0) * amount
    }
  }

  bmp.rgba[i] = Math.min(255, (out[0] ?? 0) * scan)
  bmp.rgba[i + 1] = Math.min(255, (out[1] ?? 0) * scan)
  bmp.rgba[i + 2] = Math.min(255, (out[2] ?? 0) * scan)
  bmp.rgba[i + 3] = 255
}

// A shock ring sent out from the center: its radius in pixels and how bright it still is (0..1).
export type Ring = { radius: number; strength: number }

/**
 * The A.T. Field: a hexagonal lattice whose cells light in rings spreading from the center.
 *
 * `energy` (0..1) is how many cells are lit and how bright the lattice burns; `phase` slides
 * the rings outward, so moving it by a little between two frames reads as the field pulsing.
 * Each of `rings` is a bright front travelling out through the lattice.
 */
export const atField = (
  width: number,
  height: number,
  { energy, phase, rings = [] }: { energy: number; phase: number; rings?: readonly Ring[] },
): Bitmap => {
  const bmp = blank(width, height)
  const cx = width / 2
  const cy = height / 2
  const size = 84 / 7.4
  const reach = width * 0.5

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const hex = hexAt(x - cx, y - cy, size)
      const edge = hexEdge(hex.dx, hex.dy, size)
      const line = 1 - smooth(0.5, 1.8, edge)
      const dist = Math.hypot(x - cx, y - cy)
      const falloff = Math.exp(-((dist / reach) ** 2) * 1.5)
      const wave = 0.5 + 0.5 * Math.sin(dist * 0.1 - phase)
      const cell = hash2(hex.q, hex.r)
      const lit = clamp01(wave * 0.75 + cell * 0.7 - (1.25 - energy * 1.1))
      const burn = (0.2 + 0.8 * energy * wave) * falloff
      let front = 0

      for (const ring of rings) {
        front += Math.exp(-(((dist - ring.radius) / 10) ** 2)) * ring.strength
      }
      front = Math.min(1.6, front)

      put(bmp, x, y, [
        [PALETTE.grid, line * 0.55 * (0.4 + falloff)],
        [PALETTE.orange, line * burn + (1 - line) * lit * 0.5 * falloff + front * 0.34],
        [PALETTE.hot, line * burn * wave ** 4 * energy * 0.45 + front * (line * 1.1 + 0.2)],
      ])
    }
  }

  return bmp
}

/**
 * One MAGI node: a hexagon in the seat's color, filled in proportion to `level` (0..1).
 */
export const magiHex = (
  width: number,
  height: number,
  { color, level }: { color: Rgb; level: number },
): Bitmap => {
  const bmp = blank(width, height)
  const cx = width / 2
  const cy = height / 2
  const size = Math.min(width, height) * 0.46

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const dx = x - cx
      const dy = y - cy
      const edge = hexEdge(dx, dy, size)
      const dist = Math.hypot(dx, dy)
      const border = 1 - smooth(1.2, 2.8, Math.abs(edge - 1.8))
      const inner = 1 - smooth(0.4, 1.4, Math.abs(edge - size * 0.2))
      const body = edge > 0 ? (0.05 + 0.5 * level) * (0.55 + 0.45 * (1 - dist / size)) : 0
      const glow = edge < 0 ? Math.exp(edge / 7) * (0.12 + 0.4 * level) : 0

      put(bmp, x, y, [
        [color, border * (0.55 + 0.45 * level) + body + glow],
        [PALETTE.grid, inner * 0.7],
      ])
    }
  }

  return bmp
}

/**
 * The synchronization trace: `values` as a glowing line over a grid, newest on the right,
 * the last point marked.
 */
export const syncWave = (width: number, height: number, values: readonly number[]): Bitmap => {
  const bmp = blank(width, height)
  const pad = 7
  const points = values.length === 1 ? [values[0] ?? 0, values[0] ?? 0] : [...values]
  const peak = Math.max(1, ...points)
  const step = points.length > 1 ? (width - 2 * pad) / (points.length - 1) : 0
  const pointY = (v: number): number => height - pad - (v / peak) * (height - 2 * pad)
  const gx = width / 12
  const gy = height / 4

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const gridded = x % Math.round(gx) === 0 || y % Math.round(gy) === 0 ? 0.35 : 0

      if (points.length === 0) {
        const dashed = Math.abs(y - height / 2) < 1 && x % 8 < 4 ? 0.6 : 0

        put(bmp, x, y, [[PALETTE.grid, gridded + dashed]])
        continue
      }

      const at = Math.max(0, Math.min(points.length - 2, Math.floor((x - pad) / step)))
      let nearest = Infinity
      let curveY = height

      for (let i = Math.max(0, at - 1); i <= Math.min(points.length - 2, at + 1); i++) {
        const x0 = pad + i * step
        const y0 = pointY(points[i] ?? 0)
        const x1 = pad + (i + 1) * step
        const y1 = pointY(points[i + 1] ?? 0)
        const vx = x1 - x0
        const vy = y1 - y0
        const t = clamp01(((x - x0) * vx + (y - y0) * vy) / (vx * vx + vy * vy))

        nearest = Math.min(nearest, Math.hypot(x - (x0 + t * vx), y - (y0 + t * vy)))

        if (x >= x0 && x <= x1) {
          curveY = y0 + ((x - x0) / vx) * vy
        }
      }

      const line = 1 - smooth(0.9, 2.1, nearest)
      const glow = Math.exp(-nearest / 5) * 0.4
      const area = y > curveY ? 0.14 * (1 - (y - curveY) / height) : 0
      const lastX = pad + (points.length - 1) * step
      const lastY = pointY(points[points.length - 1] ?? 0)
      const marker = 1 - smooth(2.4, 4.6, Math.hypot(x - lastX, y - lastY))

      put(bmp, x, y, [
        [PALETTE.grid, gridded],
        [PALETTE.orange, line + glow + area],
        [PALETTE.green, marker],
      ])
    }
  }

  return bmp
}

const CHUNK = 0x8000

// Standard padded base64 of the pixels, for an Image's `{ rgba, width, height }` source.
export const toBase64 = (bytes: Uint8Array): string => {
  let binary = ''

  for (let i = 0; i < bytes.length; i += CHUNK) {
    binary += String.fromCharCode(...bytes.subarray(i, i + CHUNK))
  }

  return btoa(binary)
}

// ---------------------------------------------------------------------------------------------
// The battlefield: a night-time city, the Eva on the left, the Angel on the right, and the shots,
// strikes and explosions between them. Drawn with plain alpha-blended primitives over a cached
// backdrop, so a frame only pays for what moves.
// ---------------------------------------------------------------------------------------------

export type Seat = 'melchior' | 'balthasar' | 'casper'

// A shot fired at the Angel by a tool call, `age` ms ago.
export type Shot = { seat: Seat; age: number }

export type Scene = {
  // Milliseconds on any steady clock: turns the Angel and flickers the city's windows.
  time: number
  // The Angel's remaining health and the Eva's sync, both 0..1.
  angelHp: number
  evaHp: number
  shots: readonly Shot[]
  // How long ago each of the Angel's attacks on the Eva was launched.
  strikes: readonly number[]
  // How the sortie ended, and how long ago.
  outcome: 'none' | 'cleared' | 'aborted'
  outcomeAge: number
}

// A shot's flight, and the burst and ripple on arrival, in ms.
export const SHOT_FLIGHT = 380
export const SHOT_IMPACT = 450
// An Angel strike's beam, and the Eva's A.T. Field answering it.
export const STRIKE_BEAM = 280
export const STRIKE_FIELD = 700
// The Angel's destruction, in ms.
export const CROSS_BLAST = 1500

const SEAT_COLOR: Record<Seat, Rgb> = {
  melchior: PALETTE.blue,
  balthasar: [181, 123, 255],
  casper: PALETTE.orange,
}

const lerp = (a: number, b: number, t: number): number => a + (b - a) * t

const inBounds = (bmp: Bitmap, x: number, y: number): boolean =>
  x >= 0 && y >= 0 && x < bmp.width && y < bmp.height

// Normal alpha blend of one pixel.
const blend = (bmp: Bitmap, x: number, y: number, color: Rgb, alpha: number): void => {
  if (alpha <= 0 || !inBounds(bmp, x, y)) {
    return
  }
  const i = (y * bmp.width + x) * 4
  const a = alpha > 1 ? 1 : alpha

  for (let c = 0; c < 3; c++) {
    bmp.rgba[i + c] = (bmp.rgba[i + c] ?? 0) * (1 - a) + (color[c] ?? 0) * a
  }
}

// Additive light on one pixel: beams and glows pile up toward white.
const light = (bmp: Bitmap, x: number, y: number, color: Rgb, amount: number): void => {
  if (amount <= 0 || !inBounds(bmp, x, y)) {
    return
  }
  const i = (y * bmp.width + x) * 4

  for (let c = 0; c < 3; c++) {
    bmp.rgba[i + c] = Math.min(255, (bmp.rgba[i + c] ?? 0) + (color[c] ?? 0) * amount)
  }
}

type Point = readonly [number, number]

// Even-odd scanline fill of a polygon.
const fillPoly = (bmp: Bitmap, pts: readonly Point[], color: Rgb, alpha = 1): void => {
  const ys = pts.map(p => p[1])
  const top = Math.max(0, Math.floor(Math.min(...ys)))
  const bottom = Math.min(bmp.height - 1, Math.ceil(Math.max(...ys)))

  for (let y = top; y <= bottom; y++) {
    const yc = y + 0.5
    const xs: number[] = []

    for (let i = 0; i < pts.length; i++) {
      const [x0, y0] = pts[i] as Point
      const [x1, y1] = pts[(i + 1) % pts.length] as Point

      if ((y0 <= yc && y1 > yc) || (y1 <= yc && y0 > yc)) {
        xs.push(x0 + ((yc - y0) / (y1 - y0)) * (x1 - x0))
      }
    }
    xs.sort((a, b) => a - b)

    for (let i = 0; i + 1 < xs.length; i += 2) {
      for (let x = Math.round(xs[i] ?? 0); x < Math.round(xs[i + 1] ?? 0); x++) {
        blend(bmp, x, y, color, alpha)
      }
    }
  }
}

// A glowing line segment: a solid core of `width` px and a soft halo `halo` px wide, additive.
const beam = (
  bmp: Bitmap,
  [x0, y0]: Point,
  [x1, y1]: Point,
  width: number,
  halo: number,
  color: Rgb,
  amount: number,
): void => {
  const reach = width / 2 + halo * 2.5
  const minX = Math.max(0, Math.floor(Math.min(x0, x1) - reach))
  const maxX = Math.min(bmp.width - 1, Math.ceil(Math.max(x0, x1) + reach))
  const minY = Math.max(0, Math.floor(Math.min(y0, y1) - reach))
  const maxY = Math.min(bmp.height - 1, Math.ceil(Math.max(y0, y1) + reach))
  const vx = x1 - x0
  const vy = y1 - y0
  const len2 = vx * vx + vy * vy || 1

  for (let y = minY; y <= maxY; y++) {
    for (let x = minX; x <= maxX; x++) {
      const t = clamp01(((x - x0) * vx + (y - y0) * vy) / len2)
      const d = Math.hypot(x - (x0 + t * vx), y - (y0 + t * vy))
      const core = 1 - smooth(width / 2 - 0.4, width / 2 + 0.8, d)
      const glow = halo > 0 ? Math.exp(-Math.max(0, d - width / 2) / halo) * 0.45 : 0

      light(bmp, x, y, color, (core + glow) * amount)
    }
  }
}

// A soft round glow.
const glow = (bmp: Bitmap, cx: number, cy: number, r: number, color: Rgb, amount: number): void => {
  for (let y = Math.max(0, Math.floor(cy - r)); y <= Math.min(bmp.height - 1, Math.ceil(cy + r)); y++) {
    for (let x = Math.max(0, Math.floor(cx - r)); x <= Math.min(bmp.width - 1, Math.ceil(cx + r)); x++) {
      light(bmp, x, y, color, amount * (1 - smooth(r * 0.15, r, Math.hypot(x - cx, y - cy))))
    }
  }
}

// An octagon outline: the shape an A.T. Field takes when something hits it.
const octagon = (
  bmp: Bitmap,
  cx: number,
  cy: number,
  r: number,
  width: number,
  color: Rgb,
  amount: number,
): void => {
  for (let i = 0; i < 8; i++) {
    const a0 = (Math.PI / 4) * i + Math.PI / 8
    const a1 = (Math.PI / 4) * (i + 1) + Math.PI / 8

    beam(
      bmp,
      [cx + Math.cos(a0) * r, cy + Math.sin(a0) * r * 0.9],
      [cx + Math.cos(a1) * r, cy + Math.sin(a1) * r * 0.9],
      width,
      width * 1.6,
      color,
      amount,
    )
  }
}

// The Eva's silhouette in units of 1/126 of the image height, origin between its feet, up is -y.
// Legs and body in the dark armor, with the lighter plates and green stripes laid over them.
const EVA_BODY: readonly Point[][] = [
  [[-9, 0], [-3, 0], [-2, -30], [-4, -42], [-10, -42], [-11, -28]],
  [[3, 0], [9, 0], [11, -28], [10, -42], [4, -42], [2, -30]],
  [[-10, -42], [10, -42], [8, -51], [-8, -51]],
  [[-8, -51], [8, -51], [13, -63], [-13, -63]],
  [[-13, -63], [13, -63], [10, -73], [-10, -73]],
  // Arm at the side, and the raised arm that fires.
  [[-17, -71], [-22, -60], [-21, -47], [-17, -46], [-15, -58], [-13, -68]],
  [[12, -68], [26, -63], [38, -56], [38, -51], [26, -55], [12, -60]],
  [[-3, -73], [3, -73], [3, -77], [-3, -77]],
  [[-6, -77], [6, -77], [7, -85], [2, -91], [-2, -91], [-7, -85]],
]

const EVA_PLATES: readonly Point[][] = [
  [[-13, -63], [-20, -67], [-20, -76], [-11, -75]],
  [[13, -63], [20, -67], [20, -76], [11, -75]],
  [[-8, -53], [8, -53], [11, -62], [-11, -62]],
  [[-1, -91], [1, -91], [0, -99]],
  [[-4, -42], [-10, -42], [-10, -30], [-4, -31]],
  [[4, -42], [10, -42], [10, -30], [4, -31]],
]

const EVA_STRIPES: readonly Point[][] = [
  [[-19, -69], [-14, -66], [-14, -64], [-19, -67]],
  [[19, -69], [14, -66], [14, -64], [19, -67]],
  [[-9, -20], [-4, -20], [-4, -17], [-9, -17]],
  [[4, -20], [9, -20], [9, -17], [4, -17]],
  [[24, -61], [36, -55], [36, -53], [24, -59]],
]

const EVA_ARMOR: Rgb = [48, 28, 84]
const EVA_PLATE: Rgb = [96, 56, 158]
const EVA_STRIPE: Rgb = [108, 228, 44]
const EVA_EYE: Rgb = [255, 190, 40]

type Backdrop = { base: Bitmap; windows: readonly { x: number; y: number; phase: number }[] }

const backdrops = new Map<string, Backdrop>()

// The scene's geometry as fractions of the image: where the Eva stands, her hand, and the Angel.
const stage = (width: number, height: number) => {
  const k = height / 126

  return {
    k,
    ex: width * 0.2,
    gy: height * 0.9,
    hand: [width * 0.2 + 38 * k, height * 0.9 - 53 * k] as Point,
    chest: [width * 0.2, height * 0.9 - 62 * k] as Point,
    ax: width * 0.76,
    ay: height * 0.38,
    r: height * 0.27,
  }
}

// Sky, stars, mountains, the city, the ground grid and the Eva: everything that does not move.
const backdrop = (width: number, height: number): Backdrop => {
  const key = `${width}x${height}`
  const cached = backdrops.get(key)

  if (cached !== undefined) {
    return cached
  }

  const base = blank(width, height)
  const horizon = height * 0.7
  const windows: { x: number; y: number; phase: number }[] = []

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 4

      if (y < horizon) {
        // Night sky glowing magenta toward the horizon.
        const t = (y / horizon) ** 2
        base.rgba[i] = lerp(10, 92, t)
        base.rgba[i + 1] = lerp(8, 30, t)
        base.rgba[i + 2] = lerp(22, 66, t)
        if (hash2(x, y) > 0.9975) {
          blend(base, x, y, [255, 240, 230], 0.5 + 0.5 * hash2(y, x))
        }
      } else {
        base.rgba[i] = 12
        base.rgba[i + 1] = 8
        base.rgba[i + 2] = 20
      }
      base.rgba[i + 3] = 255
    }
  }

  // Two ridges of mountains.
  for (const [lift, top, tone] of [
    [0.2, 0.17, [34, 20, 58]],
    [0.11, 0.1, [24, 14, 42]],
  ] as const) {
    for (let x = 0; x < width; x++) {
      const ridge =
        horizon -
        height *
          (top * (0.55 + 0.3 * Math.sin(x * 0.021 + lift * 40) + 0.15 * Math.sin(x * 0.07 + lift * 9)) + lift * 0.25)

      for (let y = Math.max(0, Math.floor(ridge)); y < horizon; y++) {
        blend(base, x, y, tone, 1)
      }
    }
  }

  // The city: towers of varied height with a few lit windows.
  for (let x = 0; x < width; ) {
    const w = 4 + Math.floor(hash2(x, 3) * 6)
    const h = height * (0.05 + 0.2 * hash2(x, 7) ** 1.6)
    const shade = 18 + Math.floor(hash2(x, 11) * 14)
    const top = Math.floor(horizon - h)

    for (let y = top; y < horizon; y++) {
      for (let dx = 0; dx < w - 1; dx++) {
        blend(base, x + dx, y, [shade, shade * 0.7, shade * 1.9], 1)
      }
    }
    for (let y = top + 2; y < horizon - 1; y += 3) {
      for (let dx = 1; dx < w - 2; dx += 2) {
        if (hash2(x + dx, y) > 0.55) {
          windows.push({ x: x + dx, y, phase: hash2(y, x + dx) * 6.28 })
        }
      }
    }
    x += w
  }

  // The ground: a grid running away to the horizon.
  const vx = width * 0.5

  for (let n = -24; n <= 24; n++) {
    const bottomX = vx + n * width * 0.09

    beam(base, [vx + n * 2, horizon], [bottomX, height], 0.8, 0, [70, 44, 110], 0.35)
  }
  for (let i = 1; i < 9; i++) {
    const y = horizon + (height - horizon) * (i / 9) ** 1.7

    beam(base, [0, y], [width, y], 0.8, 0, [70, 44, 110], 0.3)
  }

  // The Eva, shaded against the sky.
  const { k, ex, gy } = stage(width, height)
  const at = (pts: readonly Point[]): Point[] => pts.map(([x, y]) => [ex + x * k, gy + y * k] as Point)

  for (const part of EVA_BODY) {
    fillPoly(base, at(part), EVA_ARMOR)
  }
  for (const part of EVA_PLATES) {
    fillPoly(base, at(part), EVA_PLATE)
  }
  for (const part of EVA_STRIPES) {
    fillPoly(base, at(part), EVA_STRIPE)
  }
  fillPoly(base, at([[-4.5, -85], [-1.5, -85], [-1.5, -83.5], [-4.5, -83.8]]), EVA_EYE)
  fillPoly(base, at([[1.5, -85], [4.5, -85], [4.5, -83.8], [1.5, -83.5]]), EVA_EYE)
  glow(base, ex, gy - 84 * k, 7 * k, EVA_EYE, 0.25)

  const result = { base, windows }
  backdrops.set(key, result)

  return result
}

// A rotating octahedron: the Angel. `hurt` (0..1) flashes it white, `hp` shows the core as it fails.
const drawAngel = (
  bmp: Bitmap,
  cx: number,
  cy: number,
  r: number,
  spin: number,
  hurt: number,
  hp: number,
): void => {
  const tilt = 0.4
  const verts: [number, number, number][] = [
    [1, 0, 0],
    [-1, 0, 0],
    [0, 1, 0],
    [0, -1, 0],
    [0, 0, 1],
    [0, 0, -1],
  ]
  // The same turn applied to a vertex and to a face normal: spin about the vertical, then tip.
  const turn = ([x, y, z]: readonly [number, number, number]): [number, number, number] => {
    const x1 = x * Math.cos(spin) + z * Math.sin(spin)
    const z1 = -x * Math.sin(spin) + z * Math.cos(spin)

    return [x1, y * Math.cos(tilt) - z1 * Math.sin(tilt), y * Math.sin(tilt) + z1 * Math.cos(tilt)]
  }
  const spun = verts.map(v => turn(v))
  const lightDir = [-0.4, -0.6, 0.7]

  glow(bmp, cx, cy, r * 1.6, [30, 80, 255], 0.22 + hurt * 0.2)

  // Eight faces, one vertex from each axis pair; those whose outward normal turns toward the
  // viewer (+z after the turn) are drawn, which for a convex shape covers it without gaps.
  for (const sx of [0, 1]) {
    for (const sy of [2, 3]) {
      for (const sz of [4, 5]) {
        const [nx, ny, nz] = turn([sx === 0 ? 1 : -1, sy === 2 ? 1 : -1, sz === 4 ? 1 : -1]).map(
          n => n / Math.sqrt(3),
        ) as [number, number, number]

        if (nz <= 0.02) {
          continue
        }

        const a = spun[sx] as readonly [number, number, number]
        const b = spun[sy] as readonly [number, number, number]
        const c = spun[sz] as readonly [number, number, number]
        const shade =
          0.22 + 0.78 * Math.max(0, nx * (lightDir[0] ?? 0) + ny * (lightDir[1] ?? 0) + nz * (lightDir[2] ?? 0))
        const face: Rgb = [
          lerp(18, 110, shade) + hurt * 140,
          lerp(52, 190, shade) + hurt * 120,
          lerp(170, 255, shade),
        ]
        const at = (v: readonly [number, number, number]): Point => [cx + v[0] * r, cy + v[1] * r]

        fillPoly(bmp, [at(a), at(b), at(c)], face)
        for (const [p, q] of [[a, b], [b, c], [c, a]] as const) {
          beam(bmp, at(p), at(q), 1, 1.6, [120, 200, 255], 0.55 + hurt * 0.4)
        }
      }
    }
  }

  // The red core shows through as the Angel weakens.
  glow(bmp, cx, cy + r * 0.05, r * 0.5, [255, 40, 30], (1 - hp) * 0.9 * (0.7 + 0.3 * Math.sin(spin * 9)))
}

// The scenery a frame is drawn into, then the Angel, shots, strikes and the sortie's ending.
export const battlefield = (width: number, height: number, scene: Scene): Bitmap => {
  const { base, windows } = backdrop(width, height)
  const bmp: Bitmap = { width, height, rgba: base.rgba.slice() }
  const { k, ex, gy, hand, chest, ax, ay, r } = stage(width, height)
  const { time, shots, strikes, outcome, outcomeAge } = scene

  for (const w of windows) {
    blend(bmp, w.x, w.y, [255, 196, 96], 0.25 + 0.5 * (0.5 + 0.5 * Math.sin(time / 900 + w.phase)))
  }

  // The Eva's eyes burn brighter as her sync holds.
  glow(bmp, ex, gy - 84 * k, 9 * k, EVA_EYE, 0.12 + 0.3 * scene.evaHp)

  // The Angel hovers and turns until it is destroyed.
  const bob = Math.sin(time / 650) * height * 0.025
  const hurt = shots.reduce(
    (m, s) => (s.age >= SHOT_FLIGHT ? Math.max(m, Math.exp(-(s.age - SHOT_FLIGHT) / 110)) : m),
    0,
  )
  const angelAlive = outcome !== 'cleared' || outcomeAge < 140

  if (angelAlive) {
    drawAngel(bmp, ax, ay + bob, r, time / 900, hurt, scene.angelHp)
  }

  // Shots from the Eva's hand to the Angel, in the colors of the seat that fired them.
  for (const shot of shots) {
    const color = SEAT_COLOR[shot.seat]
    const t = clamp01(shot.age / SHOT_FLIGHT)
    const target: Point = [ax, ay + bob]

    if (shot.age < SHOT_FLIGHT) {
      const head: Point = [lerp(hand[0], target[0], t), lerp(hand[1], target[1], t)]

      if (shot.seat === 'melchior') {
        beam(bmp, hand, head, 1.4, 3, color, 0.9)
        glow(bmp, head[0], head[1], 5 * k, [200, 230, 255], 0.9)
      } else if (shot.seat === 'balthasar') {
        // Lightning: a jagged line that reshuffles every few frames.
        let prev: Point = hand
        const step = Math.floor(shot.age / 50)

        for (let i = 1; i <= 8; i++) {
          const f = (i / 8) * t
          const jitter = i === 8 ? 0 : (hash2(i, step) - 0.5) * 12 * k
          const next: Point = [lerp(hand[0], target[0], f), lerp(hand[1], target[1], f) + jitter]

          beam(bmp, prev, next, 1.8, 3, color, 0.95)
          beam(bmp, prev, next, 0.8, 0, [255, 255, 255], 0.9)
          prev = next
        }
      } else {
        // A missile lobbed in an arc, trailing fire.
        const arc = (f: number): Point => [
          lerp(hand[0], target[0], f),
          lerp(hand[1], target[1], f) - Math.sin(Math.PI * f) * height * 0.22,
        ]

        for (let i = 6; i >= 0; i--) {
          const p = arc(Math.max(0, t - i * 0.035))

          glow(bmp, p[0], p[1], (2.2 + (6 - i) * 0.4) * k, i === 0 ? [255, 230, 190] : color, 0.8 - i * 0.1)
        }
      }
    } else {
      // Arrival: the Angel's A.T. Field answers in octagons, and the seat's color bursts.
      const f = clamp01((shot.age - SHOT_FLIGHT) / SHOT_IMPACT)

      octagon(bmp, ax, ay + bob, r * (1.05 + f * 0.55), 1.6, PALETTE.orange, 1 - f)
      octagon(bmp, ax, ay + bob, r * (0.9 + f * 0.4), 1.1, PALETTE.hot, (1 - f) * 0.8)
      glow(bmp, ax, ay + bob, r * (0.6 + f * 0.5), color, (1 - f) * 0.7)
    }
  }

  // The Angel's attacks: a red beam to the Eva, and her A.T. Field flaring where it lands.
  let redFlash = 0

  for (const age of strikes) {
    if (age < STRIKE_BEAM) {
      const pulse = 0.6 + 0.4 * Math.sin(age / 18)

      beam(bmp, [ax, ay + bob], chest, 2.4, 4, [255, 50, 40], pulse)
      beam(bmp, [ax, ay + bob], chest, 1, 0, [255, 230, 220], pulse)
    } else if (age < STRIKE_BEAM + STRIKE_FIELD) {
      const f = (age - STRIKE_BEAM) / STRIKE_FIELD

      octagon(bmp, chest[0], chest[1] - 4 * k, 26 * k * (0.9 + f * 0.4), 1.8, PALETTE.orange, 1 - f)
      octagon(bmp, chest[0], chest[1] - 4 * k, 22 * k * (0.9 + f * 0.4), 1.1, PALETTE.hot, (1 - f) * 0.8)
      redFlash = Math.max(redFlash, 0.22 * (1 - f) ** 2)
    }
  }

  // The sortie's ending. The Angel dies in a cross of light; an aborted sortie only reddens.
  if (outcome === 'cleared') {
    const f = clamp01(outcomeAge / CROSS_BLAST)
    const arm = Math.min(width * 0.4, outcomeAge * 0.7)
    const thick = Math.max(0.8, 6 * (1 - f))

    beam(bmp, [ax - arm, ay + bob], [ax + arm, ay + bob], thick, thick * 1.5, [255, 230, 200], 1 - f)
    beam(bmp, [ax, ay + bob - arm], [ax, ay + bob + arm], thick, thick * 1.5, [255, 230, 200], 1 - f)
    glow(bmp, ax, ay + bob, r * (0.4 + f * 1.4), [255, 200, 140], (1 - f) * 1.1)
    redFlash = Math.max(redFlash, 0)

    const white = 0.55 * Math.max(0, 1 - outcomeAge / 320)

    for (let i = 0; i < bmp.rgba.length; i += 4) {
      for (let c = 0; c < 3; c++) {
        bmp.rgba[i + c] = Math.min(255, (bmp.rgba[i + c] ?? 0) + 255 * white)
      }
    }
  } else if (outcome === 'aborted') {
    redFlash = Math.max(redFlash, 0.22 * clamp01(outcomeAge / 300))
  }

  // Red alarm tint and CRT scanlines over the whole picture.
  for (let y = 0; y < height; y++) {
    const scan = y % 3 === 0 ? 0.86 : 1

    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 4

      bmp.rgba[i] = Math.min(255, ((bmp.rgba[i] ?? 0) + 255 * redFlash) * scan)
      bmp.rgba[i + 1] = (bmp.rgba[i + 1] ?? 0) * scan * (1 - redFlash * 0.5)
      bmp.rgba[i + 2] = (bmp.rgba[i + 2] ?? 0) * scan * (1 - redFlash * 0.5)
    }
  }

  return bmp
}
