# Build und Deployment – CamperControl gui-v2 (GX und WASM)

Diese Anleitung gilt für den V2-only-Buildstand
`9e5a5282162b590b1e446958d97bf268915b3c23`. Aus denselben QML-Quellen
entstehen zwei getrennte Ziele:

- die native ARM-GX-Oberfläche unter `/opt/victronenergy/gui-v2`;
- die WebAssembly-Remote-Console unter `/var/www/venus/gui-v2`.

Der Cerbo bleibt Eigentümer von Zustand, Cache, Wetter, Gezeiten,
Schutzlogik, Persistenz und Hardwarebefehlen. GX liest den zentralen Vertrag
über D-Bus, WASM über Victrons MQTT-Transport. Kein WASM-Browser pollt
Node-RED direkt und kein GUI-Client berechnet eigene Wetter- oder Ersatzwerte.

GX und WASM wurden aus demselben Commit gebaut. Beide Bäume werden über ihre
realen Datei-/Bytezahlen und Innenhashes identifiziert; ältere lokale Bäume
oder Hashes eines anderen Commits sind keine Releasewerte.

## Quell-, Toolchain- und Zielpins

| Merkmal | Releasewert |
|---|---|
| gui-v2-Buildcommit | `9e5a5282162b590b1e446958d97bf268915b3c23` |
| `src/veutil` | `62a05877cf6186396d1f77fc5265e518fc60381b` |
| `src/qzxing` | `e3c5d9c49be9f640b1c094b170ecbb417a70ac25` |
| Venus OS | `v3.80~39` |
| Venus-Build | `20260716174100` |
| Zielarchitektur | `armv7l` |
| Venus-gui-v2-Basispaket | `1.3.14-r0` |
| CMake-Projektversion | `1.3.14` |
| GX-SDK | `venus-scarthgap-x86_64-arm-cortexa8hf-neon-toolchain-v3.80~39.sh` |
| Qt | `6.8.3` |
| Emscripten | `3.1.56` |
| WASM-Installationswurzel | `/opt/venus/build-gx-hostedtoolcache` |

Die Firmware-/Architekturwerte sind eine Kompatibilitätsgrenze, keine bloße
Dokumentation. Ein Build oder Deployment auf eine abweichende Venus-Version
benötigt eine neue Portierungsprüfung und ein neues Manifest.
Die unveränderte Victron-Projektversion ist keine CamperControl-Releasekennung;
installierte CamperControl-Stände werden deshalb über Quellcommit und
Artefakthashes identifiziert.

## Festgeschriebener GX-Build

| Merkmal | Releasewert |
|---|---:|
| Stage | `build-gx_files_to_copy/` |
| Dateien | `924` |
| Stage-Nutzbytes | `13572678` Byte |
| Binary | `build-gx_files_to_copy/venus-gui-v2` |
| Binary-Größe | `10162764` Byte |
| Binary-SHA-256 | `0CAC164966355C6335AF3416A0615D5D6180261F5139B6EB774DA75F02F27D19` |
| Übergabearchiv-Größe | `7154486` Byte |
| Übergabearchiv-SHA-256 | `98D24996956224206F1243289765EA45AFF4A1FEFBFBA3330EFFF78C70A16FCE` |

Diese Werte gelten ausschließlich für Buildcommit `9e5a5282...` und die oben
gepinnten Submodule beziehungsweise Toolchain.

## Festgeschriebener WASM-Build

