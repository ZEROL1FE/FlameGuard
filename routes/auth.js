const express = require('express');
const admin = require('firebase-admin');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

if (!admin.apps.length) {
  try {
    const serviceAccount = require('../firebase-service-account.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } catch (error) {
    console.warn('Firebase Admin SDK not initialized:', error.message);
  }
}

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

const buildAuthResponse = (user) => ({
  success: true,
  token: jwt.sign({ userId: user._id }, JWT_SECRET, { expiresIn: '7d' }),
  user: {
    id: user._id.toString(),
    email: user.email,
    name: user.name,
    profilePicture: user.profilePicture || '',
  },
});

router.post('/signup', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email and password are required' });
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({
      name: String(name).trim(),
      email: normalizedEmail,
      provider: 'email',
      providerId: normalizedEmail,
      passwordHash,
      lastLogin: new Date(),
    });

    return res.status(201).json(buildAuthResponse(user));
  } catch (error) {
    console.error('Email signup failed:', error);
    return res.status(500).json({ error: 'Failed to create account' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    if (!user || !user.passwordHash) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const validPassword = await bcrypt.compare(password, user.passwordHash);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    user.lastLogin = new Date();
    await user.save();
    return res.json(buildAuthResponse(user));
  } catch (error) {
    console.error('Email login failed:', error);
    return res.status(500).json({ error: 'Failed to login' });
  }
});

router.post('/google-login', async (req, res) => {
  return res.status(400).json({
    error: 'Use /firebase-login with Firebase ID token',
  });
});

router.post('/facebook-login', async (req, res) => {
  return res.status(501).json({
    error: 'Facebook login is not configured on backend yet',
  });
});

router.post('/apple-login', async (req, res) => {
  return res.status(501).json({
    error: 'Apple login is not configured on backend yet',
  });
});

// ─── FIREBASE LOGIN ─────────────────────────────
router.post('/firebase-login', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'Token required' });
    }

    if (!admin.apps.length) {
      return res.status(500).json({ error: 'Firebase Admin is not configured' });
    }

    const decoded = await admin.auth().verifyIdToken(idToken);

    const { uid, email, name, picture } = decoded;
    if (!email) {
      return res.status(400).json({ error: 'Email is required from Firebase token' });
    }

    let user = await User.findOne({ firebaseUid: uid });

    if (!user) {
      user = await User.create({
        firebaseUid: uid,
        email,
        name: name || email.split('@')[0],
        profilePicture: picture || '',
        provider: 'google',
        providerId: uid,
      });
    } else {
      user.lastLogin = new Date();
      await user.save();
    }

    res.json(buildAuthResponse(user));

  } catch (err) {
    console.error(err);
    res.status(401).json({ error: 'Invalid Firebase token' });
  }
});

module.exports = router;