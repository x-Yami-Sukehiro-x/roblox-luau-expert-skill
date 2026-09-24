# File names

A downloaded file called
`Roblox_Auto_Farm_Script_Final_Fixed_Version_2026-09-24_v3_complete.lua`
tells the user nothing the first word did not, and makes the next one
`..._v4_complete_FINAL.lua`. The file name is the script's name.

---

## The rule

- **The name of the thing, 1 to 3 words.** `AutoFarm`, `ShopUI`, `DataStore`,
  `PetHatcher`. For a Roblox script, the same name it will have in the
  Explorer.
- **At most 24 characters** before the extension.
- **PascalCase** for game scripts and modules (matches Roblox naming);
  lowercase is fine for an executor script (`hub.lua`, `autofarm.lua`).
- **Extension**: `.luau` for Studio and Rojo projects, `.lua` for executors
  and when the user's tool expects it. `.txt` only when the host cannot attach
  code files.
- **No spaces**, no punctuation except `-` or `_` between words when
  lowercase.

## Never in a file name

| Word | Why |
|---|---|
| `final`, `fixed`, `updated`, `new`, `complete`, `working` | Every version claims it; the next one needs "final2" |
| `v2`, `v3`, dates, times | Versions belong in the reply or version control |
| `script`, `code`, `file`, `roblox` | Every file here is one |
| The user's request as a sentence | `make_my_ui_look_better.lua` |
| The model or tool name | Provenance belongs in the reply, not the file |

## Several files

Name each for its role, the same way: `ShopUI.luau`, `ShopServer.luau`,
`ShopConfig.luau`. A folder or archive is the feature's name: `Shop.zip`.

## Replacing a file

Same name as before. The user replaces the old file; a new name makes them
wonder which one is current.
