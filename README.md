# linux-config

My shell and terminal environment: a local WSL2 laptop plus any number of remote
Linux clusters, all running the same setup. This repo is the **source of truth**
for the shell/tmux side. It works together with a second repo:

| Repo | What | Installed to |
|---|---|---|
| **linux-config** (this one) — `github.com/no-ponomarev/linux-config` | `.bashrc`, `.tmux.conf`, this README | `~/` |
| **nvim-config** — `github.com/no-ponomarev/nvim-config` | Neovim config (lazy.nvim, catppuccin, lualine, neo-tree, fzf-lua, treesitter, which-key) | `~/.config/nvim` |

The nvim-config repo has its own README with tool downloads (nvim, ripgrep, fd,
bat, tree-sitter CLI) and its file layout. **Both repos are needed** for the full
environment.

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
      (needs ~/.claude/settings.json + AWS_BEARER_TOKEN_BEDROCK there)
```

- **Main development** happens in VS Code opened on the remote cluster, mostly on
  the oneCCL project `oneccl-v2-fork`. The Claude Code VS Code extension runs on
  the cluster, so the cluster must have the Claude settings and Bedrock token.
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
- **Secrets are NOT in this file.** It sources `~/.bashrc.secrets` (holds
  `AWS_BEARER_TOKEN_BEDROCK`) and derives `GH_TOKEN` from `~/.netrc`.
- **Machine-local overrides:** `~/.bashrc.local` (not tracked).
- **conda (miniforge in `~/bin/miniforge`):** loaded only if installed; `base`
  is not auto-activated.

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
| `~/.bashrc.secrets` | `export AWS_BEARER_TOKEN_BEDROCK=…` (Claude via Bedrock) | laptop + every cluster |
| `~/.netrc` | `machine github.com login … password <token>` (git, `GH_TOKEN`) | laptop + every cluster |
| `~/.claude/settings.json` | `CLAUDE_CODE_USE_BEDROCK=1`, `AWS_REGION=us-east-2`, theme/tui | laptop + every cluster |
| `~/.ssh/config` | host aliases, keepalive, `ControlMaster` connection sharing | laptop (WSL) only |
| `~/.bashrc.local` | per-machine overrides (`PROMPT_HOST_COLOR`, proxy, …) | as needed |

Rules: **`chmod 600`** for `.bashrc.secrets` and `.netrc`; never print their
contents, never commit them, never paste them into logs or chat.

Note: VS Code on Windows uses Windows' own ssh and `C:\Users\<me>\.ssh\config`,
not the WSL one.

---

## Setting up a machine

### Local (WSL2 laptop)
1. Windows Terminal font: **Hack Nerd Font**.
2. `git clone https://github.com/no-ponomarev/linux-config.git ~/etc/linux-config`
   and copy `.bashrc`, `.tmux.conf` to `~/` (back up existing ones first).
3. tmux ≥ 3.4, then tpm:
   `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`,
   start tmux, press `C-a I` to install plugins.
4. Put the secret files in place (table above), `chmod 600`.
5. nvim: `git clone https://github.com/no-ponomarev/nvim-config.git ~/.config/nvim`
   and follow its README.

### Remote cluster ("push the env") — instructions for an AI agent

Goal: make a fresh cluster account match this setup so I can ssh in from local
tmux and open VS Code Remote on it. Run from the **laptop**, target host
`<host>` (an alias from `~/.ssh/config`).

Rules for the agent:
- Be idempotent; re-running must be safe. **Back up** any existing remote file
  before overwriting (`<file>.bak-<timestamp>`).
- **Never print, log or commit secrets** (`.bashrc.secrets`, `.netrc`). Copy them
  with `scp`/`rsync` and set `chmod 600` on the remote.
- Do **not** install tmux or tpm on the cluster (tmux is local only).
- Check before acting, report what was done/skipped at the end.

Steps:
1. **Probe the host:** `ssh <host> 'echo $SHELL; ldd --version | head -1; uname -m;
   which git gcc curl; curl -sI https://github.com >/dev/null && echo internet'`.
   Shell must be bash. Note glibc version and whether GitHub is reachable
   (the `.bashrc` proxy may be needed).
2. **Shell config:** copy `.bashrc` from this repo to `~/.bashrc`.
3. **Login shell must load `.bashrc`** (ssh and VS Code Remote start login
   shells; VS Code takes its environment — including the Bedrock token — from
   it). If neither `~/.bash_profile` nor `~/.profile` sources `~/.bashrc`, add to
   `~/.bash_profile` (or `~/.profile` if that's what exists):
   `[ -f ~/.bashrc ] && . ~/.bashrc`
4. **Secrets:** copy `~/.bashrc.secrets` and `~/.netrc` → `chmod 600`.
5. **Claude:** copy `~/.claude/settings.json` (create `~/.claude/`). Claude Code
   on the cluster (CLI and the VS Code extension) uses Bedrock with the token
   from `~/.bashrc.secrets`.
6. **Tools into `~/bin/<tool>/`** (see nvim-config README for URLs; prefer
   statically linked *musl* builds):
   - nvim: use the **`.tar.gz`** release (AppImages need FUSE, often missing).
     On old glibc use `neovim/neovim-releases`.
   - ripgrep, fd, bat (musl builds), tree-sitter CLI (needs a recent glibc;
     if it fails, see step 8).
   - fzf: `git clone --depth 1 https://github.com/junegunn/fzf ~/.fzf && ~/.fzf/install --all`
7. **nvim config:** `git clone https://github.com/no-ponomarev/nvim-config.git ~/.config/nvim`
   (or rsync it from the laptop if there's no internet).
8. **nvim plugins:**
   - With internet: `nvim --headless "+Lazy! restore" +qa` (versions pinned by
     `lazy-lock.json`), then let treesitter build parsers on first start.
   - Without internet: rsync `~/.local/share/nvim/lazy/` from the laptop. Parsers
     (`~/.local/share/nvim/site/parser/*.so`) are glibc-specific — rebuild on the
     cluster if possible; otherwise copy and test.
   - Without internet, also consider `checker = { enabled = false }` (lazy's
     update checker) to avoid background fetch failures.
9. **Projects:** clone repos (e.g. oneCCL `oneccl-v2-fork`) from git rather than
   copying working trees; if copying, exclude `build/` dirs.
10. **Verify** (report results):
    - `ssh <host> 'bash -lic "echo \$TERM; type __build_prompt; [ -n \"\$AWS_BEARER_TOKEN_BEDROCK\" ] && echo token-set; nvim --version | head -1"'`
    - Open a local tmux window, `ssh <host>`: prompt shows the host in its
      cluster colour, tmux status shows remote host/dir.
    - In nvim on the host: `:checkhealth`, and `"+y` lands in the Windows
      clipboard.
    - `claude --version` (if installed) works without login prompts.

### Pulling updates later
- Laptop: edit `~/.bashrc` / `~/.tmux.conf`, copy them into this repo, commit,
  push. nvim: commit/push in `~/.config/nvim`.
- Cluster: re-run steps 2, 7–8 (or `git -C ~/.config/nvim pull` +
  `nvim --headless "+Lazy! restore" +qa`).

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