| Merkmal | Releasewert |
|---|---:|
| Stage | `build-wasm_files_to_copy/wasm/` |
| Dateien | `21` |
| Stage-Nutzbytes | `17307429` Byte |
| JavaScript-Größe | `303827` Byte |
| JavaScript-SHA-256 | `AA92A27CF66DFD691292ED23F9A890C41FE1B574D8C0F10ECFF3E3A91CFB41E7` |
| komprimierte WASM-Größe | `16830458` Byte |
| komprimierte WASM-SHA-256 | `5E584AAE4F0ADEBD4ACB0A175A3E4F96AD9BAFE7E7472B2EDF5258DC0702B584` |
| unkomprimierte WASM-Größe | `36950599` Byte |
| unkomprimierte WASM-SHA-256 | `44FBA9536032FCF6190732A8EF6671792BEAFD8DAB9E587609311B43A9CCC457` |
| Übergabearchiv-Größe | `16983095` Byte |
| Übergabearchiv-SHA-256 | `746ED876D3156C05A3760FC4731DBCAB4480614EC59194ECBB4A96E124DF3E96` |

## Voraussetzungen

### Gemeinsame Buildumgebung

- x86_64 Ubuntu 24.04, nativ oder unter WSL;
- normaler Benutzer, nicht `root`; die Setup-Skripte verwenden `sudo` nur für
  Systeminstallationen;
- Git mit Netzwerkzugriff für Submodule und das einmalige Toolchain-Setup;
- CMake 3.24 oder neuer, Ninja/GNU-Buildwerkzeuge und C++20;
- ausreichend Platz unter `/opt/venus`, `/tmp` und im Repository;
- Python 3 mit PySide6 6.8.3 für die Camper-Verträge und den echten
  800×480-Smoke-Test.

Die Skripte akzeptieren formal Ubuntu 22.04 oder neuer. Der aktuelle
WASM-Requirements-Weg adressiert beim `aqtinstall`-Patch jedoch ausdrücklich
`python3.12/site-packages`; für einen reproduzierbaren Release ist deshalb
Ubuntu 24.04 x86_64 der festgelegte Host.

Die Setup-Skripte benötigen Netzwerkzugriff, installieren Pakete und verändern
`/opt/venus`. Sie gehören nicht in einen Offline-Build und werden nicht auf dem
Cerbo ausgeführt.

## Sauberen Quellstand vorbereiten

Für einen Releasebuild einen eigenen abgetrennten Worktree verwenden. Im
ursprünglichen Repository:

```sh
GUI_COMMIT=9e5a5282162b590b1e446958d97bf268915b3c23
RELEASE_SRC=../camper-gui-v2-9e5a5282-release
git worktree add --detach "$RELEASE_SRC" "$GUI_COMMIT"
cd "$RELEASE_SRC"
git submodule sync --recursive
git submodule update --init --recursive
test "$(git rev-parse HEAD)" = "$GUI_COMMIT"
test -z "$(git status --porcelain)"
git submodule status --recursive
```

Die Submodule müssen ohne `+`, `-` oder `U` genau die oben festgeschriebenen
Gitlinks anzeigen. Die offiziellen Buildskripte aktualisieren Submodule, aber
checken keinen Branch aus, mergen nichts und prüfen keinen sauberen Worktree.

## Einmalige Toolchain-Installation

Aus dem sauberen Repository-Stamm:

```sh
./scripts/build-gx-install-requirements.sh
test -f /opt/venus/current/environment-setup-cortexa8hf-neon-ve-linux-gnueabi

./scripts/build-wasm-install-requirements.sh
test -x /opt/venus/build-gx-hostedtoolcache/Qt/6.8.3/wasm_singlethread/bin/qt-cmake
test -f /opt/venus/build-gx-hostedtoolcache/emsdk/emsdk_env.sh
test -f /opt/venus/build-gx-hostedtoolcache/Qt/6.8.3/wasm_singlethread/lib/cmake/Qt6Mqtt/Qt6MqttConfig.cmake
```

Die Reihenfolge ist bewusst GX vor WASM. Das GX-Setup setzt
`/opt/venus/current` auf einen SDK-Pfad; nach jeder erneuten Installation ist
die konkrete Environment-Datei erneut zu prüfen. Das Requirements-Skript pinnt
Qt, Emscripten und GX-SDK, aber nicht jedes APT-/Snap-/`aqtinstall`-Paket. Das
Artefaktmanifest mit Innenhashes bleibt deshalb das abschließende Gate.

