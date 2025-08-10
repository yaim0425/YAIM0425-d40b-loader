---------------------------------------------------------------------------------------------------
---> control.lua <---
---------------------------------------------------------------------------------------------------

--- Contenedor de funciones y datos usados
--- unicamente en este archivo
local This_MOD = {}

---------------------------------------------------------------------------------------------------

--- Cargar las funciones
require("__zzzYAIM0425-0000-lib__/control")

---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
function This_MOD.start()
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Obtener información desde el nombre de MOD
    GPrefix.split_name_folder(This_MOD)

    --- Valores de la referencia
    This_MOD.setting_mod()

    --- Cambiar la propiedad necesaria
    This_MOD.load_events()

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Valores de la referencia
function This_MOD.setting_mod()
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    ---- Entities validas
    This_MOD.entities = {
        ["splitter"] = true,
        ["loader-1x1"] = true,
        ["transport-belt"] = true,
        ["underground-belt"] = true
    }

    --- Tipo de inventarios validos
    This_MOD.inventory = {
        [defines.inventory.chest] = true,
        [defines.inventory.lab_input] = true,
        [defines.inventory.furnace_source] = true,
        [defines.inventory.rocket_silo_rocket] = true,
        [defines.inventory.assembling_machine_input] = true
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Cargar los eventos a ejecutar
function This_MOD.load_events()
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    -- Agregar la acción a los eventos
    script.on_event({
        defines.events.on_built_entity,
        defines.events.on_robot_built_entity,
        defines.events.script_raised_built,
        defines.events.script_raised_revive,
        defines.events.on_space_platform_built_entity,
    }, function(events)
        This_MOD.on_built_entity(GPrefix.create_data(events, This_MOD))
    end)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------

--- Devuelve todas las entidades situadas a
--- 1 baldosa en la dirección especificada
function This_MOD.get_neighbour_entities(entity, direction)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Converción de la direcciones
    local dir2vector = {
        [defines.direction.north] = { x = 0, y = -1 },
        [defines.direction.south] = { x = 0, y = 1 },
        [defines.direction.west] = { x = -1, y = 0 },
        [defines.direction.east] = { x = 1, y = 0 }
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Obtener la entidades en la posición
    local Entities = entity.surface.find_entities_filtered({
        position = {
            x = entity.position.x + dir2vector[direction].x,
            y = entity.position.y + dir2vector[direction].y
        }
    })

    --- Filtar las entidades validas
    local Output = {}
    for _, Entity in pairs(Entities) do
        local Flag = This_MOD.entities[Entity.type]
        Flag = Flag or This_MOD.has_inventory({ Entity })
        if Flag then table.insert(Output, Entity) end
    end

    --- Devuelve el resultado, de haberlo
    if #Output > 0 then return Output end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- La entidad tiene un inventario
function This_MOD.has_inventory(entities)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    for _, entity in pairs(entities or {}) do
        for id, _ in pairs(This_MOD.inventory) do
            if entity.get_inventory(id) then
                return true
            end
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Hay una entidad con la dirección dada
function This_MOD.is_direction(entities, direction)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    for _, entity in pairs(entities or {}) do
        local Flag = This_MOD.entities[entity.type]
        Flag = Flag and entity.direction == direction
        if Flag then return true end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------

--- Al construir un cargador
function This_MOD.on_built_entity(Data)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Renombrar la entidad a construir
    local Entity = Data.Event.entity

    --- Validar
    if not Entity then return end
    if not Entity.valid then return end
    if not GPrefix.has_id(Entity.name, This_MOD.id) then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---



    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Direcciones con las que funciona
    local opposite = {
        [defines.direction.north] = defines.direction.south,
        [defines.direction.south] = defines.direction.north,
        [defines.direction.east]  = defines.direction.west,
        [defines.direction.west]  = defines.direction.east,
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- El cargadro esta metiendo en el inventaio
    local Input = Entity.loader_type == "input"

    --- Entidades delante y atras
    local Front = This_MOD.get_neighbour_entities(Entity,
        Input and opposite[Entity.direction] or Entity.direction --- Belt
    )
    local Back = This_MOD.get_neighbour_entities(Entity,
        Input and Entity.direction or opposite[Entity.direction] --- O/I
    )

    --- Hay algún inventario
    local Front_inventory = This_MOD.has_inventory(Front)
    local Back_inventory = This_MOD.has_inventory(Back)

    --- La entidad tiene la misma dirección
    local Front_direction = This_MOD.is_direction(Front, Entity.direction)
    local Back_direction = This_MOD.is_direction(Back, Entity.direction)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Nada con lo cual alinear
    if not (Front or Back) then return end

    --- Alinear con el inventario
    if Back and Back_inventory then
        if Front and not Front_direction then
            Entity.rotate()
        end
        return
    end

    if Front and Front_inventory then
        Entity.direction = opposite[Entity.direction]
        if Back and Back_direction then
            Entity.rotate()
        end
        return
    end

    --- Alinear con lo que esté atras
    if Back and Back_direction then
        Entity.direction = opposite[Entity.direction]
        Entity.rotate()
        return
    end

    if Back and not Back_direction then
        Entity.direction = opposite[Entity.direction]
        if not This_MOD.is_direction(Back, Entity.direction) then
            if Input then Entity.rotate() end
        end
        return
    end

    --- Alinear con lo que esté delante
    if Front and Front_direction then
        return
    end

    if Front and not Front_direction then
        Entity.rotate()
        if not This_MOD.is_direction(Front, Entity.direction) then
            if not Input then Entity.rotate() end
        end
        return
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
This_MOD.start()

---------------------------------------------------------------------------------------------------
