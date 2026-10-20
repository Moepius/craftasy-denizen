# Craftasy – Hortus Manium
# Minecraft Java 26.3 / Denizen
#
# Resource Pack der ersten Version bleibt kompatibel.
#
# /hortusfx pack on   Persönliche Kameraeffekte aktivieren
# /hortusfx pack off  Persönliche Kameraeffekte deaktivieren
# /hortusfx test      Lautlose Partikelentladung testen
# /hortusfx near      Nahen Kameraeffekt testen
# /hortusfx ritual    Seelenritual testen
# /hortusfx on        Automatische Atmosphäre aktivieren
# /hortusfx off       Automatische Atmosphäre deaktivieren
# /hortusfx reset     Eigenen Kameraeffekt entfernen
# /hortusfx status    Status anzeigen
#
# Die archivierten Atmosphärenskripte bleiben außerhalb von scripts/.
# Automatik bleibt ausgeschaltet, bis /hortusfx on verwendet wird.


craftasy_hortus_config:
    type: data
    debug: false

    world: hortusmanium

    # Pro Sekunde eine Chance von 1:6:
    # durchschnittlich zehn Entladungen pro Minute je Spielergruppe.
    strike_chance_denominator: 6
    cluster_radius: 96
    strike_radius: 48

    camera_radius: 80
    near_radius: 20

    # Suche auf Spielerhöhe statt auf der Oberfläche.
    # Das erlaubt Entladungen in Räumen, garantiert aber keinen Innenraum.
    indoor_percent: 25

    # Höhe der vorläufigen Partikelentladung.
    # Massive Blöcke begrenzen die Höhe.
    discharge_height: 16

    # Partikelmengen pro Sekunde und Betrachter.
    ambient_ash: 24
    ambient_souls: 5
    center_souls: 18
    center_sculk: 12

    # Anzahl zufälliger Ausgangspunkte im Seelenschlund.
    pit_samples: 12


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

        # Zusammenstehende Spieler erzeugen keine jeweils eigene Blitzrate.
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
    - if !<[viewer].is_online>:
        - stop

    - define here <[viewer].location>

    # Asche und langsam aufsteigende Seelen im Umfeld des Spielers.
    # targets verhindert eine mehrfache Aussendung an dieselben Zuschauer.
    - playeffect effect:white_ash at:<[here].add[0,3,0]> quantity:<script[craftasy_hortus_config].data_key[ambient_ash]> offset:9,4,9 targets:<[viewer]>
    - playeffect effect:soul at:<[here].add[0,1,0]> quantity:<script[craftasy_hortus_config].data_key[ambient_souls]> offset:14,4,14 velocity:0,0.1,0 targets:<[viewer]>
    - playeffect effect:sculk_soul at:<[here].add[0,1,0]> quantity:4 offset:14,4,14 velocity:0,0.1,0 targets:<[viewer]>

    # Leise Umgebungssounds mit variierenden Abständen.
    - if !<[viewer].has_flag[craftasy_hortus.sound_cooldown]>:
        - flag <[viewer]> craftasy_hortus.sound_cooldown expire:<util.random.int[14].to[24]>s

        - playsound <[viewer]> sound:ambient.soul_sand_valley.loop custom sound_category:AMBIENT volume:0.18 pitch:0.8

        - if <util.random.int[1].to[3]> == 1:
            - playsound <[viewer]> sound:ambient.soul_sand_valley.additions custom sound_category:AMBIENT volume:0.22 pitch:0.85

        - if <util.random.int[1].to[5]> == 1:
            - playsound <[viewer]> sound:ambient.nether_wastes.mood custom sound_category:AMBIENT volume:0.14 pitch:0.9

        - if <util.random.int[1].to[5]> == 1:
            - playsound <[viewer]> sound:ambient.soul_sand_valley.mood custom sound_category:AMBIENT volume:0.15 pitch:0.85

    # Optionaler Conduit-Sound im Ego-Bereich.
    - define ego <cuboid[area_ego].if_null[null]>

    - if <[ego]> != null:
        - if <[here].is_within[<[ego]>]> && !<[viewer].has_flag[craftasy_hortus.ego_sound]>:
            - flag <[viewer]> craftasy_hortus.ego_sound expire:12s
            - playsound <[viewer]> sound:block.conduit.ambient custom sound_category:AMBIENT volume:0.2

    # Begrüßung auf Mons Manium.
    - define mons <cuboid[area_mons_manium].if_null[null]>

    - if <[mons]> != null:
        - if <[here].is_within[<[mons]>]> && !<[viewer].has_flag[craftasy_hortus.title_cooldown]>:
            - flag <[viewer]> craftasy_hortus.title_cooldown expire:10m
            - title "title:<&6>Hortus Manium" "subtitle:<&f>Mons Manium" stay:3s targets:<[viewer]>
            - playsound <[viewer]> sound:block.bell.resonate custom volume:0.25 pitch:0.8
            - playsound <[viewer]> sound:block.beacon.power_select custom volume:0.12 pitch:0.5

    # Deutlicher aufsteigende Seelen im Zentrum bei Velnias.
    - define velnias <location[velnias_location].if_null[null]>

    - if <[velnias]> != null:
        - if <[velnias].world> == <[here].world>:
            - if <[velnias].distance[<[here]>]> < 48:
                - playeffect effect:soul at:<[velnias].add[0,1,0]> quantity:<script[craftasy_hortus_config].data_key[center_souls]> offset:12,4,12 velocity:0,0.1,0 targets:<[viewer]>
                - playeffect effect:sculk_soul at:<[velnias].add[0,1,0]> quantity:<script[craftasy_hortus_config].data_key[center_sculk]> offset:12,4,12 velocity:0,0.1,0 targets:<[viewer]>
                - playeffect effect:soul at:<[velnias].add[0,2,0]> quantity:4 offset:1.5,2,1.5 velocity:0,0.15,0 targets:<[viewer]>

    # Seelenschlund: Original-Cuboid zur räumlichen Verteilung verwenden.
    # Eine fehlende zusätzliche Location-Note verhindert die Partikel nicht.
    - define pit_area <cuboid[area_hortusmanium_zentrum_seelenschlund].if_null[null]>

    - if <[pit_area]> != null:
        - repeat <script[craftasy_hortus_config].data_key[pit_samples]>:
            - define point <[pit_area].random>

            - if <[point].world> != <[here].world>:
                - repeat stop

            - if <[point].distance[<[here]>]> > 64:
                - repeat next

            - playeffect effect:soul at:<[point]> quantity:2 offset:0.4 velocity:0,0.1,0 targets:<[viewer]>
            - playeffect effect:sculk_soul at:<[point]> quantity:1 offset:0.4 velocity:0,0.1,0 targets:<[viewer]>
            - playeffect effect:smoke at:<[point]> quantity:2 offset:0.5 targets:<[viewer]>

            # Variierende Aufwärtsgeschwindigkeit wie in der Archivfassung.
            - define speed <list[1|3|5].random>
            - playeffect effect:soul_fire_flame at:<[point]> quantity:1 offset:0.3 velocity:0,<[speed]>,0 targets:<[viewer]>

    # Kleines Ritual am vorhandenen Ankerpunkt.
    - define pit <location[location_hortusmanium_zentrum_seelenschlund].if_null[null]>

    - if <[pit]> != null:
        - if <[pit].world> == <[here].world>:
            - if <[pit].distance[<[here]>]> < 48:
                - if !<[viewer].has_flag[craftasy_hortus.ritual_cooldown]>:
                    - flag <[viewer]> craftasy_hortus.ritual_cooldown expire:90s
                    - run craftasy_hortus_ritual def:<[viewer]>|<[pit]>


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

    # Maximal zwölf Positionsversuche, ausschließlich in geladenen Chunks.
    - repeat 12:
        - define point <[base].add[<util.random.int[<[radius].mul[-1]>].to[<[radius]>]>,0,<util.random.int[<[radius].mul[-1]>].to[<[radius]>]>]>

        - if !<[point].chunk.is_loaded>:
            - repeat next

        - if <[indoor]>:
            - define point <[point].block>
        - else:
            - define point <[point].highest.add[0,1,0]>

        # Begrenzte Bodensuche.
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

    - define viewers <[point].world.players.filter_tag[<[filter_value].location.distance[<[point]>].is_less_than_or_equal_to[<script[craftasy_hortus_config].data_key[camera_radius]>]>]>

    - if <[viewers].is_empty>:
        - stop

    # Vorläufige, vollständig lautlose Partikelentladung.
    # Kein strike/summon und keine Blitz-Entity.
    # Somit auch keine Blitzschäden, Brände oder Kupferänderungen.
    - define previous <[point]>
    - define height <script[craftasy_hortus_config].data_key[discharge_height]>

    - repeat <[height]> as:step:
        - define axis <[point].add[0,<[step]>,0]>

        - if <[axis].y> >= <[axis].world.max_height>:
            - repeat stop

        # An einer massiven Zimmerdecke endet die Entladung.
        - if <[axis].material.is_solid>:
            - repeat stop

        - define next <[axis].add[<util.random.decimal[-0.45].to[0.45]>,0,<util.random.decimal[-0.45].to[0.45]>]>

        - if <[next].material.is_solid>:
            - define next <[axis]>

        - define segment <[previous].points_between[<[next]>].distance[0.25]>
        - playeffect effect:electric_spark at:<[segment]> quantity:1 offset:0 targets:<[viewers]>

        - define previous <[next]>

    - playeffect effect:electric_spark at:<[point]> quantity:12 offset:0.5,0.4,0.5 targets:<[viewers]>

    - foreach <[viewers]> as:viewer:
        - define strength soft

        - if <[viewer].location.distance[<[point]>]> <= <script[craftasy_hortus_config].data_key[near_radius]>:
            - define strength near

        - run craftasy_hortus_camera def:<[viewer]>|<[strength]>


