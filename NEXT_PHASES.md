# CamperControl gui-v2: next phases

## Gate before broad UI work

Phase 2 is complete only after the complete gui-v2 application has been built and
booted, not merely after the standalone Camper Home has rendered.

The target is now fully pinned:

- Cerbo architecture: `armv7l`
- Venus OS: `v3.80~39`, build `20260716174100`
- gui-v2 source/package: `1.3.14`
- Qt: `6.8.3`
- GX SDK: `venus-scarthgap-x86_64-arm-cortexa8hf-neon-toolchain-v3.80~39.sh`
- WASM Emscripten: `3.1.56`

The GX requirements script in this fork uses the exact SDK filename instead of the
moving "latest candidate" entry.

## Phase 2 completion: build and boot gate

### Workstation setup status (2026-08-19)

- `wsl --install` completed successfully through Windows UAC.
- Ubuntu 24.04 was explicitly requested with `wsl --install Ubuntu-24.04`.
- Windows reports that the changes become active only after a system restart.
- No GX SDK, Qt WASM SDK or Emscripten package has been installed yet.
- No build or deployment to the Cerbo has been attempted.

1. Enable WSL and install Ubuntu 24.04 on the Windows development host. This is an
   administrator-level Windows change and may require a reboot.
2. Inside Ubuntu, run `scripts/build-gx-install-requirements.sh`. It installs the
   pinned v3.80~39 ARM SDK under `/opt/venus`.
3. Run `scripts/build-wasm-install-requirements.sh`. It installs Qt 6.8.3,
   Emscripten 3.1.56 and QtMQTT inside the WSL environment.
4. Run `./scripts/build-gx.sh` without `-H`.
5. Run `./scripts/build-wasm.sh` without `-H`.
6. Inspect both staging directories and archive hashes before any deployment.
7. Back up the exact installed native and web gui-v2 directories from the Cerbo.
8. Deploy the GX build manually with a rollback command prepared in advance.
9. Verify on GX Touch 50: startup, touch, real SOC/voltage/solar updates,
   `EINST.`, Victron Settings, dialogs, notifications, screen blanking and Camper
   return.
10. Only after GX passes, deploy the WASM staging directory and verify Remote Console.

Do not use the build scripts' `-H` option at this gate. That option remounts the GX
filesystem read-write and overwrites installed gui-v2 files automatically.

## Phase 3: visual and page port

The owner's current design direction is:

- use the older Dark/Light mockup as the preferred source for the Transit logo,
  line-icon language and overall visual styling;
- retain the current Ford SYNC v3.9.9 application as the behavioral, navigation,
  sizing and reusable-QML source;
- retain the current Node-RED dashboard as the live state/control behavior reference.

Work remains incremental:

1. Freeze a single 800x480 Home reference image for GX Touch 50.
2. Replace the temporary Phase-2 visual primitives with the approved old-mockup
   logo/icon set, without changing the backend adapter.
3. Port and validate one page at a time: Energy, Climate/Heating,
   Lights/Consumers, Water, Vehicle, then System.
4. After every page, render 800x480, run touch tests and compare against its source.

## Phase 4: backend adapters and controls

1. Inventory every displayed value and command against the validated Node-RED master
   and live Cerbo services.
2. Use existing gui-v2 models for native Victron values on both GX and WASM.
3. Add explicit adapters for STAR-Power, Autoterm, MaxxFan, Indevolt, water and
   vehicle integrations only after their real interfaces have been identified.
4. Keep command acknowledgement, timeout and error state separate from presentation.
5. Never introduce a D-Bus path, MQTT topic or HTTP endpoint without source evidence.

## Phase 5: WASM parity

1. Build the same commit with `scripts/build-wasm.sh`.
2. Verify MQTT reconnect, stale-value handling and command acknowledgement.
3. Test exact 800x480 rendering plus larger and differently proportioned browsers.
4. Confirm dialogs, virtual keyboard, notifications and return to Victron Settings.

## Phase 6: validation and release

1. Clean GX and WASM builds from the same tagged commit.
2. No QML runtime warnings or errors.
3. Navigation and all touch targets exercised.
4. Read-only values update; controls round-trip and expose failures.
5. Original Victron Settings/device/diagnostic functions remain reachable.
6. Screenshot comparison against the frozen source references.
7. Produce backup, install, rollback and compatibility documentation for the exact
   Venus OS beta.
