
# Red Covenant — Source

Comprehensive Luau (Roblox) source for the Red Covenant project. This repository contains shared modules, server controllers, a modular hitbox system, networking/packet utilities, a state machine, AI/passive systems, and small packaged utilities used across the experience.

## Table of contents

- Project overview
- Requirements
- Quick start
- Repository layout
- Notable modules
- Development & tooling
- Contributing
- License & contact
- Notes & next steps

## Project overview

This repo is organized to keep shared code in `ReplicatedStorage` (so both client and server can require it), server-only behavior under `ServerScriptService`, and client bootstrap code under `StarterPlayer`. The codebase favors small, well-scoped modules (state machines, packet utilities, hitbox solvers) so features are composable and testable.

## Requirements

- Roblox Studio (for running and testing the place)
- A sync tool like Rojo or Aftman if you prefer source-driven workflow (this repo includes `aftman.toml`)
- (Optional) Selene for linting (`selene.toml` is included)

## Quick start

1. Open the project in Roblox Studio, or use Rojo/Aftman to sync files into a place file.
2. Start a Play session in Studio to run server scripts in `ServerScriptService`.
3. Use StarterPlayer scripts to exercise client behavior.

Example developer commands (run in PowerShell if you have tools installed):

```powershell
# Lint with Selene (if installed)
selene .

# Build with Aftman (if configured)
aftman build

# Example Rojo usage (if using Rojo)
rojo build -o output.rbxm
```

> Note: Commands above require the respective tools installed and available on PATH.

## Repository layout

Top-level structure (high level):

- `aftman.toml`, `selene.toml`, `default.project.json`, other config files
- `src/`
	- `ReplicatedStorage/Shared/`
		- `Stats.lua` — Character stat management
		- `Data/`
			- `ItemDatabase.lua` — Item metadata and accessors
		- `General/`
			- `Formulas.lua`, `Maid.lua`, `TableUtil.lua` — utility helpers
		- `Hitbox/`
			- `ShapecastHitbox/` — Hitbox core, solvers (Raycast, Spherecast, Blockcast), visualizers, types and settings
		- `Networking/`
			- `Packets.lua` — packet definitions and helpers
		- `Packages/`
			- `GoodSignal.lua`, `Promise.lua`, `Packet/`, `RobloxStateMachine/` — packaged libs and small frameworks
		- `Ragdoll/`
			- `RagdollModule.lua` — ragdoll utilities and integration
	- `ServerScriptService/`
		- `CharacterLoader.lua`
		- `PlayerDataTemplate.lua`
		- `Entity/` — controllers and managers (CharacterController, EquipmentController, PassiveController, PassiveRegistry, StateManager, etc.)
		- `AdminHandler/` — admin commands and utilities
	- `StarterPlayer/`
		- `StarterCharacterScripts/`, `StarterPlayerScripts/` — client-side bootstrap and scripts

There are also `.meta.json` files in many folders for tooling/metadata.

## Notable modules & responsibilities

- Hitbox system (`Hitbox/`): multiple solver strategies (raycast, spherecast, blockcast), bone/attachment-aware checks, and debug visualizers.
- Networking/Packet system (`Packet/` and `Networking/`): small packet/signal abstraction used for predictable messaging between client and server.
- RobloxStateMachine: state & transition classes used by entities and AI.
- Packages: Promises and GoodSignal for simpler async and event flows across the codebase.

## Development & tooling

- Linting: `selene.toml` is included. Run `selene .` to lint the repository.
- Sync: `aftman.toml` is present; use your preferred sync tool (Aftman or Rojo) to deploy files into a Roblox place.
- Style: Follow existing Luau conventions used across the repository. Aim to keep modules small and single-responsibility.

Developer checklist:

- Keep client-accessible modules inside `ReplicatedStorage/Shared`.
- Keep server-only logic in `ServerScriptService`.
- Add folder `.meta.json` files where needed to preserve metadata expected by the toolchain.

## Git Workflow Guide

This guide outlines the recommended workflow for maintaining a clean and manageable `main` branch.

1. Start New Work in a Feature Branch  
Create a new branch off `main` for each feature, bug fix, or improvement:

    git checkout -b feature/your-feature-name

2. Commit and Push Changes  
Make your changes, then commit with a clear message and push the branch:

    git add .
	
    git commit -m "Brief description of your changes"
	
    git push -u origin feature/your-feature-name

3. Create a Pull Request (PR)  
Open a PR to merge your feature branch into `main`.  
- Review your code carefully.  
- Squash or tidy commits if necessary.  
- Merge the PR only when ready and reviewed.

4. Keep `main` Up to Date  
Before starting new work, update your local `main` branch:

    git checkout main
    git pull origin main

5. Clean Up Branches  
After your PR is merged, delete the feature branch locally and remotely:

    git branch -d feature/your-feature-name
   
    git push origin --delete feature/your-feature-name

---

## License & contact

There is no license file included in this repository. Check with the repository owner for licensing and usage permissions before distributing or reusing this code. For questions, contact the repo owner/maintainer.
