# Setting up a machine

Companion to [README.md](README.md) (what the setup is and how it works). Uses
this repo, [linux-config](https://github.com/no-ponomarev/linux-config), and [nvim-config](https://github.com/no-ponomarev/nvim-config).

## Local (WSL2 laptop)
1. Windows Terminal font: **Hack Nerd Font**.
2. `git clone https://github.com/no-ponomarev/linux-config.git ~/etc/linux-config`
   and copy `.bashrc`, `.gitconfig`, `.tmux.conf` to `~/` (back up existing ones first).
3. tmux ≥ 3.4, then tpm:
   `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`,
   start tmux, press `C-a I` to install plugins.
4. Put the files that aren't in any repo in place (see the table in
   [README.md](README.md#files-that-are-not-in-any-repo-copy-them-separately-carefully)),
   `chmod 600` for the secret ones.
5. nvim: `git clone https://github.com/no-ponomarev/nvim-config.git ~/.config/nvim`
   and follow its README ([nvim-config](https://github.com/no-ponomarev/nvim-config)).

## Remote cluster ("push the env") — instructions for an AI agent

Goal: make a fresh cluster account match this setup so I can ssh in from local
tmux and open VS Code Remote on it. Run from the **laptop**, target host
`<host>` (an alias from `~/.ssh/config`).

Rules for the agent:
- Be idempotent; re-running must be safe. **Back up** any existing remote file
  before overwriting (`<file>.bak-<timestamp>`).
- **Never print, log or commit secrets** (`.bashrc.secrets`, `.netrc`,
  `~/.claude/settings.json`) — not even variable names/values in reports. Copy them
  with `scp`/`rsync` and set `chmod 600` on the remote.
- Do **not** install tmux or tpm on the cluster (tmux is local only).
- Check before acting, report what was done/skipped at the end.

Steps:
1. **Probe the host:** `ssh <host> 'echo $SHELL; ldd --version | head -1; uname -m;
   which git gcc curl; curl -sI https://github.com >/dev/null && echo internet'`.
   Shell must be bash. Note glibc version and whether GitHub is reachable
   (the `.bashrc` proxy may be needed).
2. **Shell + git config:** copy `.bashrc` and `.gitconfig` from this repo to `~/`.
3. **Login shell must load `.bashrc`** (ssh and VS Code Remote start login
   shells; VS Code takes its environment — including the secrets — from it). If neither `~/.bash_profile` nor `~/.profile` sources `~/.bashrc`, add to
   `~/.bash_profile` (or `~/.profile` if that's what exists):
   `[ -f ~/.bashrc ] && . ~/.bashrc`
4. **Secrets:** copy `~/.bashrc.secrets` and `~/.netrc` → `chmod 600`.
5. **Claude:** copy `~/.claude/settings.json` (create `~/.claude/`). Claude Code
   on the cluster (CLI and the VS Code extension) takes its credentials from
   the environment set by `~/.bashrc.secrets`.
6. **Tools into `~/bin/<tool>/`** (see the [nvim-config](https://github.com/no-ponomarev/nvim-config) README for URLs; prefer
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
9. **Projects:** set up project repos as described in [PROJECTS.md](PROJECTS.md).
10. **Verify** (report results):
    - `ssh <host> 'bash -lic "echo \$TERM; type -t __build_prompt; [ -r ~/.bashrc.secrets ] && echo secrets-readable; nvim --version | head -1"'`
    - Open a local tmux window, `ssh <host>`: prompt shows the host in its
      cluster colour, tmux status shows remote host/dir.
    - In nvim on the host: `:checkhealth`, and `"+y` lands in the Windows
      clipboard.
    - `claude --version` (if installed) works without login prompts.

## Pulling updates later
- Laptop: edit `~/.bashrc` / `~/.gitconfig` / `~/.tmux.conf`, copy them into
  this repo, commit, push. nvim: commit/push in `~/.config/nvim`.
- Cluster: re-run steps 2, 7–8 (or `git -C ~/.config/nvim pull` +
  `nvim --headless "+Lazy! restore" +qa`).
