.pragma library

// Distinct parent directories, sorted. Used to keep the realpath run small.
function parentDirs(entries) {
    const seen = Object.create(null);
    for (const entry of entries)
        seen[entry.parentDir] = true;
    return Object.keys(seen).sort();
}

// Filters a wallpaper pool without touching the entry objects. Unknown pools fall
// back to "all" so an invalid config value behaves like the old code did.
function filterPool(entries, pool, isVideo) {
    if (pool !== "images" && pool !== "videos")
        return entries.slice();

    const wantVideo = pool === "videos";
    const out = [];
    for (const entry of entries) {
        if (!!isVideo(entry.path) === wantVideo)
            out.push(entry);
    }
    return out;
}

// Path -> index. First occurrence wins so duplicate paths keep the old
// findIndex() behaviour for "next" order.
function indexByPath(entries) {
    const index = Object.create(null);
    for (let i = 0; i < entries.length; i++) {
        const path = entries[i].path;
        if (index[path] === undefined)
            index[path] = i;
    }
    return index;
}

// Uniform random pick that never returns `currentPath` while another path exists.
// `random` is injectable so the selection rules can be tested deterministically.
function pickRandom(entries, index, currentPath, random) {
    const count = entries.length;
    if (count === 0)
        return null;

    const rand = random || Math.random;
    const currentIndex = index[currentPath];
    if (currentIndex === undefined)
        return entries[Math.floor(rand() * count)];
    if (count === 1)
        return entries[0];

    // Pick uniformly from the count - 1 slots that exclude the current entry.
    let pickIndex = Math.floor(rand() * (count - 1));
    if (pickIndex >= currentIndex)
        pickIndex++;

    const pick = entries[pickIndex];
    if (pick.path !== currentPath)
        return pick;

    // Duplicate paths are unusual, but the old filter excluded all of them.
    for (let offset = 1; offset < count; offset++) {
        const candidate = entries[(pickIndex + offset) % count];
        if (candidate.path !== currentPath)
            return candidate;
    }
    return pick;
}

function pickNext(entries, index, currentPath) {
    const count = entries.length;
    if (count === 0)
        return null;

    const currentIndex = index[currentPath];
    return entries[currentIndex === undefined ? 0 : (currentIndex + 1) % count];
}

// Full-path locale order without asking ICU to collate the shared long prefix on
// every comparison. Building a component trie and sorting each directory's
// children gives the same order as `path.localeCompare(otherPath)` for files,
// while keeping each comparison short.
function buildNextOrder(entries) {
    const root = { children: Object.create(null) };
    for (const entry of entries) {
        let node = root;
        for (const part of entry.parentDir.split("/")) {
            if (part === "")
                continue;
            let child = node.children[part];
            if (!child)
                child = node.children[part] = { children: Object.create(null) };
            node = child;
        }

        let leaf = node.children[entry.name];
        if (!leaf)
            leaf = node.children[entry.name] = { entries: [] };
        leaf.entries.push(entry);
    }

    const sorted = [];
    function walk(node) {
        const names = Object.keys(node.children).sort((a, b) => a.localeCompare(b));
        for (const name of names) {
            const child = node.children[name];
            if (child.entries) {
                for (const entry of child.entries)
                    sorted.push(entry);
            } else {
                walk(child);
            }
        }
    }
    walk(root);
    return sorted;
}

// Buckets wallpapers by the directory they sit in relative to the wallpaper dir
// that owns them. Returns the original entry objects; the wrapper objects only
// exist so the hot loop reads each QML property once.
function buildGroups(entries, absDirs) {
    const roots = [];
    const folders = Object.create(null);

    for (const entry of entries) {
        let rel = null;
        for (const absDir of absDirs) {
            if (entry.path.startsWith(absDir + "/")) {
                rel = entry.parentDir.length > absDir.length ? entry.parentDir.slice(absDir.length + 1) : "";
                break;
            }
        }
        if (rel === null)
            continue;

        const prepared = {
            entry,
            name: entry.name
        };
        if (rel === "") {
            roots.push(prepared);
        } else {
            let folder = folders[rel];
            if (!folder)
                folder = folders[rel] = [];
            folder.push(prepared);
        }
    }

    const byName = (a, b) => a.name.localeCompare(b.name);
    roots.sort(byName);

    const titles = Object.keys(folders).sort((a, b) => a.localeCompare(b));
    const outFolders = [];
    for (const title of titles) {
        const folder = folders[title];
        folder.sort(byName);
        const folderEntries = [];
        for (const prepared of folder)
            folderEntries.push(prepared.entry);
        outFolders.push({
            title,
            entries: folderEntries
        });
    }

    const outRoots = [];
    for (const prepared of roots)
        outRoots.push(prepared.entry);
    return {
        roots: outRoots,
        folders: outFolders
    };
}
