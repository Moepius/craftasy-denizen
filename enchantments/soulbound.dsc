soulbound_handler:
    type: world
    enabled: true
    debug: true
    events:
        on player death:
        - stop if:!<player.inventory.contains_item[item_enchanted:soulbound]>
        - flag <player> soulbound_items:<list[]>
        - flag <player> soulbound
        - define items <list[]>
        - define filter <player.inventory.list_contents.filter_tag[<[filter_value].advanced_matches[item_enchanted:soulbound]>]>
        - foreach <[filter]> as:item:
            - flag <player> soulbound_items:->:<[item]>
        - determine <context.drops.exclude[<[filter]>]>
        after player respawns flagged:soulbound:
        - wait 2s
        - playsound <player> sound:entity_allay_item_given pitch:0.2
        - foreach <player.flag[soulbound_items]> as:item:
            - give <[item].with[lore=<&7>Soulbound]>
        - foreach <player.inventory.map_slots> key:key as:val:
            #- define val <item[<[val]>]>
            - if <[val].advanced_matches[item_enchanted:soulbound]>:
                - narrate "<[key]> is set as <[val]>"
                - define durability <[val].durability>
                - if <[val].max_durability> <= <[val].durability.add[200]>:
                    - narrate übersprungen
                    - foreach next
                - narrate format:c_debug "Haltbarkeit: <[durability]>"
                - inventory adjust slot:<[key]> durability:<[durability].add[200]>
                - define durability <player.inventory.slot[<[key]>].durability>
                - narrate format:c_debug "Haltbarkeit neu: <[durability]>"
        - flag <player> soulbound:!
        - flag <player> soulbound_items:!
        on player prepares anvil craft item:
        - determine passively 2
        - determine <context.item.with[lore=<&7>Soulbound]>
soulbound:
    type: enchantment
    id: soulbound
    slots:
    - mainhand
    rarity: very_rare
    category: weapon
    full_name: soulbound
    min_cost: <context.level.mul[1]>
    max_cost: <context.level.mul[1]>
    treasure_only: true
    is_tradable: true
    is_discoverable: true
    is_compatible: <context.enchantment_key.advanced_matches[!minecraft:mending]>