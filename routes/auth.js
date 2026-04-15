const express = require('express');
const admin = require('firebase-admin');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

// init firebase admin
admin.initializeApp({
  credential: admin.credential.cert(require('../firebase-service-account.json'))
});

const JWT_SECRET = process.env.JWT_SECRET;

// ─── FIREBASE LOGIN ─────────────────────────────
router.post('/firebase-login', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'Token required' });
    }

    // ✅ VERIFY FIREBASE TOKEN
    const decoded = await admin.auth().verifyIdToken(idToken);

    const { uid, email, name, picture } = decoded;

    let user = await User.findOne({ firebaseUid: uid });

    if (!user) {
      user = await User.create({
        firebaseUid: uid,
        email,
        name,
        profilePicture: picture || '',
      });
    }

    const token = jwt.sign(
      { userId: user._id },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user,
    });

  } catch (err) {
    console.error(err);
    res.status(401).json({ error: 'Invalid Firebase token' });
  }
});

module.exports = router;