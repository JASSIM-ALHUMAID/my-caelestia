pragma Singleton

import Quickshell

Singleton {
    property var _regexCache: ({})

    function testRegexList(filterList: list<string>, target: string): bool {
        const regexChecker = /^\^.*\$$/;
        for (const filter of filterList) {
            if (regexChecker.test(filter)) {
                let re = _regexCache[filter];
                if (!re) {
                    re = new RegExp(filter);
                    _regexCache[filter] = re;
                }
                if (re.test(target))
                    return true;
            } else {
                if (filter === target)
                    return true;
            }
        }
        return false;
    }

    // An anchored regex matching exactly `id`, for storing in a filter list such as
    // launcher.favouriteApps. Metacharacters are escaped so ids like org.gnome.Nautilus
    // don't turn their dots into wildcards.
    function exactPattern(id: string): string {
        return `^${id.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`;
    }

    // Index of the first filter in `filterList` matching `target`, or -1.
    function findRegexList(filterList: list<string>, target: string): int {
        for (let i = 0; i < filterList.length; i++)
            if (testRegexList([filterList[i]], target))
                return i;
        return -1;
    }
}
