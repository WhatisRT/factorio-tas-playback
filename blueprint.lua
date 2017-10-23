
Blueprint = {} --luacheck: allow defined top
local Utils = require("utility_functions")

local blueprint_data_raw
function Blueprint.init(blueprint_raw)
    blueprint_data_raw = blueprint_raw or {}
end


function Blueprint.get_raw_data(name)
    return blueprint_data_raw[name]
end


function Blueprint.load(name, offset, rotation, chunk_size, area, build_order)
    local blueprint_raw = blueprint_data_raw[name]
    if not blueprint_raw then
        game.print(debug.traceback())
        error("Attempted to load not existing blueprint: " .. name)
    end
    if not blueprint_raw.anchor then error("Loading blueprint without anchor!") end
    local entities = blueprint_raw.entities

    local blueprint = {
        name = name,
        chunk_size = chunk_size or 32,
        chunked_entities = {},
        counts = {},
    }

    for index, ent in pairs(entities) do
        local entity = Utils.copy(ent)
		entity.index = index
        entity.position = Utils.translate(Utils.rotate_orthogonal(entity.position, rotation), {offset[1] - blueprint_raw.anchor.x + 0.5, offset[2] - blueprint_raw.anchor.y + 0.5})
        if not area or Utils.inside_rect(entity.position, area) then
            if blueprint.counts[entity.name] then
                blueprint.counts[entity.name] = blueprint.counts[entity.name] + 1
            else
                blueprint.counts[entity.name] = 1
            end

            if rotation then
                entity.direction = ((entity.direction or 0) + rotation) % 8
            end
			
			Utils.Chunked.create_entry(blueprint.chunked_entities, chunk_size, entity.position, entity)
        end
    end

    if build_order then blueprint.build_order = copy(blueprint_data_raw.__build_orders[build_order]) end

    return blueprint
end


function Blueprint.get_entities_in_build_range(blueprint_data, player)
    if not blueprint_data then game.print(debug.traceback()); error("Called Blueprint.get_entities_in_build_range with invalid blueprint_data!") end
    local res = {}
    local position = player.position

    local entities = blueprint_data.chunked_entities
    local x = math.floor((position.x or position[1]) / blueprint_data.chunk_size)
    local y = math.floor((position.y or position[2]) / blueprint_data.chunk_size)

    for X = x-1, x+1 do
        for Y = y-1, y+1 do
            for _, entity in pairs(entities[X .. "_" .. Y] or {}) do
                if Utils.distance_from_rect(position, Utils.collision_box(entity)) <= player.build_distance + 0.1 then -- TODO: This should be done dynamically.
                    table.insert(res, entity)
                end
            end
        end
    end

    return res
end

return Blueprint