import React from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AuthProvider, useAuth } from './hooks/useAuth'
import { PrivacyProvider } from './contexts/PrivacyContext'
import MainLayout from './components/layout/MainLayout'

// Pages
import Login from './pages/Login'
import Register from './pages/Register'
import ConfirmEmail from './pages/ConfirmEmail'
import ConfirmationInfo from './pages/ConfirmationInfo'
import ForgotPassword from './pages/ForgotPassword'
import PasswordResetSent from './pages/PasswordResetSent'
import ResetPassword from './pages/ResetPassword'
import Dashboard from './pages/Dashboard'
import ETFList from './pages/ETFList'
import ETFDetail from './pages/ETFDetail'
import PortfolioList from './pages/PortfolioList'
import PortfolioDetail from './pages/PortfolioDetail'

// Create a query client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      retry: 1,
    },
  },
})

// Protected Route component
const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const { isAuthenticated, loading } = useAuth()
  
  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center min-vh-100">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    )
  }
  
  return isAuthenticated ? <>{children}</> : <Navigate to="/login" replace />
}

// Public Route component (redirects to dashboard if already authenticated)
const PublicRoute = ({ children }: { children: React.ReactNode }) => {
  const { isAuthenticated, loading } = useAuth()
  
  if (loading) {
    return (
      <div className="d-flex justify-content-center align-items-center min-vh-100">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    )
  }
  
  return !isAuthenticated ? <>{children}</> : <Navigate to="/dashboard" replace />
}

// App Routes component
const AppRoutes = () => {
  return (
    <Routes>
      {/* Public routes */}
      <Route path="/login" element={
        <PublicRoute>
          <Login />
        </PublicRoute>
      } />
      <Route path="/register" element={
        <PublicRoute>
          <Register />
        </PublicRoute>
      } />
      <Route path="/confirmation-info" element={
        <PublicRoute>
          <ConfirmationInfo />
        </PublicRoute>
      } />
      <Route path="/confirm-email" element={
        <PublicRoute>
          <ConfirmEmail />
        </PublicRoute>
      } />
      <Route path="/forgot-password" element={
        <PublicRoute>
          <ForgotPassword />
        </PublicRoute>
      } />
      <Route path="/password-reset-sent" element={
        <PublicRoute>
          <PasswordResetSent />
        </PublicRoute>
      } />
      <Route path="/reset-password" element={
        <PublicRoute>
          <ResetPassword />
        </PublicRoute>
      } />
      
      {/* Protected routes with layout */}
      <Route path="/" element={
        <ProtectedRoute>
          <MainLayout />
        </ProtectedRoute>
      }>
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<Dashboard />} />
        <Route path="etfs" element={<ETFList />} />
        <Route path="etfs/:id" element={<ETFDetail />} />
        <Route path="portfolios" element={<PortfolioList />} />
        <Route path="portfolios/:id" element={<PortfolioDetail />} />
      </Route>
      
      {/* Catch all route */}
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  )
}

// Main App component
const App = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <PrivacyProvider>
          <Router>
            <AppRoutes />
          </Router>
        </PrivacyProvider>
      </AuthProvider>
    </QueryClientProvider>
  )
}

export default App
