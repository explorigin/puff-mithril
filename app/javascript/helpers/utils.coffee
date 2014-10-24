require('mithril')

((m) ->
    # Choose among a dictionary of options.
    # key - the key to select from options
    # options - a map of [view_func, controller]
    m.choose = (key, options) ->
        option = options[key]
        option[0](option[1])

    m.unwrap = (prop) ->
        if typeof prop is 'function'
            return prop()
        return prop

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

    m.mixinLayout = (layoutModule, contentModule) ->
        controller:
            layoutModule.controller(contentModule.controller)
        view:
            layoutModule.view(contentModule.view)
    m.log = (msg, obj) ->
        if obj isnt undefined
            console.log(msg, obj)
        else
            console.log(msg)

    m.pluck = (arrayOfObjs, propName) ->
        arrayOfObjs.map((obj) -> obj[propName])

    m.omit = (obj) ->
        output = {}
        Object.keys(obj).filter((key) -> key in arguments).forEach((key) -> output[key] = obj[key])
        return output

    m.alert = window.alert

    m.confirm = (prompt) ->
        d = m.deferred()
        output = window.confirm(prompt)

        if output
            d.resolve(output)
        else
            d.reject(output)

        d.promise

)(Mithril)
