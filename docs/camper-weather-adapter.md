# CamperControl weather adapter

The V2 weather panel is a read-only consumer of
`com.victronenergy.campercontrol/State/Weather`. `CamperWeatherAdapter.qml`
uses `VeQuickItem`, so GX reads the value through D-Bus and WASM receives the
same value through gui-v2's existing MQTT transport. The QML layer does not
contact DWD or any other HTTP endpoint.

The service item contains one JSON object normalized by the Cerbo-side weather
producer:

- `fetchedAtUtc`, `stale`, `station.name` and `sun.sunriseUtc`/`sun.sunsetUtc`
- `hourly`: up to 24 entries with `t`, `tempC`, `precipProbabilityPct`,
  `precipMm`, `ww`, `icon` and `windKmh`
- `daily`: up to six entries with `date`, `minC`, `maxC`, `precipMm`,
  `maxHourlyPrecipProbabilityPct`, `ww` and `icon`

If no explicit `current` object is present, the panel uses the first current or
future hourly entry. The Cerbo-side producer, its DWD station selection and its
refresh policy are intentionally outside gui-v2 and must be provided by the
CamperControl service before live weather appears.
