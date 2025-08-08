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

    --- Filtrar los cargadores
    This_MOD.filter = { { filter = "type", type = "loader-1x1" } }

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
    end, This_MOD.filter)

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
        [defines.direction.south] = { x = 0, y = 1 },
        [defines.direction.east]  = { x = 1, y = 0 },
        [defines.direction.west]  = { x = -1, y = 0 },
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    local Table = { position = This_MOD.add_vectors(entity.position, dir2vector[direction]) }
    return entity.surface.find_entities_filtered(Table)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- La entidad tiene un inventario
--- @param entities table # Entidad a evaluar
--- @return boolean
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
--- @param entities table # Entidad a evaluar
--- @param direction table # Dirección esperada
--- @return boolean
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

--- Receptor de los eventos a ejecutar
--- @param event table
function This_MOD.on_builtEntity(Data)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Renombrar la entidad a construir
    local Entity = Data.Event.entity

    --- ¿Construcción inválida? no te molestes con la falsa propiedad "revived" de los
    --- Nanobots/Bluebuild anteriores a la versión 1.0, ahora esas travesuras sólo pueden pasar en eventos script_raised_*.
    --- Tampoco es necesario comprobar el tipo de entidad ya que podemos filtrarlo en el manejador de eventos
    if not Entity then return end
    if not Entity.valid then return end
    if Entity.name == "gosht" then return end

    GPrefix.var_dump(Entity.name)

    --- Obtener las entidades de ambos extremos
    local Belt = This_MOD.get_neighbour_entities(Entity, Entity.direction)                       -- Front [ > ]
    local Loading = This_MOD.get_neighbour_entities(Entity, This_MOD.opposite[Entity.direction]) -- Back  [ = ]

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    --- Representación grafica
    ---    =   Lado del cargador
    ---    >   Cinta or Lado de la cita
    ---    X   Entidad con inventario
    --- [ <= ] Cargador a construir
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Inicio:  >  [ <= ]     Resultado:  >  [ >= ]
    --- Inicio: =>  [ <= ]     Resultado: =>  [ >= ]
    if This_MOD.is_direction(Belt, This_MOD.opposite[Entity.direction]) then
        Entity.rotate()
        return
    end

    --- Inicio:  >  [ => ]     Resultado:  >  [ >= ]
    --- Inicio: =>  [ => ]     Resultado: =>  [ >= ]
    if This_MOD.is_direction(Loading, Entity.direction) then
        Entity.direction = This_MOD.opposite[Entity.direction]
        Entity.rotate()
        return
    end

    --- Inicio:  <  [ => ]     Resultado:  <  [ <= ]
    if This_MOD.is_direction(Loading, This_MOD.opposite[Entity.direction]) then
        Entity.direction = This_MOD.opposite[Entity.direction]
        return
    end

    --- Inicio:  X  [ <= ]     Resultado:  X  [ =< ]
    if This_MOD.has_inventory(Belt) then
        if not This_MOD.is_direction(Loading, Entity.direction) then
            Entity.direction = This_MOD.opposite[Entity.direction]
            Entity.rotate()
        end
        return
    end

    --- Inicio:  X  [ => ]     Resultado:  X  [ => ]
    if This_MOD.has_inventory(Loading) then
        return
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
This_MOD.start()

---------------------------------------------------------------------------------------------------
