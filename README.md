# MetalStress

`MetalStress` ist eine kleine iOS-Demo-App auf Basis von MetalKit. Sie rendert animierte Testmuster auf Vollbild und blendet ein Overlay mit `FPS`, geschätzter `Frame Time`, `GPU Time` und dem aktuell aktiven Pattern ein.

## Features

- Metal-Rendering über `MTKView`
- Automatischer Pattern-Wechsel alle paar Sekunden
- Overlay mit Laufzeitmetriken
- Unterstützt `Portrait`, `Landscape Left` und `Landscape Right`

## Voraussetzungen

- iPhone oder iPad mit Metal-Unterstützung
- iOS `12.0` oder neuer
- Xcode 15+ für lokale Builds

## Build

Im Repo ist ein GitHub Actions Workflow enthalten:

- Workflow: [`.github/workflows/ios.yml`](/home/lasse/fbstress_ios/.github/workflows/ios.yml)
- Er baut einen unsignierten IPA-Artifact aus dem `Release`-Build
- Artifact-Name: `MetalStress-unsigned-ipa`

### Lokal bauen

1. Projekt in Xcode öffnen: [`MetalStress.xcodeproj`](/home/lasse/fbstress_ios/MetalStress.xcodeproj)
2. Scheme `MetalStress` auswählen
3. Zielgerät oder Generic iOS Device wählen
4. Build ausführen

## Installation auf einem iPhone

Die App kann als unsignierter IPA installiert werden, zum Beispiel mit:

### Sideloadly

1. [Sideloadly](https://sideloadly.io/) auf Windows oder macOS installieren
2. iPhone per USB verbinden
3. IPA in Sideloadly ziehen und mit Apple-ID signieren
4. Auf dem Gerät der Apple-ID unter `Einstellungen > Allgemein > VPN & Geräteverwaltung` vertrauen

### AltStore

1. [AltStore](https://altstore.io/) installieren
2. AltServer auf dem Rechner starten
3. IPA über AltStore auf das Gerät laden

### TrollStore

Falls das Gerät bereits TrollStore unterstützt und installiert hat, kann die IPA direkt dort geöffnet werden.

## Projektstruktur

- [`MetalStress/AppDelegate.m`](/home/lasse/fbstress_ios/MetalStress/AppDelegate.m)
- [`MetalStress/ViewController.m`](/home/lasse/fbstress_ios/MetalStress/ViewController.m)
- [`MetalStress/Renderer.m`](/home/lasse/fbstress_ios/MetalStress/Renderer.m)
- [`MetalStress/Shaders.metal`](/home/lasse/fbstress_ios/MetalStress/Shaders.metal)

