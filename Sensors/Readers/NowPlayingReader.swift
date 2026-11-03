//
//  NowPlayingReader.swift
//  HAL
//
//  Lecture de la piste en cours dans Music (ou iTunes, le vieux lecteur
//  tourne encore sur certaines machines). Récupéré de l'ancien
//  `Sensors/Sensors.swift`, adapté à l'architecture modulaire : le relevé
//  reste asynchrone et jamais bloquant, la pochette espacée.
//

import Foundation

public final class NowPlayingReader: @unchecked Sendable {

    /// Les lecteurs possibles, dans l'ordre de préférence : le nom du
    /// processus détecté décide lequel interroger.
    private static let playerNames = ["Music", "iTunes"]

    /// Durée de validité d'un relevé **complet** (pochette comprise) :
    /// la sonde légère repasse chaque tick, mais la pochette mérite un
    /// nouveau relevé de temps en temps — un morceau changé hors de la
    /// portée de la sonde, une pochette réparée dans le lecteur.
    private static let timeToLive: TimeInterval = 10

    /// Délai au-delà duquel le lecteur est considéré comme bloqué et tué.
    private static let watchdog: TimeInterval = 5

    /// Piste, artiste, album, année, durée, état — et, si le second
    /// argument vaut `artwork`, la pochette écrite dans le fichier passé
    /// en premier argument. Toute erreur est avalée (pas de piste
    /// courante, piste sans pochette, automatisation refusée) :
    /// `artworkData` est alors simplement nul, et le script renvoie
    /// quand même ses champs.
    ///
    /// Le relevé est donc scindé : la sonde de chaque tick ne demande
    /// pas l'image (un simple `player state` et les champs du morceau),
    /// seul le relevé complet la demande — voir `fetch(artwork:)`.
    ///
    /// Piège d'écriture : `POSIX file` **à l'intérieur** d'un
    /// `tell artwork` est résolu relativement à la cible — AppleScript
    /// tente alors de convertir « le fichier POSIX de la pochette » et
    /// échoue (-1700). On lit donc la donnée dans le `tell`, et on écrit
    /// ensuite, hors de tout contexte d'envoi.
    ///
    /// `album artist` a la priorité sur `artist` : sur une compilation ou
    /// une bande originale, c'est lui qui porte le nom affiché sur la
    /// pochette, là où `artist` nomme l'interprète du morceau.
    private static let script = """
        on run argv
            set outPath to item 1 of argv
            set wantArtwork to ((count of argv) > 1) and ((item 2 of argv) is "artwork")
            set trackName to ""
            set trackArtist to ""
            set albumName to ""
            set albumYear to ""
            set trackDuration to ""
            set stateName to "stopped"
            set imgData to missing value
            tell application "__APP__"
                set stateName to player state as text
                try
                    set t to current track
                    set trackName to name of t as text
                    set trackArtist to artist of t as text
                    try
                        set albumArtist to album artist of t as text
                        if albumArtist is not "" then set trackArtist to albumArtist
                    end try
                    try
                        set albumName to album of t as text
                    end try
                    try
                        set albumYear to year of t as text
                    end try
                    try
                        set trackDuration to duration of t as text
                    end try
                    if wantArtwork then
                        set imgData to raw data of artwork 1 of t
                    end if
                end try
            end tell
            if imgData is not missing value then
                try
                    set f to open for access (POSIX file outPath) with write permission
                    set eof f to 0
                    write imgData to f
                    close access f
                end try
            end if
            set header to trackName & tab & trackArtist & tab & stateName
            return header & tab & albumName & tab & albumYear & tab & trackDuration
        end run
        """

    /// Taille maximale de l'image transportée : au-delà, elle est réduite
    /// à la volée. Les pochettes sortent en 1400 ou 2048 px (1 à 3 Mo) pour
    /// une quarantaine de points à l'écran — la transporter telle quelle
    /// ferait payer un décodage de plusieurs mégaoctets à chaque nouvelle
    /// piste, alors qu'un simple `sips` ramène le fichier à quelques
    /// dizaines de kilo-octets.
    private static let artworkPixelSize = 256

    private let lock = NSLock()
    private let queue = DispatchQueue(label: "HAL.NowPlaying", qos: .utility)
    private var cached = NowPlaying()
    /// Instant du dernier relevé **complet** (pochette comprise). Sert à
    /// espacer les relevés lourds, pas à interdire la sonde légère.
    private var lastFetch: Date = .distantPast
    /// Identité (titre + artiste + album) de la pochette en cache : quand
    /// la sonde légère voit une autre piste, un relevé complet part sans
    /// attendre la fin du délai.
    private var artworkTrack = ""
    private var isFetching = false

    public init() {}

    // MARK: - Public Methods

    /// État en cache, rafraîchi en arrière-plan à chaque tick. **Jamais
    /// bloquant.**
    public func read() async -> NowPlaying {
        guard let player = Self.runningPlayer() else {
            // Le lecteur a quitté : on oublie aussitôt la pochette, sinon
            // le cockpit continuerait de mentir encore quelques secondes.
            lock.withLock {
                cached = NowPlaying()
                artworkTrack = ""
            }
            return NowPlaying()
        }
        queue.async { self.refresh(player: player) }
        return lock.withLock { cached }
    }

    // MARK: - Private Methods

