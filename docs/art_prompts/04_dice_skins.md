# Dice skins

**Nothing is missing.** Every playable pantheon has its dice, and so do the eight next pantheons
(`Godot/assets/images/dice-wars/dice/`, cut into faces by `tools/prepare_assets.py`):

aztec, celtic, chinese, egyptian, greek, inca, inuit, japanese, mayan, mesopotamian, norse, persian, polynesian,
slavic, yoruba.

A new sheet must keep the layout and **count-coding** of the existing ones, because the game reads each die's value
from its picture: three faces across, two down; 1 emblem, 2 crossed weapons, 3 creatures, 4 pillars, 5 objects in a
circle, 6 a sun of rays. Add it to `DICE_SKINS` in `tools/prepare_assets.py` and run the script.
