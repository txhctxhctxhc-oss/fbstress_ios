# MetalStress

Metal GPU-Shader-Demo für iOS – animierte Testmuster (Farbverläufe, Checkerboard, Rauschen, Sinuswellen).

## Bauen (kein Mac nötig)

1. Repo auf GitHub pushen
2. GitHub Actions baut automatisch → **Artifacts** → `MetalStress-unsigned-ipa` herunterladen

## Auf iPhone installieren (ohne Mac, ohne Jailbreak)

### Option A – Sideloadly (empfohlen)
1. [Sideloadly](https://sideloadly.io/) auf Windows installieren
2. iPhone per USB anschließen, iTunes / Apple Devices muss laufen
3. IPA in Sideloadly ziehen → Apple-ID eingeben (kostenlose Developer-ID reicht) → Start
4. iPhone: Einstellungen → Allgemein → VPN & Geräteverwaltung → deiner Apple-ID vertrauen

### Option B – AltStore
1. [AltStore](https://altstore.io/) auf PC installieren und AltServer starten
2. AltStore auf iPhone installieren
3. IPA über AltStore sideloaden

### Option C – TrollStore (iOS 15.x ✓)
Falls das iPhone bereits TrollStore hat:
- IPA direkt über TrollStore installieren → läuft dauerhaft ohne Re-Signing

> **Hinweis:** Das iPhone9,3 (iPhone 7) mit iOS 15.8.x ist mit
> [TrollStore 2](https://github.com/opa334/TrollStore) kompatibel.