## Tests vor beiden Builds

### CamperControl-Verträge und 800×480-Smoke-Test

Auf dem Rechner mit PySide6 6.8.3:

```powershell
python -m unittest discover -s tests -p "camper_*_contract.py"
python tools/camper-preview/smoke_test.py
```

Die Suite umfasst sechs Vertragsdateien und 35 Tests. Sie prüft V2-only,
Favoriten/Wetter, Header und Navigation, Ressourcenbegrenzung, Lichtgeometrie,
VRM-Transport, Command-Ursprünge und das echte 800×480-Touchverhalten. Ein
fehlendes oder nicht ladbares PySide6 ist ein Testfehler.

### Upstream-Desktop-CTest

Mit der wie im Workflow `run-unit-tests.yml` vorbereiteten Desktop-Qt-6.8.3-
Umgebung einschließlich QtMQTT:

```sh
export QTDIR=/opt/venus/build-gx-hostedtoolcache/Qt/6.8.3/gcc_64
rm -rf build-desktop-tests
mkdir build-desktop-tests
cd build-desktop-tests
"${QTDIR}/bin/qt-cmake" -DCMAKE_BUILD_TYPE=Release -DGUI_V2_BUILD=OFF ..
cmake --build . --config Release --parallel "$(nproc)"
QT_DEBUG_PLUGINS=1 QT_QPA_PLATFORM=offscreen ctest --rerun-failed --output-on-failure
cd ..
```

Die normalen GX-/WASM-Skripte führen weder diese CTests noch die
CamperControl-Python-Suite automatisch aus. Alle drei Testschritte sind daher
vor dem Artefaktfreeze separat zu protokollieren.

## Native GX-Oberfläche bauen

Der saubere Releasebuild läuft in Ubuntu/WSL ohne Direktupload und ohne
`--preserve`:

```sh
./scripts/build-gx.sh
```

Unter WSL liegt der temporäre CMake-Baum absichtlich in einem
repositoryspezifischen Unterverzeichnis von `/tmp/victronenergy`, um
DrvFs-Zeitstempelfehler zu vermeiden. Der installierbare Baum entsteht
unabhängig davon im Repository:

```text
build-gx_files_to_copy/
build-gx_files_to_copy/venus-gui-v2
```

Das Skript besitzt kein globales `set -e`. Ein Exitcode allein genügt daher
nicht; Stage, Dateien, Größen und Hash müssen ausdrücklich geprüft werden:

```sh
GX_STAGE=build-gx_files_to_copy
GX_BINARY="$GX_STAGE/venus-gui-v2"
GX_HASH=0cac164966355c6335af3416a0615d5d6180261f5139b6eb774da75f02f27d19

test -x "$GX_BINARY"
test "$(find "$GX_STAGE" -type f | wc -l)" -eq 924
test "$(find "$GX_STAGE" -type f -printf '%s\n' | awk '{sum += $1} END {print sum + 0}')" -eq 13572678
test "$(stat -c '%s' "$GX_BINARY")" -eq 10162764
printf '%s  %s\n' "$GX_HASH" "$GX_BINARY" | sha256sum -c -

test -f "$GX_STAGE/Victron/VenusOS/pages/camper/CamperShell.qml"
test -f "$GX_STAGE/Victron/VenusOS/pages/camper/v2/CamperV2Shell.qml"
test -f "$GX_STAGE/Victron/VenusOS/pages/camper/v2/CamperV2FavoritesPanel.qml"
test -f "$GX_STAGE/Victron/VenusOS/pages/camper/v2/CamperV2WeatherPanel.qml"
test -f "$GX_STAGE/Victron/VenusOS/data/camper/CamperWeatherAdapter.qml"
test ! -e "$GX_STAGE/Victron/VenusOS/pages/camper/CamperHome.qml"
test ! -e "$GX_STAGE/Victron/VenusOS/components/camper/CamperDesignSettings.qml"
```

