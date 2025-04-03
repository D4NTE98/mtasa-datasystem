# MTA:SA Secure Data System 🔒

# Author: D4NTE

Advanced secure player data management system with military-grade encryption and anti-cheat protection

## Features ✨
- **AES-256-GCM Encryption** - End-to-end data protection
- **Anti-Tamper Mechanisms** - Memory validation and HMAC verification
- **Admin Control Panel** - Real-time player data management (F8)
- **LRU Caching** - High-performance data access
- **Session Key Rotation** - Auto-generated every hour
- **Cross-Resource Security** - Protected inter-resource communication

## Examples
local health = exports["mtasa-datasystem"]:getPlayerData(player, "health")

exports["mtasa-datasystem"]:setPlayerData(player, "bank", 5000, {
    persist = true,
    cache = false
})

## Installation 💻
1. Download latest release
2. Place `mtasa-datasystem` in your `resources/` folder
3. Add to `mtaserver.conf`:
```bash
start mtasa-datasystem
