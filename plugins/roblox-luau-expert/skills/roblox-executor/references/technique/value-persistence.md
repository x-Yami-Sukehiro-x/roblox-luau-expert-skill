# Value persistence — identifying what resets a change

Read before changing a value that reverts or has no gameplay effect. Supplied
source goes through `decompiled-source.md` first. Pick the storage location
actually consumed by the feature, using `source-to-api.md`; do not try layers in
sequence until a number changes.

## Authority and storage are separate

A local property write normally does not become a server property write.
Ownership-related physics and specific replication paths have their own rules;
see `replication-exploitation.md`. Modifying a client display never establishes
that currency, damage, inventory or progression changed on the server.

Symptoms identify questions, not their answers:

| Observation | What to establish next |
|---|---|
| Value reverts every frame | Identify a local writer, replication update or replacement object |
| Value stays set but gameplay is unchanged | Find the actual reader and its authoritative side |
| Only the local visual changes | Check whether that is the requested outcome |
| A second run cannot restore the original | Check whether it captured the first run's patched value |

Absence from a GC search or a partial dump does not prove server ownership.

## Match the live reader to its value

| Source-established location | Access path | Persistence limit |
|---|---|---|
| Ordinary Instance property | Direct property access | Another writer, replication or replacement may overwrite it |
| Attribute | `GetAttribute` / `SetAttribute` | Same; an attribute may only be a display copy |
| Verified hidden property | `gethiddenproperty` / `sethiddenproperty` | Executor support and security vary; no server authority implied |
| Captured local | `debug.getupvalues` / `debug.setupvalue` on the identified closure | Another assignment can still replace it |
| Retained bytecode constant | `debug.getconstants` / `debug.setconstant` on the identified closure | The intended slot must exist; recreated closures or native execution may differ |
| Module table field | Established table reference, then field access | Only readers of that exact table observe the change |
| Script environment global | `getsenv(script)` and the established key | Locals are absent; the script may rewrite the global |
| Server-owned value | Server code or a server-accepted request | A client patch cannot grant authority |

Hooks serve a specific interception requirement. They are not the default access
path for ordinary properties or attributes. An upvalue write changes a stored
value, but does not guarantee that nothing writes it again.

## Locating a closure or table

Use constants, table fields and relationships from the source with `filtergc`;
option definitions are in `../api/environment.md`. Inspect the full candidate
set, then require one target that matches the feature's live reader. A matching
number or common key is a filter, not identity. Do not mutate all matches.

If the required capability is missing, name it. A different access path is a new
implementation choice requiring evidence, not a silent runtime fallback. A known
script global calls for `getsenv`; it cannot expose that script's file-local
variable. `getloadedmodules` returns ModuleScript instances, not closures that can
be passed directly to `debug.getprotos`.

## Identify the writer

### A local script overwrites the value

Trace the assignment from source or bounded instrumentation scoped to the exact
instance and property. Prefer the writer's configuration or existing setter.
Before disabling a callback, establish its identity and every other job it does.
Blanket-disabling Heartbeat, render or movement callbacks can break unrelated work
and tells you little about the intended writer.

`getconnections(signal)` can inspect signal connections. Named
`BindToRenderStep` callbacks are different; the executor-specific
`getrendersteppedlist` may expose them. Not finding a signal writer does not prove
it is a bound render callback. These calls require their own feature detection.

For an identified connection intentionally suspended by this session, capture
whether it was enabled, use `Disable` if reversible suspension is needed, and
restore only the state this session changed. Disconnect only connections the
session owns. Connection flags do not establish whether a game detects a change.

### The server replicates its value back

Establish this from the replication path or server evidence, not by disabling all
local connections. A local patch does not change that server-owned state.
`setnonreplicatedproperty` does not make the server accept a value or stop future
replication. Report the authority limit; do not escalate through unrelated APIs.

### The feature reads another copy

Trace the consumer. A HUD might read an Ammo attribute while a preview controller
reads a captured ammo table, and the server uses its own inventory. Changing one
does not change the others. Return to the observed reader and choose its access
path; do not append another patch to cover every possible copy.

### The object or closure was replaced

A respawn, new tool, camera swap or script reload can invalidate a correct earlier
reference. Observe the specific lifecycle and reacquire through the same proven
path. Invalidate work pending on the old owner before changing the new object.

## Deliver and verify

Authority-mode inspection, when relevant and available, is described in
`replication-exploitation.md`. A missing or inaccessible authority-mode property
does not prove either mode.

Capture the actual original and follow `lifecycle.md` for rerun, unload and
conflicts with another writer. State which local effect the patch supports and
what server effect remains unestablished. Test first run, rerun, unload twice and
the relevant replacement event in the intended runtime. If that runtime is not
available, report static checks and the unrun runtime cases separately.
