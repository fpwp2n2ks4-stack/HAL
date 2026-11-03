#!/bin/bash
#
# Build de HAL : un seul moniteur, plusieurs vaisseaux.
#
# Utilise uniquement les Command Line Tools (pas de Xcode) : le binaire est
# produit par swiftc, puis placé dans un .app minimal avec son Info.plist.
#
# Le script ne dépend pas du répertoire depuis lequel on l'appelle : tous les
# chemins sont résolus à partir du dossier qui le contient. On peut donc le
# lancer aussi bien par `./build.sh` que par un chemin absolu, depuis n'importe
# où.
#
# Migré vers Swift Concurrency avec structure modulaire.
#

set -euo pipefail

# Racine du projet = dossier du script, quel que soit le cwd. On résout
# d'abord le lien symbolique éventuel de `$0` : appelé via un lien, `dirname`
# renverrait le dossier du lien, pas celui du projet.
SELF="$0"
while [ -L "$SELF" ]; do
    link="$(readlink "$SELF")"
    case "$link" in
        /*) SELF="$link" ;;
        *)  SELF="$(dirname "$SELF")/$link" ;;
    esac
done
PROJECT_DIR="$(cd "$(dirname "$SELF")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME="HAL"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
INSTALL_DIR="/Applications"

INSTALL=0

# ============================================================================
# NOUVEAU SYSTÈME MODULAIRE (Swift Concurrency)
# ============================================================================

# Modèles de données (Sendable)
SENSOR_MODELS=(
    "$PROJECT_DIR/Sensors/Models/CPUUsage.swift"
    "$PROJECT_DIR/Sensors/Models/MemoryUsage.swift"
    "$PROJECT_DIR/Sensors/Models/NetworkUsage.swift"
    "$PROJECT_DIR/Sensors/Models/BatteryStatus.swift"
    "$PROJECT_DIR/Sensors/Models/GPUUsage.swift"
    "$PROJECT_DIR/Sensors/Models/Temperature.swift"
    "$PROJECT_DIR/Sensors/Models/DiskUsage.swift"
    "$PROJECT_DIR/Sensors/Models/ProcessUsage.swift"
    "$PROJECT_DIR/Sensors/Models/BluetoothDevice.swift"
    "$PROJECT_DIR/Sensors/Models/NetworkConnection.swift"
    "$PROJECT_DIR/Sensors/Models/NowPlaying.swift"
    "$PROJECT_DIR/Sensors/Models/Snapshot.swift"
)

# Erreurs
SENSOR_ERRORS=(
    "$PROJECT_DIR/Sensors/Errors/ReaderError.swift"
)

# Lecteurs asynchrones (Async/Await)
SENSOR_READERS=(
    "$PROJECT_DIR/Sensors/Readers/CPUReader.swift"
    "$PROJECT_DIR/Sensors/Readers/MemoryReader.swift"
    "$PROJECT_DIR/Sensors/Readers/NetworkReader.swift"
    "$PROJECT_DIR/Sensors/Readers/BatteryReader.swift"
    "$PROJECT_DIR/Sensors/Readers/TemperatureReader.swift"
    "$PROJECT_DIR/Sensors/Readers/GPUReader.swift"
    "$PROJECT_DIR/Sensors/Readers/DiskReader.swift"
    "$PROJECT_DIR/Sensors/Readers/ProcessReader.swift"
    "$PROJECT_DIR/Sensors/Readers/ConnectionReader.swift"
    "$PROJECT_DIR/Sensors/Readers/BluetoothReader.swift"
    "$PROJECT_DIR/Sensors/Readers/NowPlayingReader.swift"
)

# Orchestrateurs
SENSOR_ORCHESTRATORS=(
    "$PROJECT_DIR/Sensors/SnapshotReader.swift"
)

# Utilitaires
UTILITIES=(
    "$PROJECT_DIR/App/Core/Logger.swift"
)

# ============================================================================
# ANCIENS FICHIERS (pour compatibilité)
# ============================================================================

SOURCES=(
    # Localisation.
    "$PROJECT_DIR/App/Core/Localization.swift"

    # Contrat de thème et sélection.
    "$PROJECT_DIR/App/Themes/Core/Theme.swift"
    "$PROJECT_DIR/App/Themes/Core/ThemeSpecs.swift"
    "$PROJECT_DIR/App/Themes/Core/StatusItemView.swift"
    "$PROJECT_DIR/App/Themes/Core/ThemeManager.swift"

    # Voix de synthèse, dans la langue de l'application.
    "$PROJECT_DIR/App/Themes/Core/VoiceCatalog.swift"

    # Utilitaires
    "$PROJECT_DIR/App/Core/Support.swift"
    "$PROJECT_DIR/App/Core/Drawing.swift"
    "$PROJECT_DIR/App/Core/ProcessControl.swift"

    # Noyau commun : panneau, interactions, géométrie, hôte.
    "$PROJECT_DIR/App/Core/PanelView.swift"
    "$PROJECT_DIR/App/Core/PanelView+Geometry.swift"
    "$PROJECT_DIR/App/Core/PanelView+Mouse.swift"
    "$PROJECT_DIR/App/Core/PanelView+Dashboard.swift"
    "$PROJECT_DIR/App/Core/PanelView+Processes.swift"
    "$PROJECT_DIR/App/Core/PanelView+Connections.swift"
    "$PROJECT_DIR/App/Core/PanelView+Audio.swift"
    "$PROJECT_DIR/App/Core/NotchGeometry.swift"
    "$PROJECT_DIR/App/Core/NotchIslandView.swift"
    "$PROJECT_DIR/App/Core/NotchIslandController.swift"
    "$PROJECT_DIR/App/Core/NotchIslandController+States.swift"
    "$PROJECT_DIR/App/Core/AppDelegate.swift"
    "$PROJECT_DIR/App/Core/AppDelegate+Menus.swift"
    "$PROJECT_DIR/App/Core/AppDelegate+Cockpit.swift"

    # Identité HAL 9000.
    "$PROJECT_DIR/App/Themes/HAL9000/HALTheme.swift"
    "$PROJECT_DIR/App/Themes/HAL9000/HALRenderer.swift"
    "$PROJECT_DIR/App/Themes/HAL9000/HALRenderer+Audio.swift"
    "$PROJECT_DIR/App/Themes/HAL9000/HALStatusItemView.swift"
    "$PROJECT_DIR/App/Themes/HAL9000/HALVoice.swift"
    "$PROJECT_DIR/App/Themes/HAL9000/HALExitScreen.swift"

    # Identité Star Trek · LCARS.
    "$PROJECT_DIR/App/Themes/LCARS/LCARSTheme.swift"
    "$PROJECT_DIR/App/Themes/LCARS/LCARSConsoleRenderer.swift"
    "$PROJECT_DIR/App/Themes/LCARS/LCARSConsoleRenderer+Audio.swift"
    "$PROJECT_DIR/App/Themes/LCARS/LCARSStatusItemView.swift"
    "$PROJECT_DIR/App/Themes/LCARS/LCARSVoice.swift"
    "$PROJECT_DIR/App/Themes/LCARS/StarTrekExitScreen.swift"

    # Identité Blade Runner.
    "$PROJECT_DIR/App/Themes/BladeRunner/BladeRunnerTheme.swift"
    "$PROJECT_DIR/App/Themes/BladeRunner/BladeRunnerRenderer.swift"
    "$PROJECT_DIR/App/Themes/BladeRunner/BladeRunnerRenderer+Header.swift"
    "$PROJECT_DIR/App/Themes/BladeRunner/BladeRunnerRenderer+Rain.swift"
    "$PROJECT_DIR/App/Themes/BladeRunner/BladeRunnerRenderer+Audio.swift"
    "$PROJECT_DIR/App/Themes/BladeRunner/BladeRunnerStatusItemView.swift"
    "$PROJECT_DIR/App/Themes/BladeRunner/BladeRunnerVoice.swift"
    "$PROJECT_DIR/App/Themes/BladeRunner/BladeRunnerExitScreen.swift"

    # Identité WarGames · WOPR.
    "$PROJECT_DIR/App/Themes/WarGames/WarGamesTheme.swift"
    "$PROJECT_DIR/App/Themes/WarGames/WarGamesRenderer.swift"
    "$PROJECT_DIR/App/Themes/WarGames/WarGamesRenderer+Audio.swift"
    "$PROJECT_DIR/App/Themes/WarGames/WarGamesRenderer+Alertes.swift"
    "$PROJECT_DIR/App/Themes/WarGames/WarGamesStatusItemView.swift"
    "$PROJECT_DIR/App/Themes/WarGames/WOPRVoice.swift"
    "$PROJECT_DIR/App/Themes/WarGames/WarGamesExitScreen.swift"

    # Identité Moon · GERTY.
    "$PROJECT_DIR/App/Themes/Moon/MoonTheme.swift"
    "$PROJECT_DIR/App/Themes/Moon/MoonRenderer.swift"
    "$PROJECT_DIR/App/Themes/Moon/MoonStatusItemView.swift"
    "$PROJECT_DIR/App/Themes/Moon/GERTYVoice.swift"
    "$PROJECT_DIR/App/Themes/Moon/MoonExitScreen.swift"

    # Identité Matrix.
    "$PROJECT_DIR/App/Themes/Matrix/MatrixTheme.swift"
    "$PROJECT_DIR/App/Themes/Matrix/MatrixRenderer.swift"
    "$PROJECT_DIR/App/Themes/Matrix/MatrixStatusItemView.swift"
    "$PROJECT_DIR/App/Themes/Matrix/MatrixVoice.swift"
    "$PROJECT_DIR/App/Themes/Matrix/MatrixExitScreen.swift"

    # Identité The Ark · Ark One.
    "$PROJECT_DIR/App/Themes/Ark/ArkTheme.swift"
    "$PROJECT_DIR/App/Themes/Ark/ArkRenderer.swift"
    "$PROJECT_DIR/App/Themes/Ark/ArkRenderer+Alertes.swift"
    "$PROJECT_DIR/App/Themes/Ark/ArkStatusItemView.swift"
    "$PROJECT_DIR/App/Themes/Ark/ArkVoice.swift"
    "$PROJECT_DIR/App/Themes/Ark/ArkExitScreen.swift"

    # Identité Toasty · le grille-pain Cylon de la flotte coloniale.
    "$PROJECT_DIR/App/Themes/Toasty/ToastyTheme.swift"
    "$PROJECT_DIR/App/Themes/Toasty/ToastyRenderer.swift"
    "$PROJECT_DIR/App/Themes/Toasty/ToastyLED.swift"
    "$PROJECT_DIR/App/Themes/Toasty/ToastyStatusItemView.swift"
    "$PROJECT_DIR/App/Themes/Toasty/ToastyVoice.swift"
    "$PROJECT_DIR/App/Themes/Toasty/ToastyExitScreen.swift"

    # Point d'entrée.
    "$PROJECT_DIR/App/main.swift"
)

# Combiner tous les fichiers sources
ALL_SOURCES=(
    "${SENSOR_MODELS[@]}"
    "${SENSOR_ERRORS[@]}"
    "${SENSOR_READERS[@]}"
    "${SENSOR_ORCHESTRATORS[@]}"
    "${UTILITIES[@]}"
    "${SOURCES[@]}"
)

# Aucune compilation partielle : un fichier manquant est une erreur nette.
echo "▸ Vérification des fichiers sources"
for src in "${ALL_SOURCES[@]}"; do
    [ -f "$src" ] || { echo "❌ source introuvable : $src" >&2; exit 1; }
done
echo "✓ Tous les fichiers sources sont présents"

for arg in "$@"; do
    case "$arg" in
        --install) INSTALL=1 ;;
        *) echo "option inconnue : $arg" >&2
           echo "usage : $0 [--install]" >&2
           exit 2 ;;
    esac
done

echo "▸ Nettoyage"
rm -rf "$APP_BUNDLE"

echo "▸ Création du bundle"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Ressources de langue : chaque `.lproj` est copié tel quel dans Resources/.
echo "▸ Ressources de langue"
for lproj in "$PROJECT_DIR"/Resources/*.lproj; do
    [ -d "$lproj" ] || continue
    cp -R "$lproj" "$APP_BUNDLE/Contents/Resources/"
done

# Icône : le .icns versionné du vaisseau unifié.
echo "▸ Icône"
if [ -f "$PROJECT_DIR/Resources/$APP_NAME.icns" ]; then
    cp "$PROJECT_DIR/Resources/$APP_NAME.icns" "$APP_BUNDLE/Contents/Resources/"
else
    echo "  ($APP_NAME.icns absent)"
fi

echo "▸ Compilation (arm64 natif, Swift Concurrency activé)"
swiftc \
    -O \
    -whole-module-optimization \
    -target arm64-apple-macosx14.0 \
    -framework AppKit \
    -framework AVFoundation \
    -framework IOKit \
    -enable-experimental-feature StrictConcurrency \
    -o "$BINARY" \
    "${ALL_SOURCES[@]}"

echo "▸ Strip"
strip -x "$BINARY"

echo "▸ Info.plist"
cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>local.$APP_NAME</string>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>en</string>
        <string>fr</string>
        <string>es</string>
    </array>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>CFBundleIconFile</key>
    <string>$APP_NAME</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
</dict>
</plist>
PLIST

echo "▸ Signature ad-hoc"
# Nécessaire : les accès IOKit sont refusés à un binaire non signé.
codesign --force --sign - --timestamp=none "$APP_BUNDLE" 2>/dev/null \
    || echo "  (signature ignorée)"

echo "▸ Vérification"
codesign --verify --verbose=1 "$APP_BUNDLE" 2>&1 | head -2 || true

if [ "$INSTALL" = "1" ]; then
    echo "▸ Installation dans $INSTALL_DIR"
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    cp -R "$APP_BUNDLE" "$INSTALL_DIR/$APP_NAME.app"
    codesign --verify --strict "$INSTALL_DIR/$APP_NAME.app" \
        && echo "  → $INSTALL_DIR/$APP_NAME.app (signature vérifiée)"
fi

echo
echo "✓ $APP_BUNDLE construit avec Swift Concurrency"
echo "  Lancer    : open $APP_BUNDLE"
if [ "$INSTALL" = "1" ]; then
    echo "  Installée : open $INSTALL_DIR/$APP_NAME.app"
fi
