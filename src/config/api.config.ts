/**
 * API Configuration
 * Update API_URL based on your environment
 */

// For iOS Simulator: use localhost
// For Android Emulator: use 10.0.2.2
// For Physical Device: use your computer's IP address (e.g., 192.168.1.x)

export const API_CONFIG = {
  // Change this based on where you're running
  BASE_URL: __DEV__
    ? 'http://localhost:8000/api'  // Development
    : 'https://your-production-api.com/api', // Production

  TIMEOUT: 30000, // 30 seconds
};

// Alternative configurations for different devices
export const DEVICE_CONFIGS = {
  IOS_SIMULATOR: 'http://localhost:8000/api',
  ANDROID_EMULATOR: 'http://10.0.2.2:8000/api',
  // Replace with your actual IP for physical devices
  PHYSICAL_DEVICE: 'http://192.168.1.x:8000/api',
};