    /// Relevé sur la file de fond : saute si un est déjà en cours. Une
    /// sonde légère — état et piste, sans la pochette — à chaque tick ;
    /// un relevé complet, la seule passe qui transporte l'image, lorsque
    /// la piste change ou toutes les `timeToLive` secondes. Un échec
    /// **conserve** le cache connu : c'est le retour d'une veille ou un
    /// lecteur momentanément muet, pas une piste à effacer. Ne doit être
    /// appelé que depuis `queue`.
    private func refresh(player: String) {
        lock.lock()
        let busy = isFetching
        if !busy { isFetching = true }
        let previous = cached
        let fullIsDue = Date().timeIntervalSince(lastFetch) >= Self.timeToLive
        lock.unlock()
        guard !busy else { return }

        guard var fresh = Self.fetch(player: player, artwork: false) else {
            // Le lecteur n'a pas répondu : on garde l'état connu et on
            // reprend dès le prochain tick, sans attendre le délai.
            lock.lock()
            isFetching = false
            lock.unlock()
            return
        }

        // La pochette appartient à la piste : rien à en dire tant que
        // l'identité n'a pas bougé. Un relevé complet raté laisse
        // l'identité inchangée : il sera retenté au tick suivant.
        let identity = fresh.track + "\t" + fresh.artist
        if fullIsDue || identity != artworkTrack {
            if let complete = Self.fetch(player: player, artwork: true) {
                fresh = complete
                // Le relevé a répondu, image ou pas (une piste sans
                // pochette reste sans pochette) : l'identité est
                // consignée et l'on ne redemande pas à chaque tick.
                lock.lock()
                artworkTrack = identity
                lock.unlock()
            }
        }
        if fresh.artworkData == nil, identity == artworkTrack {
            // La sonde légère ne transporte jamais d'image : sans cette
            // prolongation, la pochette du relevé complet s'éteindrait
            // dès le tick suivant. Une piste nouvelle, elle, reste à
            // nu — l'ancienne image ne lui appartient pas.
            fresh.artworkData = previous.artworkData
        }

        lock.lock()
        cached = fresh
        if fullIsDue { lastFetch = Date() }
        isFetching = false
        lock.unlock()
    }

    /// Interroge le lecteur et reconstruit l'état, avec la pochette si
    /// `artwork` est vrai. Renvoie `nil` si le lecteur n'a pas répondu —
    /// l'appelant décide alors s'il doit effacer l'état connu ou le
    /// garder en attendant mieux.
    private static func fetch(player: String, artwork: Bool) -> NowPlaying? {
        var playing = NowPlaying()
        playing.isPlayerRunning = true

        let path = NSTemporaryDirectory() + "HAL-artwork-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: path) }

        var arguments = [path]
        if artwork { arguments.append("artwork") }
        guard let header = runAppleScript(script(for: player),
                                          arguments: arguments) else { return nil }
        let fields = header.components(separatedBy: "\t")
        playing.track = fields.first ?? ""
        playing.artist = fields.count > 1 ? fields[1] : ""
        playing.isPlaying = fields.count > 2 && fields[2] == "playing"
        playing.album = fields.count > 3 ? fields[3] : ""
        playing.year = fields.count > 4 ? Int(fields[4]) ?? 0 : 0
        playing.duration = fields.count > 5 ? Double(fields[5]) ?? 0 : 0
        guard artwork, FileManager.default.fileExists(atPath: path) else { return playing }
        playing.artworkData = Self.downscaled(path) ?? FileManager.default.contents(atPath: path)
        return playing
    }

    /// Le script d'interrogation, le nom du lecteur substitué.
    private static func script(for player: String) -> String {
        script.replacingOccurrences(of: "__APP__", with: player)
    }

    /// Réduit la pochette à `artworkPixelSize` sur son plus grand côté.
    ///
    /// `sips` plutôt que `NSImage` : le module n'importe pas AppKit, et
    /// l'ajouter pour un simple redimensionnement coûterait plus cher en
    /// dépendances qu'en lignes. En cas d'échec (format exotique), on
    /// garde l'original : l'afficheur sait décoder ce qu'il reçoit.
    ///
    /// L'argument `--out` reçoit le même chemin que l'entrée : `sips`
    /// écrit alors son résultat dans un fichier temporaire qu'il substitue
    /// à l'original, dont le type est conservé.
    private static func downscaled(_ source: String) -> Data? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
        process.arguments = ["-Z", "\(artworkPixelSize)", source, "--out", source]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return nil
        }
        // Chien de garde, comme pour `osascript` : un `sips` qui ne
        // rendrait pas la main laisserait `isFetching` bloqué, et HAL
        // n'afficherait plus jamais de musique.
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + watchdog) {
            if process.isRunning { process.terminate() }
        }
        process.waitUntilExit()
        guard process.terminationReason == .exit, process.terminationStatus == 0 else { return nil }
        return FileManager.default.contents(atPath: source)
    }

    /// Le lecteur lancé, s'il y en a un. On regarde les processus plutôt
    /// que d'envoyer une Apple Event : `tell application` **ouvrirait** le
    /// lecteur s'il était fermé — exactement l'inverse de ce qu'on
    /// cherche. L'énumération coûte ~1 ms, contre ~150 ms pour une Apple
    /// Event ratée.
    private static func runningPlayer() -> String? {
        for pid in ProcessReader.allPIDs() where pid > 0 {
            if let name = ProcessReader.name(for: pid),
               playerNames.contains(name) {
                return name
            }
        }
        return nil
    }

    /// Exécute `osascript` et renvoie sa sortie standard, ou `nil` si le
    /// lecteur a refusé (automatisation refusée, lecture indisponible…).
    private static func runAppleScript(_ script: String, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script] + arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return nil
        }
        // Chien de garde : un lecteur figé ne doit pas retenir la file de
        // fond au-delà du délai. `readDataToEndOfFile` rend alors la main.
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + watchdog) {
            if process.isRunning { process.terminate() }
        }
        // Lire jusqu'à EOF **avant** d'attendre la fin évite tout blocage si
        // la sortie dépassait la taille du tampon du pipe.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationReason == .exit, process.terminationStatus == 0 else {
            return nil
        }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines)
    }
}
