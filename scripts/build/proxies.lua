local utils = require("scripts/utils") --[[@as BlueprintShotgun.utils]]
local render = require("scripts/render") --[[@as BlueprintShotgun.render]]

---@class BlueprintShotgun.proxies
local lib = {}

local ultracube_active = script.active_mods["Ultracube"]

---@param params BlueprintShotgun.HandlerParams
function lib.process(params)
    if params.ammo_limit == 0 then return end

    local proxies = params.surface.find_entities_filtered{
        type = "item-request-proxy",
        position = params.target_pos,
        radius = params.radius,
        force = params.force,
    }
    table.sort(proxies, utils.distance_sort(params.target_pos))
    utils.arc_cull(proxies, params.character.position, params.target_pos)

    local used = false

    for _, proxy in pairs(proxies) do
        local target = proxy.proxy_target
        if not target then return end

        if target.to_be_upgraded() then goto continue end

        local to_insert = storage.to_insert[proxy.unit_number] or {} --[[@as ItemWithQualityCounts[] ]]
        storage.to_insert = to_insert

        local requests = proxy.item_requests
        local map = utils.map_item_count_quality(requests)
        for _, data in pairs(to_insert) do
            local qualities = map[data.name]
            if qualities then
                local item_request = qualities[data.quality]
                if item_request then
                    item_request.count = item_request.count - data.count
                end
            end
        end

        local inventory = params.inventory
        local item, stack, count
        for _, request in pairs(requests) do
            local min_count = math.min(inventory.get_item_count{name = request.name, quality = request.quality}, request.count)
            if min_count > 0 then
                stack = inventory.find_item_stack{name = request.name, quality = request.quality} ---@cast stack -?
                if target.can_insert(stack) then
                    item = {name = request.name, count = min_count, quality = request.quality}
                    count = min_count
                    item_request = request
                    break
                end
            end
        end
        if not item then goto continue end

        local positions = {} --[[@as InventoryPosition[] ]]
        local insert_plan = proxy.insert_plan
        for i, plan in pairs(insert_plan) do
            if plan.id.name == item.name then
                for j, inventory_position in pairs(plan.items.in_inventory) do
                    local insert_position = table.deepcopy(inventory_position)
                    positions[#positions+1] = insert_position
                    count = count - (inventory_position.count or 1)
                    if count < 0 then
                        insert_position.count = inventory_position.count + count
                        inventory_position.count = -count
                    else
                        plan.items.in_inventory[j] = nil
                    end
                    if count <= 0 then break end
                end

                utils.condense(plan.items.in_inventory)
                if #plan.items.in_inventory == 0 then
                    insert_plan[i] = nil
                end
            end
        end
        proxy.insert_plan = insert_plan

        local slot = game.create_inventory(1)
        slot[1].transfer_stack(stack, item.count)

        local sprite, shadow = render.draw_new_item(params.surface, item.name, params.source_pos)
        local duration = utils.get_flying_item_duration(params.source_pos, proxy.position)
        local flying_item = {
            action = "request",
            slot = slot,
            surface = params.surface,
            force = params.force,
            source_pos = params.source_pos,
            target_pos = proxy.position,
            start_tick = params.tick,
            end_tick = params.tick + duration,
            orientation_deviation = utils.orientation_deviaiton(),
            sprite = sprite,
            shadow = shadow,
            target_entity = target,
            inventory_positions = positions,
            unit_number = proxy.unit_number,
        } --[[@as FlyingRequestItem]]
        storage.flying_items[sprite.id] = flying_item

        if ultracube_active and storage.cubes[item.name] then
            flying_item.ultracube_token = utils.create_ultracube_token(item.name, item.count, params.surface, proxy.position, flying_item.velocity, 1)
        end

        used = true
        params.ammo_item.drain_ammo(1)
        params.ammo_limit = params.ammo_limit - 1
        if params.ammo_limit <= 0 then break end

        ::continue::
    end
    return used
end

---@param item FlyingRequestItem
function lib.action(item)
    local target_entity = item.target_entity
    if target_entity.valid then
        local item_stack = item.slot[1]
        local inserted
        for _, position in pairs(item.inventory_positions) do
            local inventory = target_entity.get_inventory(position.inventory) --[[@as LuaInventory]]
            local stack = inventory[position.stack + 1]
            if stack.transfer_stack(item_stack, position.count or 1) then
                inserted = true
            else
                utils.spill_item(item)
            end
        end

        if inserted then
            game.play_sound{path = "utility/inventory_move", position = item.target_pos}
        end
    else
        utils.spill_item(item)
    end
end

return lib

---@class FlyingRequestItem:FlyingItemBase
---@field action "request"
---@field target_entity LuaEntity
---@field inventory_positions InventoryPosition[]
---@field unit_number uint