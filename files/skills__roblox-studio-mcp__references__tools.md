# Tool reference

The tools Roblox documents for Studio's built-in MCP server
(<https://create.roblox.com/docs/studio/mcp>, checked 2026-09-25). Tool sets
change with Studio releases: when a call fails as unknown, list what the host
actually exposes rather than trusting this table.

| Group | Tool | Use |
|---|---|---|
| session | `list_roblox_studios` | open Studio windows with name, id and place ID |
| data model | `search_game_tree` | instance hierarchy, filtered by path, class or keyword |
| | `inspect_instance` | properties, attributes and a child summary of one instance |
| | `subagent` | a helper that runs a multi-step job and returns one summary |
| scripts | `script_search` | scripts by name, up to 10 results |
| | `script_grep` | a string or pattern across all scripts, up to 50 matches |
| | `script_read` | a script's source with line numbers |
| | `multi_edit` | exact-match edits to one script, `Edit` only |
| Luau | `execute_luau` | run code in `Edit`, `Client` or `Server` and get the result |
| playtest | `get_studio_state` | play state and which data models exist |
| | `start_stop_play` | start or stop a playtest |
| | `get_console_output` | the Output window |
| | `screen_capture` | an image of the viewport |
| input | `character_navigation` | walk the character to a position or instance |
| | `user_keyboard_input` | key presses, text and waits |
| | `user_mouse_input` | moves, clicks and scrolls on coordinates or instances |
| assets | `search_asset`, `insert_asset` | Creator Store and inventory search, insert by id |
| | `generate_mesh`, `generate_material`, `generate_procedural_model`, `wait_job_finished` | generation jobs |
| | `upload_image`, `store_image` | images for other tools |
| docs | `http_get` | Roblox documentation pages |
| | `skill` | Roblox's own reference material for a named skill |

## Shapes that trip agents

- **`multi_edit`** takes one script's path in dot notation, `datamodel_type:
  "Edit"`, and a list of `old_string` / `new_string` pairs applied in order.
  Each `old_string` must match the current source exactly, whitespace
  included; if any edit fails, none apply. Three scripts are three calls.
  Read first, or the call fails.
- **`execute_luau`** returns the value of the code or its error. `print`
  output goes to `get_console_output`, which is useful during long work.
- **`script_grep`** finds which script holds a string; take line numbers from
  `script_read`, not from the grep.
- **`http_get`** reads Roblox documentation, not the general web; the
  `query` argument returns only the matching sections.

## Roblox's own skills

The `skill` tool returns first-party reference material shipped with Studio.
The builds reported on 2026-09-25 listed `rbx-debug` (breakpoints),
`rbx-device-simulator-lua` (phone and tablet sizes), `rbx-perf-profiling`
(MicroProfiler and memory), `rbx-scene-analysis`, `rbx-unit-test`,
`rbx-docs-search` and `rbx-create-skill`. For those narrow jobs they are more
current than this stack; call the matching one first, and keep this stack
for architecture, security, code standards and UI rules.

The first-party skill names and the observation that `script_grep` line
numbers drift come from MSayib/roblox-dev-skill (MIT), which re-verified them
against a live build; the rest is from Roblox's documentation page.
