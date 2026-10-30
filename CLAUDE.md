# Pokespire (Godot 4.7, GDScript)

Roguelike deckbuilder: Slay the Spire run structure, Hearthstone-style
combat, with Pokémon as the creatures.

## Architecture rules
- `logic/` is pure rules (RefCounted, no nodes, no scenes). The UI never
  changes state directly. It calls play_card / attack / use_move / end_turn
  and redraws from CombatState signals.
- `data/` holds Resource classes and the .tres content (pokemon, moves,
  abilities, effects). Content is data-driven: new cards/abilities should be
  a .tres, not new code, wherever possible.
- Use enums, not strings, for types/statuses/target modes.
- Tests: `tests/` (TestKit, TestRec, test_*.gd), run via scenes/main.tscn.
  Every scenario builds its own CombatState. Keep all tests passing.

## Combat rules (decided)
- Hero HP plus a board of up to 5 Pokémon per side. Energy 3 per turn.
- Pokémon can't attack the enemy hero while the enemy has Pokémon on board.
- Overkill damage spills to the owner's hero. Spill applies to basic attacks
  and single-target moves. It never applies to AOE, status damage or retaliation.
- Basic attacks trade (defender retaliates). Moves do not trigger retaliation.
- One action per turn per unit: basic attack OR move. Summoning sickness
  unless Quick.
- Moves can have `bypass` (may hit the hero through a board). Charge/two-turn
  moves were cut.
- Type chart is steps (+1/0/-1), applied to moves only. Basic attacks and hero
  hits are untyped. Dual types sum then clamp.
- Burn: -1 attack, 1 damage at owner's turn end. Paralysis: unit loses its
  next turn. No stacking. A status applied during its owner's own turn needs
  turns+1 (the end-of-turn tick eats one).
- Abilities are Resources with triggers (reusing Effect bricks) and passive
  fields. Hooks fire via CombatState.fire / modify.

## Game design (decided, not built yet)
- Wild Pokémon = normal enemies (Spire-style intents). Trainers = elites.
  Gym leaders = bosses.
- After combat: choose 1 of 3 cards, one always a random defeated wild species
  (base form). Skip allowed.
- Rest site: heal, evolve (evolution is a deck upgrade, no evolution cards),
  or equip a held item. Equipping over an item destroys the old one.
- Held items drop from battles or appear in shops.

## Next up
1. Refactor statuses into data-driven StatusData resources (hook sources like
   abilities). Keep all 128 tests passing.
2. First combat scene (hot-seat), then enemy AI, then run layer.