# WhatsApp Gateway einrichten

## 1. n8n-Variable anlegen

In n8n die Projekt- oder Instanzeinstellungen öffnen und unter **Variables** anlegen:

- Key: `META_VERIFY_TOKEN`
- Value: ein selbst gewählter langer Zufallswert

Der Workflow liest ihn über `$vars.META_VERIFY_TOKEN`. Diesen Wert später bei Meta exakt gleich als Verify Token eintragen.

## 2. Workflow importieren

In n8n **Workflows → Import from File** öffnen und `n8n/workflows/whatsapp-gateway.json` auswählen.

## 3. Workflow veröffentlichen

Den importierten Workflow speichern und über **Publish** aktivieren. Erst danach die Production-Webhook-URL verwenden.

Der Pfad lautet:

```
/webhook/schmidt-tuning/whatsapp
```

## 4. Meta konfigurieren

In Meta unter **WhatsApp → Configuration → Webhook**:

- Callback URL: Production-URL des n8n-Webhooks
- Verify Token: derselbe Wert wie die n8n-Variable `META_VERIFY_TOKEN`
- Webhook-Feld abonnieren: `messages`

## 5. Test

Eine Nachricht an die registrierte WhatsApp-Nummer senden. In n8n muss eine erfolgreiche Ausführung mit dem normalisierten Ereignis erscheinen.

## Noch nicht enthalten

Dieser erste Workflow speichert noch keine Kundendaten dauerhaft und sendet keine automatische Antwort. Das folgt erst nach erfolgreichem Empfangstest.
