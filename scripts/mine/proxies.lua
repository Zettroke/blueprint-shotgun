local utils = require("scripts/utils") --[[@as BlueprintShotgun.utils]]
local vec = require("scripts/vector") --[[@as BlueprintShotgun.vector]]
local render = require("scripts/render") --[[@as BlueprintShotgun.render]]

---@param params BlueprintShotgun.HandlerParams
return function(params)
    local entities = utils.find_entities_in_radius(params.surface, {
        type = "item-request-proxy",
        position = params.target_pos,
        radius = params.radius,
    })
    table.sort(entities, utils.distance_sort(params.target_pos))

    if #entities == 0 then return end

    local vacuum_limit = 4 + params.bonus * 2
    local prev_limit = vacuum_limit
    for _, proxy in pairs(entities) do
        local removal_plan = proxy.removal_plan
        if not removal_plan[1] then goto continue end

        local target = proxy.proxy_target
        if not target then goto continue end

        for i, plan in pairs(removal_plan) do
            local slot = game.create_inventory(1)
            for j, item in pairs(plan.items.in_inventory) do
                local inventory = target.get_inventory(item.inventory) --[[@as LuaInventory]]
                if not slot[1].transfer_stack(inventory[item.stack + 1]) then break end
                plan.items[j] = nil

                vacuum_limit = vacuum_limit - 1
                params.ammo_item.drain_ammo(0.125)

                if vacuum_limit == 0 then break end
                if not params.ammo_item.valid_for_read then break end
            end

            utils.condense(plan.items.in_inventory)
            if #plan.items.in_inventory == 0 then
                removal_plan[i] = nil
            end

            game.play_sound{path = "utility/picked_up_item", position = target.position}
            local sprite, shadow = render.draw_new_item(target.surface, plan.id.name --[[@as string]], target.position, 0)
            sprite.move_to_back()
            storage.vacuum_items[sprite.id] = {
                slot = slot,
                surface = params.surface,
                character = params.character,
                time = 0,
                position = target.position,
                velocity = vec.random(1/15),
                height = 0,
                orientation_deviation = utils.orientation_deviaiton(),
                sprite = sprite,
                shadow = shadow,
                deconstruct = params.character.force,
            }

            if vacuum_limit == 0 then break end
            if not params.ammo_item.valid_for_read then break end
        end

        proxy.removal_plan = removal_plan

        if not params.ammo_item.valid_for_read then break end

        ::continue::
    end

    return vacuum_limit < prev_limit
end