### Deterministisches GX-Übergabearchiv

Das Quellskript erzeugt einen Installationsbaum, kein finales Archiv. Für die
Übergabe an `campercontrol-release` wird der Baum mit normalisierten Metadaten
gepackt:

```sh
set -o pipefail
mkdir -p dist
SOURCE_DATE_EPOCH=$(git show -s --format=%ct 9e5a5282162b590b1e446958d97bf268915b3c23)
tar --sort=name --format=gnu --mtime="@${SOURCE_DATE_EPOCH}" \
  --owner=0 --group=0 --numeric-owner \
  -C build-gx_files_to_copy -cf - . \
  | gzip -n -9 > dist/camper-gui-v2-gx-9e5a5282.tar.gz
gzip -t dist/camper-gui-v2-gx-9e5a5282.tar.gz
sha256sum dist/camper-gui-v2-gx-9e5a5282.tar.gz
```

Der ausgegebene Archivhash wird zusätzlich zum Binaryhash im Release-Manifest
gespeichert. Ein zweiter Lauf in einem neuen Zielpfad muss denselben
Archivhash liefern.

## WebAssembly/Remote Console bauen

Die Buildumgebung muss exakt die Werte aus `scripts/.env` laden:

```text
EMSCRIPTEN=3.1.56
QT_VERSION=6.8.3
OUTPUTDIR=/opt/venus/build-gx-hostedtoolcache
```

Der saubere Build, wiederum ohne Direktupload und ohne `--preserve`:

```sh
./scripts/build-wasm.sh
```

Der installierbare Baum entsteht unter:

```text
build-wasm_files_to_copy/wasm/
build-wasm_files_to_copy/wasm/index.html
build-wasm_files_to_copy/wasm/venus-gui-v2.js
build-wasm_files_to_copy/wasm/venus-gui-v2.wasm.gz
build-wasm_files_to_copy/wasm/venus-gui-v2.wasm.size
build-wasm_files_to_copy/wasm/venus-gui-v2.wasm.sha256
build-wasm_files_to_copy/wasm/qtloader.js
```

Das Skript schreibt die Größe und den SHA-256 des unkomprimierten WASM, erzeugt
`venus-gui-v2.wasm.gz` mit gzip Stufe 9 und entfernt danach die unkomprimierte
Datei aus dem Stage. Innen- und Außenhash sind unterschiedliche Werte und
müssen beide geprüft werden:

```sh
WASM_STAGE=build-wasm_files_to_copy/wasm
test -f "$WASM_STAGE/index.html"
test -f "$WASM_STAGE/venus-gui-v2.js"
test -f "$WASM_STAGE/venus-gui-v2.wasm.gz"
test -f "$WASM_STAGE/venus-gui-v2.wasm.size"
test -f "$WASM_STAGE/venus-gui-v2.wasm.sha256"
test -f "$WASM_STAGE/qtloader.js"
gzip -t "$WASM_STAGE/venus-gui-v2.wasm.gz"

expected_inner=$(awk '{print $1}' "$WASM_STAGE/venus-gui-v2.wasm.sha256")
actual_inner=$(gzip -dc "$WASM_STAGE/venus-gui-v2.wasm.gz" | sha256sum | awk '{print $1}')
actual_size=$(gzip -dc "$WASM_STAGE/venus-gui-v2.wasm.gz" | wc -c | tr -d '[:space:]')
expected_size=$(tr -d '[:space:]' < "$WASM_STAGE/venus-gui-v2.wasm.size")
test "$actual_inner" = "$expected_inner"
test "$actual_size" = "$expected_size"

test "$(find "$WASM_STAGE" -type f | wc -l)" -eq 21
test "$(find "$WASM_STAGE" -type f -printf '%s\n' | awk '{sum += $1} END {print sum + 0}')" -eq 17307429
test "$(stat -c '%s' "$WASM_STAGE/venus-gui-v2.js")" -eq 303827
test "$(stat -c '%s' "$WASM_STAGE/venus-gui-v2.wasm.gz")" -eq 16830458
test "$actual_size" -eq 36950599
printf '%s  %s\n' \
  'aa92a27cf66dfd691292ed23f9a890c41fe1b574d8c0f10ecff3e3a91cfb41e7' \
  "$WASM_STAGE/venus-gui-v2.js" | sha256sum -c -
printf '%s  %s\n' \
  '5e584aae4f0adebd4acb0a175a3e4f96ad9bafe7e7472b2edf5258dc0702b584' \
  "$WASM_STAGE/venus-gui-v2.wasm.gz" | sha256sum -c -
test "$actual_inner" = '44fba9536032fcf6190732a8ef6671792beafd8dab9e587609311b43a9ccc457'

find "$WASM_STAGE" -type f | sort
sha256sum "$WASM_STAGE/venus-gui-v2.js"
sha256sum "$WASM_STAGE/venus-gui-v2.wasm.gz"
```

