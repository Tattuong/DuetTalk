# Google Play IAP — DuetTalk

Package: `com.DuetTalkMNG.DuetTalk`

Remote config: `https://api2.blwsmartware.net/N305.json`  
If JSON field `disable` is `1`, hide Google Play purchase popups. Shop stays open for coin unlocks.

## Consumable coin packs (buy many times)

| Product ID | Coins |
| --- | --- |
| `dt_pack_1` | 50 |
| `dt_pack_2` | 100 |
| `dt_pack_3` | 200 |
| `dt_pack_4` | 350 |
| `dt_pack_5` | 500 |
| `dt_pack_6` | 750 |
| `dt_pack_7` | 1000 |
| `dt_pack_8` | 1500 |
| `dt_pack_9` | 2200 |
| `dt_pack_10` | 3000 |

## One-time

| Product ID | Unlock |
| --- | --- |
| `dt_remove_ads` | Hide the banner |
| `dt_pro` | More than 8 saved phrases |

Create these IDs in Play Console → Monetize → In-app products. Coin packs must be **consumable**. Remove ads and Pro must be **non-consumable**.
