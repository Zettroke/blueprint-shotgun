data:extend{{
    type = "int-setting",
    name = "blueprint-shotgun-cheat-bonus",
    setting_type = "startup",
    default_value = 0,
    minimum_value = 0,
    maximum_value = 24,
    order = "a",
}, {
    type = "bool-setting",
    name = "blueprint-shotgun-no-wood",
    setting_type = "startup",
    default_value = false,
    order = "b",
}}

data:extend{{
    type = "string-setting",
    name = "blueprint-shotgun-mode-swap",
    setting_type = "runtime-per-user",
    allowed_values = {"auto", "manual", "3-way"},
    default_value = "auto",
    order = "a",
}, {
    type = "string-setting",
    name = "blueprint-shotgun-aim-mode",
    setting_type = "runtime-per-user",
    allowed_values = {"auto", "position", "direction"},
    default_value = "auto",
    order = "b",
}}