(function(m) {
    // Choose among a dictionary of options.
    // key - the key to select from options
    // options - a map of [view_func, controller]
    m.choose = function(key, options) {
        var option = options[key];
        return option[0](option[1]);
    };

    m.toggle = function(prop) {
        return function(evt) { prop(!prop()); };
    };

    m.cachedComputed = function(compute) {
        var store = compute();
        var prop = function() {
            return store
        }
        prop.refresh = function() {
            store = compute();
            return store
        }
        prop.toJSON = function() {
            return store
        }
        return prop
    }

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
