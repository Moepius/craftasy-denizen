# # To update chat, simply start the server with the script loaded or run `/chat_update` with the permission `chat.admin`
# # Extra clickable buttons can be added by adding them to `chat_formatting` script under `data.buttons`:
#   example command:
# -    format: the format is what appears as the text button to click, eg `[Activate Fly]`
# -    command: the command is what command runs when clicked, eg: `/fly`

# TODO: delete history every few days
# TODO: delete history when it gets too big
# TODO: let players choose nicknames and highlight them as well
# TODO: for some trigger words add a message to a new line of the message the player is typing

chat_formatting:
  type: world
  debug: false
  enabled: true
  events:
    on player chats flagged:!player.chat.busy:
      - determine cancelled passively
      # test for muted players
      - if <player.has_flag[player.flag.muted]>:
        - run chatsounds_error def:<player>
        - narrate format:c_warn "Ihr wurdet stummgeschaltet."
        - stop
      # test for chat use permission
      - if !<player.has_permission[craftasy.denizen.player.chat.use]>:
        - run chatsounds_error def:<player>
        - narrate format:c_warn "Akzeptiert zunächst unsere Regeln, damit Ihr den Chat nutzen könnt."
        - stop
      #### highlight player names, server locations, links or other keywords defined in data script "chat_keywords"
      - define textrpl <context.message.parse_color>
      - define symbols <list[?|,|:|;|!|.]>
      - define linkstart <list[https://|http://|www.]>
      # loop through every word of the message
      - foreach <context.message.split> as:word:
        # test if the word is a link (definition used for now with list of linkstarts)
        - if <[linkstart].filter_tag[<[word].starts_with[<[filter_value]>]>].any>:
            # if the last letter of the word/link is a symbol
            - if <[word].to_list.last.contains_any_text[<[symbols]>]>:
              # save the last letter, flag the server with it, remove the letter from the word
              # and later readd it via definition (sym).
              # necessary because without it, will also highlight symbols like ?,!
              - define sym <[word].to_list.last>
              - define wordex <[word].to_list.exclude[<[word].to_list.last>].separated_by[]>
              - define textrpl <[textrpl].replace[<[word]>].with[<element[<&n><[wordex]>].custom_color[link]><[sym]>]>
            - else:
              # if the word/link does not end with a symbol, just highlight it as usual
              - define textrpl <[textrpl].replace[<[word]>].with[<element[<&n><[word]>].custom_color[link]>]>
            - foreach next
        # loop through online players, highlight player names and notify online players who got highlighted. Red coloring for admins
        - define admins <list[SilberRegen|Moepius|Tolkier|FroherFrosch]>
        - foreach <server.online_players.parse_tag[<[parse_value].name>].include[<[admins]>].exclude[<player>]> as:name:
          - if <[textrpl].contains_text[<[name]>]>:
            - if <server.match_offline_player[<[name]>].is_online>:
              - playsound <server.match_player[<[name]>]> sound:block_bell_use
            - if <[admins].filter_tag[<[name].starts_with[<[filter_value]>]>].any>:
              - define textrpl <[textrpl].replace[<[name]>].with[<element[<[name].custom_color[admin].on_hover[<&color[#ED1A3A]>Administrator]>]>]>
              - foreach next
            - define textrpl <[textrpl].replace[<[name]>].with[<element[<[name].custom_color[player]>]>]>
        # loop through every key in map "words" and highlight matching words from data script
        - foreach <script[chat_keywords].list_keys> as:replaceable:
          # if substring (length) of the currently indexed word matches with currently indexed key from words map
          - if <[word].substring[0,<[replaceable].length>].equals_case_sensitive[<[replaceable]>]>:
            - define textrpl <[textrpl].replace[<[word].substring[0,<[replaceable].length>]>].with[<script[chat_keywords].parsed_key[<[replaceable]>]>]>
            - foreach stop
      #### build the text
      - define text "<player.proc[player_name_format]><&f><&co> <[textrpl]>"
      - foreach <server.online_players> as:player:
        # narrate the build message to all online players
        - narrate <[text]> targets:<[player]> from:<player.uuid>

  ### all data needed for messages ###
  data:

    player_chat:
      format:
        # flag: player.rank.data_name - rankname, referencing data container
        prefix: <server.flag[server.rank.format.<player.flag[player.rank.data_name].if_null[Besucher]>]>
        name: <player.name>
        hover: <script[chat_formatting].parsed_key[data.title_data.<player.flag[chat.title].if_null[player]>.text]><&b>Klicken, für Privatnachricht
        suggest_command: /pn <player.name><&sp>

    more_info:
      text: <&b>Mehr Infos in unserem Wiki <&a><&n>craftasy.de/wiki<&b>.
      url: https://www.craftasy.de/wiki

    rank_data:
      ranks:
        Besucher:
          color: <&7>
          symbol: •
          info: <&7><&l>Besucher<&nl><&b>Neuer Spieler, nicht freigeschaltet.
        Veraltet:
          color: <&7>
          symbol: ❈
          info: <&7><&l>Veraltet<&nl><&b>Spieler, der noch nicht vom alten Rangsystem konvertiert wurde.<&nl><&f>--------------------
        Fremder:
          color: <&a>
          symbol: ✲
          info: <&a><&l>Fremder<&nl><&b>Neuer Spieler, freigeschaltet und Tutorial abgeschlossen.<&nl><&f>--------------------
        Reisender:
          color: <&2>
          symbol: ❊
          info: <&2><&l>Reisender<&nl><&b>Spieler, die mindestens 15 Stunden<&nl><&b>auf unserem Server verbracht haben.<&nl><&f>--------------------
        Pionier:
          color: <&b>
          symbol: ❉
          info: <&b><&l>Pionier<&nl><&b>Spieler, die mindestens 45 Stunden<&nl><&b>auf unserem Server verbracht haben.<&nl><&f>--------------------
        Entdecker:
          color: <&3>
          symbol: ❈
          info: <&3><&l>Entdecker<&nl><&b>Spieler, die mindestens 125 Stunden<&nl><&b>auf unserem Server verbracht haben.<&nl><&f>--------------------
        Siedler:
          color: <&d>
          symbol: ✶
          info: <&d><&l>Siedler<&nl><&b>Stammspieler, die mindestens 500 Stunden<&nl><&b>auf unserem Server verbracht haben.<&nl><&f>--------------------
        Gruender:
          color: <&5>
          symbol: ✷
          info: <&5><&l>Gründer<&nl><&b>Stammspieler, die mindestens 1000 Stunden<&nl><&b>auf unserem Server verbracht haben.<&nl><&f>--------------------
        Legende:
          color: <&6>
          symbol: ✸
          info: <&6><&l>Legende<&nl><&b>Stammspieler, die mindestens 2000 Stunden<&nl><&b>auf unserem Server verbracht haben.<&nl><&f>--------------------
        Legende II:
          color: <&6>
          symbol: ✸
          info: <&6><&l>Legende <&f><&lb><&6><&l>II<&f><&rb><&nl><&b>Stammspieler, die mindestens 2500 Stunden<&nl><&b>auf unserem Server verbracht haben.<&nl><&f>--------------------
        Legende III:
          color: <&6>
          symbol: ✸
          info: <&6><&l>Legende <&f><&lb><&6><&l>III<&f><&rb><&nl><&b>Stammspieler, die mindestens 3000 Stunden<&nl><&b>auf unserem Server verbracht haben.<&nl><&f>--------------------
        Legende IV:
          color: <&6>
          symbol: ✸
          info: <&6><&l>Legende <&f><&lb><&6><&l>IV<&f><&rb><&nl><&b>Stammspieler, die mindestens 4000 Stunden<&nl><&b>auf unserem Server verbracht haben.<&nl><&f>--------------------
        Legende V:
          color: <&6>
          symbol: ⦑✸⦒
          info: <&6><&l>Legende <&f><&lb><&6><&l>V<&f><&rb><&nl><&b>Stammspieler, die mindestens 5000 Stunden<&nl><&b>auf unserem Server verbracht haben.<&nl><&f>--------------------

    title_data:
      player:
        text: <&7>Spieler<n>
        info: <&7>Ein Spieler
      admin:
        text: <&c>Administrator<n>
        info: <&c>

player_name_format:
  type: procedure
  debug: false
  definitions: player
  script:
    # long, verbose version
    - define player_prefix <script[chat_formatting].parsed_key[data.player_chat.format.prefix]>
    - define player_name <script[chat_formatting].parsed_key[data.player_chat.format.name]>
    - define hover <script[chat_formatting].parsed_key[data.player_chat.format.hover]>
    - define suggest_command <script[chat_formatting].parsed_key[data.player_chat.format.suggest_command]>
    #### formatting of the full player/message prefix ####
    - determine "<&7><util.time_now.format[HH:mm].on_hover[<&f><util.time_now.format[dd.MM.yyyy]> um <util.time_now.format[HH:mm]> Uhr]> <[player_prefix]><&f> ⎜ <[player_name].on_hover[<[hover]>].on_click[<[suggest_command]>].type[suggest_command]>"

    # short instant version
    # - determine "<script.parsed_key[data.player_chat.format.prefix]><&f> ⎜ <script.parsed_key[data.player_chat.format.name].on_hover[<script.parsed_key[data.player_chat.format.hover]>].on_click[<script.parsed_key[data.player_chat.format.suggest_command]>].type[suggest_command]>"



### stores all server keywords that get highlighted in chat ###
chat_keywords:
  type: data
  # misc keywords
  Discord: <element[Discord: <&n>https://is.gd/cdiscord].custom_color[discord]>
  # server locations
  Orbis:  <element[Orbis].custom_color[location].on_hover[Projekt- und Survivalwelt]>
  Moraira:  <element[Moraira].custom_color[location].on_hover[Hauptstadt und größte Stadt in Oskania]>
  Ituria: <element[Ituria].custom_color[location]>
  Terra-Ferma: <element[Terra Ferma].custom_color[location].on_hover[Kontinent der alten Welt]>
  # server keywords
  Projektwelt: <element[Projektwelt].custom_color[server]>
  # server commands
  Regeln: <element[Regeln].custom_color[command].on_click[/regeln].on_hover[Klicken, um Regeln aufzurufen]>
  rules: <element[rules].custom_color[command].on_click[/regeln].on_hover[Klicken, um Regeln aufzurufen]>
  Hilfe: <element[Hilfe].custom_color[command].on_click[/hilfe].on_hover[Klicken, um Hilfe aufzurufen]>
  help: <element[help].custom_color[command].on_click[/hilfe].on_hover[Klicken, um Hilfe aufzurufen]>
  support: <element[support].custom_color[command].on_click[/support].on_hover[Klicken, um Support aufzurufen]>