# linux-config

My shell and terminal environment: a local WSL2 laptop plus any number of remote
Linux clusters, all running the same setup. This repo is the **source of truth**
for the shell/tmux side. It works together with a second repo:

| Repo | What | Installed to |
|---|---|---|
| **[linux-config](https://github.com/no-ponomarev/linux-config)** (this one) | `.bashrc`, `.gitconfig`, `.tmux.conf`, this README | `~/` |
| **[nvim-config](https://github.com/no-ponomarev/nvim-config)** | Neovim config (lazy.nvim, catppuccin, lualine, neo-tree, fzf-lua, treesitter, which-key) | `~/.config/nvim` |

The [nvim-config](https://github.com/no-ponomarev/nvim-config) repo has its own README with tool downloads (nvim, ripgrep, fd,
bat, tree-sitter CLI) and its file layout. **Both repos are needed** for the full
environment. Step-by-step setup (laptop and clusters, including instructions for
an AI agent) is in **[SETUP.md](SETUP.md)**.

---

## The workflow

```
Windows laptop
└─ Windows Terminal (font: Hack Nerd Font)
   └─ WSL2 (Ubuntu) ── ~/.bashrc, ~/.tmux.conf          ← "local"
      └─ tmux (local only, prefix C-a)
         ├─ window: local shell
         ├─ window: ssh jfbmg   ── ~/.bashrc, ~/.config/nvim  ← "remote"
         ├─ window: ssh aurora  ── …
         └─ …

VS Code (Windows) ── Remote-SSH ──> cluster
   └─ main development, mostly oneCCL (`oneccl-v2-fork`)
   └─ Claude Code extension runs ON THE CLUSTER
      (needs the Claude settings and credentials there)
```

- **Main development** happens in VS Code opened on the remote cluster, mostly on
  the oneCCL project `oneccl-v2-fork`. The Claude Code VS Code extension runs on
  the cluster, so the cluster must have the Claude settings and credentials.
- **nvim** is a helper editor, used on the clusters over `ssh` from local tmux.
- **tmux runs only locally.** Clusters do not need tmux; every ssh session is a
  window/pane of the local tmux.
- Locally (WSL2) VS Code is used for editing; nvim isn't the main editor there.

---

## What's in each file

### `.bashrc` (local **and** remote — same file everywhere)
- **Portable:** uses `$HOME` (no hard-coded paths), `path_prepend` skips missing
  dirs, WSL-only parts gated by `IS_WSL` (detected from `/proc/version`).
- **TERM fallback:** if the machine has no terminfo for `$TERM` (e.g.
  `tmux-256color` coming from local tmux), switches to `xterm-256color`.
- **Tools on PATH:** `~/bin/{nvim,ripgrep,fd,bat,tree-sitter}`, `~/.local/bin`.
  `EDITOR=nvim`, `vim`/`vi` aliases.
- **Proxy:** Intel `proxy-dmz.intel.com:912` (`http_proxy`/`https_proxy`). If a
  cluster must not use it, unset it in that machine's `~/.bashrc.local`.
- **History, readline, colours, aliases, `extract`, `mkcd`, fzf integration.**
- **Prompt:** two-line `╭─ user@host  dir  ⎇ branch  (env)` / `╰─❯`.
  - **Per-cluster host colour:** laptop = blue; every other host gets a stable
    colour derived from its hostname with trailing node numbers stripped, so all
    nodes of one cluster match. Override on a machine with
    `PROMPT_HOST_COLOR=<0-255>` in `~/.bashrc.local`.
  - Sets the **terminal title** to `user@host: dir`; local tmux reads it to show
    the remote host/dir (see below).
  - git branch via `git-prompt.sh` (Debian/Ubuntu and RHEL/SUSE paths).
- **Secrets are NOT in this file.** It sources `~/.bashrc.secrets` (private
  environment variables) and derives `GH_TOKEN` from `~/.netrc`.
- **Machine-local overrides:** `~/.bashrc.local` (not tracked).
- **conda (miniforge in `~/bin/miniforge`):** loaded only if installed; `base`
  is not auto-activated.

### `.gitconfig` (local **and** remote)
- Name/email, `core.editor = nvim`.
- Intel proxy for `https://github.com` and `https://lfs.github.com` only (other
  hosts go direct). Credentials for https come from `~/.netrc` (read by git
  automatically) — no credential helper needed.

### `.tmux.conf` (local only)
- Prefix **`C-a`**, mouse on, 50k scrollback, vi copy mode, new panes/windows
  open in the current dir, `C-a r` reloads.
- **Theme:** rounded "pill" status bar (needs a Nerd Font), colours match the
  prompt. Session pill turns yellow while the prefix is pressed.
- **SSH-aware status bar:** when the active pane runs `ssh`, the right side shows
  the **remote** dir and host (yellow, globe icon), parsed from the pane title
  set by the remote `.bashrc`, and windows are auto-named after the remote host.
  If the remote host doesn't have this `.bashrc` yet, it shows `ssh`.
- **Clipboard:** `set-clipboard on` so programs (nvim over ssh) can copy to the
  Windows clipboard via OSC 52. `y` in copy mode copies via tmux-yank.
- **Plugins (tpm):** tmux-yank, tmux-resurrect.
- Uses tmux ≥ 3.4 options (`menu-border-lines`, `pane-border-indicators`, …).

### nvim (from nvim-config) — relevant cross-repo points
- Over SSH (`$SSH_TTY` set) `"+y` copies to the local Windows clipboard via
  OSC 52 → local tmux → Windows Terminal. `"+p` returns nvim's last yank;
  paste from Windows with `Ctrl+Shift+V`.
- nvim-treesitter (`main` branch) builds parsers with the `tree-sitter` CLI and
  `gcc`.

---

## Files that are NOT in any repo (copy them separately, carefully)

| File | Contents | Needed on |
|---|---|---|
| `~/.bashrc.secrets` | private environment variables (API tokens, e.g. for Claude) | laptop + every cluster |
| `~/.netrc` | git hosting credentials (also used for `GH_TOKEN`) | laptop + every cluster |
| `~/.claude/settings.json` | Claude Code settings (provider/environment, UI) | laptop + every cluster |
| `~/.ssh/config` | host aliases, keepalive, `ControlMaster` connection sharing | laptop (WSL) only |
| `~/.bashrc.local` | per-machine overrides (`PROMPT_HOST_COLOR`, proxy, …) | as needed |

Rules: **`chmod 600`** for `.bashrc.secrets` and `.netrc`; never print the
contents of any of these files, never commit them, never paste them into logs
or chat.

Note: VS Code on Windows uses Windows' own ssh and `C:\Users\<me>\.ssh\config`,
not the WSL one.

---

## Cheat sheet

| Keys | Action |
|---|---|
| `C-a` | tmux prefix |
| `C-a c` / `C-a "` / `C-a %` | new window / split below / split right (current dir) |
| `C-a [` then `?` / `/`, `n`/`N`, `q` | scrollback search up/down, next/prev, quit |
| copy mode `v`, `C-v`, `y` | select, block select, copy to Windows clipboard |
| `C-a f` / `C-a w` | find window / tree of windows |
| `C-a r` | reload tmux config |
| nvim `<Space>` | which-key popup with all leader mappings |
| nvim `<Space>f` / `b` / `g` | files / buffers / live grep (fzf-lua) |
| nvim `<C-n>` | file explorer (neo-tree float) |
| nvim `<C-h>` / `<C-l>`, `<Space>w`, `<Space>s` | prev/next buffer, close buffer, save |
| nvim `"+y` (over ssh) | copy to Windows clipboard |
