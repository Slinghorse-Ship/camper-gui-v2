# CamperControl V1/V2 release notes

## Compatibility

This change remains pinned to the compatibility baseline in `PORT_BASELINE.md`:
Venus OS `v3.80~39`, gui-v2 `1.3.14-r0`, Qt `6.8.3`, and GX Touch 50 at
`800x480`.

## Display-fit patch

- V2 now owns the complete 800x480 canvas as a square, clipped gradient
  rectangle. Its four output corners are the V2 background colors in both day
  and night mode; no host background or outer rounded mask is visible.
- The day/night Transit header symbols are the final RGBA assets shared with
  Ford SYNC. They have transparent corners and the compact FORD block grille.
- The 42x42 close target at the upper right emits the shell's existing
  `closeRequested` signal. It does not quit gui-v2 and does not touch a backend
  service. The signal travels from `CamperV2Header` through `CamperV2Shell` and
  `CamperShell` to `MainView.showVictronUi()`, which hides only the Camper
  overlay and exposes the preserved Victron UI underneath. The existing
  `CAMPER` button calls `MainView.showCamperUi()` to return.
- The System page remains available in the bottom navigation. V1 files and V1
  behavior are unchanged.

## Local design selection

`components/camper/CamperDesignSettings.qml` owns the integer setting
`designVersion` in the local Qt Settings category `CamperControl`.

- Valid values are `1` (productive classic CamperControl) and `2` (Transit
  Horizon).
- A new installation, a missing setting, or an invalid value selects V2.
- An explicitly stored V1 remains V1.
- The setting is local to each gui-v2 frontend. It is not synchronized between
  GX, Remote Console/WASM, Ford SYNC, or Node-RED.
- The selector is available both on the Camper System page and at the top of
  the preserved Victron Settings tree under `CamperControl`.
- Selection is applied immediately and returns to the selected design's Home.

## Shells and preserved functionality

`pages/camper/CamperShell.qml` retains the existing V1 pages and hosts the V2
shell alongside them. V1 files are not replaced. V2 is implemented by
`pages/camper/v2/CamperV2Shell.qml` with its own Home, Light, Climate, Energy,
Water, and System pages, header, and six-item navigation.

Both shells receive the same `CamperBackendAdapter`. The existing Victron
application, Settings pages, dialogs, notifications, screen handling, D-Bus
backend, and WASM MQTT backend remain in place. `Victron öffnen` and Victron
Settings continue to use the pre-existing gui-v2 navigation contract.

## Data and command boundary

No D-Bus path, MQTT topic, Node-RED endpoint, or control target was added for
this design release.

- Battery SOC, battery voltage, and aggregate solar power continue through
  `CamperVictronAdapter` and the existing `Global.system` model. GX therefore
  uses gui-v2's D-Bus backend and WASM uses gui-v2's MQTT backend.
- Custom state and commands continue through `CamperNodeRedAdapter` and the
  existing `/camper/api/v2/state` and `/camper/api/v2/command` contracts.
  Quick-access configuration remains a `settings/patch` command on that
  command endpoint.
- Missing values render as dashes. Unavailable controls are disabled.
- Water contains only freshwater and pump; no wastewater, pressure, or flow
  sensor is implied.
- Energy exposes the five existing logical consumers plus 230 V. Technical
  channel/source labels are not shown to the user.
- The Orion card is a whole-card switch only when `online === true`; otherwise
  it is disabled and renders dashes.
- The light page uses the six existing light IDs plus STAR-Power output channel
  3 for high beam. High-beam visuals combine `manualOn` and `vehicleOn`, while
  the command always toggles `manualOn`. The control is enabled only when
  `outputOnline === true`.
- Solar detail lists every charger supplied by the adapter and INDEVOLT. No
  demonstration charger is created by the page.

## V2 source and assets

The binding design source is
`campercontrol-release/design/v2-prototype/campercontrol-v2-transit-horizon.html`.
The QML port uses the prototype's compact 50 px header, 64 px navigation,
tokens, line-icon language, card geometry, clickable vehicle light overlays,
small labelled quick-access/DC icon tiles, source icon tiles, optional Autoterm
runtime, and combined 12 V/230 V energy layout.

Registered assets:

- `images/camper_transit_line_dark.png`
- `images/camper_transit_line_light.png`
- `images/camper_v2_vehicle_left.png`
- `images/camper_v2_vehicle_right.png`

The Transit line assets and embedded vehicle renders were copied from the
binding prototype rather than recreated.

## Local verification

Use the Qt 6.8.3 preview harness before packaging:

```powershell
$env:PYTHONPATH = (Resolve-Path '.deps\pyside6').Path
$python = (Get-Command python).Source
& $python tools\camper-preview\smoke_test.py
```

The render harness accepts output path, page, design version, Energy pane, and
optional day mode (`0` night, `1` day):

```powershell
& $python tools\camper-preview\render.py outputs\v2-home.png 0 2 0
& $python tools\camper-preview\render.py outputs\v2-energy-power.png 3 2 0
& $python tools\camper-preview\render.py outputs\v2-energy-sources.png 3 2 1
& $python tools\camper-preview\render.py outputs\v2-energy-solar.png 3 2 2
& $python tools\camper-preview\render.py outputs\v2-home-photo-fix-night.png 0 2 0 0
& $python tools\camper-preview\render.py outputs\v2-home-photo-fix-day.png 0 2 0 1
```

Official packaging remains:

```bash
./scripts/build-gx.sh --preserve
./scripts/build-wasm.sh --preserve
```

Neither command deploys to a Cerbo unless a host argument is explicitly added.

## Verified build stages

Both official scripts completed with exit code 0 on 2026-08-19 from the same
source tree.

- GX staging directory: `build-gx_files_to_copy/` (938 files, `13742240`
  bytes)
- GX binary: `build-gx_files_to_copy/venus-gui-v2`
- GX binary size: `10248620` bytes
- GX binary SHA-256:
  `5F92ED798D823BDE6498B2D6A23FF1190E0B07C304B4A0DEE1139F94CF689A2C`
- WASM staging directory: `build-wasm_files_to_copy/wasm/` (21 files,
  `17461601` bytes)
- WASM JavaScript SHA-256:
  `D25B0C8720C70B85FD51A3576CE036BE09425100C7019487975B5249B1D3E788`
- Staged `venus-gui-v2.wasm.gz` size: `16983706` bytes
- Staged `venus-gui-v2.wasm.gz` SHA-256:
  `1034AFD3D10F10E11A01DC82D2EDCAE1CA9BC0882A424B345F1DB29EA42B3EC1`
- Uncompressed WASM size recorded by the official build: `37317445` bytes
- Uncompressed WASM SHA-256 recorded by the official build:
  `42AE88E350BCD9FDEA5385CD1F506371030D060AA249499A9974CC78B931FE77`

The build stages are intentionally ignored by Git. They are release/deployment
inputs, not source files.

Prototype asset checksums:

| Asset | SHA-256 |
| --- | --- |
| `camper_transit_line_dark.png` | `F54F528AF869C6F3CC2DEC1A7B90AE730B6DF1D431F67AEB55328BA1FD6AA605` |
| `camper_transit_line_light.png` | `2B67063319CDB66767CCA2229996B9E6161A849EDDD6B0941FB5F984CF1A594F` |
| `camper_v2_vehicle_left.png` | `FEA43248C03588CB57D65DA00788F429022B819C8E440731EA02136B33123DFE` |
| `camper_v2_vehicle_right.png` | `3439E784E263C051C5B229A37BE863D6EF3295887315F76969A48F516337AACA` |
