# 🎮 JR.DEV Battlepass & Daily Reward System v2.0

Ein professionelles Battlepass-System mit täglichen/wöchentlichen Belohnungen für FiveM ESX Server. Das System kombiniert moderne Gaming-Mechaniken mit robuster Server-Integration.

## ✨ Features

### 🎯 Battlepass System
- **Free Pass**: Kostenloser Fortschritt für alle Spieler
- **Premium Pass**: Erweiterte Belohnungen gegen Bezahlung
- **100 Level**: Progressives Leveling mit XP-System
- **Season-Based**: Zeitlich begrenzte Seasons mit Reset

### 🎁 Daily Reward System
**7-Tage Streak Zyklus:**
- Tag 1: 2.000€ Bargeld
- Tag 2: 5x Erste-Hilfe-Kit
- Tag 3: 3x Angel-Köder + 1.000€
- Tag 4: Zufälliger Waffenaufsatz
- Tag 5: 5.000€ Bankguthaben
- Tag 6: Premium Loot-Box
- Tag 7: MEGA-Bonus (15.000€ + seltenes Item)

### 📋 Mission System
**Daily Missions:**
- "Spiele 60 Minuten" → +500 XP
- "Fange 10 Fische" → +300 XP + Items
- "Fahre 25km" → +400 XP
- "Verdiene 10.000€" → +600 XP

**Weekly Missions:**
- "Gewinne 5 Rennen" → +2000 XP
- "Schließe 15 Jobs ab" → +2500 XP
- "Farme 50 Drogen" → +1800 XP
- "Töte 25 NPCs" → +1500 XP

### 🎨 Modern NUI Interface
- GTA Online inspiriertes Design
- Dunkles Theme mit Gold-Akzenten
- Responsive Layout (1920x1080 optimiert)
- Smooth 60fps Animationen
- Glassmorphism Effekte
- Partikel-System für Belohnungen

### 🔒 Security Features
- Server-seitige Validierung aller Claims
- Rate-Limiting (max 10 Requests/Minute)
- Session-Token System gegen Replay-Attacks
- SQL Injection Schutz mit Prepared Statements
- XP-Manipulation Detection

## 📦 Installation

### 1. 📄 Datenbankeinrichtung
Importiere die SQL-Datei in deine Datenbank:
```sql
source sql/install.sql
```

### 2. 📋 ox_inventory Items (optional)
Füge diese Items zu deiner `ox_inventory/data/items.lua` hinzu:
```lua
['battlepass_coin'] = {
    label = 'Battlepass Coin',
    weight = 0,
    stack = true,
    close = true,
    description = 'Spezielle Währung für das Battlepass-System'
},
```

### 3. 🚀 Server-Konfiguration
Füge zu deiner `server.cfg` hinzu:
```
ensure jr_battlepassv2
```

### 4. 👑 Admin-Rechte
Füge Admin-Rechte zu deiner `server.cfg` hinzu:
```
add_ace group.admin battlepass.admin allow
```

## 🎮 Nutzung

### Spieler Commands
- `F6` oder `/battlepass` - Öffnet das Battlepass Interface

### Admin Commands
- `/bp_give [player_id] [amount]` - Gibt XP an einen Spieler
- `/bp_level [player_id] [level]` - Setzt das Level eines Spielers
- `/bp_coins [player_id] [amount]` - Gibt Coins an einen Spieler
- `/bp_reset [player_id]` - Setzt Spielerdaten zurück
- `/bp_stats` - Zeigt Server-Statistiken
- `/bp_reward [player_id] [type] [item/amount]` - Gibt spezielle Belohnungen
- `/bp_season [create/end/info]` - Season-Management

## 🔧 Konfiguration

Die Hauptkonfiguration befindet sich in `config.lua`. Hier können folgende Einstellungen angepasst werden:

