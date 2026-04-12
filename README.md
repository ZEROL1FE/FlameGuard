# FlameGuard Backend API

Node.js/Express backend for the FlameGuard IoT fire protection system.

## Features

- User authentication with Google, Facebook, and Apple OAuth
- Device management and sensor data storage
- JWT-based authorization
- MongoDB Atlas integration
- Rate limiting and CORS protection

## Setup

1. **Clone and install dependencies:**
   ```bash
   cd backend
   npm install
   ```

2. **Environment variables:**
   - Copy `.env.example` to `.env`
   - Fill in your MongoDB Atlas connection string
   - Add your Google OAuth client ID
   - Set a secure JWT secret

3. **MongoDB Atlas setup:**
   - Create a free cluster at https://cloud.mongodb.com
   - Create a database named `flameguard`
   - Get your connection string and update `MONGODB_URI`

4. **Google OAuth setup:**
   - Go to Google Cloud Console
   - Create a new project or use existing
   - Enable Google+ API
   - Create OAuth 2.0 credentials
   - Add your client ID to `.env`

## Deployment to Render

1. **Create Render account** at https://render.com
2. **Connect your GitHub repository**
3. **Create a new Web Service:**
   - Runtime: Node
   - Build Command: `npm install`
   - Start Command: `npm start`
4. **Add environment variables** in Render dashboard
5. **Deploy**

## API Endpoints

### Authentication
- `POST /api/auth/google-login` - Google OAuth login
- `POST /api/auth/facebook-login` - Facebook OAuth login
- `POST /api/auth/apple-login` - Apple Sign In

### Devices
- `GET /api/devices` - Get user's devices
- `POST /api/devices` - Add new device
- `PUT /api/devices/:deviceId` - Update device
- `DELETE /api/devices/:deviceId` - Delete device
- `POST /api/devices/:deviceId/command` - Send command to device
- `POST /api/devices/:deviceId/sensor-data` - Update sensor data (ESP32)

## Development

```bash
npm run dev  # Start with nodemon
npm start    # Production start
```

## Security Notes

- Change the JWT secret in production
- Use HTTPS in production
- Implement proper Facebook and Apple token verification
- Add input validation and sanitization
- Consider adding API versioning