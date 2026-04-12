# FlameGuard Full Setup Guide

This guide walks you through setting up the complete FlameGuard IoT system using MongoDB Atlas and Render (both free tiers).

## 1. MongoDB Atlas Setup

1. **Create Account**: Go to https://cloud.mongodb.com and sign up for free
2. **Create Cluster**: Choose the free M0 cluster
3. **Create Database User**:
   - Go to Database Access
   - Add new user with read/write permissions
4. **Whitelist IP**: Add `0.0.0.0/0` for initial testing (restrict later)
5. **Get Connection String**: Click "Connect" > "Connect your application" > Copy the connection string

## 2. Google OAuth Setup

1. **Google Cloud Console**: https://console.cloud.google.com
2. **Create Project**: Name it "FlameGuard"
3. **Enable APIs**:
   - Go to APIs & Services > Library
   - Enable "Google+ API"
4. **Create OAuth Credentials**:
   - Go to Credentials > Create Credentials > OAuth 2.0 Client IDs
   - Application type: Web application
   - Authorized redirect URIs: Add your Render app URL + `/auth/google/callback` (for later)
   - Copy the Client ID

## 3. Render Deployment

1. **Create Account**: https://render.com (free tier available)
2. **Connect Repository**: Link your GitHub repo with the backend folder
3. **Create Web Service**:
   - Runtime: Node
   - Build Command: `npm install`
   - Start Command: `npm start`
   - Add Environment Variables:
     ```
     MONGODB_URI=your-mongodb-connection-string
     JWT_SECRET=your-super-secret-key
     GOOGLE_CLIENT_ID=your-google-client-id
     ```
4. **Deploy**: Click "Create Web Service" - Render will build and deploy automatically
5. **Get URL**: Copy the service URL (e.g., `https://flameguard-api.onrender.com`)

## 4. Update Flutter App

1. **Update API Base URL** in `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'https://your-render-app.onrender.com/api';
   ```

2. **Update Google OAuth** (if needed):
   - In Google Cloud Console, add your Render URL to authorized redirect URIs
   - The Flutter app uses the Client ID for mobile authentication

## 5. Test Authentication

1. **Run the Flutter app**
2. **Try Google Sign In** - should authenticate via your backend
3. **Check MongoDB**: User should be created in the `users` collection

## 6. ESP32 Setup (Next Steps)

Once authentication works, proceed to:
- Set up MQTT broker (HiveMQ Cloud free tier)
- Flash ESP32 firmware
- Test device communication

## Troubleshooting

- **MongoDB Connection**: Check connection string and IP whitelist
- **Google OAuth**: Ensure Client ID is correct and APIs are enabled
- **Render Deployment**: Check build logs for errors
- **Flutter App**: Verify base URL and handle CORS if needed

## Security Notes

- Change JWT secret to a strong random string
- Restrict MongoDB IP access in production
- Use HTTPS everywhere
- Implement proper error handling

The system is now ready for development and testing!