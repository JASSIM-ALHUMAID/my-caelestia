pragma Singleton

import QtQuick
import Quickshell
import M3Shapes

Singleton {
    id: root

    // Every M3 shape usable as a password character, keyed by the name stored
    // in GlobalConfig.lock.passwordShapes
    readonly property var catalog: [
        { name: "Circle", shape: MaterialShape.Circle },
        { name: "Square", shape: MaterialShape.Square },
        { name: "Slanted", shape: MaterialShape.Slanted },
        { name: "Arch", shape: MaterialShape.Arch },
        { name: "Fan", shape: MaterialShape.Fan },
        { name: "Arrow", shape: MaterialShape.Arrow },
        { name: "SemiCircle", shape: MaterialShape.SemiCircle },
        { name: "Oval", shape: MaterialShape.Oval },
        { name: "Pill", shape: MaterialShape.Pill },
        { name: "Triangle", shape: MaterialShape.Triangle },
        { name: "Diamond", shape: MaterialShape.Diamond },
        { name: "ClamShell", shape: MaterialShape.ClamShell },
        { name: "Pentagon", shape: MaterialShape.Pentagon },
        { name: "Gem", shape: MaterialShape.Gem },
        { name: "Sunny", shape: MaterialShape.Sunny },
        { name: "VerySunny", shape: MaterialShape.VerySunny },
        { name: "Cookie4Sided", shape: MaterialShape.Cookie4Sided },
        { name: "Cookie6Sided", shape: MaterialShape.Cookie6Sided },
        { name: "Cookie7Sided", shape: MaterialShape.Cookie7Sided },
        { name: "Cookie9Sided", shape: MaterialShape.Cookie9Sided },
        { name: "Cookie12Sided", shape: MaterialShape.Cookie12Sided },
        { name: "Ghostish", shape: MaterialShape.Ghostish },
        { name: "Clover4Leaf", shape: MaterialShape.Clover4Leaf },
        { name: "Clover8Leaf", shape: MaterialShape.Clover8Leaf },
        { name: "Burst", shape: MaterialShape.Burst },
        { name: "SoftBurst", shape: MaterialShape.SoftBurst },
        { name: "Boom", shape: MaterialShape.Boom },
        { name: "SoftBoom", shape: MaterialShape.SoftBoom },
        { name: "Flower", shape: MaterialShape.Flower },
        { name: "Puffy", shape: MaterialShape.Puffy },
        { name: "PuffyDiamond", shape: MaterialShape.PuffyDiamond },
        { name: "PixelCircle", shape: MaterialShape.PixelCircle },
        { name: "PixelTriangle", shape: MaterialShape.PixelTriangle },
        { name: "Bun", shape: MaterialShape.Bun },
        { name: "Heart", shape: MaterialShape.Heart }
    ]

    // The pre-passwordShapes pool, used while nothing is selected
    readonly property list<string> defaults: ["Circle", "Triangle", "Diamond", "Pentagon", "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided", "Sunny", "VerySunny", "SoftBurst", "Gem", "Arch", "Arrow", "Pill", "Fan", "Oval", "ClamShell", "Slanted"]

    // Configured names -> shape values; unknown names are dropped and an
    // empty result falls back to the default set
    function resolve(names: var): var {
        const shapes = [];
        for (const n of names ?? []) {
            const entry = catalog.find(c => c.name === n);
            if (entry)
                shapes.push(entry.shape);
        }
        if (shapes.length > 0)
            return shapes;
        return defaults.map(n => catalog.find(c => c.name === n).shape);
    }
}
