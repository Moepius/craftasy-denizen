# Craftasy / Hortus Manium atmosphere, Minecraft Java 26.3 + Denizen 1.3.4.
# First: /hortusfx test, /hortusfx ritual. Install pack, then /hortusfx pack on.
# Enable automatic atmosphere: /hortusfx on. Disable: /hortusfx off.
# pack on/off is a personal accessibility switch; all other commands require
# craftasy.hortus.admin or OP. Pack effects never change the player's aim.
# Old hortusmanium_handler MUST remain outside scripts/.
# Optional existing notes are reused; missing notes simply skip that feature.

craftasy_hortus_config:
    type: data
    debug: false
    world: hortusmanium
    # 1 in 6 each second = 10/minute on average, not a fixed schedule.
    strike_chance_denominator: 6
    cluster_radius: 96
    strike_radius: 48
    camera_radius: 80
    near_radius: 20
    # Indoor attempts use the player's height; outdoors use the surface.
    indoor_percent: 25

craftasy_hortus_events:
    type: world
    debug: false
    events:
        on system time secondly:
        - if !<server.has_flag[craftasy_hortus.enabled]>:
            - stop
        - define world <world[<script[craftasy_hortus_config].data_key[world]>].if_null[null]>
        - if <[world]> == null:
            - stop
        - define remaining <[world].players>
        - foreach <[remaining]> as:viewer:
            - run craftasy_hortus_ambient def:<[viewer]>
        # Group nearby viewers so ten players together do not cause 100 strikes/min.
        # No persistent queues: script reloads cannot duplicate a background loop.
        - while !<[remaining].is_empty>:
            - define anchor <[remaining].first>
            - define group <[remaining].filter_tag[<[filter_value].location.distance[<[anchor].location>].is_less_than[<script[craftasy_hortus_config].data_key[cluster_radius]>]>]>
            - define remaining <[remaining].exclude[<[group]>]>
            - if <util.random.int[1].to[<script[craftasy_hortus_config].data_key[strike_chance_denominator]>]> == 1:
                - run craftasy_hortus_random_strike def:<[group].random>
        on player changes world:
        - run craftasy_hortus_reset def:<player>
        on player quits:
        - run craftasy_hortus_reset def:<player>
        on script reload:
        - foreach <server.online_players> as:viewer:
            - run craftasy_hortus_reset def:<[viewer]>

craftasy_hortus_ambient:
    type: task
    debug: false
    definitions: viewer
    script:
    - define here <[viewer].location>
    # Small client-local clouds instead of thousands of random cuboid calls.
    - playeffect effect:white_ash at:<[here].add[0,3,0]> quantity:24 offset:9,4,9 targets:<[viewer]>
    - playeffect effect:sculk_soul at:<[here].add[0,1,0]> quantity:4 offset:7,2,7 targets:<[viewer]>
    - playeffect effect:soul at:<[here].add[0,1,0]> quantity:2 offset:6,2,6 targets:<[viewer]>
    - if !<[viewer].has_flag[craftasy_hortus.sound_cooldown]>:
        - flag <[viewer]> craftasy_hortus.sound_cooldown expire:<util.random.int[14].to[24]>s
        - playsound <[viewer]> sound:ambient.soul_sand_valley.loop custom sound_category:AMBIENT volume:0.18 pitch:0.8
        - if <util.random.int[1].to[3]> == 1:
            - playsound <[viewer]> sound:ambient.soul_sand_valley.additions custom sound_category:AMBIENT volume:0.22 pitch:0.85
        - if <util.random.int[1].to[5]> == 1:
            - playsound <[viewer]> sound:ambient.nether_wastes.mood custom sound_category:AMBIENT volume:0.14 pitch:0.9
        - if <util.random.int[1].to[5]> == 1:
            - playsound <[viewer]> sound:ambient.soul_sand_valley.mood custom sound_category:AMBIENT volume:0.15 pitch:0.85
    - define ego <cuboid[area_ego].if_null[null]>
    - if <[ego]> != null:
        - if <[here].is_within[<[ego]>]> && !<[viewer].has_flag[craftasy_hortus.ego_sound]>:
            - flag <[viewer]> craftasy_hortus.ego_sound expire:12s
            - playsound <[viewer]> sound:block.conduit.ambient custom sound_category:AMBIENT volume:0.2
    - define mons <cuboid[area_mons_manium].if_null[null]>
    - if <[mons]> != null:
        - if <[here].is_within[<[mons]>]> && !<[viewer].has_flag[craftasy_hortus.title_cooldown]>:
            - flag <[viewer]> craftasy_hortus.title_cooldown expire:10m
            - title "title:<&6>Hortus Manium" "subtitle:<&f>Mons Manium" stay:3s targets:<[viewer]>
            - playsound <[viewer]> sound:block.bell.resonate custom volume:0.25 pitch:0.8
            - playsound <[viewer]> sound:block.beacon.power_select custom volume:0.12 pitch:0.5
    - define pit <location[location_hortusmanium_zentrum_seelenschlund].if_null[null]>
    - if <[pit]> != null:
        - if <[pit].world> == <[here].world>:
            - if <[pit].distance[<[here]>]> < 64:
                - playeffect effect:soul at:<[pit]> quantity:12 offset:3,4,3 targets:<[viewer]>
                - playeffect effect:sculk_soul at:<[pit]> quantity:8 offset:3,3,3 targets:<[viewer]>
                - playeffect effect:smoke at:<[pit]> quantity:12 offset:3,2,3 targets:<[viewer]>
                - playeffect effect:soul_fire_flame at:<[pit]> quantity:5 offset:2,1,2 targets:<[viewer]>
                - if !<[viewer].has_flag[craftasy_hortus.ritual_cooldown]>:
                    - flag <[viewer]> craftasy_hortus.ritual_cooldown expire:90s
                    - run craftasy_hortus_ritual def:<[viewer]>|<[pit]>
    - define velnias <location[velnias_location].if_null[null]>
    - if <[velnias]> != null:
        - if <[velnias].world> == <[here].world>:
            - if <[velnias].distance[<[here]>]> < 32:
                - playeffect effect:soul at:<[velnias].add[0,2,0]> quantity:3 offset:0.7,1,0.7 targets:<[viewer]>

