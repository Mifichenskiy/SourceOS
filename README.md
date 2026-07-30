# SourceOS

**A Minecraft Operating System** — secure shell with JSON-based user database, sudo/wheel permission system, a plugin architecture, and a built-in shop POS system, built entirely in Lua for CraftOS (ComputerCraft).

> v1.0.0 — *"Release"*

## Features

- **Multi-user authentication** with a login/password system stored in `users.json`
- **Root & wheel group permissions** — classic Unix-style privilege separation
- **Cashier-friendly** — standard (non-wheel) accounts get just enough access to run the shop (`stock`, `sell`) with zero visibility into admin/staff commands
- **sudo** — run commands with elevated privileges (wheel members only)
- **Plugin system** — add custom commands on the fly via `cmadd`, stored in `/plugins_source/`
- **pms** — a minimal package manager that installs plugins from a remote GitHub manifest (root only)
- **Shop / POS system** — sell items, track stock and prices, and log every sale
- **Redstone control** — toggle redstone output on any side (staff only), with permission-based auto-off timers:
  - `root` — signal stays on indefinitely
  - `wheel` — up to 7 seconds
  - standard users — up to 3 seconds
- **sourcefetch** — neofetch-style system info screen
- Built-in file editing via `vim`/`nvim` (wraps CraftOS's native editor, staff only)

## Installation

1. Copy `Source.lua` to the root of your ComputerCraft computer's file system.
2. Run it:
   ```
   Source
   ```
3. On first launch, a default `users.json` will be created automatically with sample accounts. **Change these passwords immediately** (see below).

## Default accounts (change these!)

| User | Wheel | Password |
|------|-------|----------|
| root | Yes | *(set in `users.json` — change on first login)* |
| toha | Yes | t2x2_streamer |

> Log in as `toha` to add your own account: `sudo useradd <user>`, `sudo passwd <user>`, and `wheel <user> add/remove`. Then change every default password with `passwd`.

## Commands

### Everyone
| Command | Description |
|---|---|
| `clear` | Clear the screen |
| `ls` | List files and installed plugins |
| `cat [file]` | Print file contents (blocks reading `users.json` unless root) |
| `stock` | View shop catalog — items, prices, and stock |
| `sell [item] [qty]` | Sell an item, deduct stock, log the sale |
| `sourcefetch` | Show system info |
| `help` | List commands available to your role |
| `exit` | Log out |

### Staff (`wheel`)
| Command | Description |
|---|---|
| `vim` / `nvim [file]` | Edit or create a file |
| `cmadd` | Create a new custom command/plugin |
| `additem [item] [price] [qty]` | Add a new product to the shop catalog |
| `setprice [item] [price]` | Change an item's price |
| `restock [item] [qty]` | Add stock to an existing item |
| `sales` | View the sales log and grand total |
| `redstone` / `rs [side] [on\|off] [time]` | Control redstone output |
| `sudo [command]` | Run a command as root |

### Root only
| Command | Description |
|---|---|
| `useradd [user]` | Create a new user |
| `passwd [user]` | Change a user's password |
| `wheel [user] [add\|remove]` | Grant/revoke staff privileges |
| `pms [list\|install\|remove\|installed]` | Install/remove plugins from the remote package manifest |

## Plugins

Custom commands live in `/plugins_source/` as `.lua` files. Add one interactively with `cmadd`, install one via `pms install <name>` (if a manifest is configured), or drop a script named `mycommand.lua` into the folder to make `mycommand` available as a shell command.

## Project structure

```
/Source.lua              -- main kernel/shell
/users.json               -- user database (gitignored — don't commit real passwords!)
/shop_inventory.json       -- shop catalog: items, prices, stock (gitignored)
/sales_log.json            -- sales history (gitignored)
/plugins_source/            -- custom command plugins
```

## Disclaimer

This is a hobby project built inside Minecraft using ComputerCraft. It is not a real operating system and has no relation to actual OS security — passwords are stored in **plaintext JSON**, so don't reuse real-world passwords here.

## License

MIT — do whatever you want with it.

---

*Developed by Mifichenskiy*
