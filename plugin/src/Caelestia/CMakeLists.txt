# Target MUST stay named caelestia-core to match upstream (renamed in 3d97d504,
# shipped since v2.1.0). It sets the built artifact names — libcaelestia-coreplugin.so
# and caelestia-core.qmltypes — which must be identical to the caelestia-shell
# package's, so this build cleanly replaces it rather than sitting beside it.
# Two .so files both declaring `module Caelestia` makes Qt abort with
# "Cannot add multiple registrations for Caelestia" under quickshell-git.
qml_module(caelestia-core
    URI Caelestia
    SOURCES
        cutils.hpp cutils.cpp
        qalculator.hpp qalculator.cpp
        appdb.hpp appdb.cpp
        requests.hpp requests.cpp
        toaster.hpp toaster.cpp
        imageanalyser.hpp imageanalyser.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
        Qt::Sql
        PkgConfig::Qalculate
)

# Bake the shell version in so CUtils can expose it without spawning a process
target_compile_definitions(caelestia-core PRIVATE CAELESTIA_VERSION="${VERSION}")

add_subdirectory(Components)
add_subdirectory(Config)
add_subdirectory(Internal)
add_subdirectory(Models)
add_subdirectory(Services)
add_subdirectory(Blobs)
add_subdirectory(Images)
