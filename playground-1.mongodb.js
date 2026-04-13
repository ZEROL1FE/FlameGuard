/* global use, db */
// FlameGuard MongoDB Playground
// Test database schema and queries for FlameGuard IoT system

// Switch to your flameguard database
use('flameguard');

// ─── CREATE SAMPLE USERS ──────────────────────────────────────────────────
db.getCollection('users').insertMany([
  {
    email: 'john.doe@example.com',
    name: 'John Doe',
    profilePicture: 'https://example.com/john.jpg',
    provider: 'google',
    providerId: 'google_123456789',
    devices: [], // Will be populated after device creation
    sharedAccess: [],
    createdAt: new Date(),
    lastLogin: new Date()
  },
  {
    email: 'jane.smith@example.com',
    name: 'Jane Smith',
    profilePicture: 'https://example.com/jane.jpg',
    provider: 'google',
    providerId: 'google_987654321',
    devices: [],
    sharedAccess: [],
    createdAt: new Date(),
    lastLogin: new Date()
  }
]);

// ─── CREATE SAMPLE DEVICES ────────────────────────────────────────────────
const user1 = db.getCollection('users').findOne({ email: 'john.doe@example.com' });
const user2 = db.getCollection('users').findOne({ email: 'jane.smith@example.com' });

db.getCollection('devices').insertMany([
  {
    deviceId: 'ESP32_001',
    name: 'Living Room Sensor',
    type: 'multi_sensor',
    owner: user1._id,
    location: 'Living Room',
    isActive: true,
    lastSeen: new Date(),
    sensorData: {
      temperature: 25.5,
      humidity: 60.2,
      flameDetected: false,
      smokeDetected: false,
      batteryLevel: 85
    },
    settings: {
      temperatureThreshold: 50,
      alertEnabled: true,
      autoShutdown: false
    },
    createdAt: new Date()
  },
  {
    deviceId: 'ESP32_002',
    name: 'Kitchen Detector',
    type: 'flame_sensor',
    owner: user1._id,
    location: 'Kitchen',
    isActive: true,
    lastSeen: new Date(),
    sensorData: {
      temperature: 28.0,
      humidity: 45.8,
      flameDetected: false,
      smokeDetected: false,
      batteryLevel: 92
    },
    settings: {
      temperatureThreshold: 45,
      alertEnabled: true,
      autoShutdown: false
    },
    createdAt: new Date()
  },
  {
    deviceId: 'ESP32_003',
    name: 'Bedroom Monitor',
    type: 'smoke_sensor',
    owner: user2._id,
    location: 'Master Bedroom',
    isActive: false, // Simulate offline device
    lastSeen: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
    sensorData: {
      temperature: 22.1,
      humidity: 55.3,
      flameDetected: false,
      smokeDetected: false,
      batteryLevel: 78
    },
    settings: {
      temperatureThreshold: 55,
      alertEnabled: true,
      autoShutdown: true
    },
    createdAt: new Date()
  }
]);

// ─── UPDATE USERS WITH DEVICE REFERENCES ──────────────────────────────────
const device1 = db.getCollection('devices').findOne({ deviceId: 'ESP32_001' });
const device2 = db.getCollection('devices').findOne({ deviceId: 'ESP32_002' });
const device3 = db.getCollection('devices').findOne({ deviceId: 'ESP32_003' });

db.getCollection('users').updateOne(
  { _id: user1._id },
  { $set: { devices: [device1._id, device2._id] } }
);

db.getCollection('users').updateOne(
  { _id: user2._id },
  { $set: { devices: [device3._id] } }
);

// ─── TEST QUERIES ─────────────────────────────────────────────────────────

// Find all active devices
console.log('Active devices:');
db.getCollection('devices').find({ isActive: true }).toArray().forEach(device => {
  console.log(`- ${device.name} (${device.deviceId}) - ${device.location}`);
});

// Find devices with low battery
console.log('\nDevices with low battery (< 80%):');
db.getCollection('devices').find({ 'sensorData.batteryLevel': { $lt: 80 } }).toArray().forEach(device => {
  console.log(`- ${device.name}: ${device.sensorData.batteryLevel}%`);
});

// Find devices that haven't been seen recently (simulate offline detection)
console.log('\nPotentially offline devices (not seen in last hour):');
const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
db.getCollection('devices').find({ lastSeen: { $lt: oneHourAgo } }).toArray().forEach(device => {
  console.log(`- ${device.name}: Last seen ${device.lastSeen}`);
});

// Get user's devices with owner info
console.log('\nJohn Doe\'s devices:');
db.getCollection('devices').aggregate([
  { $match: { owner: user1._id } },
  {
    $lookup: {
      from: 'users',
      localField: 'owner',
      foreignField: '_id',
      as: 'ownerInfo'
    }
  },
  { $unwind: '$ownerInfo' },
  {
    $project: {
      name: 1,
      deviceId: 1,
      location: 1,
      isActive: 1,
      'sensorData.temperature': 1,
      'ownerInfo.name': 1
    }
  }
]).toArray().forEach(device => {
  console.log(`- ${device.name} (${device.deviceId}) in ${device.location}: ${device.sensorData.temperature}°C`);
});

// ─── CLEANUP (uncomment to reset database) ────────────────────────────────
// db.getCollection('users').deleteMany({});
// db.getCollection('devices').deleteMany({});
