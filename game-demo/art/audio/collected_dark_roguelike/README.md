# Dark Guofeng Roguelike Card Audio Candidates

This folder collects audio candidates for a dark Chinese-fantasy roguelike card game.

## Folder Map

- `bgm/`: downloaded BGM candidates from OpenGameArt.
- `sfx_packs/`: downloaded and extracted SFX packs from OpenGameArt.
- `source_archives/`: original zip archives for traceability.
- `THIRD_PARTY_AUDIO.md`: source URLs, license notes, and attribution text.

## Recommended BGM

| File | Best use | Mood | License |
| --- | --- | --- | --- |
| `bgm/demon_lord_scrabbit_ccby40.mp3` | boss / elite combat | bombastic dark boss | CC-BY 4.0 |
| `bgm/boss_battle_2_symphonic_metal/boss_battle_#2_metal_loop.wav` | boss loop | aggressive orchestral metal | CC0 |
| `bgm/fall_of_nightmares_orchestral_mastered.wav` | main menu sting / boss intro | choir, brass, dark epic | CC0 |
| `bgm/no_more_magic_horrorpen_ccby30.ogg` | map / story / event | cinematic dark fantasy | CC-BY 3.0 |
| `bgm/the_dark_amulet_matthew_pablo_ccby30.mp3` | enemy spellcaster / elite combat | dark mage, occult | CC-BY 3.0 |
| `bgm/battle_theme_wolfgang_cc0.mp3` | normal combat | tense orchestral | CC0 |
| `bgm/vampires_piano_tad_cc0.mp3` | rest / shop / cursed event | loopable sad dark piano | CC0 |
| `../dark_theme_jaggedstone.ogg` | dungeon ambience / old main menu | spooky dark | CC0 |

## Recommended SFX

| Need | Files to audition first |
| --- | --- |
| Draw card / inspect card | `sfx_packs/Cardsounds/cockatrice/draw.wav`, `sfx_packs/80-CC0-RPG-SFX/book_01.ogg` to `book_04.ogg` |
| Play card | `sfx_packs/Cardsounds/cockatrice/playcard.wav`, `sfx_packs/kenney_casino-audio/Audio/card-place-*.ogg` |
| Shuffle / deck movement | `sfx_packs/Cardsounds/cockatrice/shuffle.wav`, `sfx_packs/kenney_casino-audio/Audio/card-shuffle.ogg`, `card-slide-*.ogg` |
| Hover / select / tap | `sfx_packs/Cardsounds/cockatrice/tap.wav`, `untap.wav`, `sfx_packs/kenney_casino-audio/Audio/card-fan-*.ogg` |
| Sword / slash cards | `sfx_packs/80-CC0-RPG-SFX/blade_*.ogg`, `sfx_packs/battle_sound_effects_0/battle_sound_effects/swish_*.wav` |
| Spell / demonic skill | `sfx_packs/80-CC0-RPG-SFX/spell_*.ogg`, `spell_fire_*.ogg`, `sfx_packs/Magic SFX Preview Pack/*.wav` |
| Ritual / guofeng hit accent | `sfx_packs/100-CC0-SFX/gong_*.ogg`, `bell_*.ogg`, `metal_*.ogg` |
| Hit / block / impact | `sfx_packs/100-CC0-SFX/hit_*.ogg`, `slam_*.ogg`, `sfx_packs/80-CC0-RPG-SFX/metal_*.ogg` |
| Reward / loot / shop | `sfx_packs/80-CC0-RPG-SFX/item_coins_*.ogg`, `item_gem_*.ogg`, `sfx_packs/kenney_casino-audio/Audio/chips-*.ogg` |

## Online Guofeng BGM Candidates

These Pixabay tracks have stronger Chinese / oriental color than the downloaded OpenGameArt tracks. They are linked for audition and possible project integration, but the raw files are not mirrored here because the Pixabay license forbids distributing unmodified content as standalone files.

- [China Chinese Epic Music](https://pixabay.com/music/action-china-chinese-epic-music-348422/) by Tunetank: direct Chinese epic action cue.
- [Mountains And Rivers Have Dreams](https://pixabay.com/music/china-mountains-and-rivers-have-dreams-2-min-edit-chinese-cinematic-459976/) by kaazoom: majestic Chinese cinematic.
- [On Misty Mountains](https://pixabay.com/music/china-on-misty-mountains-2-min-edit-chinese-cinematic-459986/) by kaazoom: calmer Chinese cinematic exploration.
- [Dark Cinematic Oriental Action Music | Dark Frame](https://pixabay.com/music/arabic-dark-cinematic-oriental-action-music-dark-frame-508494/) by OpenMindAudio: darker oriental action, but Arabic-leaning rather than Chinese.
- [China Epic Background Music](https://pixabay.com/music/build-up-scenes-china-epic-background-music-349892/): Chinese epic background candidate.
- [Dark suspense score with deep Taiko drum strikes](https://pixabay.com/music/crime-scene-dark-suspense-score-with-deep-taiko-drum-strikes-415948/): useful for boss tension, more Japanese percussion than Chinese.

## Integration Notes

- Prefer OGG or WAV for Godot loops. Convert MP3 BGM to OGG after final selection.
- Keep BGM around `-12 dB` to `-16 dB` under combat SFX, then duck briefly when cards resolve.
- For card play, layer a dry card sound with a low gong or spell tail on rare / demonic cards.
- For CC-BY tracks, add credits exactly as listed in `THIRD_PARTY_AUDIO.md`.
