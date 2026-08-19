# Camper gui-v2 port baseline

This repository is the custom CamperControl fork of Victron Energy `gui-v2`.

## Victron base

- Upstream: `https://github.com/victronenergy/gui-v2.git`
- Upstream remote name: `upstream`
- Base tag: `v1.3.14`
- Base commit: `c8f5a14353d1c6dc7554cbc8bf5d167af8fd00d7`
- Target firmware: Venus OS `v3.80~39`
- Target firmware build: `20260716174100`
- Installed native package: `gui-v2 1.3.14-r0`
- Installed WASM package: `gui-v2-webassembly 1.3.14-r0`
- Target GX SDK: `venus-scarthgap-x86_64-arm-cortexa8hf-neon-toolchain-v3.80~39.sh`
- Port branch: `camper-v3.80-beta39`

Pinned submodules from the base tag:

- `src/veutil`: `62a05877cf6186396d1f77fc5265e518fc60381b`
- `src/qzxing`: `e3c5d9c49be9f640b1c094b170ecbb417a70ac25`

Read-only verification against the target Cerbo GX (`einstein`) completed before this baseline was committed:

- Native binary SHA-256: `82e3aa86933abdb9c28458fe3f4e004631fb5533e80236139a00ac506d1f2f52`
- Installed WASM SHA-256: `e3068c214f14f3af5722bbba55ecaab4fb4892138b7efac09c02603f1c4af91d`
- Installed uncompressed WASM size: `35853791` bytes
- Installed artifact timestamp: `2026-07-16 17:39:41 UTC`

These package versions map directly to the public `v1.3.14` tag, so a full Cerbo root filesystem extraction is not required for the source baseline. The installed gui-v2 directories should still be backed up before the first deployment.

## Design source

Ford SYNC CamperControl is the visual and interaction source of truth.

- Version: CamperControl v3.9.9
- Source repository baseline: `6385dd85449066f648cd34095d08a2b32b0aa120`
- Source package SHA-256: `B786EE408E8EB78FD8050E9F42FD9DC4F0F4A8A025C06E484E16CE1B822C6CE1`

The port must preserve layout, navigation, typography, spacing, icons, colors, cards, buttons, switches and interaction behavior. It must not be restyled as a standard Victron UI.

## Backend source

`campercontrol-node-red` is the authoritative Node-RED, Dashboard, Cerbo service, build and test repository.

- Master commit supplied for this baseline: `bec1522`
- Flow size: 358 nodes
- Supplied validation result: 1,232 assertions, zero failures

Native Victron data continues to use the existing gui-v2 D-Bus infrastructure on GX and MQTT infrastructure in WASM. Node-RED remains responsible for custom logic and devices which are not represented natively. No new D-Bus service names or paths may be invented without a confirmed backend contract.

## Initial integration boundary

The first prototype will keep `Main.qml`, `ApplicationContent.qml`, the backend, global data models, dialogs, notifications, screen handling and Victron settings intact. The Camper UI will initially be introduced as a full-screen layer inside `pages/MainView.qml`, with explicit access to the original Victron Settings/System UI.

No Camper application code has been added at this baseline commit.
