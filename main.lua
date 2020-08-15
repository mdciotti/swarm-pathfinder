local TILE_WIDTH = 4
local TILE_HEIGHT = 4
local CHUNK_WIDTH = 16
local CHUNK_HEIGHT = 16
local ELEVATION_SCALE = 2
local MOISTURE_SCALE = 4

local TILE_TYPE_NONE = 0
local TILE_TYPE_EARTH = 1
local TILE_TYPE_WATER = 2
local TILE_TYPE_CLIFF = 3

local BIOME_OCEAN = 1
local BIOME_BEACH = 2
local BIOME_SCORCHED = 3
local BIOME_BARE = 4
local BIOME_TUNDRA = 5
local BIOME_SNOW = 6
local BIOME_TEMPERATE_DESERT = 7
local BIOME_SHRUBLAND = 8
local BIOME_TAIGA = 9
local BIOME_GRASSLAND = 10
local BIOME_TEMPERATE_DECIDUOUS_FOREST = 11
local BIOME_TEMPERATE_RAIN_FOREST = 12
local BIOME_SUBTROPICAL_DESERT = 13
local BIOME_TROPICAL_SEASONAL_FOREST = 14
local BIOME_TROPICAL_RAIN_FOREST = 15

local THEME_DEFAULT = {}
THEME_DEFAULT[BIOME_OCEAN] = 0x43437a
THEME_DEFAULT[BIOME_BEACH] = 0xa09177
THEME_DEFAULT[BIOME_SCORCHED] = 0x555555
THEME_DEFAULT[BIOME_BARE] = 0x888888
THEME_DEFAULT[BIOME_TUNDRA] = 0xbcbcab
THEME_DEFAULT[BIOME_SNOW] = 0xdedee5
THEME_DEFAULT[BIOME_TEMPERATE_DESERT] = 0xc9d29b
THEME_DEFAULT[BIOME_SHRUBLAND] = 0x889977
THEME_DEFAULT[BIOME_TAIGA] = 0x98a977
THEME_DEFAULT[BIOME_GRASSLAND] = 0x88ab55
THEME_DEFAULT[BIOME_TEMPERATE_DECIDUOUS_FOREST] = 0x679359
THEME_DEFAULT[BIOME_TEMPERATE_RAIN_FOREST] = 0x438855
THEME_DEFAULT[BIOME_SUBTROPICAL_DESERT] = 0xd2b98b
THEME_DEFAULT[BIOME_TROPICAL_SEASONAL_FOREST] = 0x569944
THEME_DEFAULT[BIOME_TROPICAL_RAIN_FOREST] = 0x337755

local world = {
    seed = 0,
    width = 200,
    height = 150,
    chunks = {},
    theme = THEME_DEFAULT
}

local camera = {
    x = 0,
    y = 0,
    width = 0,
    height = 0
}


function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.math.setRandomSeed(love.timer.getTime())
    elevation_seed = love.math.random()
    moisture_seed = love.math.random()
    camera.width = love.graphics.getWidth()
    camera.height = love.graphics.getHeight()
end

function love.mousepressed(x, y, button, istouch, presses)
    -- world.seed = (love.math.random() + 1) / 2
    -- love.math.setRandomSeed(love.timer.getTime())
    -- elevation_seed = love.math.random()
    -- moisture_seed = love.math.random()
    -- generate_chunk()
    -- print(get_visible_chunks())
end

function love.mousemoved(x, y, dx, dy)
    -- elevation_seed = TILE_WIDTH * (x / world.width)
    -- moisture_seed = TILE_HEIGHT * (y / world.height)
    -- generate_chunk()
    if love.mouse.isDown(1) then
        camera.x = camera.x - dx
        camera.y = camera.y - dy
    end
end

function fractal_noise(x, y, n)
    return fractal_noise_inner(x, y, 1, n)
end

function fractal_noise_inner(x, y, f, n)
    if n == 1 then return 0 end
    return 1 / f * love.math.noise(f * x, f * y) + fractal_noise_inner(x, y, f * 2, n - 1)
end

function elevation(nx, ny, gamma)
    -- local e = 1 * love.math.noise(elevation_seed, 1 * nx, 1 * ny) + 0.5 * love.math.noise(elevation_seed, 2 * nx, 2 * ny) + 0.25 * love.math.noise(elevation_seed, 4 * nx, 4 * ny)
    local e = fractal_noise(nx / ELEVATION_SCALE, ny / ELEVATION_SCALE, 3)
    -- e = e / 1.75
    return math.pow(e, gamma)
end

function moisture(nx, ny, gamma)
    -- local m = 1 * love.math.noise(moisture_seed, 1 * nx, 1 * ny) + 0.5 * love.math.noise(moisture_seed, 2 * nx, 2 * ny) + 0.25 * love.math.noise(moisture_seed, 4 * nx, 4 * ny)
    local m = fractal_noise(nx / MOISTURE_SCALE, ny / MOISTURE_SCALE, 3)
    -- m = m / 1.75
    return math.pow(m, gamma)
