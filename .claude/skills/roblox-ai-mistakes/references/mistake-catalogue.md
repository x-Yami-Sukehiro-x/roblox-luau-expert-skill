# Mistake catalogue

Every mistake below has been made by a model writing Roblox or executor code,
and every one has a check. Codes are the findings `check-file` prints: `E-`
and `W-` from the slop, UI and register tools, `K` numbers from
`roblox-attempt-memory/references/known-failures.md`. "Reading" means no tool
counts it and the check is a question you ask of the draft.

## Accuracy

| Mistake | Tell | Check | Instead |
|---|---|---|---|
| A member that does not exist | `X is not a valid member of Y` | `verify-api.mjs <Name>`, `check-file` api gate (`INVENTED`) | The member the dump has, or say there is none |
| A deprecated API | `wait()`, `spawn`, `BodyVelocity`, `FindPartOnRay` | `E-DEPRECATED`, `verify-api.mjs`, K1 | `task.*`, `LinearVelocity`, `Workspace:Raycast` |
| An API this script cannot reach | Works in the command bar, not in a LocalScript | `verify-api.mjs` `SECURITY` line | An API at the script's level, or say it is gated |
| An executor function under the wrong name | `syn.request`, `get_hidden_gui` written as if universal | `verify-executor-api.mjs <name>`, exit 1 | The sUNC name, bound once |
| Seven capability checks | `if typeof(x) ~= "function"` blocks through the file | `E-CAPCHECK` | One `local` bind, one `assert` |
| More executor functions than the job needs | Six or more for one feature | `W-EXECSURFACE` | Find the one layer the value lives on |
| An invented asset id | An icon that renders blank | `verify-asset-ids.mjs`, `W-ASSETLOOSE` | An id read from a source, in one table |

## Which side owns it

| Mistake | Tell | Check | Instead |
|---|---|---|---|
| A client write expected to replicate | "It resets", "others can't see it" | Reading: which side owns this value? | Say the client cannot; offer what it can do |
| Currency, items or damage "from the client" | "Infinite money" in a feature list | `client-feasibility.md` | The server-owned list; never code for it |
| A sent request reported as a result | "Done" after `FireServer` | Reading: what confirms the server accepted it? | Wait for the game's result, or say it is unconfirmed |
| A server trusting a remote argument (game code) | A price or damage read from the client | `roblox-game-security` | Validate type, range, ownership, rate |

## Compiling

| Mistake | Tell | Check | Instead |
|---|---|---|---|
| 200 locals in one function | `Out of local registers`; in an executor `attempt to call a nil value` | `E-COMPILE`, `I-LOCALS`, `W-REGISTERS` | Families in tables, a builder per tab (`roblox-register-budget`) |
| A local left outside the block it moved into | Nil at runtime after a register fix | `W-SCOPE` | A table both places can see |
| A very wide call or long `..` chain | `Out of registers when trying to allocate` | `E-COMPILE` | A table argument; `table.concat` |
| Globals to dodge the limit | No `local` on dozens of names | Reading; `W-SCOPE` finds the half-converted ones | Tables, not globals |

## Lifetime

| Mistake | Tell | Check | Instead |
|---|---|---|---|
| Connections with no teardown | Doubled effects after respawn or rerun | `E-LEAK` | Store every connection; disconnect in `stop` and `unload` |
| The character cached at the top | Works until the first death | K4 | Resolve on use; re-apply on `CharacterAdded` |
| A loop on a global flag | Two loops after a rerun | K5 | Connections in the session table |
| A template connected before cloning | Clones do nothing | K16 | Connect each clone |
| A GUI that resets on spawn | The window vanishes on death | `W-RESPAWN`, K17 | `ResetOnSpawn = false` |
| A rerun on top of the last session | Two windows; the "original" is the patched value | Reading; premium check 2 | Unload the `getgenv()` session first |
| A restored retyped literal | Right until the game changes the number | K7 | Restore the captured variable |
| A value held by writing it every frame | Frame cost, and it still flickers | K9 | `GetPropertyChangedSignal`, or disable the writer |

## Executor evidence

