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
}

struct AppStrings {
    let language: AppLanguage

    private var values: [String: String] {
        switch language {
        case .english:
            [
                "newTab": "New Tab", "settings": "Settings", "private": "Private",
                "search": "Search or enter website address", "bookmarks": "Bookmarks",
                "recent": "Recent", "showHistory": "Show history", "privateBrowsing": "Private browsing",
                "clearData": "Clear browsing data", "downloads": "Show downloads",
                "removeBookmark": "Remove Bookmark", "addBookmark": "Add Bookmark",
                "unable": "Unable to load this page", "tryAgain": "Try Again",
                "recentPages": "Recent pages", "noRecent": "No recent pages",
                "focusAddress": "Focus Address Bar", "quit": "Quit SwiftSurf"
            ]
        case .italian:
            [
                "newTab": "Nuova scheda", "settings": "Impostazioni", "private": "Privata",
                "search": "Cerca o inserisci un indirizzo", "bookmarks": "Preferiti",
                "recent": "Recenti", "showHistory": "Mostra cronologia", "privateBrowsing": "Navigazione privata",
                "clearData": "Cancella dati di navigazione", "downloads": "Mostra download",
                "removeBookmark": "Rimuovi preferito", "addBookmark": "Aggiungi preferito",
                "unable": "Impossibile caricare questa pagina", "tryAgain": "Riprova",
                "recentPages": "Pagine recenti", "noRecent": "Nessuna pagina recente",
                "focusAddress": "Attiva barra degli indirizzi", "quit": "Esci da SwiftSurf"
            ]
        case .spanish:
            [
                "newTab": "Nueva pestaña", "settings": "Ajustes", "private": "Privada",
                "search": "Busca o introduce una dirección", "bookmarks": "Marcadores",
                "recent": "Recientes", "showHistory": "Mostrar historial", "privateBrowsing": "Navegación privada",
                "clearData": "Borrar datos de navegación", "downloads": "Mostrar descargas",
                "removeBookmark": "Quitar marcador", "addBookmark": "Añadir marcador",
                "unable": "No se puede cargar esta página", "tryAgain": "Reintentar",
                "recentPages": "Páginas recientes", "noRecent": "No hay páginas recientes",
                "focusAddress": "Activar barra de direcciones", "quit": "Salir de SwiftSurf"
            ]
        case .french:
            [
                "newTab": "Nouvel onglet", "settings": "Réglages", "private": "Privé",
                "search": "Rechercher ou saisir une adresse", "bookmarks": "Signets",
                "recent": "Récent", "showHistory": "Afficher l’historique", "privateBrowsing": "Navigation privée",
                "clearData": "Effacer les données de navigation", "downloads": "Afficher les téléchargements",
                "removeBookmark": "Supprimer le signet", "addBookmark": "Ajouter aux signets",
                "unable": "Impossible de charger cette page", "tryAgain": "Réessayer",
                "recentPages": "Pages récentes", "noRecent": "Aucune page récente",
                "focusAddress": "Activer la barre d’adresse", "quit": "Quitter SwiftSurf"
            ]
        case .german:
            [
                "newTab": "Neuer Tab", "settings": "Einstellungen", "private": "Privat",
                "search": "Suchen oder Adresse eingeben", "bookmarks": "Lesezeichen",
                "recent": "Zuletzt", "showHistory": "Verlauf anzeigen", "privateBrowsing": "Privates Surfen",
                "clearData": "Browserdaten löschen", "downloads": "Downloads anzeigen",
                "removeBookmark": "Lesezeichen entfernen", "addBookmark": "Lesezeichen hinzufügen",
                "unable": "Diese Seite konnte nicht geladen werden", "tryAgain": "Erneut versuchen",
                "recentPages": "Zuletzt besuchte Seiten", "noRecent": "Keine zuletzt besuchten Seiten",
                "focusAddress": "Adressleiste aktivieren", "quit": "SwiftSurf beenden"
            ]
        }
    }

    subscript(_ key: String) -> String {
        values[key] ?? key
    }
}
