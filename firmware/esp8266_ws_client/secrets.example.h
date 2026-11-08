#pragma once
// ---------------------------------------------------------------------------
// Copy this file to `secrets.h` (same folder) and fill in your real values:
//     cp secrets.example.h secrets.h
// `secrets.h` is gitignored — NEVER commit real credentials.
// ---------------------------------------------------------------------------

#define WIFI_SSID     "MyWiFiSSID"
#define WIFI_PASSWORD "MyWiFiPassword"

// Public (Elastic) IP of the EC2 backend running the WebSocket server.
#define WS_HOST       "203.0.113.10"   // EXAMPLE (RFC 5737) — replace with yours
#define WS_PORT       5000