Zusätzlich müssen Datei-/Bytezahl, JavaScript-Größe und alle drei Hashes exakt
der Tabelle entsprechen. Abweichungen blockieren den Freeze.

### Checksumgeprüftes WASM-Übergabearchiv

`build-wasm.sh` verwendet für den einzelnen gzip-Inhalt nicht `gzip -n`; der
gzip-Header enthält deshalb den Dateizeitstempel. Ein zweiter frischer Build
muss denselben JavaScript- und WASM-Innenhash liefern, sein gzip-Außenhash kann
aber trotz identischem unkomprimiertem Inhalt abweichen. Der oben
festgeschriebene Außenhash identifiziert daher die tatsächlich eingefrorene
Datei. Sie darf nach dem Freeze nicht neu komprimiert oder ersetzt werden.

Der vollständige, bereits geprüfte Stage wird mit normalisierten äußeren
Archivmetadaten gepackt:

```sh
set -o pipefail
mkdir -p dist
SOURCE_DATE_EPOCH=$(git show -s --format=%ct 9e5a5282162b590b1e446958d97bf268915b3c23)
tar --sort=name --format=gnu --mtime="@${SOURCE_DATE_EPOCH}" \
  --owner=0 --group=0 --numeric-owner \
  -C build-wasm_files_to_copy/wasm -cf - . \
  | gzip -n -9 > dist/camper-gui-v2-wasm-9e5a5282.tar.gz
gzip -t dist/camper-gui-v2-wasm-9e5a5282.tar.gz
sha256sum dist/camper-gui-v2-wasm-9e5a5282.tar.gz
```

Archivhash, Datei-/Bytezahl, JavaScript-Hash, WASM-Innenhash und der Hash der
konkret eingefrorenen gzip-Datei gehören gemeinsam in `build-manifest.json`,
`release.json` und `checksums.sha256`. Eine künftig vollständig bitidentische
Neuerzeugung des gzip-Außencontainers erfordert eine Quelländerung auf
`gzip -n`; sie ist nicht Teil dieses dokumentarischen Freeze.

## Kein Direktdeployment aus den Buildskripten

`build-gx.sh` und `build-wasm.sh` besitzen `-H`/`--host`. Diese Option ist kein
sicherer Produktionsweg:

- sie überschreibt den aktiven Baum dateiweise statt atomar;
- alte, im neuen Build nicht mehr vorhandene Dateien können liegen bleiben;
- es gibt kein vollständiges Backup, Firmware-Gate oder Rollback;
- ein fehlgeschlagener GX-Upload kann die GUI gestoppt zurücklassen;
- das Root-Dateisystem wird nicht als vollständige Transaktion behandelt.

Releasebuilds werden daher immer ohne `-H` ausgeführt. Ebenso werden aktive
GUI-Verzeichnisse niemals manuell geleert oder überkopiert.

## Sicherer Upload und Produktionsdeployment

