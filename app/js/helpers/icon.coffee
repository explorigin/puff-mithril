# helpers/icon.js
m.factory(
    "helpers.icon"
    ["application.config"]
    (cfg) ->
        icon = ""

        switch cfg.iconset
            when "bootstrap" then icon = "span.glyphicon.glyphicon-"
            when "fontawesome" then icon = "i.fa.fa-"

        (type) ->
            return m(icon + type)
)