- **Battlepass Settings**: Level, XP-Anforderungen, Premium-Kosten
- **Daily Rewards**: 7-Tage Belohnungszyklen
- **Mission Configuration**: Tägliche und wöchentliche Missionen
- **Loot Box Contents**: Verschiedene Loot-Box-Typen
- **UI Settings**: Theme, Animationen, Keybinds

## 📊 Database Schema

Das System verwendet 6 Haupttabellen:
- `battlepass_players` - Spielerdaten
- `battlepass_missions` - Mission-Fortschritt
- `battlepass_rewards` - Belohnungshistorie
- `battlepass_seasons` - Season-Management
- `battlepass_level_rewards` - Level-Belohnungen
- `battlepass_statistics` - Spielerstatistiken

## 🔗 Integration

### ESX Framework
Vollständig integriert mit ESX für:
- Spielerdaten-Management
- Inventar-System (ox_inventory Support)
- Wirtschafts-System (Geld, Bank)
- Job-System Integration

### Andere Ressourcen
Das System kann einfach in andere Ressourcen integriert werden:

```lua
-- XP geben von anderem Script
exports.jr_battlepassv2:giveXP(playerId, amount, reason)

-- Mission-Fortschritt aktualisieren
exports.jr_battlepassv2:updateMissionProgress(missionId, progress, isIncrement)

-- Spielerdaten abrufen
local playerData = exports.jr_battlepassv2:getPlayerData(playerId)
```

## 🎨 UI Customization

Das Design kann über CSS-Variablen angepasst werden:
```css
:root {
    --primary-gold: #FFD700;
    --background-dark: #0d1117;
    --glass-bg: rgba(255, 255, 255, 0.05);
}
```

## 📱 Responsive Design

Die Benutzeroberfläche ist vollständig responsiv und funktioniert auf verschiedenen Bildschirmauflösungen:
- Desktop: 1920x1080 (optimiert)
- Laptop: 1366x768
- Ultrawide: 2560x1080

## 🔧 Troubleshooting

### Häufige Probleme:

**Database Fehler:**
- Überprüfe Datenbankverbindung in `server.cfg`
- Stelle sicher, dass MySQL-async richtig installiert ist

**UI öffnet sich nicht:**
- Überprüfe Browser-Konsole (F12)
- Stelle sicher, dass alle CSS/JS Dateien geladen werden

**Premium funktioniert nicht:**
- Überprüfe Coin-Balance des Spielers
- Verifiziere Datenbankeinträge in `battlepass_players`

## 📈 Performance

Das System ist für hohe Performance optimiert:
- Caching von Spielerdaten
- Optimierte Datenbankabfragen
- Effizientes NUI-Rendering
- Rate-Limiting für Sicherheit

## 🛡️ Sicherheit

Implementierte Sicherheitsmaßnahmen:
- Server-seitige Validierung
- SQL-Injection Schutz
- Rate-Limiting
- Session-Token System
- Anti-Cheat Detection

## 📜 Changelog

### Version 2.0.0
- Komplette Neuentwicklung
- Modern NUI Interface
- Erweiterte Mission-System
- Premium Pass Features
- Loot-Box System
- Admin Panel
- Multi-Language Support

## 👥 Support

Bei Problemen oder Fragen:
1. Überprüfe die Dokumentation
2. Schaue in die Logs (`F8` Konsole)
3. Kontaktiere den Support

## 📄 Lizenz

Dieses Projekt ist unter einer proprietären Lizenz veröffentlicht.
Copyright © 2024 JR.DEV - Alle Rechte vorbehalten.

## 🙏 Credits

- **Entwickler**: JR.DEV Team
- **UI Design**: Inspiriert von GTA Online
- **Framework**: ESX Legacy
- **Database**: MySQL mit mysql-async

---

**Hinweis**: Dieses System erfordert ESX Legacy Framework und eine MySQL-Datenbank. Stelle sicher, dass alle Abhängigkeiten installiert sind, bevor du das System verwendest.
