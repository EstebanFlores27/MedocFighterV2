# Médoc Fighter — Game Spec (Organized)

> Synthesis of `Livrable F6.1 ...md` and `TRAVAIL P6.md`. Source docs remain authoritative; this file is the working reference for implementation.

## 1. Pitch

> "Dans un monde hostile qui réagit à chacun de tes choix, survivre ne dépend pas de ta force brute, mais de ton équilibre. Chaque combat est possible… à condition de rester stable."

Pedagogical 2D game about **adherence to chronic-disease treatment**. The player fights manifestations of disease (Chroniks) across a locked-down city. Continuity and regularity of treatment is the core lesson — taught through gameplay, not text.

## 2. Pedagogical goals

- Treatment is not a bonus; it is a **necessary condition** of staying functional.
- Counter false beliefs about stopping/altering treatment by showing in-game consequences.
- Build anticipation and self-regulation: plan, manage resources, sustain over time.
- Experiential, implicit learning. No quiz. No explicit pedagogical text mid-play.

## 3. Story (intro, Mini-Chronik dialogue)

- Opens on Seek City under a purple opaque energy dome. Player stands outside, in B&W (just diagnosed).
- **Mini-Chronik** (small friendly monster) is the guide.
- Goal: clear each district of its Chroniks to advance; the dome unlocks district by district.
- Player gets a starter med chest at the dome.
- After beating each district's final Chronik, unlocks the **Adrenaline Booster** (+70% HP) for the next zone.
- After each Chronik defeat → short pedagogical feedback (organ/system saved).

## 4. World structure — Seek City

4 districts, **10 Chroniks** total:

| # | District | Chroniks |
|---|----------|----------|
| 1 | Place centrale | Cortexia (cerveau), Epidermos (peau) |
| 2 | Centre commercial | Pancréok, Hépatox, Gastrix, Nefronix |
| 3 | Parc | Kardiox, Pulmos, Ostéox, Articulix |
| 4 | Hôpital | Boss final |

Sizing rule: last Chronik of each district = slightly larger than others; hospital boss = much larger.

## 5. Core mechanics

### 5.1 Combat & movement (primary)
- Side-scrolling 2D.
- Controls: ◀ ▶ to move, ▲ jump, ▼ duck, **punch** attack, **boîte à médicaments** to use a med.
- Player has an HP gauge; each Chronik has one too. Player attacks reduce monster HP; monster attacks reduce player HP.

### 5.2 Medication chest (primary)
Each district starts with a chest of **3 meds**:

| Med | Effect |
|---|---|
| Soin | +20% HP |
| Vitesse | ×2 movement speed |
| Force | ×2 attack power |

- **The chest does not refill within a district.** Player must ration across all Chroniks of that district.
- After the district's last Chronik falls, the chest refills and unlocks the **Adrenaline Booster** (+70% HP) for the next district.

### 5.3 Secondary mechanics
- **Indications trompeuses** — misleading hints (anti-misinformation theme).
- **Health state feedback** — HP bar + visual/audio cues (animations, ambiance shifts). No numbers shoved at the player.
- **Death / checkpoint return** — die → respawn at last checkpoint. Encourages learning by trial.
- **Personalization** — character classes: Combattant (more strength), Roublard (better loot recovery), Sportif (more endurance, less force).

### 5.4 Daily Boost (umbrella mechanic) — the "adherence" lever
- A daily chest, accessible **once per 24h** real-time.
- Streak system:
  - 3 days in a row → B&W → faded color (improved health).
  - 12 days in a row → faded color → vivid color (very good health).
- Better health state → HP gauge drops more slowly during combat (more resistance to monster attacks).
- This is the in-game embodiment of "take your treatment regularly".

### 5.5 Support mechanics
- Optional progressive tutorial (combat, crafting/using meds).
- Contextual hints for danger / missed treatment / critical drops — no lecture screens.
- Save & resume.
- Gradual difficulty progression.

## 6. Visual & audio

- 2D, retro style (Taken-inspired per the prompt notes), sober and symbolic.
- Player visual states: B&W (sick) → pastel desaturated → vivid (healthy).
- Music shifts with zone and player state; calm when stable, oppressive when stats drop.
- Distinct SFX for hits, movement, enemy attacks, environment.

## 7. Technical baseline

- **Engine:** Godot 4.6.2 (confirmed installed, connected).
- **Project:** currently empty (0 scenes, 0 scripts).
- `project.godot` has `Mobile` feature and `mobile` renderer → **mobile-targeted build**.
- Orientation: **landscape** (per doc spec).
- Physics engine: Jolt (currently set for 3D — not relevant for 2D, can revisit).
- Sprites: characters 256×256, ~4–5 heads tall.
- Background layers (combat scene): far 2880×1080, mid 2400×1080, near 1920×1080. Parallax.
- Mini-map: 200×200, top-right corner, 40 px margin.
- Touch controls:
  - Virtual joystick (left): 280×280 (detection 320×320).
  - Main attack (right): 220×220.
  - Secondary buttons: 180×180, arc around main.
  - Bottom margin 80 px; side margins 100–120 px. Opacity 60–75%.

