tool_autosave:
    type: world
    debug: true
    enabled: false
    events:
        on delta time minutely every:2:
        - announce to_console "Speichere Denizen und Citizens ..."
        - adjust server save
        - adjust server save_citizens