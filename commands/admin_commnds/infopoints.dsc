ausrufezeichen_oben:
    type: entity
    debug: false
    entity_type: item_display
    mechanisms:
      item: yellow_concrete
      scale: 0.15,0.9,0.15
      brightness: sky=15;block=15
      view_range: 40

ausrufezeichen_unten:
    type: entity
    debug: false
    entity_type: item_display
    mechanisms:
      item: yellow_concrete
      scale: 0.15,0.15,0.15
      brightness: sky=15;block=15
      view_range: 40

ausrufezeichen_interact_entity:
    type: entity
    debug: false
    entity_type: interaction
    mechanisms:
      height: 2

### run this to spawn new interact entities
task_display:
  type: task
  debug: false
  definitions: book
  script:
    - spawn ausrufezeichen_oben <player.cursor_on.add[0,3,0]> persistent save:oben
    - spawn ausrufezeichen_unten <player.cursor_on.add[0,2.2,0]> persistent save:unten
    - spawn ausrufezeichen_interact_entity <player.cursor_on.add[0,1,0]> save:interaction
    - flag <entry[interaction].spawned_entity> book:<[book]>
    - run task_animation def:<entry[oben].spawned_entity>
    - run task_animation def:<entry[unten].spawned_entity>

task_animation:
  type: task
  debug: false
  definitions: ent
  script:
  - rotate <[ent]> infinite
  - while <[ent].is_spawned>:
      # aufwärts
      - adjust <[ent]> interpolation_start:0t
      - adjust <[ent]> interpolation_duration:1.2s
      - adjust <[ent]> translation:0,-0.2,0
      - wait 1.2s
      - adjust <[ent]> interpolation_start:0t
      - adjust <[ent]> interpolation_duration:0.7s
      - adjust <[ent]> translation:0,-0.1,0
      - wait 0.7s
      # abwärts
      - adjust <[ent]> interpolation_start:0t
      - adjust <[ent]> interpolation_duration:1.2s
      - adjust <[ent]> translation:0,0.2,0
      - wait 1.2s
      - adjust <[ent]> interpolation_start:0t
      - adjust <[ent]> interpolation_duration:0.7s
      - adjust <[ent]> translation:0,0.1,0
      - wait 0.7s

info_item_handler:
  type: world
  enabled: true
  debug: false
  events:
    on player right clicks ausrufezeichen_interact_entity:
      - ratelimit <player> 1t
      - wait 1t
      - playsound <player> sound:item_book_page_turn
      - adjust <player> show_book:<context.entity.flag[book].if_null[kolonien_info]>

command_ipcreate:
    type: command
    debug: false
    name: ipcreate
    usage: /ipcreate [script]
    description: Creates an info-point at the given location.
    tab completions:
        1: <static[<util.scripts.filter[container_type.equals[book]].parse[name]>]>
    script:
    - if <context.source_type> != PLAYER:
        - narrate "<&c>Only a player can use this command!"
        - stop
    - define name <context.args.first.if_null[Null]>
    - if <[name]> == Null:
        - narrate "<&c>You need to provide name of the book script!"
        - stop
    - define script <script[<[name]>].if_null[Null]>
    - if <[script]> == Null or <[script].container_type> != book:
        - narrate "<&c>This script does not exist or is not a book type!"
        - stop
    - narrate "<&a>You have succesfully create an info-point!"
    - run task_display def:<[script].name>

command_ipremove:
    type: command
    debug: false
    name: ipremove
    usage: /ipremove
    description: Removes an info-point at the given location.
    script:
    - if <context.source_type> != PLAYER:
        - narrate "<&c>Only a player can use this command!"
        - stop
    - define interaction_entity  <player.eye_location.ray_trace_target[entities=INTERACTION].if_null[Null]>
    - if <[interaction_entity]> == Null or <[interaction_entity].script.name> != ausrufezeichen_interact_entity:
        - narrate "<&c>No info-points found!"
        - stop
    - define item_displays <[interaction_entity].location.find_entities[item_display].within[3].first[2].if_null[Null]>
    - if <[item_displays]> == Null:
        - narrate "<&c>This... should not happen..?"
        - stop
    - remove <[interaction_entity]>
    - remove <[item_displays]>
    - narrate "<&c>Succesfully removed info-point"
