# Luau standard library — behaviour and traps

Signatures verified against luau.org. Roblox ships its own Luau build; check
`tools/api-dump/version.txt` for the client version this stack is pinned to.

---

## `table`

| Function | Note |
|---|---|
| `table.insert(t, v)` | O(1) append |
| `table.insert(t, pos, v)` | **O(n)** — shifts everything after `pos` |
| `table.remove(t, pos?)` | O(n); defaults to last element |
| `table.find(t, v, init?)` | linear scan, returns index or nil |
| `table.concat(t, sep?, i?, j?)` | the only correct way to join many strings |
| `table.create(count, value?)` | preallocates; use for known-size arrays |
| `table.clone(t)` | **shallow**, preserves the metatable |
| `table.freeze(t)` | **shallow**, permanent, no unfreeze |
| `table.isfrozen(t)` | |
| `table.move(src, a, b, t, dst?)` | bulk copy, no allocation when `dst` exists |
| `table.pack(...)` / `table.unpack(t, i?, j?)` | `pack` sets `n`, which is nil-safe |

**`#` on a table with holes is undefined.** `{1, nil, 3}` may report 1 or 3
depending on internal layout. If a table can contain nil gaps, track the count
yourself or use `table.pack`'s `n` field.

**`table.create` matters in hot code.** Growing an array by repeated append
reallocates; `table.create(1000)` allocates once.

```lua
local hits = table.create(#targets)
for i, target in targets do
    hits[i] = evaluate(target)
end
```

**Freeze your constants.** It turns "someone mutated the config at runtime" from
a three-hour bug into an immediate error.

```lua
local WEAPON_STATS = table.freeze({
    sword = table.freeze({ damage = 25, cooldown = 0.4 }),
    axe   = table.freeze({ damage = 40, cooldown = 0.9 }),
})
```

`table.freeze` is shallow — the nested freezes above are not redundant.

---

## `string`

Luau strings are byte strings. `#s` is bytes, not characters. For anything a
player typed, use the `utf8` library.

| Function | Note |
|---|---|
| `string.format(fmt, ...)` | `%s %d %f %.2f %q`; `%*` accepts any value |
| `string.split(s, sep?)` | **plain substring**, not a pattern; returns a table |
| `string.find(s, pat, init?, plain?)` | pass `plain = true` to skip pattern parsing |
| `string.gsub(s, pat, repl, n?)` | returns string **and** count — mind the second return |
| `string.gmatch(s, pat)` | iterator |
| `string.rep(s, n, sep?)` | |
| `string.byte` / `string.char` | |

**Lua patterns are not regular expressions.**

- The escape character is `%`, not `\`. `%.` is a literal dot.
- Character classes: `%a` letters, `%d` digits, `%s` space, `%w` alphanumeric,
  `%p` punctuation, uppercase negates (`%D` = non-digit).
- There is **no alternation** (`|`) and no `{n,m}` quantifier.
- `-` is a lazy quantifier; `*` and `+` are greedy.
- Anchors are `^` and `$`.

```lua
-- WRONG: "." matches any character
if string.find(name, "sword.png") then end
-- RIGHT
if string.find(name, "sword%.png") then end
-- or skip patterns entirely
if string.find(name, "sword.png", 1, true) then end
```

**Concatenation in a loop is quadratic.** Each `..` allocates a new string.

```lua
-- WRONG
local out = ""
for _, line in lines do out ..= line .. "\n" end

