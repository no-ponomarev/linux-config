# Project setup on a cluster

General rules for getting development projects onto a cluster after the
environment from [SETUP.md](SETUP.md) is in place. Project-specific layouts
(dev and testing directories) will be added below as separate sections.

## General rules
- **Clone from git, don't copy working trees.** Use `git clone` on the cluster
  (credentials come from `~/.netrc`). Only rsync when the cluster has no access to
  the git host; then exclude build outputs (`build/`, `_install/`, `*.o`, …) and
  copy `.git` along so the result is a real clone.
- **Keep sources under `~/dev/<project>/`** unless the cluster requires a
  different filesystem (e.g. a project/scratch area with more space or faster
  I/O). If so, put the clone there and add a symlink in `~/dev/`.
- **Build on the cluster.** Builds are machine-specific (compilers, MPI, GPU
  drivers, modules); never copy build directories between machines.
- **Branches and remotes:** keep the same remotes as on other machines
  (`origin` = my fork, `upstream` = the main repo where applicable) so work can
  move between clusters through git.
- **Per-cluster environment** (modules, compiler/MPI paths, proxy exceptions)
  goes into that machine's `~/.bashrc.local`, not into `.bashrc` in this repo.
- **Secrets:** never put tokens into project files, scripts or commit messages.

## Instructions for an AI agent
1. Ask which projects to set up if not specified.
2. For each project: check whether it already exists on the cluster; if so,
   `git fetch` and report its status instead of re-cloning.
3. Clone into the agreed location, set up the remotes, check out the requested
   branch.
4. Don't build or run tests unless asked; report what was done.

## Projects

_Project-specific dev and testing layouts will be added here later._
