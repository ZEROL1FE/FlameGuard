const express = require('express');
const jwt = require('jsonwebtoken');
const Device = require('../models/Device');
const User = require('../models/User');
const SensorHistory = require('../models/SensorHistory');

const router = express.Router();

const userCanAccessDevice = (device, userId) => {
  if (device.owner.toString() === userId) return true;
  return device.sharedAccess.some(
    (entry) => entry.user && entry.user.toString() === userId
  );
};

const userCanManageAccess = (device, userId) => {
  if (device.owner.toString() === userId) return true;
  const permission = sharedPermissionForUser(device, userId);
  return permission === 'manage';
};

const sharedPermissionForUser = (device, userId) => {
  const entry = device.sharedAccess.find(
    (item) => item.user && item.user.toString() === userId
  );
  return entry ? entry.permission : null;
};

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
      $or: [{ owner: req.user.userId }, { 'sharedAccess.user': req.user.userId }],
    })
      .populate('owner', 'name email')
      .populate('sharedAccess.user', 'name email');

    res.json({
      success: true,
      devices: devices.map((device) => ({
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
        isOwner: device.owner._id.toString() === req.user.userId,
        accessPermission:
          device.owner._id.toString() === req.user.userId
            ? 'owner'
            : sharedPermissionForUser(device, req.user.userId) || 'view',
        sharedUsers: device.sharedAccess.map((entry) => ({
          id: entry.user?._id?.toString() || '',
          name: entry.user?.name || '',
          email: entry.user?.email || '',
          permission: entry.permission,
        })),
      })),
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

    const device = await Device.findOne({ deviceId: req.params.deviceId });

    if (!device || !userCanAccessDevice(device, req.user.userId)) {
      return res.status(404).json({ error: 'Device not found' });
    }

    const permission = sharedPermissionForUser(device, req.user.userId);
    if (
      device.owner.toString() !== req.user.userId &&
      permission !== 'control'
    ) {
      return res
        .status(403)
        .json({ error: 'No control permission for this device' });
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

// ─── SHARE DEVICE ACCESS ────────────────────────────────────────────────────
router.post('/:deviceId/share', authenticateToken, async (req, res) => {
  try {
    const { email, permissions, permission: directPermission } = req.body;
    const requestedPermission =
      directPermission ||
      (Array.isArray(permissions) && permissions.includes('manage')
        ? 'manage'
        : Array.isArray(permissions) && permissions.includes('control')
        ? 'control'
        : 'view');
    const permission = ['view', 'control', 'manage'].includes(
      requestedPermission
    )
      ? requestedPermission
      : 'view';

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const device = await Device.findOne({ deviceId: req.params.deviceId });

    if (!device || !userCanManageAccess(device, req.user.userId)) {
      return res.status(404).json({ error: 'Device not found' });
    }
    if (device.owner.toString() !== req.user.userId && permission === 'manage') {
      return res
        .status(403)
        .json({ error: 'Only owner can grant manage permission' });
    }

    const targetUser = await User.findOne({
      email: String(email).trim().toLowerCase(),
    });
    if (!targetUser) {
      return res.status(404).json({ error: 'User not found' });
    }
    if (targetUser._id.toString() === req.user.userId) {
      return res.status(400).json({ error: 'Cannot share device with yourself' });
    }

    const existingIndex = device.sharedAccess.findIndex(
      (entry) => entry.user.toString() === targetUser._id.toString()
    );
    if (existingIndex >= 0) {
      device.sharedAccess[existingIndex].permission = permission;
      device.sharedAccess[existingIndex].sharedAt = new Date();
    } else {
      device.sharedAccess.push({
        user: targetUser._id,
        permission,
      });
    }

    await device.save();

    await User.findByIdAndUpdate(targetUser._id, {
      $addToSet: {
        sharedAccess: {
          deviceId: device._id,
          sharedWith: targetUser._id,
          permissions: permission,
          sharedAt: new Date(),
        },
      },
    });

    return res.json({
      success: true,
      message: `Device shared with ${targetUser.email}`,
      shared: {
        id: targetUser._id.toString(),
        name: targetUser.name,
        email: targetUser.email,
        permission,
      },
    });
  } catch (error) {
    console.error('Share device error:', error);
    return res.status(500).json({ error: 'Failed to share device' });
  }
});

router.get('/:deviceId/shared', authenticateToken, async (req, res) => {
  try {
    const device = await Device.findOne({
      deviceId: req.params.deviceId,
    }).populate('sharedAccess.user', 'name email');

    if (!device || !userCanManageAccess(device, req.user.userId)) {
      return res.status(404).json({ error: 'Device not found' });
    }

    return res.json({
      success: true,
      shared: device.sharedAccess.map((entry) => ({
        id: entry.user?._id?.toString() || '',
        name: entry.user?.name || '',
        email: entry.user?.email || '',
        permission: entry.permission,
        sharedAt: entry.sharedAt,
      })),
    });
  } catch (error) {
    console.error('Get shared users error:', error);
    return res.status(500).json({ error: 'Failed to fetch shared access' });
  }
});

router.delete('/:deviceId/share/:userId', authenticateToken, async (req, res) => {
  try {
    const device = await Device.findOne({ deviceId: req.params.deviceId });
    if (!device || !userCanManageAccess(device, req.user.userId)) {
      return res.status(404).json({ error: 'Device not found' });
    }
    if (device.owner.toString() === req.params.userId) {
      return res.status(403).json({ error: 'Cannot remove device owner' });
    }

    const targetEntry = device.sharedAccess.find(
      (entry) => entry.user.toString() === req.params.userId
    );
    if (!targetEntry) {
      return res.status(404).json({ error: 'Shared user not found' });
    }
    if (
      device.owner.toString() !== req.user.userId &&
      targetEntry.permission === 'manage'
    ) {
      return res
        .status(403)
        .json({ error: 'Only owner can remove manage users' });
    }

    const before = device.sharedAccess.length;
    device.sharedAccess = device.sharedAccess.filter(
      (entry) => entry.user.toString() !== req.params.userId
    );
    await device.save();
    await User.updateOne(
      { _id: req.params.userId },
      { $pull: { sharedAccess: { deviceId: device._id } } }
    );

    return res.json({ success: true, message: 'Access removed' });
  } catch (error) {
    console.error('Remove shared access error:', error);
    return res.status(500).json({ error: 'Failed to remove shared access' });
  }
});

// ─── UPDATE SENSOR DATA (called by ESP32 via MQTT) ────────────────────────
router.post('/:deviceId/sensor-data', async (req, res) => {
  try {
    const {
      temperature,
      voltage,
      current,
      humidity,
      flameDetected,
      smokeDetected,
      batteryLevel,
    } = req.body;

    const device = await Device.findOne({ deviceId: req.params.deviceId });

    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }

    device.sensorData = {
      temperature: temperature ?? device.sensorData.temperature,
      voltage: voltage ?? device.sensorData.voltage,
      current: current ?? device.sensorData.current,
      humidity: humidity ?? device.sensorData.humidity,
      flameDetected: flameDetected ?? device.sensorData.flameDetected,
      smokeDetected: smokeDetected ?? device.sensorData.smokeDetected,
      batteryLevel: batteryLevel ?? device.sensorData.batteryLevel
    };

    device.lastSeen = new Date();
    await device.save();

    await SensorHistory.create({
      device: device._id,
      deviceId: device.deviceId,
      temperature: device.sensorData.temperature,
      humidity: device.sensorData.humidity,
      voltage: device.sensorData.voltage,
      current: device.sensorData.current,
      flameDetected: device.sensorData.flameDetected,
      smokeDetected: device.sensorData.smokeDetected,
      batteryLevel: device.sensorData.batteryLevel,
      recordedAt: new Date(),
    });

    res.json({ success: true, message: 'Sensor data updated' });

  } catch (error) {
    console.error('Update sensor data error:', error);
    res.status(500).json({ error: 'Failed to update sensor data' });
  }
});

router.get('/:deviceId/history', authenticateToken, async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit, 10) || 100, 1000);
    const sinceHours = Math.min(parseInt(req.query.sinceHours, 10) || 24, 24 * 30);
    const since = new Date(Date.now() - sinceHours * 60 * 60 * 1000);

    const device = await Device.findOne({ deviceId: req.params.deviceId });
    if (!device || !userCanAccessDevice(device, req.user.userId)) {
      return res.status(404).json({ error: 'Device not found' });
    }

    const rows = await SensorHistory.find({
      device: device._id,
      recordedAt: { $gte: since },
    })
      .sort({ recordedAt: -1 })
      .limit(limit)
      .lean();

    return res.json({
      success: true,
      history: rows.map((row) => ({
        temperature: row.temperature,
        humidity: row.humidity,
        voltage: row.voltage,
        current: row.current,
        flameDetected: row.flameDetected,
        smokeDetected: row.smokeDetected,
        batteryLevel: row.batteryLevel,
        recordedAt: row.recordedAt,
      })),
    });
  } catch (error) {
    console.error('Get history error:', error);
    return res.status(500).json({ error: 'Failed to fetch device history' });
  }
});

module.exports = router;