-- RIGHT
local parts = table.create(#lines)
for i, line in lines do parts[i] = line end
local out = table.concat(parts, "\n")
```

Interpolation compiles to concatenation, so the same rule applies inside loops.

**`gsub` returns two values.** `local s = str:gsub("a", "b")` is correct;
`return str:gsub("a", "b")` returns *two* values and will surprise a caller that
expected one. Wrap in parentheses to truncate: `return (str:gsub("a", "b"))`.

---

## `math`

All Luau numbers are IEEE doubles. There is no separate integer type.

| Function | Note |
|---|---|
| `math.floor` / `ceil` / `round` | `round` is half-away-from-zero |
| `math.clamp(x, min, max)` | errors if `min > max` |
| `math.sign(x)` | -1, 0 or 1 |
| `math.fmod(a, b)` | truncated remainder; `%` is floored — they differ for negatives |
| `math.huge` | infinity |
| `math.random(m?, n?)` | shared global generator |
| `math.noise(x, y?, z?)` | Perlin, deterministic |

**`0.1 + 0.2 ~= 0.3`.** Compare floats with an epsilon:

```lua
local function nearly(a: number, b: number, epsilon: number?): boolean
    return math.abs(a - b) <= (epsilon or 1e-6)
end
```

**NaN fails every comparison, including with itself.** `x ~= x` is the NaN test,
and it is a required check on any number that came from a client:

```lua
if amount ~= amount then return end     -- NaN
if amount == math.huge or amount == -math.huge then return end
```

An exploiter sending `0/0` through a remote will otherwise sail past
`amount > 0 and amount < 100`, because every comparison against NaN is false —
so `not (amount > 100)` is true.

**`math.random` vs `Random.new`.** `math.random` uses one global generator;
`Random.new(seed)` gives an independent, seedable stream. Use `Random.new` for
anything reproducible or per-entity.

---

## `os` and time

| Call | Returns |
|---|---|
| `os.clock()` | monotonic CPU/wall seconds, high resolution — **use for elapsed time** |
| `os.time()` | UTC seconds since epoch, integer — use for timestamps |
| `os.date(fmt?, time?)` | formatted date |
| `DateTime.now()` | the modern Roblox API; timezone-aware formatting |
| `tick()` | **deprecated**, timezone-dependent |
| `workspace:GetServerTimeNow()` | server clock, synchronized, for cross-client timing |

Never subtract two `os.time()` values for sub-second work — the resolution is
one second.

---

## `buffer` — binary data

Fixed-size mutable byte arrays. The reason to care in Roblox is network
bandwidth: a table sent over a remote is serialized with type tags and field
names; a buffer is raw bytes.

```lua
function buffer.create(size: number): buffer
function buffer.fromstring(str: string): buffer
function buffer.tostring(b: buffer): string
function buffer.len(b: buffer): number

function buffer.readi8/readu8/readi16/readu16/readi32/readu32(b, offset): number
function buffer.readf32/readf64(b, offset): number
function buffer.writei8/writeu8/writei16/writeu16/writei32/writeu32(b, offset, value): ()
function buffer.writef32/writef64(b, offset, value): ()

function buffer.readstring(b, offset, count): string
function buffer.writestring(b, offset, value, count: number?): ()
function buffer.readbits(b, bitOffset, bitCount): number
function buffer.writebits(b, bitOffset, bitCount, value): ()
function buffer.copy(target, targetOffset, source, sourceOffset?, count?): ()
function buffer.fill(b, offset, value, count?): ()
```

Offsets are **zero-based** and in bytes. Reading past the end errors — it does
not return nil.

```lua
-- 9 bytes instead of a table with three named number fields
local b = buffer.create(9)
buffer.writeu8(b, 0, actionId)
buffer.writef32(b, 1, position.X)
buffer.writef32(b, 5, position.Z)
Remote:FireServer(b)
```

Buffers cross remotes as a native type. For a real protocol, use a library that
generates the layout (**ByteNet**, **Blink**) rather than hand-counting offsets
— see `roblox-networking`.

---

## `vector` — the Luau native vector

Luau has a native 3-wide (optionally 4-wide) float vector with SIMD support in
the VM. **This is not `Vector3`.** Roblox's `Vector3` is the datatype you use in
almost all engine APIs; `vector` is the raw language-level value, relevant for
native codegen and heavy math.

```lua
vector.zero
vector.one
function vector.create(x: number, y: number, z: number): vector
function vector.magnitude(v: vector): number
function vector.normalize(v: vector): vector
function vector.cross(a: vector, b: vector): vector
function vector.dot(a: vector, b: vector): number
function vector.angle(a: vector, b: vector, axis: vector?): number
function vector.floor/ceil/abs/sign(v: vector): vector
function vector.clamp(v: vector, min: vector, max: vector): vector
function vector.max(...: vector): vector
function vector.min(...: vector): vector
```

Do not reach for `vector` by default. Use `Vector3` — it is what every engine
API accepts. `vector` earns its place inside `--!native` numeric kernels.

---

## `utf8`

Needed for anything a player typed. `#s` counts bytes; an emoji is four.

<!-- lint: fragment -->
```lua
utf8.len(s)                 -- character count, or nil + position on invalid input
utf8.char(...)              -- codepoints to string
utf8.codepoint(s, i?, j?)
utf8.offset(s, n, i?)       -- byte offset of the nth character
for pos, code in utf8.codes(s) do end
utf8.charpattern            -- "[\0-\x7F\xC2-\xFD][\x80-\xBF]*"
```

Truncating a display name with `string.sub` will split a multi-byte character
and produce mojibake. Use `utf8.offset` to find a safe cut point.

---

## `debug` (Roblox engine, not the executor library)

<!-- lint: fragment -->
```lua
debug.traceback(message?, level?)     -- call stack as a string
debug.profilebegin(label)             -- MicroProfiler scope open
debug.profileend()                    -- close it
debug.setmemorycategory(name)         -- tag this thread's allocations
debug.info(level|func, options)       -- structured stack info
```

`profilebegin`/`profileend` must be balanced on the same thread. They cost
almost nothing when the MicroProfiler is closed, so leaving them in shipped code
is fine and useful. See `roblox-performance`.

The executor `debug` library — `getupvalue`, `getconstants`, `getproto` — is a
completely different, much larger surface. It is documented in
`roblox-executor/references/api/debug.md`.
