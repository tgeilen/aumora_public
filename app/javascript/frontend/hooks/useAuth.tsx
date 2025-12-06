import React, { createContext, useContext, ReactNode, useState, useEffect, useCallback, useMemo } from 'react';
import authService, { LoginCredentials, RegisterData, PasswordResetData } from '../services/auth';

interface User {
  id: number;
  email: string;
}

interface AuthContextType {
  user: User | null;
  loading: boolean;
  error: string | null;
  login: (credentials: LoginCredentials) => Promise<void>;
  register: (data: RegisterData) => Promise<{ message: string; confirmationRequired: boolean }>;
  confirmEmail: (token: string) => Promise<{ message: string; confirmed: boolean }>;
  resendConfirmation: (email: string) => Promise<{ message: string }>;
  requestPasswordReset: (email: string) => Promise<{ message: string }>;
  resetPassword: (data: PasswordResetData) => Promise<{ message: string; success: boolean }>;
  logout: () => Promise<void>;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  // Check if user is already logged in
  useEffect(() => {
    const checkAuth = async () => {
      try {
        setLoading(true);
        if (authService.isAuthenticated()) {
          const userData = await authService.getCurrentUser();
          setUser(userData);
          setIsAuthenticated(true);
        }
      } catch (err) {
        console.error('Authentication check failed:', err);
        // Clear any invalid tokens
        localStorage.removeItem('auth_token');
      } finally {
        setLoading(false);
      }
    };

    checkAuth();
  }, []);

  const login = useCallback(async (credentials: LoginCredentials) => {
    try {
      setLoading(true);
      setError(null);
      const response = await authService.login(credentials);
      setUser(response.user);
      setIsAuthenticated(true);
    } catch (err: any) {
      // Handle specific confirmation required error
      if (err.response?.data?.confirmation_required) {
        setError('Please confirm your email address before signing in.');
      } else {
        setError('Login failed. Please check your credentials and try again.');
      }
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const register = useCallback(async (data: RegisterData) => {
    try {
      setLoading(true);
      setError(null);
      const response = await authService.register(data);
      // User is not automatically authenticated after registration
      // They need to confirm their email first
      return {
        message: response.message,
        confirmationRequired: response.confirmation_required
      };
    } catch (err) {
      setError('Registration failed. Please try again.');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const confirmEmail = useCallback(async (token: string) => {
    try {
      setLoading(true);
      setError(null);
      const response = await authService.confirmEmail(token);
      return {
        message: response.message,
        confirmed: response.confirmed
      };
    } catch (err) {
      setError('Email confirmation failed. The token may be invalid or expired.');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const resendConfirmation = useCallback(async (email: string) => {
    try {
      setLoading(true);
      setError(null);
      const response = await authService.resendConfirmation(email);
      return {
        message: response.message
      };
    } catch (err) {
      setError('Failed to resend confirmation email. Please try again.');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const requestPasswordReset = useCallback(async (email: string) => {
    try {
      setLoading(true);
      setError(null);
      const response = await authService.requestPasswordReset(email);
      return {
        message: response.message
      };
    } catch (err) {
      setError('Failed to send password reset email. Please try again.');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const resetPassword = useCallback(async (data: PasswordResetData) => {
    try {
      setLoading(true);
      setError(null);
      const response = await authService.resetPassword(data);
      return {
        message: response.message,
        success: response.success || false
      };
    } catch (err) {
      setError('Failed to reset password. Please try again.');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const logout = useCallback(async () => {
    try {
      setLoading(true);
      await authService.logout();
      setUser(null);
      setIsAuthenticated(false);
    } catch (err) {
      console.error('Logout failed:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  const value = useMemo(() => ({
    user,
    loading,
    error,
    login,
    register,
    confirmEmail,
    resendConfirmation,
    requestPasswordReset,
    resetPassword,
    logout,
    isAuthenticated
  }), [user, loading, error, login, register, confirmEmail, resendConfirmation, requestPasswordReset, resetPassword, logout, isAuthenticated]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export default useAuth; 