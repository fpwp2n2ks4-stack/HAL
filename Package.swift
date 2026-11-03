// swift-tools-version:6.0
import PackageDescription

// Package de test de HAL : `swift test` compile le code de l'application
// (cible « HAL ») et les tests unitaires de Tests/. Le binaire de production
// reste produit par build.sh (swiftc direct, avec App/main.swift) ; ce
// fichier ne sert qu'aux tests.
//
// App/Sensors est un lien symbolique vers ../Sensors : SwiftPM exige qu'une
// cible vive dans un seul dossier, alors que l'application vit dans App/ et
// Sensors/. Le lien évite de déplacer les fichiers.

let package = Package(
    name: "HALTests",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "HAL",
            path: "App",
            exclude: [
                // Point d'entrée : code top-level, compilé seulement par
                // build.sh. Les tests testent le module, pas le lancement.
                "main.swift"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "HALTests",
            dependencies: ["HAL"],
            path: "Tests",
            exclude: [
                "Mocks"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
