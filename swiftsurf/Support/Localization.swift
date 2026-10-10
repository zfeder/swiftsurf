//
//  Localization.swift
//  swiftsurf
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case italian = "it"
    case spanish = "es"
    case french = "fr"
    case german = "de"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: "English"
        case .italian: "Italiano"
        case .spanish: "Español"
        case .french: "Français"
        case .german: "Deutsch"
        }
    }

    /// The first of the user's preferred system languages that SwiftSurf supports.
    static var systemDefault: AppLanguage {
        for identifier in Locale.preferredLanguages {
            let code = String(identifier.prefix(2))
            if let language = AppLanguage(rawValue: code) {
                return language
            }
        }
        return .english
    }
}

struct AppStrings {
    let language: AppLanguage

    init(language: AppLanguage) {
        self.language = language
    }

    init(rawValue: String) {
        language = AppLanguage(rawValue: rawValue) ?? .english
    }

    subscript(_ key: String) -> String {
        Self.tables[language]?[key] ?? Self.tables[.english]?[key] ?? key
    }

    static let tables: [AppLanguage: [String: String]] = [
        .english: [
            "newTab": "New Tab", "settings": "Settings", "private": "Private",
            "search": "Search or enter website address", "bookmarks": "Bookmarks",
            "recent": "Recent", "privateBrowsing": "Private browsing",
            "clearData": "Clear browsing data",
            "removeBookmark": "Remove Bookmark", "addBookmark": "Add Bookmark",
            "unable": "Unable to load this page", "tryAgain": "Try Again",
            "recentPages": "Recent pages", "noRecent": "No recent pages", "quit": "Quit SwiftSurf",
            "stop": "Stop", "keepOpen": "Keep window open", "cancel": "Cancel", "ok": "OK", "done": "Done",
            "delete": "Delete", "dialog.from": "%@ says", "findPlaceholder": "Find in page",
            "notFound": "Not found", "openInNewTab": "Open in New Tab",
            "startHint": "Type an address or search above.", "searchHistory": "Search history",
            "clearHistory": "Clear History", "noDownloads": "No downloads",
            "openDownloadsFolder": "Open Downloads Folder", "clearList": "Clear List",
            "downloadFinished": "Finished", "downloadCancelled": "Cancelled", "showInFinder": "Show in Finder",
            "zoomLevel": "Zoom (%d%%)", "exitReader": "Exit Reader", "pictureInPicture": "Picture in Picture",
            "requestMobileSite": "Request mobile website",
            "menu.view": "View", "menu.navigate": "Navigate",
            "command.newTab": "New Tab", "command.reopenClosedTab": "Reopen Closed Tab",
            "command.closeTab": "Close Tab", "command.focusAddress": "Focus Address Bar",
            "command.find": "Find in Page…", "command.findNext": "Find Next", "command.findPrevious": "Find Previous",
            "command.reload": "Reload Page", "command.goBack": "Back", "command.goForward": "Forward",
            "command.nextTab": "Next Tab", "command.previousTab": "Previous Tab",
            "command.zoomIn": "Zoom In", "command.zoomOut": "Zoom Out", "command.actualSize": "Actual Size",
            "command.toggleReader": "Reader Mode", "command.toggleBookmark": "Add or Remove Bookmark",
            "command.showHistory": "Show History", "command.showDownloads": "Downloads",
            "settings.language": "Language", "settings.startup": "Startup", "settings.homePage": "Home page URL",
            "settings.homePageFooter": "The home page opens when there is no previous session to restore.",
            "settings.restoreSession": "Reopen tabs from last session", "settings.searchEngine": "Search engine",
            "settings.privacy": "Privacy", "settings.blockTrackers": "Block ads and trackers",
            "settings.blockTrackersFooter": "Blocks requests to well-known third-party advertising and tracking services.",
            "settings.appearance": "Appearance", "settings.showDockIcon": "Show icon in Dock",
            "settings.favoritesBar": "Show favorites bar",
            "settings.appearanceFooter": "Without the Dock icon, SwiftSurf stays available from the menu bar. Drag the window away from the menu bar to detach it.",
            "settings.keyboard": "Keyboard", "settings.globalShortcut": "Open SwiftSurf from anywhere",
            "settings.globalShortcutFooter": "Press the shortcut in any app to show or hide SwiftSurf.",
            "settings.off": "Off"
        ],
        .italian: [
            "newTab": "Nuova scheda", "settings": "Impostazioni", "private": "Privata",
            "search": "Cerca o inserisci un indirizzo", "bookmarks": "Preferiti",
            "recent": "Recenti", "privateBrowsing": "Navigazione privata",
            "clearData": "Cancella dati di navigazione",
            "removeBookmark": "Rimuovi preferito", "addBookmark": "Aggiungi preferito",
            "unable": "Impossibile caricare questa pagina", "tryAgain": "Riprova",
            "recentPages": "Pagine recenti", "noRecent": "Nessuna pagina recente", "quit": "Esci da SwiftSurf",
            "stop": "Interrompi", "keepOpen": "Mantieni la finestra aperta", "cancel": "Annulla", "ok": "OK",
            "done": "Fine", "delete": "Elimina", "dialog.from": "%@ dice", "findPlaceholder": "Cerca nella pagina",
            "notFound": "Nessun risultato", "openInNewTab": "Apri in una nuova scheda",
            "startHint": "Digita un indirizzo o una ricerca qui sopra.", "searchHistory": "Cerca nella cronologia",
            "clearHistory": "Cancella cronologia", "noDownloads": "Nessun download",
            "openDownloadsFolder": "Apri la cartella Download", "clearList": "Svuota elenco",
            "downloadFinished": "Completato", "downloadCancelled": "Annullato", "showInFinder": "Mostra nel Finder",
            "zoomLevel": "Zoom (%d%%)", "exitReader": "Esci dalla modalità lettura",
            "pictureInPicture": "Picture in Picture", "requestMobileSite": "Richiedi sito per dispositivi mobili",
            "menu.view": "Vista", "menu.navigate": "Naviga",
            "command.newTab": "Nuova scheda", "command.reopenClosedTab": "Riapri scheda chiusa",
            "command.closeTab": "Chiudi scheda", "command.focusAddress": "Attiva barra degli indirizzi",
            "command.find": "Cerca nella pagina…", "command.findNext": "Trova successivo",
            "command.findPrevious": "Trova precedente", "command.reload": "Ricarica pagina",
            "command.goBack": "Indietro", "command.goForward": "Avanti",
            "command.nextTab": "Scheda successiva", "command.previousTab": "Scheda precedente",
            "command.zoomIn": "Ingrandisci", "command.zoomOut": "Riduci", "command.actualSize": "Dimensioni reali",
            "command.toggleReader": "Modalità lettura", "command.toggleBookmark": "Aggiungi o rimuovi preferito",
            "command.showHistory": "Mostra cronologia", "command.showDownloads": "Download",
            "settings.language": "Lingua", "settings.startup": "Avvio", "settings.homePage": "URL pagina iniziale",
            "settings.homePageFooter": "La pagina iniziale si apre quando non c'è una sessione precedente da ripristinare.",
            "settings.restoreSession": "Riapri le schede dell'ultima sessione", "settings.searchEngine": "Motore di ricerca",
            "settings.privacy": "Privacy", "settings.blockTrackers": "Blocca pubblicità e tracker",
            "settings.blockTrackersFooter": "Blocca le richieste verso noti servizi di terze parti per pubblicità e tracciamento.",
            "settings.appearance": "Aspetto", "settings.showDockIcon": "Mostra icona nel Dock",
            "settings.favoritesBar": "Mostra barra dei preferiti",
            "settings.appearanceFooter": "Senza icona nel Dock, SwiftSurf resta disponibile dalla barra dei menu. Trascina la finestra lontano dalla barra dei menu per staccarla.",
            "settings.keyboard": "Tastiera", "settings.globalShortcut": "Apri SwiftSurf da qualsiasi app",
            "settings.globalShortcutFooter": "Premi la scorciatoia in qualsiasi app per mostrare o nascondere SwiftSurf.",
            "settings.off": "Disattivata"
        ],
        .spanish: [
            "newTab": "Nueva pestaña", "settings": "Ajustes", "private": "Privada",
            "search": "Busca o introduce una dirección", "bookmarks": "Marcadores",
            "recent": "Recientes", "privateBrowsing": "Navegación privada",
            "clearData": "Borrar datos de navegación",
            "removeBookmark": "Quitar marcador", "addBookmark": "Añadir marcador",
            "unable": "No se puede cargar esta página", "tryAgain": "Reintentar",
            "recentPages": "Páginas recientes", "noRecent": "No hay páginas recientes", "quit": "Salir de SwiftSurf",
            "stop": "Detener", "keepOpen": "Mantener la ventana abierta", "cancel": "Cancelar", "ok": "Aceptar",
            "done": "OK", "delete": "Eliminar", "dialog.from": "%@ dice", "findPlaceholder": "Buscar en la página",
            "notFound": "No encontrado", "openInNewTab": "Abrir en una pestaña nueva",
            "startHint": "Escribe una dirección o una búsqueda arriba.", "searchHistory": "Buscar en el historial",
            "clearHistory": "Borrar historial", "noDownloads": "No hay descargas",
            "openDownloadsFolder": "Abrir la carpeta Descargas", "clearList": "Limpiar lista",
            "downloadFinished": "Completada", "downloadCancelled": "Cancelada", "showInFinder": "Mostrar en el Finder",
            "zoomLevel": "Zoom (%d%%)", "exitReader": "Salir del modo lectura",
            "pictureInPicture": "Imagen dentro de imagen", "requestMobileSite": "Solicitar sitio web móvil",
            "menu.view": "Visualización", "menu.navigate": "Navegar",
            "command.newTab": "Nueva pestaña", "command.reopenClosedTab": "Reabrir pestaña cerrada",
            "command.closeTab": "Cerrar pestaña", "command.focusAddress": "Activar barra de direcciones",
            "command.find": "Buscar en la página…", "command.findNext": "Buscar siguiente",
            "command.findPrevious": "Buscar anterior", "command.reload": "Recargar página",
            "command.goBack": "Atrás", "command.goForward": "Adelante",
            "command.nextTab": "Pestaña siguiente", "command.previousTab": "Pestaña anterior",
            "command.zoomIn": "Ampliar", "command.zoomOut": "Reducir", "command.actualSize": "Tamaño real",
            "command.toggleReader": "Modo lectura", "command.toggleBookmark": "Añadir o quitar marcador",
            "command.showHistory": "Mostrar historial", "command.showDownloads": "Descargas",
            "settings.language": "Idioma", "settings.startup": "Inicio", "settings.homePage": "URL de la página de inicio",
            "settings.homePageFooter": "La página de inicio se abre cuando no hay una sesión anterior que restaurar.",
            "settings.restoreSession": "Reabrir las pestañas de la última sesión", "settings.searchEngine": "Motor de búsqueda",
            "settings.privacy": "Privacidad", "settings.blockTrackers": "Bloquear anuncios y rastreadores",
            "settings.blockTrackersFooter": "Bloquea las solicitudes a servicios conocidos de publicidad y rastreo de terceros.",
            "settings.appearance": "Apariencia", "settings.showDockIcon": "Mostrar icono en el Dock",
            "settings.favoritesBar": "Mostrar barra de favoritos",
            "settings.appearanceFooter": "Sin el icono en el Dock, SwiftSurf sigue disponible desde la barra de menús. Arrastra la ventana fuera de la barra de menús para separarla.",
            "settings.keyboard": "Teclado", "settings.globalShortcut": "Abrir SwiftSurf desde cualquier app",
            "settings.globalShortcutFooter": "Pulsa el atajo en cualquier app para mostrar u ocultar SwiftSurf.",
            "settings.off": "Desactivado"
        ],
        .french: [
            "newTab": "Nouvel onglet", "settings": "Réglages", "private": "Privé",
            "search": "Rechercher ou saisir une adresse", "bookmarks": "Signets",
            "recent": "Récent", "privateBrowsing": "Navigation privée",
            "clearData": "Effacer les données de navigation",
            "removeBookmark": "Supprimer le signet", "addBookmark": "Ajouter aux signets",
            "unable": "Impossible de charger cette page", "tryAgain": "Réessayer",
            "recentPages": "Pages récentes", "noRecent": "Aucune page récente", "quit": "Quitter SwiftSurf",
            "stop": "Arrêter", "keepOpen": "Garder la fenêtre ouverte", "cancel": "Annuler", "ok": "OK",
            "done": "Terminé", "delete": "Supprimer", "dialog.from": "%@ indique", "findPlaceholder": "Rechercher dans la page",
            "notFound": "Introuvable", "openInNewTab": "Ouvrir dans un nouvel onglet",
            "startHint": "Saisissez une adresse ou une recherche ci-dessus.", "searchHistory": "Rechercher dans l’historique",
            "clearHistory": "Effacer l’historique", "noDownloads": "Aucun téléchargement",
            "openDownloadsFolder": "Ouvrir le dossier Téléchargements", "clearList": "Effacer la liste",
            "downloadFinished": "Terminé", "downloadCancelled": "Annulé", "showInFinder": "Afficher dans le Finder",
            "zoomLevel": "Zoom (%d %%)", "exitReader": "Quitter le mode lecture",
            "pictureInPicture": "Image dans l’image", "requestMobileSite": "Demander le site mobile",
            "menu.view": "Présentation", "menu.navigate": "Navigation",
            "command.newTab": "Nouvel onglet", "command.reopenClosedTab": "Rouvrir l’onglet fermé",
            "command.closeTab": "Fermer l’onglet", "command.focusAddress": "Activer la barre d’adresse",
            "command.find": "Rechercher dans la page…", "command.findNext": "Rechercher le suivant",
            "command.findPrevious": "Rechercher le précédent", "command.reload": "Recharger la page",
            "command.goBack": "Précédent", "command.goForward": "Suivant",
            "command.nextTab": "Onglet suivant", "command.previousTab": "Onglet précédent",
            "command.zoomIn": "Zoom avant", "command.zoomOut": "Zoom arrière", "command.actualSize": "Taille réelle",
            "command.toggleReader": "Mode lecture", "command.toggleBookmark": "Ajouter ou supprimer le signet",
            "command.showHistory": "Afficher l’historique", "command.showDownloads": "Téléchargements",
            "settings.language": "Langue", "settings.startup": "Démarrage", "settings.homePage": "URL de la page d’accueil",
            "settings.homePageFooter": "La page d’accueil s’ouvre lorsqu’il n’y a pas de session précédente à restaurer.",
            "settings.restoreSession": "Rouvrir les onglets de la dernière session", "settings.searchEngine": "Moteur de recherche",
            "settings.privacy": "Confidentialité", "settings.blockTrackers": "Bloquer les publicités et traqueurs",
            "settings.blockTrackersFooter": "Bloque les requêtes vers des services tiers connus de publicité et de pistage.",
            "settings.appearance": "Apparence", "settings.showDockIcon": "Afficher l’icône dans le Dock",
            "settings.favoritesBar": "Afficher la barre des favoris",
            "settings.appearanceFooter": "Sans icône dans le Dock, SwiftSurf reste accessible depuis la barre des menus. Faites glisser la fenêtre hors de la barre des menus pour la détacher.",
            "settings.keyboard": "Clavier", "settings.globalShortcut": "Ouvrir SwiftSurf depuis n’importe quelle app",
            "settings.globalShortcutFooter": "Appuyez sur le raccourci dans n’importe quelle app pour afficher ou masquer SwiftSurf.",
            "settings.off": "Désactivé"
        ],
        .german: [
            "newTab": "Neuer Tab", "settings": "Einstellungen", "private": "Privat",
            "search": "Suchen oder Adresse eingeben", "bookmarks": "Lesezeichen",
            "recent": "Zuletzt", "privateBrowsing": "Privates Surfen",
            "clearData": "Browserdaten löschen",
            "removeBookmark": "Lesezeichen entfernen", "addBookmark": "Lesezeichen hinzufügen",
            "unable": "Diese Seite konnte nicht geladen werden", "tryAgain": "Erneut versuchen",
            "recentPages": "Zuletzt besuchte Seiten", "noRecent": "Keine zuletzt besuchten Seiten",
            "quit": "SwiftSurf beenden",
            "stop": "Stoppen", "keepOpen": "Fenster geöffnet lassen", "cancel": "Abbrechen", "ok": "OK",
            "done": "Fertig", "delete": "Löschen", "dialog.from": "%@ meldet", "findPlaceholder": "Auf Seite suchen",
            "notFound": "Nicht gefunden", "openInNewTab": "In neuem Tab öffnen",
            "startHint": "Gib oben eine Adresse oder einen Suchbegriff ein.", "searchHistory": "Verlauf durchsuchen",
            "clearHistory": "Verlauf löschen", "noDownloads": "Keine Downloads",
            "openDownloadsFolder": "Downloads-Ordner öffnen", "clearList": "Liste leeren",
            "downloadFinished": "Fertig", "downloadCancelled": "Abgebrochen", "showInFinder": "Im Finder zeigen",
            "zoomLevel": "Zoom (%d %%)", "exitReader": "Reader beenden",
            "pictureInPicture": "Bild-in-Bild", "requestMobileSite": "Mobile Website anfordern",
            "menu.view": "Darstellung", "menu.navigate": "Navigieren",
            "command.newTab": "Neuer Tab", "command.reopenClosedTab": "Geschlossenen Tab wieder öffnen",
            "command.closeTab": "Tab schließen", "command.focusAddress": "Adressleiste aktivieren",
            "command.find": "Auf Seite suchen …", "command.findNext": "Weitersuchen",
            "command.findPrevious": "Rückwärts suchen", "command.reload": "Seite neu laden",
            "command.goBack": "Zurück", "command.goForward": "Vorwärts",
            "command.nextTab": "Nächster Tab", "command.previousTab": "Vorheriger Tab",
            "command.zoomIn": "Vergrößern", "command.zoomOut": "Verkleinern", "command.actualSize": "Originalgröße",
            "command.toggleReader": "Reader", "command.toggleBookmark": "Lesezeichen hinzufügen oder entfernen",
            "command.showHistory": "Verlauf anzeigen", "command.showDownloads": "Downloads",
            "settings.language": "Sprache", "settings.startup": "Start", "settings.homePage": "Startseiten-URL",
            "settings.homePageFooter": "Die Startseite wird geöffnet, wenn keine vorherige Sitzung wiederhergestellt werden kann.",
            "settings.restoreSession": "Tabs der letzten Sitzung wieder öffnen", "settings.searchEngine": "Suchmaschine",
            "settings.privacy": "Datenschutz", "settings.blockTrackers": "Werbung und Tracker blockieren",
            "settings.blockTrackersFooter": "Blockiert Anfragen an bekannte Werbe- und Tracking-Dienste von Drittanbietern.",
            "settings.appearance": "Darstellung", "settings.showDockIcon": "Symbol im Dock anzeigen",
            "settings.favoritesBar": "Favoritenleiste anzeigen",
            "settings.appearanceFooter": "Ohne Dock-Symbol bleibt SwiftSurf über die Menüleiste erreichbar. Ziehe das Fenster von der Menüleiste weg, um es abzulösen.",
            "settings.keyboard": "Tastatur", "settings.globalShortcut": "SwiftSurf aus jeder App öffnen",
            "settings.globalShortcutFooter": "Drücke den Kurzbefehl in einer beliebigen App, um SwiftSurf ein- oder auszublenden.",
            "settings.off": "Aus"
        ]
    ]
}