craftasy_hortus_random_strike:
    type: task
    debug: false
    definitions: anchor
    script:
    - if !<[anchor].is_online>:
        - stop
    - define base <[anchor].location>
    - define radius <script[craftasy_hortus_config].data_key[strike_radius]>
    - define indoor <util.random.int[1].to[100].is_less_than_or_equal_to[<script[craftasy_hortus_config].data_key[indoor_percent]>]>
    # Bounded search, loaded chunks only. Skip a strike if no valid floor exists.
    - repeat 12:
        - define point <[base].add[<util.random.int[<[radius].mul[-1]>].to[<[radius]>]>,0,<util.random.int[<[radius].mul[-1]>].to[<[radius]>]>]>
        - if !<[point].chunk.is_loaded>:
            - repeat next
        - if !<[indoor]>:
            - define point <[point].highest.add[0,1,0]>
        - else:
            - define point <[point].block>
        - repeat 20:
            - if <[point].y> <= <[point].world.min_height.add[1]>:
                - repeat stop
            - if <[point].below.material.is_solid> && !<[point].material.is_solid> && !<[point].above.material.is_solid>:
                - run craftasy_hortus_strike def:<[point].center>
                - stop
            - define point <[point].below>

craftasy_hortus_strike:
    type: task
    debug: false
    definitions: point
    script:
    - if !<[point].chunk.is_loaded>:
        - stop
    # Visual lightning: no entity damage or creeper charging; silent on 26.3.
    - strike <[point]> no_damage silent
    - playeffect effect:electric_spark at:<[point]> quantity:12 offset:0.5,0.4,0.5 visibility:80
    - foreach <[point].world.players> as:viewer:
        - define distance <[viewer].location.distance[<[point]>]>
        - if <[distance]> <= <script[craftasy_hortus_config].data_key[camera_radius]>:
            - define strength soft
            - if <[distance]> <= <script[craftasy_hortus_config].data_key[near_radius]>:
                - define strength near
            - run craftasy_hortus_camera def:<[viewer]>|<[strength]>

craftasy_hortus_camera:
    type: task
    debug: false
    definitions: viewer|strength
    script:
    - if !<[viewer].is_online> || !<[viewer].has_flag[craftasy_hortus.pack]> || <[viewer].has_flag[craftasy_hortus.camera_busy]>:
        - stop
    - flag <[viewer]> craftasy_hortus.camera_busy expire:2s
    - define token <queue.id>
    - flag <[viewer]> craftasy_hortus.camera_token:<[token]>
    - define effect shake_soft
    - define duration 3t
    - if <[strength]> == near:
        - define effect impact_near
        - define duration 5t
    - flag <[viewer]> craftasy_hortus.active_effect:<[effect]>
    - execute as_server "minecraft:posteffect add <[viewer].name> craftasy:hortus/<[effect]>" silent
    - wait <[duration]>
    - if !<[viewer].is_online> || <[viewer].flag[craftasy_hortus.camera_token].if_null[none]> != <[token]>:
        - stop
    - execute as_server "minecraft:posteffect remove <[viewer].name> craftasy:hortus/<[effect]>" silent
    - define effect <[effect]>_fade
    - flag <[viewer]> craftasy_hortus.active_effect:<[effect]>
    - execute as_server "minecraft:posteffect add <[viewer].name> craftasy:hortus/<[effect]>" silent
    - wait <[duration]>
    - if <[viewer].is_online> && <[viewer].flag[craftasy_hortus.camera_token].if_null[none]> == <[token]>:
        - run craftasy_hortus_reset def:<[viewer]>