GX und WASM werden ausschließlich als Teil eines vollständig gefrorenen
`campercontrol-release` installiert. Das Release muss beide Artefakte aus
demselben GUI-Commit enthalten und die Reihenfolge einhalten:

1. Cerbo-D-Bus-/Wetterdienst;
2. Node-RED-Flow;
3. GX;
4. WASM;
5. Ford SYNC separat per USB.

Aus dem finalen Releaseverzeichnis in PowerShell:

```powershell
$cerboHost = '172.24.24.1'
$identityFile = "$env:USERPROFILE\.ssh\id_ed25519"
$reportDirectory = Join-Path (Get-Location) 'reports\preapply-gui'

.\tools\verify-release.ps1
.\tools\CamperControl-Maintenance.ps1 `
  -CerboHost $cerboHost `
  -IdentityFile $identityFile `
  -ReportDirectory $reportDirectory
```

Der erste Aufruf ist read-only. Er prüft Firmware, Architektur, Speicher,
laufende Dienste, aktive Hashes, persistente Releasekopie und Backups. Nur
wenn Verifier, Audit und alle WASM-Pins grün sind:

```powershell
.\tools\CamperControl-Maintenance.ps1 `
  -CerboHost $cerboHost `
  -IdentityFile $identityFile `
  -ReportDirectory $reportDirectory `
  -Apply `
  -Confirm
```

Das Werkzeug lädt zunächst nach `/data/campercontrol/incoming`, prüft jede
Checksumme und installiert eine persistente Kopie unter
`/data/campercontrol/releases`. Vor der Aktivierung erzeugt es ein gehashtes
Preapply-Backup. Unbekannte SSH-Hostschlüssel, vorhandene Stages, beschädigte
persistente Releases und Firmwareabweichungen blockieren den Lauf. Passwörter
werden nicht in Befehlen oder Manifesten gespeichert.

### Atomare GX-Aktivierung

Der checksumgeprüfte GX-Stage wird zunächst als eindeutig benannter Kandidat
neben `/opt/victronenergy/gui-v2` kopiert. Nach Datei-, V2-Vertrags-, Größen-
und Binaryhashprüfung stoppt das Werkzeug `/service/start-gui`, benennt den
aktiven Baum in den vom Werkzeug konkret ausgegebenen, releasebezogenen
Pre-Pfad und den Kandidaten zu `gui-v2` um.
Erst wenn der Prozess stabil läuft und der aktive Binaryhash
`07C0AB68...` ist, wird der alte Baum auf `/data/campercontrol/backups`
komprimiert, gehasht und der exakt benannte Rootfs-Pre-Baum entfernt.

### Atomare WASM-Aktivierung

Der WASM-Stage wird neben `/var/www/venus/gui-v2` vorbereitet. Datei-/Bytezahl,
Pflichtdateien, gzip-Integrität sowie die final eingetragenen Innen- und
Außenhashes müssen stimmen. Danach erfolgt derselbe exakte
Kandidat/Pre-Baum-Rename. Der aktive gzip-Hash wird sofort und nach einer
Wartezeit erneut geprüft, bevor der vorherige Baum gehasht archiviert wird.

## Verifikation nach dem Deployment

Read-only vom Buildrechner:

```powershell
$expectedGxHash = '07C0AB68CAB304E13F082DB094ADA2D5A871A386AF81C8FB5A680B612E077DA4'
$expectedWasmHash = '657CA9CA082B309C0204EE3AB91205122A64819EE36FFBB90093F2981E220778'

$gxHash = (ssh -i $identityFile "root@$cerboHost" "sha256sum /opt/victronenergy/gui-v2/venus-gui-v2").Split()[0].ToUpperInvariant()
if ($gxHash -ne $expectedGxHash) { throw "Aktiver GX-Hash falsch: $gxHash" }

$wasmHash = (ssh -i $identityFile "root@$cerboHost" "gzip -t /var/www/venus/gui-v2/venus-gui-v2.wasm.gz && sha256sum /var/www/venus/gui-v2/venus-gui-v2.wasm.gz").Split()[0].ToUpperInvariant()
if ($wasmHash -ne $expectedWasmHash) { throw "Aktiver WASM-Hash falsch: $wasmHash" }

ssh -i $identityFile "root@$cerboHost" "svstat /service/start-gui; pidof venus-gui-v2"
ssh -i $identityFile "root@$cerboHost" "dbus -y com.victronenergy.campercontrol /Status/ApiConnected GetValue"
ssh -i $identityFile "root@$cerboHost" "dbus -y com.victronenergy.campercontrol /State/Weather GetValue"
```

