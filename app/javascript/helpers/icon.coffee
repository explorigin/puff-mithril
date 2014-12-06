# helpers/icon.js
m = require('mithril')
cfg = require('config')

icon = ""

switch cfg.iconset
    when "bootstrap" then icon = "span.glyphicon.glyphicon-"
    when "fontawesome" then icon = "i.fa.fa-"

module.exports = (type, options) ->
    return m(icon + type, options or {})
