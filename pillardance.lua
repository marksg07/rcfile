crawl.mpr("hello i am my.rc")

mk = 1
_path = nil
_seqForward = nil
_seqBackward = nil
_seqidx = 0
_dir = true
_better = false
_xoff = 0
_yoff = 0

function inputPillar()
    local x, y = crawl.get_target()
    doPillar(x, y)
end

function doPillar(x, y)
    killPillar()
    doSearch(x, y)
    doStart()
end

function dancePillar()
    if _path == nil then
        crawl.mpr("No search selected!")
        return
    end
    local x = _xoff
    local y = _yoff
    local path = _path
    local idx = 0
    for i, xy in ipairs(path) do
        if xy[1] == x and xy[2] == y then
            idx = i
            break
        end
    end
    if idx == 0 then
        crawl.mpr("Please step on one of the excluded tiles.")
        return
    end
    stopStepTracker()
    startPillarDance()
    _path = nil
    _seqForward = getSeq(path)
    _seqBackward = getSeqBackwards(path)
    _seqidx = idx
end

do
    local toOff
    function getOffset(cmd)
        toOff = toOff or {CMD_MOVE_UP_LEFT={-1, -1},
            CMD_MOVE_UP_RIGHT={1, -1},
            CMD_MOVE_DOWN_LEFT={-1, 1},
            CMD_MOVE_DOWN_RIGHT={1, 1},
            CMD_MOVE_UP={0, -1},
            CMD_MOVE_DOWN={0, 1},
            CMD_MOVE_LEFT={-1, 0},
            CMD_MOVE_RIGHT={1, 0} }
        return toOff[cmd]
    end
end


