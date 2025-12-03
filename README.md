![rigby lol](https://images.steamusercontent.com/ugc/12310949826572664578/F8639C0A63ABD86D15FA3FBA00FB09E9FD1C98B3/?imw=200&imh=200&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false)
## Description
Random Asylum is a chaotic Garry's Mod gamemode where players fight with completely random SWEPs. Every spawn, players receive random weapons from the server's collection, creating unpredictable and hilarious combat scenarios. The gamemode features round-based gameplay with automatic map voting between rounds.

## Features
* **Random SWEP Distribution** - Players receive random weapons on each spawn
* **Round-Based Gameplay** - Timed rounds with automatic map voting
* **Player Statistics Tracking** - Tracks kills and deaths per round
* **Custom HUD** - Shows round time, player counts, and round results
* **Configurable Settings** - Server owners can adjust various gameplay parameters

## Installation
1. Download the latest release from the [Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3590237349)
2. Subscribe to the addon in Steam Workshop
3. Restart your Garry's Mod server
4. Set the gamemode using the following command: `gamemode randomasylum`

## Configuration
The gamemode includes several configurable settings that can be adjusted via the server console or configuration files:

| ConVar | Default | Description |
|--------|---------|-------------|
| `ra_allow_admin_weapons` | `0` | If enabled (1), admin-only weapons can be given randomly |
| `ra_swep_count` | `1` | Number of random SWEPs to give each player on spawn |
| `ra_round_time` | `300` | Duration of each round in seconds (5 minutes) |
| `ra_min_players` | `2` | Minimum players required to start a round |

To change these settings permanently, add them to your server's `server.cfg` file:
```
ra_allow_admin_weapons 1
ra_swep_count 2
ra_round_time 600
ra_min_players 3
```

## Recommended Addons
For the best experience, we recommend installing these complementary addons:
* [Random Asylum (audio-pack) Item Asylum edition](https://steamcommunity.com/sharedfiles/filedetails/?id=3590260323) - Enhanced audio experience
* [Advanced Killfeed](https://steamcommunity.com/sharedfiles/filedetails/?id=3414546020) - Improved kill notification system
* [Random Death Sounds](https://steamcommunity.com/sharedfiles/filedetails/?id=694098968) - Varied death sounds for more fun
* [Spawn Protection](https://steamcommunity.com/sharedfiles/filedetails/?id=3401291379) - Prevents spawn camping
* [MapVote](https://steamcommunity.com/sharedfiles/filedetails/?id=151583504) - Required for automatic map voting between rounds

## FAQ
### End-of-Round Map Voting
If the map vote doesn't start automatically at the end of a round, make sure you have the [MapVote addon](https://steamcommunity.com/sharedfiles/filedetails/?id=151583504) installed and properly configured.

### Killfeed Not Showing
The gamemode doesn't include a custom killfeed by default. We recommend installing the [Advanced Killfeed](https://steamcommunity.com/sharedfiles/filedetails/?id=3414546020) addon for better kill notifications. A custom killfeed may be added in future updates based on community feedback.

### Banned Weapons
The gamemode automatically excludes certain tools like the physics gun and toolgun to maintain fair gameplay. These can be modified by editing the `bannedWeapons` table in `weapon_system.lua`.

## Server Commands
* `mapvote` - Manually trigger map voting (handled automatically by the gamemode)
* `ra_changemodel <player> <model>` - Change a player's model (requires admin privileges)

## License
This project is licensed under the GNU Affero General Public License v3.0. See the [LICENSE](LICENSE) file for details.

## Support
If you enjoy this gamemode and want to support its development, you can donate via: [DonationAlerts](https://dalink.to/adskoe95)

## Contributing
Contributions are welcome! Please feel free to submit pull requests or open issues on this repository.

## Credits
* **Author**: adsk-dev
* **Website**: [https://adskoe96.github.io/links/](https://adskoe96.github.io/links/)