craftasy_hortus_camera:
    type: task
    debug: false
    definitions: viewer|strength

    script:
    - if !<[viewer].is_online>:
        - stop

    - if !<[viewer].has_flag[craftasy_hortus.pack]>:
        - stop

    - if <[viewer].has_flag[craftasy_hortus.camera_busy]>:
        - stop

    - flag <[viewer]> craftasy_hortus.camera_busy expire:2s

    # Token verhindert, dass eine ältere Queue einen neueren Effekt entfernt.
    - define token <queue.id>
    - flag <[viewer]> craftasy_hortus.camera_token:<[token]>

    - define effect shake_soft
    - define duration 3t

    - if <[strength]> == near:
        - define effect impact_near
        - define duration 5t

    - flag <[viewer]> craftasy_hortus.active_effect:<[effect]>

    # Übergangsschnittstelle:
    # Für diese neuen Post-Effects fehlt im geprüften Denizen-Stand
    # ein nativer Befehl bzw. Player-Mechanismus.
    - execute as_server "minecraft:posteffect add <[viewer].name> craftasy:hortus/<[effect]>" silent

    - wait <[duration]>

    - if !<[viewer].is_online>:
        - stop

    - if <[viewer].flag[craftasy_hortus.camera_token].if_null[none]> != <[token]>:
        - stop

    - execute as_server "minecraft:posteffect remove <[viewer].name> craftasy:hortus/<[effect]>" silent

    - define effect <[effect]>_fade
    - flag <[viewer]> craftasy_hortus.active_effect:<[effect]>

    - execute as_server "minecraft:posteffect add <[viewer].name> craftasy:hortus/<[effect]>" silent

    - wait <[duration]>

    - if !<[viewer].is_online>:
        - stop

    - if <[viewer].flag[craftasy_hortus.camera_token].if_null[none]> == <[token]>:
        - run craftasy_hortus_reset def:<[viewer]>


