const express = require('express');
const jwt = require('jsonwebtoken');
const Device = require('../models/Device');
const User = require('../models/User');

const router = express.Router();

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key', (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid token' });
    }
    req.user = user;
    next();
  });
};

// ─── GET USER'S DEVICES ────────────────────────────────────────────────────
router.get('/', authenticateToken, async (req, res) => {
  try {
    const devices = await Device.find({
      $or: [
        { owner: req.user.userId },
        { _id: { $in: req.user.sharedDevices || [] } }
      ]
    }).populate('owner', 'name email');

    res.json({
      success: true,
      devices: devices.map(device => ({
        id: device._id,
        deviceId: device.deviceId,
        name: device.name,
        type: device.type,
        location: device.location,
        isActive: device.isActive,
        lastSeen: device.lastSeen,
        sensorData: device.sensorData,
        settings: device.settings,
        owner: device.owner.name,
        isOwner: device.owner._id.toString() === req.user.userId
      }))
    });

  } catch (error) {
    console.error('Get devices error:', error);
    res.status(500).json({ error: 'Failed to fetch devices' });
  }
});

// ─── ADD NEW DEVICE ────────────────────────────────────────────────────────
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { deviceId, name, type, location } = req.body;

    if (!deviceId || !name) {
      return res.status(400).json({ error: 'Device ID and name are required' });
    }

    // Check if device already exists
    const existingDevice = await Device.findOne({ deviceId });
    if (existingDevice) {
      return res.status(409).json({ error: 'Device already exists' });
    }

    const device = new Device({
      deviceId,
      name,
      type: type || 'multi_sensor',
      location: location || '',
      owner: req.user.userId,
    });

    await device.save();

    // Add to user's devices
    await User.findByIdAndUpdate(req.user.userId, {
      $push: { devices: device._id }
    });

    res.status(201).json({
      success: true,
      device: {
        id: device._id,
        deviceId: device.deviceId,
        name: device.name,
        type: device.type,
        location: device.location,
        isActive: device.isActive,
        sensorData: device.sensorData,
        settings: device.settings
      }
    });

  } catch (error) {
    console.error('Add device error:', error);
    res.status(500).json({ error: 'Failed to add device' });
  }
});

// ─── UPDATE DEVICE ─────────────────────────────────────────────────────────
router.put('/:deviceId', authenticateToken, async (req, res) => {
  try {
    const { name, location, settings } = req.body;

    const device = await Device.findOne({
      deviceId: req.params.deviceId,
      owner: req.user.userId
    });

    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }

    if (name) device.name = name;
    if (location !== undefined) device.location = location;
    if (settings) device.settings = { ...device.settings, ...settings };

    await device.save();

    res.json({
      success: true,
      device: {
        id: device._id,
        deviceId: device.deviceId,
        name: device.name,
        type: device.type,
        location: device.location,
        settings: device.settings
      }
    });

  } catch (error) {
    console.error('Update device error:', error);
    res.status(500).json({ error: 'Failed to update device' });
  }
});

// ─── DELETE DEVICE ─────────────────────────────────────────────────────────
router.delete('/:deviceId', authenticateToken, async (req, res) => {
  try {
    const device = await Device.findOneAndDelete({
      deviceId: req.params.deviceId,
      owner: req.user.userId
    });

    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }

    // Remove from user's devices
    await User.findByIdAndUpdate(req.user.userId, {
      $pull: { devices: device._id }
    });

    res.json({ success: true, message: 'Device deleted' });

  } catch (error) {
    console.error('Delete device error:', error);
    res.status(500).json({ error: 'Failed to delete device' });
  }
});

// ─── SEND COMMAND TO DEVICE ────────────────────────────────────────────────
router.post('/:deviceId/command', authenticateToken, async (req, res) => {
  try {
    const { command, value } = req.body;

    const device = await Device.findOne({
      deviceId: req.params.deviceId,
      $or: [
        { owner: req.user.userId },
        { _id: { $in: req.user.sharedDevices || [] } }
      ]
    });

    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }

    // Here you would send the command via MQTT to the ESP32
    // For now, just update the device status
    if (command === 'power') {
      device.isActive = value;
    } else if (command === 'alert') {
      device.settings.alertEnabled = value;
    }

    await device.save();

    res.json({
      success: true,
      message: `Command ${command} sent to device`,
      device: {
        id: device._id,
        deviceId: device.deviceId,
        isActive: device.isActive,
        settings: device.settings
      }
    });

  } catch (error) {
    console.error('Send command error:', error);
    res.status(500).json({ error: 'Failed to send command' });
  }
});

// ─── UPDATE SENSOR DATA (called by ESP32 via MQTT) ────────────────────────
router.post('/:deviceId/sensor-data', async (req, res) => {
  try {
    const { temperature, humidity, flameDetected, smokeDetected, batteryLevel } = req.body;

    const device = await Device.findOne({ deviceId: req.params.deviceId });

    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }

    device.sensorData = {
      temperature: temperature ?? device.sensorData.temperature,
      humidity: humidity ?? device.sensorData.humidity,
      flameDetected: flameDetected ?? device.sensorData.flameDetected,
      smokeDetected: smokeDetected ?? device.sensorData.smokeDetected,
      batteryLevel: batteryLevel ?? device.sensorData.batteryLevel
    };

    device.lastSeen = new Date();
    await device.save();

    res.json({ success: true, message: 'Sensor data updated' });

  } catch (error) {
    console.error('Update sensor data error:', error);
    res.status(500).json({ error: 'Failed to update sensor data' });
  }
});

module.exports = router;