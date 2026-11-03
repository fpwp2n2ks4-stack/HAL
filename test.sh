#!/bin/bash
#
# Harnais de test de HAL
#
# Sans Xcode (Command Line Tools seuls), XCTest ne peut pas s'exécuter :
# ce script fait alors ce qui reste vérifiable sans lui — compiler tout le
# code de l'application via le package (swift build), puis vérifier que les
# fichiers de test compilent (repli hérité de test_cli.sh).
#
# Si Xcode est installé, `swift test` exécute les tests pour de vrai.
#
# Le script ne dépend pas du répertoire depuis lequel on l'appelle.

set -euo pipefail

# Racine du projet = dossier du script, quel que soit le cwd.
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

echo "▸ Compilation de l'application (swift build)"
swift build
echo "✓ Application compilée sans erreur"

# XCTest n'est livré qu'avec Xcode : sa présence dans CommandLineTools
# indique que swift test peut tourner.
if [ -d "/Library/Developer/CommandLineTools/Developer/Library/Frameworks" ] \
   || xcode-select -p 2>/dev/null | grep -qv CommandLineTools; then
    echo ""
    echo "▸ Exécution des tests (swift test)"
    swift test
    exit 0
fi

echo ""
echo "▸ Xcode absent : XCTest ne peut pas s'exécuter."
echo "  Repli sur la vérification de syntaxe des fichiers de test."
echo ""
exec bash "$PROJECT_DIR/test_cli.sh"
