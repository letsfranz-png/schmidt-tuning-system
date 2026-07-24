# Schmidt Tuning System

Zentrales System für Kundenanfragen, Fahrzeugdaten und Werkstattabläufe von Schmidt Tuning.

## Aktueller Stand

Phase 1 baut das WhatsApp-Gateway auf:

1. Meta sendet WhatsApp-Webhooks an n8n.
2. n8n bestätigt die Webhook-Verifizierung.
3. Eingehende Ereignisse werden normalisiert und protokolliert.
4. Danach folgen dauerhafte Speicherung, Kunden- und Fahrzeugzuordnung sowie KI-Antworten.

## Repository-Struktur

- `n8n/workflows/` – importierbare n8n-Workflows
- `docs/` – Einrichtung und technische Entscheidungen
- `.env.example` – benötigte Variablen ohne echte Zugangsdaten

## Datenschutz und Sicherheit

Keine Tokens, App-Secrets, Telefonnummern oder Kundendaten committen. Zugangsdaten werden in n8n beziehungsweise als Umgebungsvariablen hinterlegt.

## Geplanter Funktionsumfang

Dauerhaft gespeichert werden Kunden-, Fahrzeug-, Software-, Diagnose-, Termin-, Datei-, Rechnungs- und Prüfstandsdaten. Allgemeine Wartungsdaten gehören nicht zum System; einzige Ausnahme sind Ölwechsel inklusive späterer Kundenerinnerung.
