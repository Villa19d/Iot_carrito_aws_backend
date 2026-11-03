#include <ESP8266WiFi.h>
#include <WebSocketsClient.h>
#include "secrets.h"

// ========== CONFIGURACIÓN ==========
const char* ssid = "iPhone de Villa";
const char* password = "Contraseña";
// const char* ssid = "TELECABLE-F2E0";
const char* password = "Contraseña";

// const char* ssid = "WIFI-ALUMNOS";
const char* password = "Contraseña";



const char* ws_host = "50.16.92.186";
const uint16_t ws_port = 5000;

#define IN_2 4
#define IN_1 14
#define IN_4 12
#define IN_3 13

WebSocketsClient webSocket;
unsigned long tiempo_fin = 0;
bool moviendo = false;

void setup() {
  Serial.begin(115200);
  delay(100);
  
  Serial.println("\n=== CARRITO IoT - MOVIMIENTO CONTINUO ===");
  
  pinMode(IN_1, OUTPUT);
  pinMode(IN_2, OUTPUT);
  pinMode(IN_3, OUTPUT);
  pinMode(IN_4, OUTPUT);
  detener();
  
  WiFi.begin(ssid, password);
  Serial.print("Conectando WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ WiFi conectado");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
  
  webSocket.begin(ws_host, ws_port, "/");
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000);
  
  Serial.println("✅ ESP8266 listo - Adelante/Atrás continuos, demás temporizados");
}

void loop() {
  webSocket.loop();
  
  // Solo detiene movimientos temporizados
  if (moviendo && millis() >= tiempo_fin) {
    moviendo = false;
    detener();
    Serial.println("✅ Movimiento temporizado terminado");
  }
}

