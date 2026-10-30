# Game Specification: Mythological Dice Wars (Working Title)

## 1. Executive Summary
**Concept:** A turn-based strategy territorial conquest game heavily inspired by classic *Dice Wars* (*Dicewars*), reimagined with a mythological reskin, dice tower aesthetics, cross-platform responsiveness (PC & Mobile), and a strategic dual-god blessing system.
**Target Audience:** Strategy gamers, fans of quick-session tactical games (like *Risk* or *Dice Wars*), and mythology enthusiasts.
**Platforms:** Web Browsers (PC/Mac) and Mobile Devices (iOS/Android via responsive web or native wrapper).

---

## 2. Core Gameplay Loop
1. **Map Setup:** Players (2–8) are randomly placed across a generated mythological realm divided into territories (temples/regions). Each territory holds a starting dice stack (1–8).
2. **Turn Phase (Attack):** 
   * Players select an adjacent enemy territory from a controlled node that has $\ge 2$ dice.
   * A battle is resolved by rolling dice (represented via animated dice towers). 
   * Higher total sum wins. The winner occupies the territory, leaving 1 die behind and moving the rest.
3. **Reinforcement Phase:** At the end of a turn, players receive bonus reinforcement dice equal to the size of their **largest contiguous block of territories**.
4. **Victory Condition:** Conquer 100% of the map territories or eliminate all rival pantheons.

---

## 3. Key Unique Features

### A. The Dual-God System (Primary & Secondary)
Each player chooses a pantheon (e.g., Greek, Norse, Egyptian) and selects two gods:
* **Primary God:** Grants a permanent positive passive/active bonus with **zero negative drawbacks**. Chosen at game start.
* **Secondary God:** Grants a powerful secondary ability, but **comes coupled with a severe mechanical flaw/trade-off**. Unlocked mid-game through milestones or chosen alongside the primary.

### B. Land & Dice Tower Skins
* **Thematic Realms:** Visual styles adapt to chosen pantheons (e.g., Greek marble and olive groves vs. Norse frost and runestones).
* **Dice Towers:** Combat is visualized via 3D dice towers. Tall stacks are dynamically managed using numerical badges and collapsible 3D views to prevent visual clutter on smaller screens.

---

## 4. Technical & UI Specifications

### A. Cross-Platform Adaptability
* **Responsive Layout:** 
  * *Mobile (Portrait):* Map occupies the upper/center viewport; dice towers, god panels, and turn controls sit within thumb reach at the bottom.
  * *PC/Tablet (Landscape):* Expansive map view with sidebars for player stats, pantheon trackers, and reserve banks.
* **Touch & Mouse Controls:** 
  * Tap-to-zoom and drag-and-swipe gestures for fluid territory attacks on mobile touchscreens.
  * Precise hover/click navigation for desktop users.

### B. UI Stack Management
* **Clutter Reduction:** Territories with high stacks (6–8 dice) display a clean numerical badge/shield icon by default when zoomed out. Tapping or hovering expands the physical 3D dice tower and isolates the node.

---

## 5. Future Expansion Roadmap
* **Multi-Pantheon Crossovers:** Allowing mixed pantheon matches (e.g., Zeus vs. Odin).
* **Divine Miracles / Spells:** Consumable power-ups earned through faith/combat loss.
* **Single-Player Campaign:** Era-by-era historical/mythological conquests.