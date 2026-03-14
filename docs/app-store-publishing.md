# App Store Publishing – Plan & Strategie

## Phasen

### Phase 1 – Web-App (aktiv)
Die App läuft als PWA unter hoodini.vercel.app.
Nutzer können sie per Homescreen-Shortcut installieren (iOS Safari / Android Chrome).
Kosten: 0. Ziel: Feedback sammeln, Nutzerbasis aufbauen, Bugs fixen.

### Phase 2 – Google Play (nächster Schritt)
Einmalige Kosten: **25 USD**
Kein Mac nötig. Review meist schnell/automatisch.

**Was zu tun ist:**
1. `flutter_launcher_icons` + `flutter_native_splash` einrichten
2. Bundle ID setzen (z.B. `de.hoodini.app`) in `android/app/build.gradle`
3. Signing Keystore erstellen (`keytool`) + in Gradle eintragen
4. `flutter build appbundle` → `.aab` hochladen
5. Play Console Store-Eintrag ausfüllen (Screenshots, Beschreibung, Datenschutz-URL)
6. Bedingten Image-Picker-Import auf native testen (`image_picker_stub.dart`)

Zeitaufwand: ~1–2 Tage.

### Phase 3 – Apple App Store (später)
Laufende Kosten: **99 USD/Jahr** (Ablauf = App wird entfernt)
Braucht zwingend **macOS + Xcode** — oder einen Cloud-Build-Dienst wie [Codemagic](https://codemagic.io) (~15 USD/Monat oder Freiminuten).

**Zusätzlich zu Phase 2:**
- Bundle ID bei Apple registrieren
- Provisioning Profile + Signing Certificate
- `flutter build ipa`
- App Review (1–3 Tage, manuell)

---

## Kosten-Übersicht

| | Google Play | Apple App Store |
|---|---|---|
| Einmalig | 25 USD | – |
| Jährlich | 0 | 99 USD |
| App kostenlos anbieten | ja | ja |
| Später kostenpflichtig machen | ja, jederzeit | ja, jederzeit |
| Store-Provision auf Käufe | 30% (15% < 1M$) | 30% (15% < 1M$) |

---

## Monetarisierung (später)

Jederzeit möglich:
- App kostenpflichtig machen
- In-App-Käufe (z.B. Premium-Marker-Skins, XP-Boosts)
- Subscription (z.B. Pro-Lobby-Features)
- Freemium: Basis kostenlos, Extras gegen Bezahlung

---

## Bekannte technische Stolperfallen

- `dart:html` im Image-Picker ist **web-only** → nativer Build bricht ohne den
  konditionalen Import (`image_picker_stub.dart`). Muss vor Phase 2 getestet werden.
- Supabase Deep Link / OAuth Redirect braucht native URL-Schemes (`supabase_flutter` Config).
- Datenschutzerklärung (URL) ist für beide Stores Pflicht.

---

## Geplante Features (Backlog)

### Direkte Kamera-Aufnahme beim Marker erstellen
Statt Bild aus der Galerie wählen → direkt Kamera öffnen.

**Web:** `<input type="file" accept="image/*" capture="environment">` — öffnet direkt die Rückkamera.
**Native (Phase 2+):** `image_picker` Plugin mit `ImageSource.camera`.

Implementierung: eigener "Kamera"-Button neben "Galerie"-Button im Create-Sheet.
Aufwand: ~2h, sinnvoll ab Phase 2 (native App).
