# Dungeon Puzzle Creator Standard (F13)

This is the mapper-facing standard for building reusable dungeon logic with:

- `code/modules/f13/dungeon_puzzle_kit.dm`

The goal is **high reuse, low custom code**.

## 1) Core Pieces

- **Doors**
  - Set `dungeon_channel` on all doors that should be controlled together.
- **Door Console**
  - Type: `/obj/machinery/f13/dungeon/door_console`
  - Required vars: `puzzle_id`, `door_channel`
- **Puzzle Nodes**
  - Type: `/obj/machinery/f13/dungeon/puzzle_node/*`
  - Required vars: `puzzle_id`, `node_id`
- **Trigger Anchors**
  - Type: `/obj/effect/f13/dungeon_trigger_anchor`
  - Optional logic/action extension points.

## 2) Naming Rules (Important)

Use deterministic lowercase names:

- `puzzle_id`: `<site>_<wing>_<purpose>`  
  Example: `vault7_lab_blastdoor`
- `node_id`: `<stage>_<role>_<index>`  
  Example: `alpha_fuse_1`, `beta_keypad_1`
- `door_channel`: match your door group exactly  
  Example: `vault7_lab_mainblast`

## 3) Baseline Mapper Setup

1. Place all target doors, set same `dungeon_channel`.
2. Place 1 door console:
   - set `puzzle_id` and matching `door_channel`.
3. Place puzzle nodes:
   - set same `puzzle_id`
   - unique `node_id` for each node.
4. Pick console logic mode (`logic_mode`) and thresholds.
5. (Optional) Add trigger anchors for side effects (spawns, messages, cross-puzzle wiring).

## 4) Supported Logic Modes

- `all`: all tracked nodes active.
- `any`: at least one active.
- `n_of_m`: at least `required_nodes`.
- `exact`: exactly `required_nodes`.
- `xor`: exactly one active.
- `sequence`: requires `required_node_ids_text` order.
- `simultaneous`: active within small window.
- `time_window`: active within wider configurable window.

Advanced filters:

- `required_node_ids_text`: only evaluate listed nodes.
- `forbidden_node_ids_text`: listed nodes must remain inactive.
- `use_weighted_logic = TRUE`: use node weights.
- `required_weight`: weighted threshold.

## 5) Node Toolkit

Common node vars:

- `node_weight`
- `required_interactions` / `current_interactions`
- `required_unique_users` / `unique_users`
- `requires_item_type` + `required_amount`
- `one_time`, `auto_deactivate_ds`, `activation_cooldown_ds`

Provided node types:

- `lever`
- `keypad`
- `item_socket`
- `multitool_patch`
- `pressure_plate`
- `timer`
- `fuse_box`
- `biometric_reader`

## 6) Trigger Anchor Actions

`trigger`: `solve`, `unsolve`, `reset`

`action` options:

- `open_doors`, `close_doors`, `cycle_doors`
- `message`, `message_global`, `sound`
- `spawn_item`, `spawn_mob`
- `set_node_on`, `set_node_off`, `toggle_node`
- `reset_puzzle`

Advanced runtime controls:

- `delay_ds`
- `cooldown_ds`
- `chance_percent`
- `one_shot`

Cross-puzzle wiring:

- Set `target_puzzle_id` + `target_node_id` for node actions.

## 7) Recommended Templates

### A) Classic Blastdoor (All Nodes)
- Console preset: `all_nodes`
- 3 nodes: `fuse_box`, `keypad`, `multitool_patch`

### B) Team Split Puzzle (Simultaneous)
- Console preset: `simultaneous`
- 3 pressure plates far apart
- `window_ds = 30..60`

### C) Weighted Grid Restore
- Console preset: `weighted`
- Multiple nodes with different `node_weight`
- Heavy nodes behind danger zones

### D) Fail-safe Sequence
- Console preset: `sequence`
- Add anchor on `unsolve` to close secondary doors
- Add reset console nearby for admins/mappers

## 8) Quality Checklist (Before Shipping)

- Every console has `puzzle_id` and `door_channel`.
- Every node has same `puzzle_id` and unique `node_id`.
- All target doors have correct `dungeon_channel`.
- At least one recovery/reset path exists.
- No hard softlock (e.g., consumed one-off item with no replacement).
- Add one diagnostics terminal:
  - `/obj/machinery/f13/dungeon/puzzle_debug_console`

## 9) Anti-Cheese Defaults

- Use `required_unique_users` for key progression nodes.
- Put high-value nodes on cooldown (`activation_cooldown_ds`).
- Use `forbidden_node_ids_text` where brute-force toggling is likely.
- Add anchor `cooldown_ds` for spawn actions.

## 10) Fast Troubleshooting

- Door won’t open:
  - check `door_channel` vs door `dungeon_channel`.
- Puzzle never solves:
  - inspect required/forbidden node IDs spelling.
- Random behavior:
  - check anchor `chance_percent`, `delay_ds`, `cooldown_ds`.
- Use diagnostics:
  - console option `Diagnostics`
  - or `puzzle_debug_console` output.

