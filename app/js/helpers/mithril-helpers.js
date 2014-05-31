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

    m.cachedComputed = function(compute, async) {
        var store = undefined,
            d = null,
            prop = function() { return store; };

        async = async === undefined ? false : async;

        prop.clear = function() {
            store = undefined;
        };
        prop.refresh = function(async) {
            async = async === undefined ? false : async;

            if (async === false) {
                if (d !== null) {
                    throw new Error("Sync refresh already in progress.");
                }
                store = compute();
                return store;
            } else {
                if (d !== null) {
                    return d.promise;
                } else {
                    d = m.deferred();
                    setTimeout(function() {
                        try {
                            store = computed();
                            d.resolve(store);
                        } catch (e) {
                            d.reject(e);
                        } finally {
                            d = null;
                        }
                    }, 0)
                    return d.promise;
                }
            }
        };
        prop.toJSON = function() {
            return store
        };

        prop.refresh(async);

        return prop
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