craftasy_hortus_reset:
    type: task
    debug: false
    definitions: viewer

    script:
    # Ausschließlich unseren aktiven Effekt entfernen.
    # Kein globales "posteffect clear".
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
    - if !<[viewer].is_online>:
        - stop

    - if <[viewer].world> != <[point].world>:
        - stop

    - playsound <[viewer]> sound:entity.evoker.prepare_attack custom volume:0.15 pitch:0.5

    - define ring <[point].points_around_y[radius=5;points=48]>
    - playeffect effect:soul_fire_flame at:<[ring]> quantity:1 offset:0 velocity:0,0.5,0 targets:<[viewer]>

    - wait 12t

    - if !<[viewer].is_online>:
        - stop

    - if <[viewer].world> != <[point].world>:
        - stop

    - if <[viewer].location.distance[<[point]>]> > 64:
        - stop

    - playeffect effect:soul at:<[point]> quantity:35 offset:6,3,6 velocity:0,0.15,0 targets:<[viewer]>
    - playeffect effect:sculk_soul at:<[point]> quantity:18 offset:5,2,5 velocity:0,0.1,0 targets:<[viewer]>
    - playeffect effect:smoke at:<[point]> quantity:24 offset:3,2,3 targets:<[viewer]>
    - playeffect effect:soul at:<[ring]> quantity:1 offset:0 velocity:0,0.2,0 targets:<[viewer]>

    - playsound <[viewer]> sound:entity.illusioner.prepare_blindness custom volume:0.12 pitch:0.7
    - playsound <[viewer]> sound:particle.soul_escape custom volume:0.4 pitch:0.8


