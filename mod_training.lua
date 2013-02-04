LICENSE = [[
mod_training.lua

Copyright (c) 2013 Phil Hassey

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

MODES = {
    {id="tunnel",   name="Tunneling"},
    {id="survival", name="Survival"},
    {id="defense",  name="Defense"},
}

function reset()
    OPTS = {
        sw = 640,
        sh = 480,    
    }
end
 
function init()
    math.randomseed(os.time());

    COLORS = {0x555555,
        0x0000ff,0xff0000,
        0xffff00,0x00ffff,
        0xffffff,0xffbb00,
        0x99ff99,0xff9999,
        0xbb00ff,0xff88ff,
        0x9999ff,0x00ff00,
    }

    main_menu();

    g2_param_set("state","menu");
end

function loop(t)
    OPTS.time = OPTS.time + t
    over, victory = _ENV[OPTS.mode .. "_loop"](t)
    if over then
        g2_param_set("state","pause");

        if victory then
            _ENV[OPTS.mode .. "_victory"](winner);
        else
            _ENV[OPTS.mode .. "_failure"](winner);
        end
    end
end

function fix(v,d,a,b)
    if (type(v) == "string") then v = tonumber(v) end
    if (type(v) ~= "number") then v = d end
    if v < a then v = a end
    if v > b then v = b end
    return v
end

function start()
    _ENV[OPTS.mode .. "_setup"]();
    _ENV[OPTS.mode .. "_init"]();
    OPTS.time = nil;
    get_ready();
    g2_param_set("state","pause")
end

function event(e)
    if e["type"] == "onclick" and e["value"] then
        if string.find(e["value"],"mode:") ~= nil then
            OPTS.mode = string.sub(e["value"],6)
            _ENV[OPTS.mode .. "_menu"]()
        elseif string.find(e["value"],"newmap:") ~= nil then
            OPTS.data = string.sub(e["value"],8)
            start();
        elseif string.find(e["value"],"restart:") ~= nil then
            OPTS.data = string.sub(e["value"],9)
            start();
        elseif e["value"] == "newmap" or e["value"] == "restart" then
            start();
        elseif e["value"] == "home" then
            main_menu();
        elseif (e["value"] == "resume") then
            if OPTS.time == nil then OPTS.time = 0; end
            g2_param_set("state","play");
        elseif (e["value"] == "quit") then
            g2_param_set("state","quit");
        end

    elseif e["type"] == "pause" then
        paused();
        g2_param_set("state","pause");
    end
end

function main_menu()
    reset();

    local buttons = ""
    for _,v in ipairs(MODES) do
        buttons = buttons .. "<tr><td><input type='button' value='"..v["name"].."' onclick='mode:"..v["id"].."'/>"
    end

    g2_param_set("html", [[
        <table>
            <tr><td><h1>Training Mod</h1>
            <tr><td><p>by Milagre</p>
            <tr><td><p></p>
            <tr><td><p>Select a Training Scenario</p>
            ]]..buttons..[[
        </table>
    ]]);
end

function get_ready()
    g2_param_set("html", ""..
    "<table>"..
    "<tr><td><h1>Get Ready!</h1>"..
    "<tr><td><input type='button' value='Tap to Begin' onclick='resume' />"..
    "");
end

function paused()
    local restart_opts = ""
    if OPTS.data then
        restart_opts = ":" .. OPTS.data
    end
    g2_param_set("html", ""..
    "<table>"..
    "<tr><td><input type='button' value='Resume'          onclick='resume' />"..
    "<tr><td><input type='button' value='Restart'         onclick='restart"..restart_opts.."' />"..
    "<tr><td><input type='button' value='Change Settings' onclick='mode:"..OPTS.mode.."' />"..
    "<tr><td><input type='button' value='New Challenge'   onclick='home' />"..
    "<tr><td><input type='button' value='Quit'            onclick='quit' />"..
    "");
end

---- {{{ TUNNEL

function tunnel_menu()
    g2_param_set("html", [[
        <table><tr><td colspan=2><h1>Tunneling Training</h1>
        <tr><td colspan=2><p>How fast can you take every planet?</p>
        <tr><td colspan=2><p></p>
        <tr><td><p>Planets:</p><td><input type='text' name='planets'/>
        <tr><td><p>Cost:</p><td><input type='text' name='cost'/>
        <tr><td colspan=2><p></p>
        <tr>
        <td><input width=100 type='button' value='Back' onclick='home'/>
        <td><input type='button' value="Let's Go!" onclick='newmap' />
        </table>
    ]]);

    g2_gui_set("planets",    10);
    g2_gui_set("cost",       5);
end

function tunnel_setup()
    OPTS.planets    = fix(g2_gui_get("planets")    or OPTS.planets,    10, 5,  25)
    OPTS.cost       = fix(g2_gui_get("cost")       or OPTS.cost,       5,  2,  15)
end

function tunnel_init()
    g2_game_reset();
    
    local neutral = g2_user_init("neutral", COLORS[1]);
    g2_item_set(neutral,"user_neutral",1);
    g2_item_set(neutral,"ships_production_enabled",0);
    
    local player = g2_user_init("player", COLORS[2]);
    g2_item_set(player,"has_player",1);

    g2_planet_init(player, 0, 0, 25, 100);
    for i=1,OPTS.planets do
        g2_planet_init(neutral, 40*i, 0, 25, OPTS.cost);
    end
   
    g2_planets_settle();
end

function tunnel_loop(t)
    local won = true;
    for i,pid in ipairs(g2_items_find("planet")) do
        if g2_item_get(g2_item_get(pid,"owner_n"), "user_neutral") == 1 then
            won = false;
            break;
        end
    end
    return won, won;
end

function tunnel_victory() 
    local rank = math.floor(10 - (((OPTS.time/OPTS.planets) * 10) - 10))
    rank = fix(rank,1,1,10);
    g2_param_set("html", ""..
    "<table>"..
    "<tr><td><h1>Good Job!</h1>"..
    "<tr><td><p>Time: " .. string.format("%d", OPTS.time) .. " seconds</p>"..
    "<tr><td>"..
    "<tr><td>"..
    "<input type='image' src='rank"..rank..".png' width=34 height=34/>"..
    "<tr><td><input type='button' value='Replay' onclick='restart' />"..
    "<tr><td><input type='button' value='Change Settings' onclick='mode:tunnel' />"..
    "<tr><td><input type='button' value='New Challenge' onclick='home' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "");
end

failure_tunnel = victory_tunnel

---- }}} 
---- {{{ SURVIVAL

function survival_menu()
    local html = string.gsub(([[
        <table>
        <tr><td colspan=5><h1>Survival Training</h1>
        <tr><td colspan=5><p>Survive for 60 seconds</p>
        <tr><td colspan=5><p>You must always have at least one planet</p>
        <tr><td colspan=5><p></p>
        <tr>
        <td><input type='image' src='rank1.png' width=$Z height=$Z onclick='newmap:1' />
        <td><input type='image' src='rank2.png' width=$Z height=$Z onclick='newmap:2' />
        <td><input type='image' src='rank3.png' width=$Z height=$Z onclick='newmap:3' />
        <td><input type='image' src='rank4.png' width=$Z height=$Z onclick='newmap:4' />
        <td><input type='image' src='rank5.png' width=$Z height=$Z onclick='newmap:5' />
        <tr>
        <td><input type='image' src='rank6.png' width=$Z height=$Z onclick='newmap:6' />
        <td><input type='image' src='rank7.png' width=$Z height=$Z onclick='newmap:7' />
        <td><input type='image' src='rank8.png' width=$Z height=$Z onclick='newmap:8' />
        <td><input type='image' src='rank9.png' width=$Z height=$Z onclick='newmap:9' />
        <td><input type='image' src='rank10.png' width=$Z height=$Z onclick='newmap:10' />
        <tr><td colspan=5><p></p>
        <tr><td colspan=5><input type='button' value='Back' onclick='home'/>
        </table>
    ]]), "$Z", 34)
    g2_param_set("html", html);
end

function survival_setup()
    OPTS.difficulty = fix(OPTS.data, 1, 1, 10);
end

function survival_draw_planets(player, distance, number, cost, production)
    for i=1,number,1 do
        local angle = math.rad(180.0 * (i-1)/(number-1))
        local x = distance*math.cos(angle)
        local y = distance*math.sin(angle)
        g2_planet_init(player, x, y, production, cost);
    end
end

function survival_init()
    g2_game_reset();

    local neutral = g2_user_init("neutral", COLORS[1]);
    g2_item_set(neutral,"user_neutral",1);
    g2_item_set(neutral,"ships_production_enabled",0);
 
    local player = g2_user_init("player", COLORS[2]);
    local enemy1 = g2_user_init("enemy1", COLORS[3]);
    local enemy2 = g2_user_init("enemy2", COLORS[4]);
    
    g2_item_set(player,"has_player",1);
    g2_item_set(enemy1, "bot_name","");
    g2_item_set(enemy2, "bot_name","");

    OPTS.player = player;
    OPTS.homes = {
        g2_planet_init(player, 25, 0, 100, 100),
        g2_planet_init(player, -25, 0, 100, 100),
    }

    survival_draw_planets(neutral, 150, 5, 25, 100);
    survival_draw_planets(neutral, 300, 5, 25, 100);

    OPTS.enemies = {
        g2_planet_init(enemy1, 150, -400, 250, OPTS.difficulty * 50 + 500),
        g2_planet_init(enemy2, -150, -400, 250, OPTS.difficulty * 50 + 500),
    }

    g2_planets_settle();
end

function survival_loop(t)

    local users = g2_items_find("user");
    for _i,uid in ipairs(users) do
        local bot_name = g2_item_get(uid,"bot_name");
        if g2_item_get(uid, "has_player") ~= 1 then
            local planets = g2_items_find("planet");
            local player_planets = {}
            for _i,n in ipairs(planets) do
                if g2_item_get(n, "owner_n") == OPTS.player then
                    table.insert(player_planets, n)
                end
            end
            for _i,n in ipairs(planets) do
                if g2_item_get(n,"owner_n") == uid then
                    local count = g2_item_get(n,"ships_value");
                    -- Player home
                    if n ~= OPTS.enemies[1] and n ~= OPTS.enemies[2] then
                        if count > 30 + (OPTS.difficulty * 2) then
                            g2_fleet_send(50,n,player_planets[math.random(1,#player_planets)])
                        end
                    elseif count > OPTS.difficulty * 50 + 500 then
                        local target = 1;
                        if n == OPTS.enemies[2] then
                            target = 2
                        end
                        g2_fleet_send(10,n,OPTS.homes[target])
                    end
                end
            end
        end
    end


    local alive = false;
    for i,pid in ipairs(g2_items_find("planet")) do
        if g2_item_get(g2_item_get(pid,"owner_n"), "has_player") == 1 then
            alive = true;
            break;
        end
    end

    local over = (OPTS.time >= 60) or not alive
    return over, alive
end

function survival_victory() 
    local html = string.gsub((""..
    "<table>"..
    "<tr><td><h1>Good Job!</h1>"..
    "<tr><td><input type='image' src='rank"..OPTS.difficulty..".png' width=$Z height=$Z/>"..
    "<tr><td>"..
    "<tr><td><input type='button' value='Replay' onclick='newmap:"..OPTS.difficulty.."' />"..
    "<tr><td><input type='button' value='Change Settings' onclick='mode:survival' />"..
    "<tr><td><input type='button' value='New Challenge' onclick='home' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    ""), "$Z", 34);
    g2_param_set("html", html);
end

function survival_failure()
    g2_param_set("html", ""..
    "<table>"..
    "<tr><td><h1>You died =(</h1>"..
    "<tr><td>"..
    "<tr><td><input type='button' value='Try Again' onclick='newmap:"..OPTS.difficulty.."' />"..
    "<tr><td><input type='button' value='Change Settings' onclick='mode:survival' />"..
    "<tr><td><input type='button' value='New Challenge' onclick='home' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "")
end


---- }}} 
---- {{{ DEFENSE

function defense_menu()
    local html = string.gsub(([[
        <table>
        <tr><td colspan=5><h1>Defense Training</h1>
        <tr><td colspan=5><p>Don't lose any planets!</p>
        <tr><td colspan=5><p>Each game lasts 90 seconds</p>
        <tr><td colspan=5><p></p>
        <tr>
        <td><input type='image' src='rank1.png' width=$Z height=$Z onclick='newmap:1' />
        <td><input type='image' src='rank2.png' width=$Z height=$Z onclick='newmap:2' />
        <td><input type='image' src='rank3.png' width=$Z height=$Z onclick='newmap:3' />
        <td><input type='image' src='rank4.png' width=$Z height=$Z onclick='newmap:4' />
        <td><input type='image' src='rank5.png' width=$Z height=$Z onclick='newmap:5' />
        <tr>
        <td><input type='image' src='rank6.png' width=$Z height=$Z onclick='newmap:6' />
        <td><input type='image' src='rank7.png' width=$Z height=$Z onclick='newmap:7' />
        <td><input type='image' src='rank8.png' width=$Z height=$Z onclick='newmap:8' />
        <td><input type='image' src='rank9.png' width=$Z height=$Z onclick='newmap:9' />
        <td><input type='image' src='rank10.png' width=$Z height=$Z onclick='newmap:10' />
        <tr><td colspan=5><p></p>
        <tr><td colspan=5><input type='button' value='Back' onclick='home'/>
        </table>
    ]]), "$Z", 34)
    g2_param_set("html", html);
end

function defense_setup()
    OPTS.difficulty = fix(OPTS.data, 1, 1, 10);
 
    OPTS.t    = 3
    OPTS.wait = 4
end

function defense_draw_planets(players, distance, number, cost, production)
    for i=1,number,1 do
        local angle = math.rad(360.0 * (i-1)/(number))
        local x = distance*math.cos(angle)
        local y = distance*math.sin(angle)
        g2_planet_init(players[i], x, y, production, cost);
    end
end

function defense_init()
    g2_game_reset();

    OPTS.player = g2_user_init("player", COLORS[2]);

    OPTS.enemies = {
        g2_user_init("enemy", COLORS[3]),
        g2_user_init("enemy", COLORS[4]),
        g2_user_init("enemy", COLORS[5]),
        g2_user_init("enemy", COLORS[6]),
        g2_user_init("enemy", COLORS[7]),
        g2_user_init("enemy", COLORS[8]),
    }
    
    g2_item_set(OPTS.player, "has_player",1);
    for i=1,#OPTS.enemies,1 do
        g2_item_set(OPTS.enemies[i], "bot_name", "");
    end

    OPTS.homes = {
        g2_planet_init(OPTS.player, 0, 0, 100, 100),
        g2_planet_init(OPTS.player, math.random(30,50),    -1*math.random(30,50), 25, 50),
        g2_planet_init(OPTS.player, math.random(30,50),    math.random(30,50),    25, 50),
        g2_planet_init(OPTS.player, -1*math.random(30,50), -1*math.random(30,50), 25, 50),
        g2_planet_init(OPTS.player, -1*math.random(30,50), math.random(30,50),    25, 50),
    }

    defense_draw_planets(OPTS.enemies, 250, 6, 200, 100)

    g2_planets_settle();
end

function defense_dist(p1, p2)
    local x1 = g2_item_get(p1, "position_x");
    local y1 = g2_item_get(p1, "position_y");
    local x2 = g2_item_get(p2, "position_x");
    local y2 = g2_item_get(p2, "position_y");
    return math.sqrt((x1-x2)^2 + (y1-y2)^2) 
end

function defense_closest_planet(planet, targets)
    local closest = targets[1]
    local current_dist = defense_dist(planet, closest)
    for i=2,#targets,1 do
        local this_dist = defense_dist(planet, targets[i])
        if this_dist <= current_dist then
            closest = targets[i]
            current_dist = this_dist
        end
    end

    return closest
end

function defense_loop(t)
    OPTS.t = OPTS.t + t
    if OPTS.t >= OPTS.wait or OPTS.time >= 89.4 then
        OPTS.t = OPTS.t - OPTS.wait
        local planets = g2_items_find("planet");
        local player_count = 8
        for _i,n in ipairs(planets) do
            if g2_item_get(n,"owner_n") == OPTS.player then
                player_count = player_count + g2_item_get(n, "ships_value")
            end
        end
        local fleets = g2_items_find("fleet");
        for _i,n in ipairs(fleets) do
            if g2_item_get(n,"owner_n") == OPTS.player then
                player_count = player_count + g2_item_get(n, "ships_value")
            end
        end
        local uid = OPTS.enemies[math.random(1,#OPTS.enemies)]
        for _i,n in ipairs(planets) do
            if g2_item_get(n,"owner_n") == uid then
                local count = g2_item_get(n,"ships_value");
                local target = defense_closest_planet(n, OPTS.homes)
                local perc = (player_count * 100)/(count*(11 - (OPTS.difficulty/2.3 + 5)))
                perc = fix(perc, 100, 1, 100)
                g2_fleet_send(perc,n,target)
            end
        end
    end

    local count = 0;
    for i,pid in ipairs(g2_items_find("planet")) do
        if g2_item_get(g2_item_get(pid,"owner_n"), "has_player") == 1 then
            count = count + 1
        end
    end

    local over = (OPTS.time >= 90) or count ~= 5
    return over, count == 5 
end

function defense_victory() 
    local html = string.gsub((""..
    "<table>"..
    "<tr><td><h1>Good Job!</h1>"..
    "<tr><td><input type='image' src='rank"..OPTS.difficulty..".png' width=$Z height=$Z/>"..
    "<tr><td>"..
    "<tr><td><input type='button' value='Replay' onclick='newmap:"..OPTS.difficulty.."' />"..
    "<tr><td><input type='button' value='Change Settings' onclick='mode:defense' />"..
    "<tr><td><input type='button' value='New Challenge' onclick='home' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    ""), "$Z", 34);
    g2_param_set("html", html);
end

function defense_failure()
    g2_param_set("html", ""..
    "<table>"..
    "<tr><td><h1>You died =(</h1>"..
    "<tr><td>"..
    "<tr><td><input type='button' value='Try Again' onclick='newmap:"..OPTS.difficulty.."' />"..
    "<tr><td><input type='button' value='Change Settings' onclick='mode:defense' />"..
    "<tr><td><input type='button' value='New Challenge' onclick='home' />"..
    "<tr><td><input type='button' value='Quit' onclick='quit' />"..
    "")
end


---- }}} 

