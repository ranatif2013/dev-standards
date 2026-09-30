# dev-standards — ek hi tareeqa, har project, har server

Har project (isp-saas, NEXORA, client projects) aur har agent (Claude, Codex, NEXORA) isi standard par chalta hai.
Is repo mein koi secret nahi hai.

## Servers ka kaam
| Server | Kaam | Tools |
|---|---|---|
| **machine03** | Development — agents yahan code likhte hain, har kaam ki alag branch | `ops-setup-dev`, `ops-clone`, `ops-adopt` |
| **machine02** | Production — sirf GitHub `main` chalta hai | `ops-link`, `ops-deploy` |

Code ka raasta: **machine03 branch -> GitHub PR -> CI green -> Rana merge -> `ops-deploy` on machine02**.

## Ek dafa: tools install (dono servers)
```bash
git clone https://github.com/ranatif2013/dev-standards ~/dev-standards && bash ~/dev-standards/install.sh && source ~/.bashrc
```
Update: `git -C ~/dev-standards pull && bash ~/dev-standards/install.sh`

## machine03 (development)
| Command | Kya karta hai |
|---|---|
| `ops-setup-dev` | Ek dafa. Ek SSH key banata hai; woh GitHub -> Settings -> SSH keys mein add karein. Phir saare repos accessible |
| `ops-clone <repo>` | Project `~/projects/<repo>` mein laata / update karta hai |
| `ops-adopt` | Project folder ke andar: missing standard files (AGENTS.md, .planning, REGRESSIONS, CI) add karke branch push karta hai. Kuch overwrite nahi karta |

## machine02 (production)
| Command | Kya karta hai |
|---|---|
| `ops-link <repo> <app_dir>` | Har project ke liye ek dafa. Read-only deploy key (GitHub -> repo -> Settings -> Deploy keys, write OFF). Server ka code GitHub ke kisi commit se match na kare to ruk jata hai. Running app ko nahi chhedta |
| `ops-deploy <repo>` | Backup (.env, build, DB) -> code -> build -> restart -> health checks. Kuch fail ho to **khud rollback** |
| `ops-deploy <repo> --rollback <dir>` | Manual rollback |
| `ops-deploy <repo> --allow-migration` | Sirf jab release mein DB change ho aur Rana ne "approved" likha ho |

Har project ki settings: `~/ops/projects/<repo>.env` (health URL, build command, DB dump...).

## Naya project
1. GitHub par repo banayein (ya purana).
2. machine03: `ops-clone <repo> && cd ~/projects/<repo> && ops-adopt` -> PR merge.
3. `main` protection: on the free GitHub plan, branch rules are NOT enforced on private repos. Protection = AGENTS.md rules + CI. If any agent ever pushes to `main` directly, upgrade to GitHub Pro and add the rule (PR + status check `check`).
4. Live karna ho to machine02: `ops-link <repo> <app_dir>`, phir `ops-deploy <repo>`.

## Template (`template/`)
`AGENTS.md` (rules for all agents), `CLAUDE.md`, `.planning/STATE.md` + `PROJECT.md` (short state, so new chats don't re-read history), `docs/REGRESSIONS.md` (fixed bugs never come back), `.github/workflows/ci.yml` (Node/Python checks), PR template.
