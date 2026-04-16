const mongoose = require('mongoose');

const sensorHistorySchema = new mongoose.Schema({
  device: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Device',
    required: true,
    index: true,
  },
  deviceId: {
    type: String,
    required: true,
    index: true,
  },
  temperature: Number,
  humidity: Number,
  voltage: Number,
  current: Number,
  flameDetected: Boolean,
  smokeDetected: Boolean,
  batteryLevel: Number,
  recordedAt: {
    type: Date,
    default: Date.now,
    index: true,
  },
});

sensorHistorySchema.index({ device: 1, recordedAt: -1 });

module.exports = mongoose.model('SensorHistory', sensorHistorySchema);
