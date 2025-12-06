import api from './api';

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData extends LoginCredentials {
  password_confirmation: string;
}

export interface AuthResponse {
  token: string;
  user: {
    id: number;
    email: string;
  };
}

export interface RegisterResponse {
  user: {
    id: number;
    email: string;
    created_at: string;
    updated_at: string;
  };
  message: string;
  confirmation_required: boolean;
}

export interface ConfirmationResponse {
  message: string;
  confirmed: boolean;
  errors?: string[];
}

export interface PasswordResetRequest {
  email: string;
}

export interface PasswordResetData {
  reset_password_token: string;
  password: string;
  password_confirmation: string;
}

export interface PasswordResetResponse {
  message: string;
  email_sent?: boolean;
  success?: boolean;
  errors?: string[];
}

/**
 * Authentication service for login, register, and logout operations
 */
const authService = {
  /**
   * Login with email and password
   */
  login: async (credentials: LoginCredentials): Promise<AuthResponse> => {
    const response = await api.post<AuthResponse>('/login', { 
      user: credentials 
    });
    console.log('Login response:', response.data);
    if (response.data.token) {
      localStorage.setItem('auth_token', response.data.token);
    }
    return response.data;
  },

  /**
   * Register new user
   */
  register: async (data: RegisterData): Promise<RegisterResponse> => {
    const response = await api.post<RegisterResponse>('/users', { user: data });
    console.log('Register response:', response.data);
    // Note: Registration no longer returns a token - confirmation required first
    return response.data;
  },

  /**
   * Confirm email address with token
   */
  confirmEmail: async (confirmationToken: string): Promise<ConfirmationResponse> => {
    const response = await api.get<ConfirmationResponse>(`/confirmations?confirmation_token=${confirmationToken}`);
    console.log('Confirmation response:', response.data);
    return response.data;
  },

  /**
   * Resend confirmation email
   */
  resendConfirmation: async (email: string): Promise<ConfirmationResponse> => {
    const response = await api.post<ConfirmationResponse>('/confirmations', { 
      user: { email } 
    });
    console.log('Resend confirmation response:', response.data);
    return response.data;
  },

  /**
   * Request password reset email
   */
  requestPasswordReset: async (email: string): Promise<PasswordResetResponse> => {
    const response = await api.post<PasswordResetResponse>('/passwords', { 
      user: { email } 
    });
    console.log('Password reset request response:', response.data);
    return response.data;
  },

  /**
   * Reset password with token
   */
  resetPassword: async (data: PasswordResetData): Promise<PasswordResetResponse> => {
    const response = await api.put<PasswordResetResponse>('/passwords', { 
      user: data 
    });
    console.log('Password reset response:', response.data);
    return response.data;
  },

  /**
   * Logout user
   */
  logout: async (): Promise<void> => {
    // The token is automatically included in the Authorization header by the API interceptor
    // This calls the backend to add the token to the denylist
    await api.delete('/logout');
    // Remove token from local storage to complete the logout process on the client
    localStorage.removeItem('auth_token');
  },

  /**
   * Get current user profile
   */
  getCurrentUser: async () => {
    const response = await api.get('/users/current');
    return response.data;
  },

  /**
   * Check if user is authenticated
   */
  isAuthenticated: (): boolean => {
    const token = localStorage.getItem('auth_token');
    return !!token;
  }
};

export default authService; 