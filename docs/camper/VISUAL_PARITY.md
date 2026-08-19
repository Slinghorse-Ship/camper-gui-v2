# CamperControl: visuelle Parität

## Verbindliche Quellen

Die sichtbare Gestaltung wird aus zwei vorhandenen Quellen zusammengesetzt, ohne sie neu zu entwerfen:

1. `sync3-camper/reference/CamperControl_SYNC3_Dark_Light_Mockup.png` ist die Referenz für Transit-Signet, klare Linien-Icons, Dark/Light-Farben und die visuelle Sprache.
2. `sync3-camper/SyncMyMod/files/app/Jan/Camper/ModernShell.qml` aus SYNC 3.9.9 bleibt die Referenz für das logische Raster 800 × 480, Größen, Abstände, Touch-Flächen und Verhalten.

Das Mock-up hat 1619 × 971 Pixel und den SHA-256-Hash `95CCA2C870CABF2BDA9C6DBCCB2CD3F75A88587C4ECCB30503B9C262CF2A31B3`. So lässt sich später eindeutig prüfen, ob noch dieselbe Referenz verwendet wird.

## Gemeinsame Tokens

| Bedeutung | Dark | Light | SYNC / gui-v2 | Node-RED |
| --- | --- | --- | --- | --- |
| Hintergrund oben | `#081116` | `#fafafa` | `backgroundTop` | radialer Hintergrund / `--bg` |
| Hintergrund unten | `#03090d` | `#eceff1` | `backgroundBottom` | radialer Hintergrund |
| Kopf-/Navigationsleiste | `#071116` | `#ffffff` | `header` | `.fs-top`, `.fs-nav` |
| Karte | `#111b20` | `#fbfbfb` | `panel` | `--panel` |
| Innere Fläche | `#0d171c` | `#f1f3f4` | `inner` | `--panel2` |
| Primärtext | `#f4f7f9` | `#24282c` | `text` | `--text` |
| Sekundärtext | `#aab4ba` | `#626a70` | `muted` | `--muted` |
| Kontur / Trenner | `#344149` | `#d0d3d5` | `border` | `--border` |
| Camper-Blau | `#42b9f4` | `#0875c1` | `blue` | `--blue` |
| Positiv / verbunden | `#2fd49b` | `#11845f` | `green` | `--accent` |
| Warnung | `#ff981f` | `#d66b00` | `orange` | `--orange` |
| Solar | `#f4c94c` | `#a96f00` | `yellow` | semantischer Solarwert |
| 230 V | `#ad8cf2` | `#7555b5` | `purple` | MultiPlus-Zustand |
| Fehler / offline | `#ef6e76` | `#b83f4a` | `red` | `.offline` / Fehlerzustand |

Die QML-Definitionen liegen in:

- Ford SYNC: `SyncMyMod/files/app/Jan/Camper/CamperStyle.qml`
- gui-v2: `components/camper/CamperStyle.qml`
- Node-RED: `<style id="fs-mockup-visual-language-v1">` in `dashboard/camper-dashboard.html`

## Signet und Icon-Zuordnung

Das detaillierte Transit-Signet des Mock-ups bleibt als vorhandene Originalgrafik erhalten. Ford SYNC und gui-v2 enthalten bytegleich dasselbe 256 × 256-PNG mit dem SHA-256-Hash `D64AB6D614CA5588FB73D80C257775B49DB601D157DBB3FBD66A828D10E15AF2`. Node-RED referenziert dieselbe auf dem Cerbo bereitgestellte Grafik als `/camper-assets/CamperIcon.png`.

| Bedeutung | Ford SYNC | gui-v2 | Node-RED |
| --- | --- | --- | --- |
| Transit-Signet | `Icon.png` | `images/camper_logo.png` | `/camper-assets/CamperIcon.png` |
| Batterie | `LineIcon.kind: "battery"` | `CamperLineIcon.kind: "battery"` | `#fs-battery` |
| Solar mit Panel | `"solar"` | `"solar"` | `#fs-solar` |
| Frischwasser | `"water"` | `"water"` | `#fs-water` |
| Temperatur | `"climate"` | `"climate"` | `#fs-climate` |
| Licht / Navigation | `"light"` | `"light"` | `#fs-bulb` |
| Home | `"home"` | `"home"` | `#fs-home` |
| 12/230 V | `"power"` / `"plug"` | `"power"` / `"plug"` | `#fs-plug` |
| Wasserpumpe | `"pump"` | `"pump"` | `#fs-pump` |
| MaxxFan | `"fan"` | `"fan"` | `#fs-fan` |
| Arbeitsleuchten | `workLight*`, `rearLight` | identische Namen | `#fs-left-light`, `#fs-right-light`, `#fs-down-light` |
| Lichtbalken | `lightBar`, `warningBar` | identische Namen | `#fs-lightbar`, `#fs-warningbar` |
| Fernlicht | `highBeam` | `highBeam` | `#fs-highbeam` |

Für QML gelten runde Linienenden und Linienverbindungen. Die normale Strichstärke ist bei 32–48 Pixel großen Symbolen 1,8–2,2 logische Pixel. Node-RED verwendet dieselbe visuelle Stärke über SVG `stroke-width: 2`.

Die vorhandene Grafik wird nicht neu gezeichnet oder stilisiert. So bleibt die im alten Mock-up gewünschte detaillierte Transit-Form erhalten; nur die Header-Geometrie skaliert sie innerhalb der bereits vorhandenen Fläche.

## Bewusst unverändert

- 800 × 480 als primäres GX-Touch-50-/SYNC-Raster
- bestehende Seiten, Reihenfolge und Navigation
- Touch-Flächen und Klicksignale
- D-Bus-, MQTT-, HTTP- und Node-RED-Bindings
- Statusfarben für reale Zustände und die bisherige Bedienlogik
- Fahrzeugbilder und Licht-Hotspots auf der Lichtseite

## Noch zu entscheidende visuelle Punkte

1. Der Headertext ist aktuell weiterhin dynamisch und fällt auf `FORD TRANSIT CAMPER` zurück. Das alte Mock-up zeigt kürzer `CAMPER`. Eine Änderung wäre inhaltlich sichtbar und wird deshalb nicht stillschweigend vorgenommen.
2. Die aktuelle Navigation hat drei Ziele; das Mock-up zeigt sechs. Das bleibt unverändert, bis die zusätzlichen Seiten in gui-v2 tatsächlich vorhanden sind.
3. SYNC übernimmt Dark/Light vom Ford-System, Node-RED hat einen manuellen Umschalter, gui-v2 ist im Prototyp noch fest dunkel. Die automatische GX-Tag-/Nachtquelle wird erst mit einem bekannten, echten Victron-Datenpunkt angebunden.
4. Die systemweit identische Schrift ist noch nicht gebündelt. SYNC und Qt verwenden die vorhandene Systemschrift, Node-RED `Inter, Arial, sans-serif`. Abstände und Größen werden nicht für eine unbestätigte Schriftdatei verändert.
