events_test:
  type: world
  enabled: true
  debug: false
  events:
    on fire physics:
      - narrate "huch"
    on leaves decay in:orbis:
      - determine cancelled
    on *_door physics:
      - narrate physics

task_tests:
  type: task
  debug: true
  definitions: ploc|player|ups|radius
  script:
    #- define blocks <[ploc].add[0,5,0].find_blocks.within[<[radius]>]>
    #- foreach <[blocks]> as:b:
    #  - showfake netherite_block <[b].up> players:<[player]>
    #- showfake beacon <[ploc].add[0,<[ups]>,0]> players:<[player]>
    #- adjust <[ploc].add[0,<[ups]>,0]> beacon_primary_effect:haste
    - define ploc <player.location>
    - foreach <list[<util.list_numbers[from=1;to=500]>]> as:b:
      - showfake red_concrete <[ploc].add[0,<[b]>,0]> players:<player> d:50s