Danach werden GX Touch, lokale Remote Console und VRM/VRM Beta getrennt
abgenommen:

- V2 füllt 800×480 ohne schwarze Reststreifen;
- `System` öffnet weiterhin die originale Victron-Konfiguration;
- Favoriten links und Wetter rechts teilen den exklusiven Overlay-Host;
- DWD-/BSH-Daten, Tidekurve und Fehlwerte entsprechen dem Cerbo-Snapshot;
- Licht-Hotspots, Dimmer, Orion, INDEVOLT/Shelly, Klima und Wasser zeigen reale
  Rückmeldungen;
- Rückkehr-/Schließen-Funktion arbeitet auf GX und Remote Console;
- Remote-Monitor bleibt read-only;
- direkte und in Szenen enthaltene Remote-Starlink-Aus-Befehle werden zentral
  atomar abgelehnt, lokale Bedienung bleibt möglich;
- CPU, RAM, Root-/Data-Speicher, Logs und Node-RED-Kontext wachsen im
  Beobachtungszeitraum nicht ungebremst.

## Rollback

Schlägt während der Aktivierung ein Prozess-, Datei- oder Hashcheck fehl,
stoppt das jeweilige Deployskript, verschiebt den fehlgeschlagenen Kandidaten
auf seinen exakt benannten Fehlerpfad und benennt den unmittelbar vorherigen
Pre-Baum wieder zum aktiven Baum. GX wird anschließend neu gestartet. Es wird
kein Elternverzeichnis und kein Wildcardpfad gelöscht.

Ein bewusstes Rollback nach bereits erfolgreichem Deployment erfolgt durch
erneutes Anwenden des vorherigen, gefrorenen und checksumgeprüften
Gesamtreleases. Nach bewusster Navigation in dessen konkretes Releaseverzeichnis:

```powershell
.\tools\verify-release.ps1
.\tools\CamperControl-Maintenance.ps1 `
  -CerboHost $cerboHost `
  -IdentityFile $identityFile `
  -ReportDirectory (Join-Path (Get-Location) 'reports\rollback') `
  -Apply `
  -Confirm
```

Die gehashten Archive unter `/data/campercontrol/backups` werden nur mit ihrem
vollständigen, vom Deployskript ausgegebenen Namen und nach Inhaltsprüfung
verwendet. Direktes Löschen von `/opt/victronenergy/gui-v2`,
`/var/www/venus/gui-v2`, `/opt/victronenergy`, `/var/www/venus` oder `/data`
ist kein Rollback.

## Venus-Firmware-Update

Ein Firmwareupdate kann beide aktiven GUI-Bäume ersetzen. Vor dem Update
müssen die checksumgeprüfte persistente Releasekopie und mindestens ein
gültiges Preapply-Backup auf `/data` liegen. Danach:

1. neuen read-only Audit ausführen;
2. Venus-Version, Build und Architektur gegen die Matrix prüfen;
3. nur bei exakter Kompatibilität das gefrorene Gesamtrelease erneut anwenden;
4. Dienst, Node-RED, GX und WASM in dieser Reihenfolge verifizieren;
5. SYNC erst danach erneut Ende-zu-Ende abnehmen.

Es gibt keinen automatischen Checkout, Merge oder Port auf eine unbekannte
Firmware und keinen Build auf dem Cerbo.
