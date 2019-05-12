crawl.mpr("hello i am my.rc")
function print_a()
    crawl.mpr("hello i am my.rc")
end

function doSearch(x, y)
    local pillar = create(x, y)
    if pillar == nil then
        return nil
    end
    local xmin, ymin, xmax, ymax = getBbox(pillar.tiles)
    local x1, y1, x2, y2 = findTwoNeighboringTilesOnBorder(pillar.tiles, xmin, ymin, xmax, ymax)
    local tileset = getTilesInBox(xmin, ymin, xmax, ymax)
end

function getTilesInBox(xmin, ymin, xmax, ymax)
    local tiles = {}
    for x=xmin,xmax do
        for y=ymin,ymax do
            tiles[{x, y}] = travel.feature_is_traversable(view.feature_at(x, y))
        end
    end
    return tiles
end

function create(x, y)
    local pillar = {}
    pillar.tiles = getNeighboringType(floodFillType(x, y, "wall"), "floor");
    if not has(pillar.tiles, {0, 0}) then
        crawl.mpr("Please walk onto a tile orthogonally adjacent to the pillar.")
        return nil
    end
    return pillar
end
crawl.mpr("i create")

function showTiles(tiles)
    for xy, _ in pairs(tiles) do
        local x = xy[1]
        local y = xy[2]
        travel.set_exclude(x, y, 0)
    end
end

function joinSets(a, b)
    local join = newTupleSet()
    for k, _ in pairs(a) do
        join[k] = true
    end
    for k, _ in pairs(b) do
        join[k] = true
    end
    return join
end

function has(l, t)
    for k, _ in pairs(l) do
        print(k)
        if k[1] == t[1] and k[2] == t[2] then
            return true
        end
    end
    return false
end

function newTupleSet()
    return {}
end

function floodFillType(x, y, type)
    return floodFillTypeHelper(x, y, type, {}, {0})
end

function floodFillTypeHelper(x, y, type, used, counter)
    if has(used, {x, y}) or travel.feature_is_traversable(view.feature_at(x, y)) then
        return {}
    end
    local ffRes = newTupleSet()
    ffRes[{x, y}] = true
    counter[1] = counter[1] + 1
    if counter[1] >= 1000 then
        crawl.mpr("Pillar too large! Did you select a map border?")
        return nil
    end
    used[{x, y}] = true
    local n_pos = newTupleSet()
    n_pos[{0, 1}] = true
    n_pos[{0, -1}] = true
    n_pos[{1, 0}] = true
    n_pos[{-1, 0}] = true
    for oxoy, _ in pairs(n_pos) do
        local off_x = oxoy[1]
        local off_y = oxoy[2]
        local ff = floodFillTypeHelper(x+off_x, y+off_y, type, used, counter)
        if ff == nil then
            return nil
        end
        ffRes = joinSets(ffRes, ff)
    end
    return ffRes
end

function getNeighboringType(tiles, type)
    local neighbors = {}
    local n_pos = newTupleSet()
    n_pos[{0, 1}] = true
    n_pos[{0, -1}] = true
    n_pos[{1, 0}] = true
    n_pos[{-1, 0}] = true
    for xy, _ in pairs(tiles) do
        local x = xy[1]
        local y = xy[2]
        crawl.mpr("Processing tile " .. x .. ", " .. y)
        for oxoy, _ in pairs(n_pos) do
            local off_x = oxoy[1]
            local off_y = oxoy[2]
            crawl.mpr("Tile bordering is of type " .. view.feature_at(x+off_x, y+off_y))
            if travel.feature_is_traversable(view.feature_at(x+off_x, y+off_y), type) then
                neighbors[{x+off_x, y+off_y}] = true
            end
        end
    end
    return neighbors
end

function getBbox(tiles)
    local xmin = math.huge
    local xmax = -math.huge
    local ymin = math.huge
    local ymax = -math.huge
    for tile, _ in pairs(tiles) do
        local x = tile[1]
        local y = tile[2]
        if x > xmax then
            xmax = x
        end
        if x < xmin then
            xmin = x
        end
        if y > ymax then
            ymax = y
        end
        if y < ymin then
            ymin = y
        end
    end
    return xmin, ymin, xmax, ymax
end

function findTwoNeighboringTilesOnBorder(tiles, xmin, ymin, xmax, ymax)
    for tile, _ in pairs(tiles) do
        local x = tile[1]
        local y = tile[2]
        if (x == xmin or x == xmax) and tiles.has({x, y + 1}) then
            return x, y, x, y + 1
        end
        if (y == ymin or y == ymax) and tiles.has({x + 1, y}) then
            return x, y, x + 1, y
        end
    end
    return nil
end

function newNode(x, y)
    return {x, y, {}}
end

function newEdge(n1, n2)
    return {n1, n2}
end

function addEdge(n1, n2)
    local e = newEdge(n1, n2)
    n1[3][e] = true
    n2[3][e] = true
end

function formGraph(tiles)
    local nodes = {}
    for tile, _ in pairs(tiles) do
        nodes[newNode(tile[1], tile[2])] = true
    end
    for n1, _ in pairs(nodes) do
        for n2, _ in pairs(nodes) do
            if n1 ~= n2 then
            end
        end
    end
end

function getNextTile(thisTile, lastTile)
end