void webSocketEvent(WStype_t type, uint8_t* payload, size_t length) {
  if (type == WStype_CONNECTED) {
    Serial.println("✅ WebSocket conectado");
  }
  else if (type == WStype_TEXT) {
    String json = String((char*)payload);
    Serial.println("📨 Recibido: " + json);
    
    // Detección de movimiento
    String movimiento = "";
    if (json.indexOf("Atr\\u00e1s") > 0 || json.indexOf("Atrás") > 0 || json.indexOf("Atras") > 0) {
      movimiento = "Atrás";
    }
    else if (json.indexOf("Adelante") > 0) {
      movimiento = "Adelante";
    }
    else if (json.indexOf("Detener") > 0) {
      movimiento = "Detener";
    }
    else if (json.indexOf("Vuelta adelante derecha") > 0) {
      movimiento = "Vuelta adelante derecha";
    }
    else if (json.indexOf("Vuelta adelante izquierda") > 0) {
      movimiento = "Vuelta adelante izquierda";
    }
    else if (json.indexOf("Vuelta atr") > 0 && json.indexOf("derecha") > 0) {
      movimiento = "Vuelta atrás derecha";
    }
    else if (json.indexOf("Vuelta atr") > 0 && json.indexOf("izquierda") > 0) {
      movimiento = "Vuelta atrás izquierda";
    }
    else if (json.indexOf("Giro 90") > 0 && json.indexOf("derecha") > 0) {
      movimiento = "Giro 90° derecha";
    }
    else if (json.indexOf("Giro 90") > 0 && json.indexOf("izquierda") > 0) {
      movimiento = "Giro 90° izquierda";
    }
    else if (json.indexOf("Giro 360") > 0 && json.indexOf("derecha") > 0) {
      movimiento = "Giro 360° derecha";
    }
    else if (json.indexOf("Giro 360") > 0 && json.indexOf("izquierda") > 0) {
      movimiento = "Giro 360° izquierda";
    }
    
    // Extraer PWM y tiempo
    int pwm_izq = 0, pwm_der = 0, tiempo = 2000;
    int idx = json.indexOf("\"mia_pwm\":");
    if (idx > 0) {
      int start = idx + 10;
      int end = json.indexOf(",", start);
      if (end < 0) end = json.indexOf("}", start);
      pwm_izq = json.substring(start, end).toInt();
    }
    idx = json.indexOf("\"mda_pwm\":");
    if (idx > 0) {
      int start = idx + 10;
      int end = json.indexOf(",", start);
      if (end < 0) end = json.indexOf("}", start);
      pwm_der = json.substring(start, end).toInt();
    }
    idx = json.indexOf("\"mi_time\":");
    if (idx > 0) {
      int start = idx + 10;
      int end = json.indexOf(",", start);
      if (end < 0) end = json.indexOf("}", start);
      tiempo = json.substring(start, end).toInt();
      if (tiempo == 0) tiempo = 2000;
    }
    
    if (pwm_izq == 0) pwm_izq = 200;
    if (pwm_der == 0) pwm_der = 200;
    
    Serial.println("═══════════════════════════════");
    Serial.print("🎬 Movimiento: ");
    Serial.println(movimiento);
    Serial.print("   PWM Izq: ");
    Serial.println(pwm_izq);
    Serial.print("   PWM Der: ");
    Serial.println(pwm_der);
    Serial.print("   Tiempo original: ");
    Serial.println(tiempo);
    Serial.println("═══════════════════════════════");
    
    // ========== EJECUCIÓN ==========
    // Siempre detener cualquier movimiento anterior antes de empezar uno nuevo
    detener();
    
    if (movimiento == "Adelante") {
      digitalWrite(IN_3, LOW);
      analogWrite(IN_4, pwm_izq);
      analogWrite(IN_1, pwm_der);
      digitalWrite(IN_2, LOW);
      moviendo = false;
    }
    else if (movimiento == "Atrás") {
      analogWrite(IN_3, pwm_izq);
      digitalWrite(IN_4, LOW);
      digitalWrite(IN_1, LOW);
      analogWrite(IN_2, pwm_der);
      moviendo = false;
    }
    else if (movimiento == "Detener") {
      detener();
    }
    else if (movimiento == "Vuelta adelante derecha") {
      digitalWrite(IN_3, LOW);
      analogWrite(IN_4, pwm_izq * 0.6);
      analogWrite(IN_1, pwm_der);
      digitalWrite(IN_2, LOW);
      programarFin(tiempo);
    }
    else if (movimiento == "Vuelta adelante izquierda") {
      digitalWrite(IN_3, LOW);
      analogWrite(IN_4, pwm_izq);
      analogWrite(IN_1, pwm_der * 0.6);
      digitalWrite(IN_2, LOW);
      programarFin(tiempo);
    }
    else if (movimiento == "Vuelta atrás derecha") {
      analogWrite(IN_3, pwm_izq * 0.6);
      digitalWrite(IN_4, LOW);
      digitalWrite(IN_1, LOW);
      analogWrite(IN_2, pwm_der);
      programarFin(tiempo);
    }
    else if (movimiento == "Vuelta atrás izquierda") {
      analogWrite(IN_3, pwm_izq);
      digitalWrite(IN_4, LOW);
      digitalWrite(IN_1, LOW);
      analogWrite(IN_2, pwm_der * 0.6);
      programarFin(tiempo);
    }
    else if (movimiento == "Giro 90° derecha") {
      // CORRECCIÓN FINAL: usa la misma lógica que Giro 360° derecha (gira a la derecha) y tiempo mitad
      analogWrite(IN_3, pwm_izq);
      digitalWrite(IN_4, LOW);
      digitalWrite(IN_2, LOW);
      analogWrite(IN_1, pwm_der);
      programarFin(tiempo / 2);
    }
    else if (movimiento == "Giro 90° izquierda") {
      // YA FUNCIONA: mantiene su lógica original (gira a la izquierda) con tiempo mitad
      digitalWrite(IN_3, LOW);
      analogWrite(IN_4, pwm_izq);
      analogWrite(IN_2, pwm_der);
      digitalWrite(IN_1, LOW);
      programarFin(tiempo / 2);
    }
    else if (movimiento == "Giro 360° derecha") {
      // YA FUNCIONA: gira a la derecha completa
      analogWrite(IN_3, pwm_izq);
      digitalWrite(IN_4, LOW);
      digitalWrite(IN_2, LOW);
      analogWrite(IN_1, pwm_der);
      programarFin(tiempo / 2);
    }
    else if (movimiento == "Giro 360° izquierda") {
      // YA FUNCIONA: gira a la izquierda completa
      digitalWrite(IN_3, LOW);
      analogWrite(IN_4, pwm_izq);
      analogWrite(IN_2, pwm_der);
      digitalWrite(IN_1, LOW);
      programarFin(tiempo / 2);
    }
    else {
      detener();
    }
  }
}

void programarFin(int duracion) {
  if (duracion > 0) {
    moviendo = true;
    tiempo_fin = millis() + duracion;
    Serial.print("⏱️ Duración real (ms): ");
    Serial.println(duracion);
  } else {
    detener();
  }
}

void detener() {
  digitalWrite(IN_1, LOW);
  digitalWrite(IN_2, LOW);
  digitalWrite(IN_3, LOW);
  digitalWrite(IN_4, LOW);
  moviendo = false;
}