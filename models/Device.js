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
    trim: true,
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
    voltage: {
      type: Number,
      default: null
    },
    current: {
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
  sharedAccess: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    permission: {
      type: String,
      enum: ['view', 'control', 'manage'],
      default: 'view'
    },
    sharedAt: {
      type: Date,
      default: Date.now
    }
  }],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Index for faster queries (deviceId already indexed by unique: true)
deviceSchema.index({ owner: 1 });
deviceSchema.index({ isActive: 1 });

module.exports = mongoose.model('Device', deviceSchema);