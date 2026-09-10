pragma Singleton

import Quickshell
import Caelestia.Config

Singleton {
    function isFavourite(appId: string): bool {
        return Strings.testRegexList(GlobalConfig.launcher.favouriteApps, appId);
    }

    function toggleFavourite(appId: string): void {
        const apps = [...GlobalConfig.launcher.favouriteApps];
        const idx = Strings.findRegexList(apps, appId);
        if (idx >= 0) {
            apps.splice(idx, 1);
        } else {
            apps.push(Strings.exactPattern(appId));
        }
        GlobalConfig.launcher.favouriteApps = apps;
    }
}