craftasy_hortus_command:
    type: command
    debug: false

    name: hortusfx
    description: Hortus-Atmosphäre testen und Kameraeffekte umschalten.
    usage: /hortusfx <&lt>test/near/ritual/on/off/status/pack/reset<&gt>

    tab completions:
        1: test|near|ritual|on|off|status|pack|reset
        2: on|off

    script:
    - if <context.source_type> != PLAYER:
        - announce to_console "Bitte /hortusfx ingame benutzen."
        - stop

    - define action <context.args.get[1].if_null[status].to_lowercase>

    # Persönlicher Schalter ohne Adminberechtigung.
    - if <[action]> == pack:
        - define setting <context.args.get[2].if_null[none].to_lowercase>

        - choose <[setting]>:
            - case on:
                - flag <player> craftasy_hortus.pack
                - narrate "<&a>Hortus-Kameraeffekte aktiviert. Das Resource Pack muss aktiv sein."

            - case off:
                - flag <player> craftasy_hortus.pack:!
                - run craftasy_hortus_reset def:<player>
                - narrate "<&e>Hortus-Kameraeffekte deaktiviert."

            - default:
                - narrate "/hortusfx pack on oder /hortusfx pack off"

        - stop

    - if !<player.is_op> && !<player.has_permission[craftasy.hortus.admin]>:
        - narrate "<&c>Dafür fehlt craftasy.hortus.admin."
        - stop

    - choose <[action]>:
        - case on:
            - flag server craftasy_hortus.enabled
            - narrate "<&a>Automatische Hortus-Atmosphäre aktiviert."

        - case off:
            - flag server craftasy_hortus.enabled:!

            - foreach <server.online_players> as:viewer:
                - run craftasy_hortus_reset def:<[viewer]>

            - narrate "<&e>Automatische Hortus-Atmosphäre deaktiviert."

        - case reset:
            - run craftasy_hortus_reset def:<player>

        - case test:
            - if <player.world.name> != <script[craftasy_hortus_config].data_key[world]>:
                - narrate "<&e>Bitte in Hortus Manium testen."
                - stop

            - run craftasy_hortus_strike def:<player.location.forward[8]>

        - case near:
            - run craftasy_hortus_camera def:<player>|near

        - case ritual:
            - run craftasy_hortus_ritual def:<player>|<player.location.forward[4]>

        - case status:
            - narrate "Automatik=<server.has_flag[craftasy_hortus.enabled]> | Kamera=<player.has_flag[craftasy_hortus.pack]>"
            - narrate "Entladungen=lautlose Partikel"

        - default:
            - narrate "/hortusfx test|near|ritual|on|off|status|pack on/off|reset"