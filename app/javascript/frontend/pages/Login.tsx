import React, { useState } from 'react';
import { Link, Navigate } from 'react-router-dom';
import useAuth from '../hooks/useAuth';
import logoGreen from '../assets/logos/logo-green-nobg.png';

const Login = () => {
  const { login, resendConfirmation, isAuthenticated, loading, error } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [showResendConfirmation, setShowResendConfirmation] = useState(false);
  const [resendMessage, setResendMessage] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);
    setShowResendConfirmation(false);
    setResendMessage(null);
    
    try {
      await login({ email, password });
    } catch (err: any) {
      if (err.response?.data?.confirmation_required) {
        setSubmitError('Please confirm your email address before signing in.');
        setShowResendConfirmation(true);
      } else {
        setSubmitError('Login failed. Please check your credentials.');
      }
    }
  };

  const handleResendConfirmation = async () => {
    try {
      const response = await resendConfirmation(email);
      setResendMessage(response.message);
      setSubmitError(null);
    } catch {
      setSubmitError('Failed to resend confirmation email. Please try again.');
    }
  };

  if (isAuthenticated) {
    return <Navigate to="/" />;
  }

  return (
    <div className="min-vh-100 d-flex align-items-center justify-content-center bg-forest-500" style={{ background: 'linear-gradient(135deg, #2c7c57 0%, #216543 100%)' }}>
      <div className="container">
        <div className="row justify-content-center">
          <div className="col-md-6 col-lg-5">
            <div className="card shadow border-0">
              <div className="card-body p-4 p-md-5">
                <div className="text-center mb-4">
                  <img src={logoGreen} alt="Aumora" className="img-fluid mb-4" style={{ maxHeight: '80px' }} />
                  <h3 className="fw-bold text-forest-600 mb-3">Sign in to your account</h3>
                </div>
                
                <form className="mb-3" onSubmit={handleSubmit}>
                  <div className="mb-3">
                    <label htmlFor="email-address" className="form-label">Email address</label>
                    <input
                      id="email-address"
                      name="email"
                      type="email"
                      autoComplete="email"
                      required
                      className="form-control"
                      placeholder="Email address"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                    />
                  </div>
                  
                  <div className="mb-4">
                    <label htmlFor="password" className="form-label">Password</label>
                    <input
                      id="password"
                      name="password"
                      type="password"
                      autoComplete="current-password"
                      required
                      className="form-control"
                      placeholder="Password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                    />
                  </div>

                  {resendMessage && (
                    <div className="alert alert-success py-2" role="alert">
                      {resendMessage}
                    </div>
                  )}

                  {(error || submitError) && (
                    <div className="alert alert-danger py-2" role="alert">
                      {error || submitError}
                      {showResendConfirmation && (
                        <div className="mt-2">
                          <button
                            type="button"
                            onClick={handleResendConfirmation}
                            className="btn btn-sm btn-outline-danger"
                            disabled={loading}
                          >
                            {loading ? 'Sending...' : 'Resend confirmation email'}
                          </button>
                        </div>
                      )}
                    </div>
                  )}

                  <div className="d-grid gap-2 mb-4">
                    <button
                      type="submit"
                      disabled={loading}
                      className="btn btn-primary py-2"
                    >
                      {loading ? 'Signing in...' : 'Sign in'}
                    </button>
                  </div>

                  <div className="text-center mb-3">
                    <Link to="/forgot-password" className="text-decoration-none text-muted">
                      Forgot your password?
                    </Link>
                  </div>

                  <div className="text-center">
                    <Link to="/register" className="text-decoration-none">
                      Don't have an account? <span className="fw-semibold text-forest-600">Sign up</span>
                    </Link>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login; 