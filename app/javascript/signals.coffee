Signal = require('js-signals/dist/signals').Signal

module.exports = {
    fullscreen:
        requested: new Signal()
        cancelled: new Signal()
}
