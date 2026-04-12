const mongoose = require('mongoose');

const deviceSchema = new mongoose.Schema({
  deviceId: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  type: {
    type: String,
    enum: ['flame_sensor', 'smoke_sensor', 'temperature_sensor', 'multi_sensor'],
    default: 'multi_sensor'
  },
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  location: {
    type: String,
    default: ''
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastSeen: {
    type: Date,
    default: Date.now
  },
  sensorData: {
    temperature: {
      type: Number,
      default: null
    },
    humidity: {
      type: Number,
      default: null
    },
    flameDetected: {
      type: Boolean,
      default: false
    },
    smokeDetected: {
      type: Boolean,
      default: false
    },
    batteryLevel: {
      type: Number,
      default: 100
    }
  },
  settings: {
    temperatureThreshold: {
      type: Number,
      default: 50
    },
    alertEnabled: {
      type: Boolean,
      default: true
    },
    autoShutdown: {
      type: Boolean,
      default: false
    }
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Index for faster queries
deviceSchema.index({ deviceId: 1 });
deviceSchema.index({ owner: 1 });
deviceSchema.index({ isActive: 1 });

module.exports = mongoose.model('Device', deviceSchema);