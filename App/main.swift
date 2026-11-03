//
//  main.swift
//  HAL
//
//  Point d'entrée explicite (pas de `@main` : sur ce SDK, le chemin par
//  défaut d'AppKit démarre le processus sans appeler
//  `applicationDidFinishLaunching`). Le delegate doit être conservé par une
//  variable forte, `NSApplication.delegate` étant `weak`.
//

import AppKit

let application = NSApplication.shared
let appDelegate = AppDelegate()

application.delegate = appDelegate
application.setActivationPolicy(.accessory)
application.run()
