# Changelog
**v0.3a**
## Refactor - Code deduplication (no behavior changes)

- Unified all texture setters (`tex_joystick_*`, `tex_dpad_*`) into a single `_set_tex()` helper.
- Unified setters that repeated `notify_property_list_changed()` + `queue_redraw()` (and sometimes `update_configuration_warnings()`) into the `_refresh_inspector()` and `_refresh_editor_state()` helpers.
- Merged the duplicated D-Pad octant selection logic (`_preset_state_index()` plus the if/elif custom-texture block inside `_get_dpad_texture()`) into a single `_dpad_octant_index()` function plus the `_custom_dpad_textures()` accessor.
- Extracted `_apply_axis()` to replace the repeated press/release logic in `_trigger_actions()` for the X and Y axes.
- Extracted `_apply_region_hint()` to unify the 4 nearly identical `region_x/y/w/h` cases in `_validate_property()`.
- Extracted the drawing helpers `_rect_from_center()`, `_fill_color()` and `_draw_ring()` to avoid repeating the same `Rect2`, alpha-adjusted `Color`, and `draw_arc()` calculations in `_draw_joystick()`, `_draw_dpad()`, and the debug-draw functions.
- No logic/behavior changes: all changes are internal code organization (789 -> 757 lines).

---

**v0.3b**

- Updated "README.MD" file.
- Joystick, D-Pad, Active Region, Dead Zone, and Clamp Zone colors have been readjusted.

- No other significant changes.