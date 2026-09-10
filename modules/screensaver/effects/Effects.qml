import QtQuick
import qs.services

QtObject {
    id: root

    readonly property list<var> all: [
        { id: "logo", label: qsTr("Logo"), component: logoComp },
        { id: "clock", label: qsTr("Clock"), component: clockComp },
        { id: "matrix", label: qsTr("Matrix rain"), component: matrixComp },
        { id: "starfield", label: qsTr("Starfield"), component: starfieldComp },
        { id: "aurora", label: qsTr("Aurora"), component: auroraComp },
        { id: "terminal", label: qsTr("CRT terminal"), component: terminalComp },
        { id: "constellation", label: qsTr("Particle constellation"), component: constellationComp },
        { id: "mosaic", label: qsTr("Pixel mosaic"), component: mosaicComp },
        { id: "video", label: qsTr("Video"), component: videoComp }
    ]

    readonly property Component logoComp: Component {
        EffectLogo {}
    }

    readonly property Component clockComp: Component {
        EffectClock {}
    }

    readonly property Component matrixComp: Component {
        EffectMatrix {}
    }

    readonly property Component starfieldComp: Component {
        EffectStarfield {}
    }

    readonly property Component auroraComp: Component {
        EffectAurora {}
    }

    readonly property Component terminalComp: Component {
        EffectTerminal {}
    }

    readonly property Component constellationComp: Component {
        EffectConstellation {}
    }

    readonly property Component mosaicComp: Component {
        EffectMosaic {}
    }

    readonly property Component videoComp: Component {
        EffectVideo {}
    }

    function pick(id: string): var {
        for (const e of root.all) {
            if (e.id === id)
                return e;
        }
        return root.all[0];
    }
}