## 8. Deliverables & deadlines

| ID | Item | Due |
|---|---|---|
| F6.1 | Design doc | 15/05 23h59 |
| **F6.2** | **Alpha executable** | **26/05 12h** |
| F6.3 | Cross audit (individual) | 29/05 9h |
| **F6.4** | **Final version (executable + source + 1-page description)** | **08/06 9h** |
| F6.5 | Reflective report (individual) | 09/06 9h |

Today: **2026-05-10**. Alpha is **~16 days out**; final ~29 days out.

## 9. Scope plan

### 9.1 Alpha (target: 26/05) — user-requested
- Main menu.
- City map view with **zoom** (overhead → district entry).
- Side-scroll movement (left/right/jump/duck).
- **1–2 functional fights** (HP bars, basic attack, basic med use, win/lose).

### 9.2 Beta / MVP (target: 08/06)
- Full game, **all 10 Chroniks + hospital boss**.
- Playable from tutorial (Mini-Chronik intro) → final boss.
- Med chest economy across districts.
- Daily Boost (real 24h gate or simulated).
- Save/resume + checkpoints.
- Health-state visual progression (B&W → pastel → vivid).
- Per-Chronik post-victory feedback text (already written in source doc).

## 10. Playtest feedback to incorporate

Recurring asks from Tests 1–3 in `TRAVAIL P6.md`:
- Clear "end of fight" signal ("Bravo!").
- "3, 2, 1, GO!" before combat starts.
- Joystick > directional buttons (more intuitive).
- Tutorial appears progressively, not all at once.
- Medication box explanation: meds are per-district; chest only refills after clearing the district.
- Color/state legend for the character.
- Show district progress (how many Chroniks left).
- Daily Boost concept was repeatedly unclear → needs strong onboarding.

## 11. Alpha — locked decisions (2026-05-10)

| Decision | Choice |
|---|---|
| Map style | Overhead city map (4 districts) with zoom → tap district → enter side-scroll level |
| Platform | Both keyboard (arrows + space/X) **and** touch (virtual joystick + buttons), landscape |
| Fight content | District 1 only — **Cortexia** + **Epidermos**, real names/feedback text, placeholder art |
| Daily Boost | Full real 24h-gated version with streak persistence (file save) |
| Art / audio | All placeholders (colored rects, simple shapes). Hot-swap when real assets land. |
| Intro | Full Mini-Chronik intro dialogue from `TRAVAIL P6.md` |
| Language | French only (no i18n wiring for Alpha) |

## 12. Alpha build plan — milestones (playtest-first order)

Working back from **F6.2 = 2026-05-26** (~16 days). Branch: `feature/julie`, one commit per milestone. Each step ends in a **runnable, testable artifact** so the team can playtest after every commit. Desktop-first (keyboard); Android export and touch tuning come at the end.

1. **Walkable level** — minimal scaffolding (autoloads, input map for both keyboard+touch) + a player rectangle you can move (◀▶▲▼) in a flat placeholder level with parallax bg. → *Playtest: does movement feel right?*
2. **First fight (Cortexia)** — Chronik encounter triggers, HP bars for both, punch attack, basic monster AI, "3,2,1,GO!" intro and "BRAVO!" outro, post-victory feedback text. → *Playtest: is the combat readable?*
3. **Med chest** — 3 meds (Soin/Vitesse/Force) usable mid-fight, no refill, basic inventory UI. → *Playtest: do players ration meds?*
4. **Second fight (Epidermos)** — second encounter in the same level, Adrenaline boost drops on victory. → *Playtest: does district 1 feel complete?*
5. **City map + main menu** — overhead city map with zoom (4 districts, only #1 unlocked), main menu (New Game / Continue / Quit), wire menu → map → district → combat → return. → *Playtest: end-to-end flow with placeholder art.*
6. **Mini-Chronik intro** — full dome scene + dialogue from `TRAVAIL P6.md`, skippable. → *Playtest: is the narrative framing landing?*
7. **Save / resume** — `user://save.cfg` persists district progress + character state; Continue button works. → *Playtest: does state survive a quit?*
8. **Daily Boost** — daily chest on map, real 24h gate via `Time.get_unix_time_from_system()`, streak persists, character tint shifts (B&W → pastel → vivid). → *Playtest: do players understand the adherence loop?*
9. **Touch controls polish + Android export** — tune virtual joystick + on-screen buttons per doc specs, export Android APK, test on a real device. → *Playtest: mobile build playable.*
10. **Pre-submission pass** — bug bash, final feedback text wiring, package F6.2 deliverable.

Risk items: combat feel with placeholder art (visual feedback may be unclear); touch joystick tuning on real device; 24h gate needs a mocked-clock debug switch for QA.

