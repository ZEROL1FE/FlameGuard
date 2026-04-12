# FlameGuard IoT System Setup Guide

This guide will help you set up the complete FlameGuard system with database connectivity and ESP32 device communication.

## 🏗️ System Architecture

```
Flutter App ↔️ Render API ↔️ MongoDB Atlas
     ↓
ESP32 Devices ↔️ MQTT Broker ↔️ Flutter App
```

## 📋 Prerequisites

- Flutter development environment
- MongoDB Atlas account (free tier)
- Render account (free tier)
- Arduino IDE with ESP32 support
- MQTT broker (free options: HiveMQ Cloud, Mosquitto, or EMQX)

## 1. 🗄️ Database Setup (MongoDB Atlas)

### Create MongoDB Atlas Cluster

1. Go to [mongodb.com/atlas](https://mongodb.com/atlas)
2. Create free account → Create cluster (M0 Sandbox)
3. Create database user with read/write permissions
4. Add your IP address to whitelist (or 0.0.0.0/0 for development)
5. Get connection string: `mongodb+srv://username:password@cluster.mongodb.net/flameguard`

### Database Schema

```javascript
// Users collection
{
  _id: ObjectId,
  email: String,
  name: String,
  password: String, // hashed
  provider: String, // 'google', 'facebook', 'apple', 'email'
  providerId: String,
  createdAt: Date
}

// Devices collection
{
  _id: ObjectId,
  userId: ObjectId,
  deviceId: String, // ESP32 unique ID
  name: String,
  type: String, // 'fire_detector', 'smoke_sensor', etc.
  zone: String, // room/area
  icon: String,
  wattage: Number,
  voltage: Number,
  current: Number,
  temperature: Number,
  active: Boolean,
  risk: String,
  riskScore: Number,
  autoCutoff: Boolean,
  threshold: String,
  sharedUsers: [ObjectId],
  createdAt: Date
}

// AccessShares collection
{
  _id: ObjectId,
  deviceId: ObjectId,
  sharedWithUserId: ObjectId,
  permissions: [String],
  createdAt: Date
}
```

## 2. 🚀 Backend Setup (Render)

### Create Render Web Service

1. Go to [render.com](https://render.com)
2. Create new Web Service from Git repository
3. Connect your GitHub repo with the backend code
4. Set environment variables:
   ```
   MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/flameguard
   JWT_SECRET=your-super-secret-jwt-key
   MQTT_BROKER=your-mqtt-broker.com
   MQTT_USERNAME=your-mqtt-username
   MQTT_PASSWORD=your-mqtt-password
   GOOGLE_CLIENT_ID=your-google-oauth-client-id
   FACEBOOK_APP_ID=your-facebook-app-id
   APPLE_CLIENT_ID=your-apple-client-id
   ```

### Sample Backend Structure (Node.js/Express)

```javascript
// server.js
const express = require('express');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const mqtt = require('mqtt');

const app = express();
app.use(express.json());

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI);

// MQTT Client
const mqttClient = mqtt.connect(process.env.MQTT_BROKER, {
  username: process.env.MQTT_USERNAME,
  password: process.env.MQTT_PASSWORD
});

// Auth routes
app.post('/api/auth/google-login', async (req, res) => {
  // Verify Google token and create/login user
});

app.post('/api/auth/facebook-login', async (req, res) => {
  // Verify Facebook token and create/login user
});

app.post('/api/auth/apple-login', async (req, res) => {
  // Verify Apple credentials and create/login user
});

// Device routes
app.get('/api/devices', authenticateToken, async (req, res) => {
  // Get user's devices from MongoDB
});

app.post('/api/devices', authenticateToken, async (req, res) => {
  // Add new device to MongoDB
});

// ESP32 command routes
app.post('/api/devices/:deviceId/command', authenticateToken, async (req, res) => {
  // Send command to ESP32 via MQTT
  const { command, params } = req.body;
  mqttClient.publish(`flameguard/devices/${req.params.deviceId}/commands`, JSON.stringify({
    command,
    params,
    timestamp: new Date().toISOString()
  }));
  res.json({ success: true });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
```

## 3. 📱 Mobile App Configuration

### Update API Configuration

In `lib/config/app_config.dart`, update:

```dart
class ProdConfig extends Config {
  @override
  static const String apiBaseUrl = 'https://your-render-app.onrender.com/api';
  @override
  static const String mqttBroker = 'your-mqtt-broker.com';
  // ... other settings
}
```

### OAuth Setup

#### Google Sign-In
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create OAuth 2.0 credentials
3. Add authorized redirect URIs for Android/iOS
4. Update `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`

#### Facebook Login
1. Go to [Facebook Developers](https://developers.facebook.com)
2. Create Facebook App
3. Enable Facebook Login
4. Add app IDs to Android/iOS manifests

#### Apple Sign-In
1. Go to [Apple Developer](https://developer.apple.com)
2. Create App ID with Sign In with Apple capability
3. Configure in Xcode

## 4. 🌐 MQTT Broker Setup

### Free MQTT Options

#### Option 1: HiveMQ Cloud (Recommended)
1. Go to [hivemq.com/cloud](https://hivemq.com/cloud)
2. Create free account (1000 messages/day)
3. Get broker URL, username, password
4. Update ESP32 firmware and app config

#### Option 2: Self-hosted Mosquitto
```bash
# Install Mosquitto
sudo apt install mosquitto mosquitto-clients

# Configure authentication
sudo nano /etc/mosquitto/mosquitto.conf
# Add:
# listener 1883
# allow_anonymous false
# password_file /etc/mosquitto/passwd

# Create password file
sudo mosquitto_passwd -c /etc/mosquitto/passwd username

# Restart service
sudo systemctl restart mosquitto
```

## 5. 🔌 ESP32 Setup

### Hardware Requirements

- ESP32 development board
- MCP9808 temperature sensor (I2C)
- Optional: DHT11/DHT22 humidity sensor
- Optional: Relay module for emergency response
- Power supply (5V/3.3V)

### Wiring Diagram

```
ESP32        MCP9808       DHT11        Relay
3.3V      →  VCC        →  VCC       →  VCC
GND       →  GND        →  GND       →  GND
GPIO21    →  SDA        →  DATA
GPIO22    →  SCL
GPIO12                   →             →  IN (relay control)
```

### Sensor Details

**MCP9808 Temperature Sensor:**
- I2C address: 0x18-0x1F (auto-detected)
- Range: -40°C to +125°C
- Accuracy: ±0.5°C
- Used for fire detection via temperature thresholds

**Optional DHT Sensor:**
- GPIO4 for humidity monitoring
- Provides additional environmental data

**Relay Module:**
- GPIO12 for control
- Can shut down power in emergency situations

### Upload Firmware

1. Open `esp32_firmware/flameguard_esp32.ino` in Arduino IDE
2. Update WiFi and MQTT credentials
3. Select ESP32 board and port
4. Upload firmware

### Device Registration

1. Power on ESP32 (it will connect to WiFi/MQTT)
2. In the app, add a new device
3. Use the ESP32's `DEVICE_ID` as the device identifier

## 6. 🧪 Testing

### Test Authentication
1. Try Google/Facebook/Apple login
2. Verify user creation in MongoDB

### Test Device Communication
1. Add device in app
2. Toggle device power
3. Check ESP32 serial output
4. Verify MQTT messages

### Test Sensors
1. Heat up temperature sensor (use warm water or hair dryer)
2. Check for temperature alerts in app (warning at 45°C, critical at 60°C)
3. Verify sensor data appears in device details
4. Test relay activation during critical alerts

## 7. 🚀 Deployment

### Environment Variables

Create `.env` files for different environments:

```bash
# .env.production
API_BASE_URL=https://your-render-app.onrender.com/api
MQTT_BROKER=your-mqtt-broker.com
MQTT_USERNAME=your-username
MQTT_PASSWORD=your-password
```

### Build Commands

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web (optional)
flutter build web --release
```

## 🔧 Troubleshooting

### Common Issues

1. **ESP32 not connecting to MQTT**
   - Check WiFi credentials
   - Verify MQTT broker URL/port
   - Check firewall settings

2. **Authentication failing**
   - Verify OAuth client IDs
   - Check backend JWT secret
   - Ensure MongoDB connection

3. **Device commands not working**
   - Check MQTT topic names
   - Verify device ID matching
   - Check ESP32 serial output

### Debug Tools

- **MQTT Explorer**: Test MQTT connections
- **MongoDB Compass**: View database data
- **Flutter DevTools**: Debug app state
- **ESP32 Serial Monitor**: Debug device firmware

## 📞 Support

For issues:
1. Check the troubleshooting section
2. Review ESP32 serial output
3. Check Render logs
4. Verify MongoDB Atlas metrics

The system is now ready for production use! 🎉</content>
<parameter name="filePath">c:\Windows D stuff\Cedric\Coding stuff\college\Flameguard\SETUP_GUIDE.md