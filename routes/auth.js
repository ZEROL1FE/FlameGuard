const express = require('express');
const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

// Initialize Google OAuth client
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// JWT secret
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// ─── GOOGLE LOGIN ──────────────────────────────────────────────────────────
router.post('/google-login', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ error: 'ID token is required' });
    }

    // Verify the Google ID token
    const ticket = await googleClient.verifyIdToken({
      idToken: idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const payload = ticket.getPayload();
    const { sub: providerId, email, name, picture } = payload;

    // Check if user exists, if not create one
    let user = await User.findOne({ providerId, provider: 'google' });

    if (!user) {
      user = new User({
        email,
        name,
        profilePicture: picture || '',
        provider: 'google',
        providerId,
      });
      await user.save();
    } else {
      // Update last login
      user.lastLogin = new Date();
      await user.save();
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, email: user.email },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        profilePicture: user.profilePicture,
      }
    });

  } catch (error) {
    console.error('Google login error:', error);
    res.status(401).json({ error: 'Invalid Google token' });
  }
});

// ─── FACEBOOK LOGIN ────────────────────────────────────────────────────────
router.post('/facebook-login', async (req, res) => {
  try {
    const { accessToken } = req.body;

    if (!accessToken) {
      return res.status(400).json({ error: 'Access token is required' });
    }

    // Verify Facebook token (simplified - in production use Facebook SDK)
    // For now, we'll trust the token and create user
    // TODO: Implement proper Facebook token verification

    // This is a placeholder - you need to verify with Facebook Graph API
    const fbUserData = {
      id: 'facebook-user-id', // Get from Facebook API
      email: 'user@example.com',
      name: 'Facebook User',
      picture: { data: { url: '' } }
    };

    let user = await User.findOne({ providerId: fbUserData.id, provider: 'facebook' });

    if (!user) {
      user = new User({
        email: fbUserData.email,
        name: fbUserData.name,
        profilePicture: fbUserData.picture.data.url,
        provider: 'facebook',
        providerId: fbUserData.id,
      });
      await user.save();
    }

    const token = jwt.sign(
      { userId: user._id, email: user.email },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        profilePicture: user.profilePicture,
      }
    });

  } catch (error) {
    console.error('Facebook login error:', error);
    res.status(401).json({ error: 'Facebook login failed' });
  }
});

// ─── APPLE LOGIN ───────────────────────────────────────────────────────────
router.post('/apple-login', async (req, res) => {
  try {
    const { identityToken, userIdentifier } = req.body;

    if (!identityToken || !userIdentifier) {
      return res.status(400).json({ error: 'Identity token and user identifier are required' });
    }

    // Verify Apple token (simplified - in production use Apple's verification)
    // TODO: Implement proper Apple token verification

    let user = await User.findOne({ providerId: userIdentifier, provider: 'apple' });

    if (!user) {
      user = new User({
        email: 'apple-user@example.com', // Apple doesn't provide email in token
        name: 'Apple User',
        provider: 'apple',
        providerId: userIdentifier,
      });
      await user.save();
    }

    const token = jwt.sign(
      { userId: user._id, email: user.email },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        profilePicture: user.profilePicture,
      }
    });

  } catch (error) {
    console.error('Apple login error:', error);
    res.status(401).json({ error: 'Apple login failed' });
  }
});

// ─── EMAIL/PASSWORD LOGIN (for future use) ────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user by email
    const user = await User.findOne({ email: email.toLowerCase(), provider: 'email' });

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // TODO: Verify password with bcrypt
    // const isValidPassword = await bcrypt.compare(password, user.password);

    const token = jwt.sign(
      { userId: user._id, email: user.email },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        profilePicture: user.profilePicture,
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

module.exports = router;