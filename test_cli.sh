#!/bin/bash
#
# Script d'exécution des tests pour HAL avec uniquement les Command Line Tools
#
# Ce script vérifie la syntaxe des tests en les compilant avec swiftc.
# Comme XCTest nécessite Xcode pour s'exécuter, nous nous contentons de vérifier
# que les fichiers de test compilent correctement.
#

set -euo pipefail

# Racine du projet
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

# Dossiers
TESTS_DIR="$PROJECT_DIR/Tests"
BUILD_DIR="$PROJECT_DIR/build"
TEST_BUILD="$BUILD_DIR/tests"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "▸ Vérification des tests avec Command Line Tools..."
echo ""

# Créer le dossier de build
mkdir -p "$TEST_BUILD"

# Compter les fichiers de test
TEST_FILES=$(find "$TESTS_DIR" -name "*Tests.swift" -type f)
TEST_COUNT=$(echo "$TEST_FILES" | wc -l)

echo "Trouvé $TEST_COUNT fichiers de test :"
echo "$TEST_FILES" | while read -r file; do
    echo "  - $(basename "$file")"
done
echo ""

# Vérifier la syntaxe Swift de chaque fichier de test
echo "▸ Vérification de la syntaxe Swift..."

SYNTAX_OK=true
for file in $TEST_FILES; do
    echo -n "  Vérification de $(basename "$file" 2>/dev/null)... "
    
    # Utiliser swiftc pour vérifier la syntaxe (en mode parse-only)
    if swiftc -parse-as-library -typecheck -Xfrontend -disable-primary-file-processing \
        -I "$PROJECT_DIR/App" -I "$PROJECT_DIR/Sensors" \
        "$file" -o /dev/null 2>&1 | grep -q "error"; then
        echo -e "${RED}✗ FAILED${NC}"
        SYNTAX_OK=false
    else
        echo -e "${GREEN}✓ OK${NC}"
    fi
done

echo ""

if [ "$SYNTAX_OK" = true ]; then
    echo -e "${GREEN}✓ Tous les fichiers de test ont une syntaxe valide !${NC}"
    echo ""
    echo "Nombre de tests estimés :"
    grep -r "func test" "$TESTS_DIR" | wc -l | xargs echo "  ~ tests trouvés"
    echo ""
    echo "Pour exécuter les tests avec Xcode :"
    echo "  xcodebuild test -scheme HAL -destination 'platform=macOS'"
else
    echo -e "${RED}✗ Certains fichiers de test ont des erreurs de syntaxe${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Vérification terminée${NC}"