craftasy_hortus_reset:
    type: task
    debug: false
    definitions: viewer
    script:
    # Remove only OUR active effect; never clear another pack/plugin's effects.
    - if <[viewer].has_flag[craftasy_hortus.active_effect]>:
        - execute as_server "minecraft:posteffect remove <[viewer].name> craftasy:hortus/<[viewer].flag[craftasy_hortus.active_effect]>" silent
    - flag <[viewer]> craftasy_hortus.active_effect:!
    - flag <[viewer]> craftasy_hortus.camera_busy:!
    - flag <[viewer]> craftasy_hortus.camera_token:!

craftasy_hortus_ritual:
    type: task
    debug: false
    definitions: viewer|point
    script:
    - if !<[viewer].is_online> || <[viewer].world> != <[point].world>:
        - stop
    - playsound <[viewer]> sound:entity.evoker.prepare_attack custom volume:0.15 pitch:0.5
    - define ring <[point].points_around_y[radius=5;points=48]>
    - playeffect effect:soul_fire_flame at:<[ring]> quantity:1 offset:0 targets:<[viewer]>
    - wait 12t
    - if !<[viewer].is_online> || <[viewer].world> != <[point].world>:
        - stop
    - if <[viewer].location.distance[<[point]>]> > 64:
        - stop
    - playeffect effect:soul at:<[point]> quantity:45 offset:3,4,3 targets:<[viewer]>
    - playeffect effect:smoke at:<[point]> quantity:30 offset:3,2,3 targets:<[viewer]>
    - playeffect effect:soul at:<[ring]> quantity:1 offset:0 targets:<[viewer]>
    - playsound <[viewer]> sound:entity.illusioner.prepare_blindness custom volume:0.12 pitch:0.7
    - playsound <[viewer]> sound:particle.soul_escape custom volume:0.4 pitch:0.8

craftasy_hortus_command:
    type: command
    debug: false
    name: hortusfx
    description: Hortus-Atmosphaere testen und Kamerabewegung umschalten.
    usage: /hortusfx <test/near/ritual/on/off/status/pack/reset>
    tab completions:
        1: test|near|ritual|on|off|status|pack|reset
        2: on|off
    script:
    - if <context.source_type> != PLAYER:
        - announce to_console "Bitte /hortusfx ingame benutzen."
        - stop
    - define action <context.args.get[1].if_null[status].to_lowercase>
    - if <[action]> == pack:
        - if <context.args.get[2].if_null[off]> == on:
            - flag <player> craftasy_hortus.pack
            - narrate "<&a>Hortus-Kameraeffekte an. Das Craftasy-Pack muss aktiviert sein."
        - else:
            - flag <player> craftasy_hortus.pack:!
            - run craftasy_hortus_reset def:<player>
            - narrate "<&e>Hortus-Kameraeffekte aus."
        - stop
    - if !<player.is_op> && !<player.has_permission[craftasy.hortus.admin]>:
        - narrate "<&c>Dafuer fehlt craftasy.hortus.admin. /hortusfx pack on/off ist frei."
        - stop
    - choose <[action]>:
        - case on:
            - flag server craftasy_hortus.enabled
            - narrate "<&a>Automatische Hortus-Atmosphaere aktiviert."
        - case off:
            - flag server craftasy_hortus.enabled:!
            - foreach <server.online_players> as:viewer:
                - run craftasy_hortus_reset def:<[viewer]>
            - narrate "<&e>Automatische Hortus-Atmosphaere deaktiviert."
        - case reset:
            - run craftasy_hortus_reset def:<player>
        - case test:
            - run craftasy_hortus_camera def:<player>|soft
            - if <player.world.name> == <script[craftasy_hortus_config].data_key[world]>:
                - run craftasy_hortus_strike def:<player.location.forward[8]>
            - else:
                - narrate "<&e>Nur Kameratest. Blitztest bitte in Hortus Manium."
        - case near:
            - run craftasy_hortus_camera def:<player>|near
        - case ritual:
            - run craftasy_hortus_ritual def:<player>|<player.location.forward[4]>
        - case status:
            - narrate "Auto=<server.has_flag[craftasy_hortus.enabled]> | Pack/Kamera=<player.has_flag[craftasy_hortus.pack]>"
        - default:
            - narrate "/hortusfx test|near|ritual|on|off|status|pack on/off|reset"
