((m) ->
    # Choose among a dictionary of options.
    # key - the key to select from options
    # options - a map of [view_func, controller]
    m.choose = (key, options) ->
        option = options[key]
        option[0](option[1])

    m.toggle = (prop) ->
        (evt) -> prop(not prop())

    m.debubble = (evtHandler) ->
        (evt) ->
            evt.stopPropagation()
            evt.preventDefault()
            m.startComputation()
            try
                return evtHandler.apply(this, arguments)
            finally
                m.endComputation()

)(Mithril)
