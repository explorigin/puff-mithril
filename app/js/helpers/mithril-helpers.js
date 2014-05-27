(function(m) {
    // Choose among a dictionary of options.
    // key - the key to select from options
    // options - a map of [view_func, controller]
    m.choose = function(key, options) {
        var option = options[key];
        return option[0](option[1]);
    };

    m.omit = function(obj) {
        var copy = {},
            ArrayProto = Array.prototype,
            keys = ArrayProto.concat.apply(ArrayProto, ArrayProto.slice.call(arguments, 1));
        for (var key in obj) {
          if (keys.indexOf(key) === -1) copy[key] = obj[key];
        }
        return copy;
    };

    m.toggle = function(prop) {
        return function(evt) { prop(!prop()); };
    };

    m.debubble = function(evtHandler) {
        return function(evt) {
            evt.stopPropagation();
            evt.preventDefault();
            m.startComputation();
            try { return evtHandler.apply(this, arguments); }
            finally { m.endComputation(); }
        };
    };
})(Mithril);
