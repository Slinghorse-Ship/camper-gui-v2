# CamperControl weather adapter

The V2 weather panel is a read-only consumer of
`com.victronenergy.campercontrol/State/Weather`. `CamperWeatherAdapter.qml`
uses `VeQuickItem`, so GX reads the value through D-Bus and WASM receives the
same value through gui-v2's existing MQTT transport. The QML layer does not
contact DWD or any other HTTP endpoint.

The service item contains one JSON object normalized by the Cerbo-side weather
producer:

- `source`, `attribution`, `license`, `licenseUrl`, `changes`, `fetchedAtUtc`,
  `stale`, `station.name` and `sun.riseUtc`/`sun.setUtc`
- `hourly`: up to 48 entries with `t`, `tempC`, `precipProbabilityPct`,
  `precipMm`, `ww`, `icon` and `windKmh`
- `daily`: up to six entries with `date`, `minC`, `maxC`, `precipMm`,
  `maxHourlyPrecipProbabilityPct`, `ww` and `icon`
- optional `tides` with its own `attribution`, `license`, `licenseUrl` and
  `changes` fields for the separately licensed BSH data

If no explicit `current` object is present, the panel uses the first current or
future hourly entry. The Cerbo-side producer, its DWD station selection and its
refresh policy are intentionally outside gui-v2 and must be provided by the
CamperControl service before live weather appears.

The full DWD/BSH attribution and processing notice is documented in
[`DATA-LICENSES.md`](../DATA-LICENSES.md). The noncommercial CamperControl
software license does not restrict the CC-BY-4.0 data itself.
