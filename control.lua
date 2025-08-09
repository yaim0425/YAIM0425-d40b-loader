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

    --- Direcciones con las que funciona
    This_MOD.opposite = {
        [defines.direction.north] = defines.direction.south,
        [defines.direction.south] = defines.direction.north,
        [defines.direction.east]  = defines.direction.west,
        [defines.direction.west]  = defines.direction.east,
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
        This_MOD.on_builtEntity(GPrefix.create_data(events, This_MOD))
    end)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------

--- Sumar dos vectores
function This_MOD.add_vectors(v1, v2)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    return { v1.x + v2.x, v1.y + v2.y }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Devuelve todas las entidades situadas a
--- 1 baldosa en la dirección especificada
function This_MOD.get_neighbour_entities(entity, direction)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local dir2vector = {
        [defines.direction.north] = { x = 0, y = -1 },
        [defines.direction.east]  = { x = 1, y = 0 },
        [defines.direction.south] = { x = 0, y = 1 },
        [defines.direction.west]  = { x = -1, y = 0 },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local Position = {
        position = This_MOD.add_vectors(
            entity.position,
            dir2vector[direction]
        )
    }

    return entity.surface.find_entities_filtered(Position)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- La entidad tiene un inventario
function This_MOD.has_inventory(entities)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    for _, entity in pairs(entities) do
        local Flag = false
        Flag = Flag or entity.get_inventory(defines.inventory.chest)
        Flag = Flag or entity.get_inventory(defines.inventory.furnace_source)
        Flag = Flag or entity.get_inventory(defines.inventory.assembling_machine_input)
        Flag = Flag or entity.get_inventory(defines.inventory.lab_input)
        Flag = Flag or entity.get_inventory(defines.inventory.rocket_silo_rocket)
        if Flag then return true end
    end

    return false

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Detección de la cara del cinturón
function This_MOD.is_direction(entities, direction)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    for _, entity in pairs(entities) do
        local Flag = false
        Flag = Flag or entity.type == "splitter"
        Flag = Flag or entity.type == "loader-1x1"
        Flag = Flag or entity.type == "transport-belt"
        Flag = Flag or entity.type == "underground-belt"
        Flag = Flag and entity.direction == direction
        if Flag then return true end
    end

    return false

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------

--- Receptor de los eventos a ejecutar
function This_MOD.on_builtEntity(Data)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Renombrar la entidad a construir
    local Entity = Data.Event.entity

    --- Validar
    if not Entity then return end
    if not Entity.valid then return end
    if not GPrefix.has_id(Entity.name, This_MOD.id) then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---



    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Variables a usar
    local Front --- Belt
    local Back  --- O/I

    --- Direcciones a evaluar
    local Direction = Entity.direction
    local Opposite = This_MOD.opposite[Entity.direction]

    --- Entidades al frente y atras
    if Entity.loader_type == "output" then
        Front = This_MOD.get_neighbour_entities(Entity, Direction)
        Back = This_MOD.get_neighbour_entities(Entity, Opposite)
    end

    if Entity.loader_type == "input" then
        Front = This_MOD.get_neighbour_entities(Entity, Opposite)
        Back = This_MOD.get_neighbour_entities(Entity, Direction)
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Nada a evaluar
    if not (Front or Back) then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Valores a usar
    local Input = Entity.loader_type == "input"
    local Fron_inventory = This_MOD.has_inventory(Front)
    local Back_inventory = This_MOD.has_inventory(Back)
    local Front_direction = This_MOD.is_direction(Front, Entity.direction)
    local Back_direction = This_MOD.is_direction(Back, Entity.direction)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    if Back and Back_direction then
        Entity.direction = Opposite
        Entity.rotate()
        return
    end

    if Back and not Back_direction then
        Entity.direction = Opposite
        if not This_MOD.is_direction(Back, Entity.direction) then
            Entity.direction = Direction
        end
        return
    end



    if Front and Back_direction then
        return
    end

    if Front and not Back_direction then
        Entity.rotate()
        return
    end



    if Back and not Input and Back_inventory then
        return
    end

    if Back and Input and Back_inventory then
        Entity.rotate()
        return
    end

    if Front and not Input and Fron_inventory then
        Entity.direction = Opposite
        return
    end

    if Front and Input and Fron_inventory then
        Entity.direction = Opposite
        Entity.rotate()
        return
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    if true then return end
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local dir2vector = {
        [defines.direction.north] = { x = 0, y = -1 },
        [defines.direction.east]  = { x = 1, y = 0 },
        [defines.direction.south] = { x = 0, y = 1 },
        [defines.direction.west]  = { x = -1, y = 0 },
    }

    local Datos = {
        Entity = {
            name = Entity.name,
            direction = dir2vector[Entity.direction],
            loader_type = Entity.loader_type,
        },
    }

    Datos.Front = {}
    for _, belt in pairs(Front) do
        table.insert(Datos.Front, {
            name = belt.name,
            direction = dir2vector[belt.direction],
        })
    end

    Datos.Back = {}
    for _, loading in pairs(Back) do
        table.insert(Datos.Back, {
            name = loading.name,
            direction = dir2vector[loading.direction],
        })
    end

    log("\n\n\n\n\n")
    GPrefix.var_dump(Datos)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---



    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Representación grafica
    ---    >   Cinta or Lado de la cita
    ---    X   Entidad con inventario
    --- [ < ] Cargador a construir
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    if true then return end
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---





    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Inicio: >  [ < ]     Resultado: >  [ > ]
    --- Inicio: >  [ < ]     Resultado: >  [ > ]
    if This_MOD.is_direction(Direction, This_MOD.opposite[Entity.direction]) then
        Entity.rotate()
        return
    end

    --- Inicio:  >  [ => ]     Resultado:  >  [ >= ]
    --- Inicio: =>  [ => ]     Resultado: =>  [ >= ]
    if This_MOD.is_direction(Opposite, Entity.direction) then
        Entity.direction = This_MOD.opposite[Entity.direction]
        Entity.rotate()
        return
    end

    --- Inicio:  <  [ => ]     Resultado:  <  [ <= ]
    if This_MOD.is_direction(Opposite, This_MOD.opposite[Entity.direction]) then
        Entity.direction = This_MOD.opposite[Entity.direction]
        return
    end

    --- Inicio:  X  [ <= ]     Resultado:  X  [ =< ]
    if This_MOD.has_inventory(Direction) then
        if not This_MOD.is_direction(Opposite, Entity.direction) then
            Entity.direction = This_MOD.opposite[Entity.direction]
            Entity.rotate()
        end
        return
    end

    --- Inicio:  X  [ => ]     Resultado:  X  [ => ]
    if This_MOD.has_inventory(Opposite) then
        return
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
This_MOD.start()

---------------------------------------------------------------------------------------------------
