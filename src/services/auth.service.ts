import apiService from './api.service';

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface RegisterData {
  username: string;
  email: string;
  password: string;
}

export interface AuthResponse {
  success: boolean;
  message?: string;
  data?: {
    token?: string;
    user?: {
      id: number;
      username: string;
      email: string;
      avatar: string;
      role: number;
      created_at: string;
    };
  };
}

class AuthService {
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    const response = await apiService.post<AuthResponse>('/auth/login', credentials);
    if (response.data?.token) {
      await apiService.setToken(response.data.token);
    }
    return response;
  }

  async register(data: RegisterData): Promise<AuthResponse> {
    const response = await apiService.post<AuthResponse>('/auth/register', data);
    return response;
  }

  async logout(): Promise<void> {
    await apiService.removeToken();
  }

  async getCurrentUser(): Promise<any> {
    const token = await apiService.getToken();
    if (!token) {
      throw new Error('No token found');
    }
    // Add endpoint to get current user info
    return await apiService.get('/auth/me');
  }

  async isAuthenticated(): Promise<boolean> {
    const token = await apiService.getToken();
    return !!token;
  }
}

export default new AuthService();