| Mistake | Tell | Check | Instead |
|---|---|---|---|
| Decompiler labels kept as names | `v14`, `u3`, `p1` in the delivered script | `E-DECOMPNAME` | A name from what the source proves it holds |
| A fallback chain across value layers | `getsenv(...) or getupvalue(...) or ...` | `E-LAYERCHAIN`, K8 | One layer, asserted |
| The first of several matches | `filtergc(..., true)` on a common key | Reading; `table-finder.luau` prints the count | Assert exactly one; add a distinguishing key |
| Remote arguments guessed | `FireServer("Buy", 1)` with no call site | Reading; `remotes-from-evidence.md` | The call site's arguments, or `remote-spy.luau` |
| A hook that catches its own calls | Recursion, a frozen game | K11 | `checkcaller()` first |
| An action repeated faster than its cooldown | Requests refused, a kick | Reading; the source's cooldown | `action-loop.luau` at the source's interval |
| A teleport chain untested | Snapped back, or kicked, mid-route | Reading; archetype 6 | One hop first, then the route |
| A toggle lit while its feature failed | "It does nothing" | Premium check 3 | The feature registry's status |

## Interface

| Mistake | Tell | Check | Instead |
|---|---|---|---|
| `Position` on a child of a layout | The value is ignored | `E-LAYOUTPOS` | Order with `LayoutOrder`; a `UIFlexItem` gap |
| `MouseButton1Click` | Dead on phone and gamepad | `E-MOUSEONLY`, K10 | `Activated` |
| `TextScaled` on a sentence | Text sizes differ per label | `E-TEXTSCALED` | Fixed sizes from the type scale |
| Colour literals everywhere | A palette nobody chose | `W-TOKENS` | One token block |
| No `UISizeConstraint` on the root | Huge on ultrawide, off a phone | `E-UNBOUNDED`, `E-MINFIT` | Scale size, both bounds |
| An Outer stroke inside a scrolling list | The outline is cut off | `E-STROKECLIP`, K14 | `Inner`, or pad the parent |
| `ClipsDescendants` to round a panel | Square corners still show | `E-CORNERBLEED`, K13 | A `CanvasGroup` |
| `"×"` as a close icon | Sits on the baseline, off centre | `W-GLYPHICON` | An image icon |
| The engine's button tint left on | States fight the tint | `E-AUTOBUTTON` | `AutoButtonColor = false` |
| Hover, press and focus missing | A button that does not respond | `W-STATES` | Six states |
| Help only on hover | Nothing on a phone | K12 | Long press or a visible line |
| A toast gone before it is read | "I didn't see anything" | `E-TOASTFAST` | 1.5 s after arrival |

## Words

| Mistake | Tell | Check | Instead |
|---|---|---|---|
| Where the code came from, in comments | "Based on the uploaded script" | `E-PROVENANCE` | Say it in the reply |
| Edit notes | `-- Fixed:`, `-- Changed` | `E-EDITNOTE` | The diff is the changelog |
| Comments restating the line | `-- set speed` above `speed = 16` | `E-RESTATE` | Delete, or say why |
| Generic or shortened names | `data`, `temp`, `plr`, `btn`, `frame2` | `W-GENERIC`, `W-ABBREV`, `W-NUMSUFFIX` | The game's words |
| Success prints | `print("Loaded!")` | `W-SUCCESSPRINT` | Quiet when it works |
| Long, advising error messages | "An error occurred, please try again!" | `E-ERRPROSE` | One clause naming the value |
| Hype in labels and notices | "Ultimate OP Speed", emoji labels | `W-EMOJI`; reading with `roblox-copy-craft` | Name the effect |

## Process

| Mistake | Tell | Check | Instead |
|---|---|---|---|
| Answering a different question | A new fly when asked to fix mobile | Reading the request after the plan | Re-read the request |
| Repeating an approach that failed | "Try this" twice with the same idea | `attempt-ledger plan` | New evidence, or a different approach |
| A rewrite when recommendations were asked for | 400 changed lines for "what would you improve?" | Reading | Ranked findings; apply on request |
| A fragment to splice | "Replace lines 40-60 with" | Reading | The whole file |
| A claim with no receipt | "Tested and working" | Reading | Quote the tool; name what did not run |
| Ten questions before any work | A questionnaire | `roblox-request-intake` | Decide, build, state assumptions |