end

function biome(e, m)
    if e < 0.10 then return BIOME_OCEAN end
    if e < 0.12 then return BIOME_BEACH end

    if e > 0.80 then
        if m < 0.10 then return BIOME_SCORCHED end
        if m < 0.20 then return BIOME_BARE end
        if m < 0.50 then return BIOME_TUNDRA end
        return BIOME_SNOW
    end

    if e > 0.60 then
        if m < 0.33 then return BIOME_TEMPERATE_DESERT end
        if m < 0.66 then return BIOME_SHRUBLAND end
        return BIOME_TAIGA
    end

    if e > 0.30 then
        if m < 0.16 then return BIOME_TEMPERATE_DESERT end
        if m < 0.50 then return BIOME_GRASSLAND end
        if m < 0.83 then return BIOME_TEMPERATE_DECIDUOUS_FOREST end
        return BIOME_TEMPERATE_RAIN_FOREST
    end

    if m < 0.16 then return BIOME_SUBTROPICAL_DESERT end
    if m < 0.33 then return BIOME_GRASSLAND end
    if m < 0.66 then return BIOME_TROPICAL_SEASONAL_FOREST end
    return BIOME_TROPICAL_RAIN_FOREST
end

function generate_chunk(x, y)
    local chunk = { data = {} }
    local ox = x * CHUNK_WIDTH
    local oy = y * CHUNK_HEIGHT
    for row = 1, CHUNK_WIDTH do
        for col = 1, CHUNK_HEIGHT do
            local nx = x + col / CHUNK_WIDTH
            local ny = y + row / CHUNK_HEIGHT
            local e = elevation(nx, ny, 3)
            local m = moisture(nx, ny, 1)
            local i = (row - 1) * CHUNK_WIDTH + col
            chunk.data[i] = biome(e, m)
        end
    end
    return chunk
end

function hex2rgb(hex)
    -- local r = ((hex & 0xFF0000) >> 16) / 255.0
    local r = (math.floor(hex / 2 ^ 16) % 2 ^ 8) / 255.0
    -- local g = ((hex & 0x00FF00) >> 8) / 255.0
    local g = (math.floor(hex / 2 ^ 8) % 2 ^ 8) / 255.0
    -- local b = (hex & 0x0000FF) / 255.0
    local b = (hex % 2 ^ 8) / 255.0
    return { r, g, b, 1 }
end

function get_visible_chunks()
    local locations = {}
    local start_y = camera.y / (CHUNK_HEIGHT * TILE_HEIGHT)
    local end_y = (camera.y + camera.height) / (CHUNK_HEIGHT * TILE_HEIGHT)
    local start_x = camera.x / (CHUNK_WIDTH * TILE_WIDTH)
    local end_x = (camera.x + camera.width) / (CHUNK_WIDTH * TILE_WIDTH)
    for y = math.floor(start_y), math.ceil(end_y) do
        for x = math.floor(start_x), math.ceil(end_x) do
            table.insert(locations, { x = x, y = y })
        end
    end
    return locations
    -- return { { x = 0, y = 0 } }
end

function chunk_hash(x, y)
    -- TODO: use geospatial indexing or space-filling curve?
    return y * 1024 + x
end

function love.update()
    -- TODO: remove stale chunks?

    -- If a chunk in view has not been generated yet, generate one
    for _, location in pairs(get_visible_chunks()) do
        local x = location.x
        local y = location.y
        local hash = chunk_hash(x, y)
        local chunk = world.chunks[hash]
        if not chunk then
            world.chunks[hash] = generate_chunk(x, y)
        end
    end
end

function draw_chunk(chunk, cx, cy)
    for row = 1, CHUNK_HEIGHT do
        local y = (cy * CHUNK_HEIGHT + (row - 1)) * TILE_HEIGHT
        for col = 1, CHUNK_WIDTH do
            local x = (cx * CHUNK_WIDTH + (col - 1)) * TILE_WIDTH
            -- local nx = cx + col / CHUNK_WIDTH
            -- local ny = cy + row / CHUNK_HEIGHT
            local biome = chunk.data[(row - 1) * CHUNK_WIDTH + col]
            local color = world.theme[biome]
            love.graphics.setColor(hex2rgb(color))
            -- love.graphics.setColor((col - 1) / CHUNK_WIDTH, (row - 1) / CHUNK_HEIGHT, 0.0, 1.0)
            love.graphics.rectangle('fill', x, y, TILE_WIDTH, TILE_HEIGHT)
        end
    end
end

function love.draw()
    love.graphics.translate(-camera.x, -camera.y)
    for _, chunk_location in pairs(get_visible_chunks()) do
        local x = chunk_location.x
        local y = chunk_location.y
        local chunk = world.chunks[chunk_hash(x, y)]
        if chunk then draw_chunk(chunk, x, y) end
    end
end
