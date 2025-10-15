import React, { createContext, useState, useContext, useEffect } from 'react';
import authService from '../services/auth.service';
import apiService from '../services/api.service';

interface User {
  id: number;
  username: string;
  email?: string;
  role: number;
  avatar?: string;
}

interface AuthContextType {
  user: User | null;
  loading: boolean;
  isAuthenticated: boolean;
  login: (username: string, password: string) => Promise<void>;
  register: (username: string, email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  // Check if user is logged in on mount
  useEffect(() => {
    checkAuthStatus();
  }, []);

  const checkAuthStatus = async () => {
    try {
      const token = await apiService.getToken();
      if (token) {
        // For now, we don't have a /me endpoint, so we can't fetch user data
        // User will be set during login. This just checks if a token exists.
        // We'll set a minimal placeholder to mark as authenticated
        setUser({
          id: 0,
          username: 'User',
          email: '',
          role: 0,
          avatar: ''
        });
      }
    } catch (error) {
      console.error('Error checking auth status:', error);
    } finally {
      setLoading(false);
    }
  };

  const login = async (username: string, password: string) => {
    try {
      const response = await authService.login({ username, password });
      console.log('Login response:', response);
      if (response.data?.user) {
        console.log('Setting user:', response.data.user);
        const userData = {
          id: response.data.user.id,
          username: response.data.user.username,
          email: response.data.user.email || '',
          role: response.data.user.role,
          avatar: response.data.user.avatar || '',
        };
        console.log('User data to set:', userData);
        setUser(userData);
      }
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  };

  const register = async (username: string, email: string, password: string) => {
    try {
      await authService.register({ username, email, password });
      // After registration, automatically login
      await login(username, password);
    } catch (error) {
      throw error;
    }
  };

  const logout = async () => {
    try {
      await authService.logout();
      setUser(null);
    } catch (error) {
      console.error('Error logging out:', error);
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        loading,
        isAuthenticated: !!user,
        login,
        register,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
