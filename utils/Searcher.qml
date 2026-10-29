import "scripts/fzf.js" as Fzf
import "scripts/fuzzysort.js" as Fuzzy
import QtQuick
import Quickshell

Singleton {
    required property list<QtObject> list
    property string key: "name"
    property bool useFuzzy: false
    property var extraOpts: ({})

    // Extra stuff for fuzzy
    property list<string> keys: [key]
    property list<real> weights: [1]
    property var _fuzzyPrepped: null

    readonly property var fzf: useFuzzy ? [] : new Fzf.Finder(list, Object.assign({
        selector
    }, extraOpts))
    // Empty until a non-empty query needs it. The launcher is the only consumer,
    // and preparing a large wallpaper list at startup was pure waste while closed.
    readonly property list<var> fuzzyPrepped: _fuzzyPrepped ?? []

    function _ensureFuzzyPrepped(): var {
        if (!useFuzzy)
            return [];
        if (_fuzzyPrepped === null) {
            _fuzzyPrepped = list.map(e => {
                const obj = {
                    _item: e
                };
                for (const k of keys)
                    obj[k] = Fuzzy.prepare(e[k]);
                return obj;
            });
        }
        return _fuzzyPrepped;
    }

    function transformSearch(search: string): string {
        return search;
    }

    function selector(item: var): string {
        // Only for fzf
        return item[key];
    }

    function query(search: string): list<var> {
        search = transformSearch(search.trim().replace(/\s+/g, " "));
        if (!search)
            return [...list];

        if (useFuzzy)
            return Fuzzy.go(search, _ensureFuzzyPrepped(), Object.assign({
                all: true,
                keys,
                scoreFn: r => weights.reduce((a, w, i) => a + r[i].score * w, 0)
            }, extraOpts)).map(r => r.obj._item);

        return fzf.find(search).sort((a, b) => {
            if (a.score === b.score)
                return selector(a.item).trim().length - selector(b.item).trim().length;
            return b.score - a.score;
        }).map(r => r.item);
    }

    onListChanged: _fuzzyPrepped = null
    onKeysChanged: _fuzzyPrepped = null
    onUseFuzzyChanged: _fuzzyPrepped = null
}