function doNextAction()
    if not shouldDance() then
        killPillar()
        return
    end
    assert(_seqForward ~= nil)
    assert(_seqBackward ~= nil)
    assert(_seqidx ~= 0)
    local monsters = getAllMonsters()
    for i, mon in ipairs(monsters) do
        if string.find(mon:speed_description(), "fast") then
            crawl.mpr("Fast monster in LOS!")
            killPillar()
            return
        end
        if #(mon:spells()) ~= 0 or mon:has_known_ranged_attack() then
            crawl.mpr("Spellcaster/ranged/abilityperson in LOS!")
            killPillar()
            return
        end
        if mon:status("fast") or mon:status("covering ground quickly") then
            crawl.mpr("Hasted/berserked/swifting monster in LOS!")
            killPillar()
            return
        end
    end

    crawl.mpr("Num monsters: " .. #monsters)
    local x, y, xdir, ydir, xndir, yndir
    if _dir then
        local xy = getOffset(_seqForward[_seqidx])
        x = xy[1]
        y = xy[2]
        xdir, ydir = x, y
    else
        assert(not _dir)
        local xy = getOffset(_seqBackward[_seqidx])
        x = xy[1]
        y = xy[2]
        xdir, ydir = x, y
    end
    if not tileIsBetter(x, y, monsters) then
        crawl.mpr("Prev direction not better, checking backwards")
        if not _dir then
            local xy = getOffset(_seqForward[_seqidx])
            x = xy[1]
            y = xy[2]
            xndir, yndir = x, y
        else
            assert(_dir)
            local xy = getOffset(_seqBackward[_seqidx])
            x = xy[1]
            y = xy[2]
            xndir, yndir = x, y
        end
        _dir = not _dir
        if not tileIsBetter(x, y, monsters) then
            crawl.mpr("Neither direction better, checking forwards")
            _dir = not _dir
            x, y = xdir, ydir
            if not tileIsGood(x, y, monsters) then
                crawl.mpr("Forwards not good, trying backwards")
                _dir = not _dir
                x, y = xndir, yndir
                if not tileIsGood(x, y, monsters) then
                    crawl.mpr("No good choices to walk!")
                    killPillar()
                    return
                end
            end
        end
    end
    local nextAction
    if _dir then
        nextAction = _seqForward[_seqidx]
        _seqidx = _seqidx + 1
        if _seqidx > #_seqForward then
            _seqidx = 1
        end
    else
        assert(not _dir)
        nextAction = _seqBackward[_seqidx]
        _seqidx = _seqidx - 1
        if _seqidx < 1 then
            _seqidx = #_seqBackward
        end

    end
    crawl.do_commands({nextAction})
end

_arb = 0
function shouldDance()
    if _arb < 100 then
        _arb = _arb + 1
        return true
    end
    _arb = 0
    return false
end

_trackSteps = false
_pillarDance = false

function startStepTracker()
    _trackSteps = true
    _xoff = 0
    _yoff = 0
end

function stopStepTracker()
    _trackSteps = false
end

function startPillarDance()
    _pillarDance = true
end

function stopPillarDance()
    _pillarDance = false
end

function killPillar()
    stopStepTracker()
    stopPillarDance()
    _path = nil
    _xoff = 0
    _yoff = 0
    _seqForward = nil
    _seqBackward = nil
    _seqidx = nil
    _dir = true
    _better = false
end

function ch_start_running(kind)
    if _trackSteps and kind ~= nil then
        crawl.mpr("Any form of autotravel (including shift+dir running) does not work with pillar dancing!")
        killPillar()
    end
end

function ready()
    if _pillarDance then
        doNextAction()
    end
end

function moveUpLeft()
    move(-1, -1, "CMD_MOVE_UP_LEFT")
end

function moveUpRight()
    move(1, -1, "CMD_MOVE_UP_RIGHT")
end

function moveDownLeft()
    move(-1, 1, "CMD_MOVE_DOWN_LEFT")
end

function moveDownRight()
    move(1, 1, "CMD_MOVE_DOWN_RIGHT")
end

function moveDown()
    move(0, 1, "CMD_MOVE_DOWN")
end

function moveUp()
    move(0, -1, "CMD_MOVE_UP")
end

function moveLeft()
    move(-1, 0, "CMD_MOVE_LEFT")
end

function moveRight()
    move(1, 0, "CMD_MOVE_RIGHT")
end

function move(x, y, cmd)
    crawl.do_commands({cmd})
    if _trackSteps then
        _moved = true
        _xoff = _xoff + x
        _yoff = _yoff + y
    end
end

function is_candidate_for_attack(m)
    --if m then crawl.mpr("Checking: (" .. x .. "," .. y .. ") " .. m:name()) end
    if not m or m:attitude() ~= 0 then
        return false
    end
    if m:name() == "butterfly"
            or m:name() == "orb of destruction" then
        return false
    end
    if m:is_firewood() then
        --crawl.mpr("... is firewood.")
        if string.find(m:name(), "ballistomycete") then
            return true
        end
        return false
    end
    return true
end

function getAllMonsters()
    local monsters = {}
    local los = you.los()
    for x_off=-los,los do
        for y_off=-los,los do
            if view.cell_see_cell(0, 0, x_off, y_off) then
                local mon = monster.get_monster_at(x_off, y_off)
                if is_candidate_for_attack(mon) then
                    monsters[#monsters + 1] = mon
                end
            end
        end
    end
    return monsters
end

function tileIsGood(x, y, monsters)
    for i, mon in ipairs(monsters) do
        if getDist(0, 0, mon:x_pos(), mon:y_pos()) > getDist(x, y, mon:x_pos(), mon:y_pos()) then
            if view.cell_see_cell(x, y, mon:x_pos(), mon:y_pos()) then
                return false
            end
        end
    end
    return true
end

function tileIsBetter(x, y, monsters)
    for i, mon in ipairs(monsters) do
        if getDist(0, 0, mon:x_pos(), mon:y_pos()) >= getDist(x, y, mon:x_pos(), mon:y_pos()) then
            if view.cell_see_cell(x, y, mon:x_pos(), mon:y_pos()) then
                return false
            end
        end
    end
    return true
end


function doSearch(x, y)
    local pillar = create(x, y)
    if pillar == nil then
        return nil
    end
    local xmin, ymin, xmax, ymax = getBbox(pillar.tiles)
    local x1, y1, x2, y2 = findTwoTilesOnBorder(pillar.tiles, xmin, ymin, xmax, ymax)
    local tileset = getTilesInBox(xmin, ymin, xmax, ymax)
    -- showTiles(tileset)
    -- local toHide = {}
    -- toHide[{x1, y1}] = true
    -- toHide[{x2, y2}] = true
    -- hideTiles(toHide)
    -- crawl.mpr("hiding tiles: " .. x1 .. ", " .. y1 .. " -- " .. x2 .. ", " .. y2)
    local path = getPath(tileset, x1, y1, x2, y2)
    local pathTiles = {}
    for i, t in ipairs(path) do
        pathTiles[t] = true
    end
    --showTiles(pathTiles)
    local next = path[2]
    if x1 == xmin then
        mk.put(tileset, x1, next[2], false)
        mk.put(tileset, x1+1, next[2], false)
    elseif x1 == xmax then
        mk.put(tileset, x1, next[2], false)
        mk.put(tileset, x1-1, next[2], false)
    elseif y1 == ymin then
        mk.put(tileset, next[1], y1, false)
        mk.put(tileset, next[1], y1+1, false)
    elseif y1 == ymax then
        mk.put(tileset, next[1], y1, false)
        mk.put(tileset, next[1], y1-1, false)
    end
    local path2 = getPath(tileset, x1, y1, x2, y2)
    pathTiles = {}
    for i, t in ipairs(path2) do
        pathTiles[t] = true
    end
    --showTiles(pathTiles)
    reverse(path2)
    local prevlen = #path
    for i=2,(#path2-1) do
        path[prevlen + i - 1] = path2[i]
    end
    local pathTiles = {}
    for i, t in ipairs(path) do
        pathTiles[t] = true
    end
    --showTiles(pathTiles)
    --printTiles(path)
    --seq = getSeq(path)
    --for i, n in ipairs(seq) do
    --  crawl.mpr(n)
    --end
    _path = path
    startStepTracker()
    return path
end

function getSeq(path)
    local seq = {}
    for i, s in ipairs(path) do
        local t = path[(i + 1)]
        --crawl.mpr("asdasde")
        if i == #path then
            --crawl.mpr("EZZZZZZZZZZZZ")
            t = path[1]
        end
        local n = nil
        if t[1]==s[1] and t[2]==s[2]+1 then
            n = "CMD_MOVE_DOWN"
        elseif t[1]==s[1] and t[2]==s[2]-1 then
            n = "CMD_MOVE_UP"
        elseif t[1]==s[1]+1 and t[2]==s[2] then
            n = "CMD_MOVE_RIGHT"
        elseif t[1]==s[1]-1 and t[2]==s[2] then
            n = "CMD_MOVE_LEFT"
        elseif t[1]==s[1]+1 and t[2]==s[2]+1 then
            n = "CMD_MOVE_DOWN_RIGHT"
        elseif t[1]==s[1]+1 and t[2]==s[2]-1 then
            n = "CMD_MOVE_UP_RIGHT"
        elseif t[1]==s[1]-1 and t[2]==s[2]+1 then
            n = "CMD_MOVE_DOWN_LEFT"
        elseif t[1]==s[1]-1 and t[2]==s[2]-1 then
            n = "CMD_MOVE_UP_LEFT"
        end
        seq[i] = n
    end
    return seq
end

function getSeqBackwards(path)
    local seq = {}
    for i, s in ipairs(path) do
        local t = path[(i - 1)]
        --crawl.mpr("asdasde")
        if i == 1 then
            t = path[#path]
        end
        local n = nil
        if t[1]==s[1] and t[2]==s[2]+1 then
            n = "CMD_MOVE_DOWN"
        elseif t[1]==s[1] and t[2]==s[2]-1 then
            n = "CMD_MOVE_UP"
        elseif t[1]==s[1]+1 and t[2]==s[2] then
            n = "CMD_MOVE_RIGHT"
        elseif t[1]==s[1]-1 and t[2]==s[2] then
            n = "CMD_MOVE_LEFT"
        elseif t[1]==s[1]+1 and t[2]==s[2]+1 then
            n = "CMD_MOVE_DOWN_RIGHT"
        elseif t[1]==s[1]+1 and t[2]==s[2]-1 then
            n = "CMD_MOVE_UP_RIGHT"
        elseif t[1]==s[1]-1 and t[2]==s[2]+1 then
            n = "CMD_MOVE_DOWN_LEFT"
        elseif t[1]==s[1]-1 and t[2]==s[2]-1 then
            n = "CMD_MOVE_UP_LEFT"
        end
        seq[i] = n
    end
    return seq
end


function getTilesInBox(xmin, ymin, xmax, ymax)
    local tiles = {}
    for x=xmin,xmax do
        for y=ymin,ymax do
            mk.put(tiles, x, y, travel.feature_traversable(view.feature_at(x, y)))
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

function showTiles(tiles)
    for xy, _ in pairs(tiles) do
        local x = xy[1]
        local y = xy[2]
        travel.set_exclude(x, y, 0)
    end
end

function printTiles(tiles)
    for i, xy in ipairs(tiles) do
        crawl.mpr("(" .. xy[1] .. ", " .. xy[2] .. ")")
    end
end

function hideTiles(tiles)
    for xy, _ in pairs(tiles) do
        local x = xy[1]
        local y = xy[2]
        crawl.mpr("hiding: " .. x .. ", " .. y)
        travel.del_exclude(x, y)
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
    if has(used, {x, y}) or travel.feature_traversable(view.feature_at(x, y)) then
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
        --crawl.mpr("Processing tile " .. x .. ", " .. y)
        for oxoy, _ in pairs(n_pos) do
            local off_x = oxoy[1]
            local off_y = oxoy[2]
            --crawl.mpr("Tile bordering is of type " .. view.feature_at(x+off_x, y+off_y))
            if travel.feature_traversable(view.feature_at(x+off_x, y+off_y), type) then
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

function tilesOneApart(x1, y1, x2, y2)
    return math.abs(x1 - x2) <= 1 and math.abs(y1 - y2) <= 1
end


function findTwoTilesOnBorder(tiles, xmin, ymin, xmax, ymax)
    local t1found = false
    local t1 = nil
    for tile, _ in pairs(tiles) do
        local x = tile[1]
        local y = tile[2]
        if (x == xmin or x == xmax or y == ymin or y == ymax) then
            if t1found then
                if not tilesOneApart(t1[1], t1[2], x, y) then
                    return t1[1], t1[2], x, y
                end
            else
                t1found = true
                t1 = {x, y}
            end
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

function getDist(x1, y1, x2, y2)
    return math.max(math.abs(x1 - x2), math.abs(y1 - y2))
end

function getNeighboring(tileset, x, y)
    local neighbors = {}
    for ox=-1,1 do
        for oy=-1,1 do
            if mk.get(tileset, x+ox, y+oy) ~= nil and not (ox == 0 and oy == 0) then
                neighbors[{x+ox, y+oy}] = true
            end
        end
    end
    return neighbors
end

function getMinTile(nodes, dist)
    local m = 100000
    local t = nil
    for _, x, y, __ in mk.tuples(nodes) do
        local cost = mk.get(dist, x, y)
        if cost ~= nil and cost <= m then
            m = cost
            t = {x, y}
        end
    end
    return t
end

function getPath(tileset, x1, y1, x2, y2)
    local dist = {}
    local nodes = {}
    local prev = {}
    for _, x, y, trav in mk.tuples(tileset) do
        if trav then
            mk.put(dist, x, y, 10000)
            mk.put(nodes, x, y, true)
            --crawl.mpr("set: x = " .. x .. " y = " .. y)
        end
    end
    mk.put(dist, x1, y1, 0)
    while next(nodes) ~= nil do
        local u = getMinTile(nodes, dist)
        mk.put(nodes, u[1], u[2], nil)
        --crawl.mpr("Getting next: x = " .. u[1] .. " y = " .. u[2])
        if u[1] == x2 and u[2] == y2 then
            if mk.get(prev, u[1], u[2]) == nil then
                crawl.mpr("PANIC U NOT IN PREV")
                assert(false)
            end
            return parsePrev(prev, x1, y1, x2, y2)
        end
        for v, _ in pairs(getNeighboring(nodes, u[1], u[2])) do
            --crawl.mpr("Neighbor: x = " .. v[1] .. " y = " .. v[2])
            local altDist = mk.get(dist, u[1], u[2]) + 1
            if mk.get(dist, v[1], v[2]) == nil or altDist < mk.get(dist, v[1], v[2]) then
                mk.put(dist, v[1], v[2], altDist)
                mk.put(prev, v[1], v[2], u)
                if u == nil then
                    crawl.mpr("WTF")
                    assert(false)
                end
            end
        end
    end
    return nil
end

function parsePrev(prev, x1, y1, x2, y2)
    local path = {}
    local i = 2
    local u = {x2, y2}
    path[1] = u
    while not (u[1] == x1 and u[2] == y1) do
        --crawl.mpr("Adding to path: " .. u[1] .. ", " .. u[2])
        u = mk.get(prev, u[1], u[2])
        if u == nil then
            crawl.mpr("BAD PATH!")
            return nil
        end
        path[i] = u
        i = i + 1
    end
    reverse(path)
    return path
end

function reverse (arr)
	local i, j = 1, #arr

	while i < j do
		arr[i], arr[j] = arr[j], arr[i]

		i = i + 1
		j = j - 1
	end
end

local function getMk()
    -- simple table adaptor for using multiple keys in a lookup table

    -- cache some global functions/tables for faster access
    local assert = assert
    local select = assert( select )
    local next = assert( next )
    local setmetatable = assert( setmetatable )

    -- sentinel values for the key tree, nil keys, and nan keys
    local KEYS, NIL, NAN = {}, {}, {}


    local M = {}
    local M_meta = {
    __index = M
    }


    function M.new()
    return setmetatable( { [ KEYS ] = {} }, M_meta )
    end
    setmetatable( M, { __call = M.new } )


    function M.clear( t )
    for k in next, t do
        t[ k ] = nil
    end
    return t
    end


    -- local helper function to map a vararg of keys to the real key
    local function get_key( key, ... )
    for i = 1, select( '#', ... ) do
        if key == nil then break end
        local e = select( i, ... )
        if e == nil then
        e = NIL
        elseif e ~= e then -- can only happen for NaNs
        e = NAN
        end
        key = key[ e ]
    end
    return key
    end


    function M.get( t, ... )
    local key = get_key( t[ KEYS ], ... )
    if key ~= nil then
        return t[ key ]
    end
    return nil
    end


    -- local helper function for both put variants below
    local function put( t, idx, val, n, ... )
    for i = 1, n do
        local e = select( i, ... )
        if e == nil then
        e = NIL
        elseif e ~= e then -- can only happen for NaNs
        e = NAN
        end
        local nextidx = idx[ e ]
        if not nextidx then
        nextidx = {}
        idx[ e ] = nextidx
        end
        idx = nextidx
    end
    t[ idx ] = val
    end


    -- returns true if tab can be removed from the parent table
    local function del( t, idx, n, ... )
    if n > 0 then
        local e = ...
        if e == nil then
        e = NIL
        elseif e ~= e then -- can only happen for NaNs
        e = NAN
        end
        local nextidx = idx[ e ]
        if nextidx and del( t, nextidx, n-1, select( 2, ... ) ) then
        idx[ e ] = nil
        return t[ idx ] == nil and next( idx ) == nil
        end
        return false
    else
        t[ idx ] = nil
        return next( idx ) == nil
    end
    end


    function M.put( t, ... )
    local n, keys, val = select( '#', ... ), t[ KEYS ], nil
    if n > 0 then
        val = select( n, ... )
        n = n - 1
    end
    if val == nil then
        if keys ~= nil then
        del( t, keys, n, ... )
        end
    else
        if keys == nil then
        keys = {}
        t[ KEYS ] = keys
        end
        put( t, keys, val, n, ... )
    end
    return t
    end


    -- same as M.put, but value comes first not last
    function M.putv( t, val, ... )
    local keys = t[ KEYS ]
    if val == nil then
        if keys ~= nil then
        del( t, keys, select( '#', ... ), ... )
        end
    else
        if keys == nil then
        keys = {}
        t[ KEYS ] = keys
        end
        put( t, keys, val, select( '#', ... ), ... )
    end
    return t
    end


    -- iteration is only available with coroutine support
    if coroutine ~= nil then
    local unpack = assert( unpack or table.unpack )
    local pairs = assert( pairs )
    local ipairs = assert( ipairs )
    local co_yield = assert( coroutine.yield )
    local co_wrap = assert( coroutine.wrap )


    -- internal iterator function
    local function iterate( iter, t, key, keystack, n )
        if t[ key ] ~= nil then
        keystack[ n+1 ] = t[ key ]
        co_yield( unpack( keystack, 1, n+1 ) )
        end
        for k,v in iter( key ) do
        if k == NIL then
            k = nil
        elseif k == NAN then
            k = 0/0
        end
        keystack[ n+1 ] = k
        iterate( iter, t, v, keystack, n+1 )
        end
        return nil
    end


    -- iterator similar to pairs, but since we have multiple keys ...
    function M.tuples( t, ... )
        local vals, n = { true, ... }, select( '#', ... )+1
        return co_wrap( function()
            local key = get_key( t[ KEYS ], unpack( vals, 2, n ) )
            if key ~= nil then
            return iterate( pairs, t, key, vals, n )
            end
        end )
    end


    function M.ituples( t, ... )
        local vals, n = { ... }, select( '#', ... )
        return co_wrap( function()
            local key = get_key( t[ KEYS ], unpack( vals, 1, n ) )
            if key ~= nil then
            return iterate( ipairs, t, key, vals, n )
            end
        end )
    end


    -- Lua 5.2 metamethods for iteration
    M_meta.__pairs = M.tuples
    M_meta.__ipairs = M.ituples
    end


    return M
end

mk = getMk()
