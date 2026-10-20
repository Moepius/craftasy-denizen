def_sample:
    type: task
    debug: false
    script:
        - foreach <server.sound_keys.alphabetical> as:key:
            - narrate <[key]>