import React, { useState } from 'react';
import { Link, useSearchParams, Navigate } from 'react-router-dom';
import useAuth from '../hooks/useAuth';
import logoGreen from '../assets/logos/logo-green-nobg.png';

const PasswordResetSent = () => {
  const { requestPasswordReset, loading, isAuthenticated } = useAuth();
  const [searchParams] = useSearchParams();
  const email = searchParams.get('email');
  const [resendMessage, setResendMessage] = useState<string | null>(null);
  const [resendError, setResendError] = useState<string | null>(null);

  // If user is already authenticated, redirect to dashboard
  if (isAuthenticated) {
    return <Navigate to="/" />;
  }

  // If no email parameter, redirect to forgot password
  if (!email) {
    return <Navigate to="/forgot-password" />;
  }

  const handleResendReset = async () => {
    setResendError(null);
    setResendMessage(null);

    try {
      const response = await requestPasswordReset(email);
      setResendMessage(response.message);
    } catch (err: any) {
      console.error('Resend password reset error:', err);
      
      let errorMessage = 'Failed to resend password reset email. Please try again.';
      
      if (err.response?.data?.message) {
        errorMessage = err.response.data.message;
      } else if (err.response?.data?.errors && Array.isArray(err.response.data.errors)) {
        errorMessage = err.response.data.errors.join(', ');
      }
      
      setResendError(errorMessage);
    }
  };

  return (
    <div className="min-vh-100 d-flex align-items-center justify-content-center bg-forest-500" style={{ background: 'linear-gradient(135deg, #2c7c57 0%, #216543 100%)' }}>
      <div className="container">
        <div className="row justify-content-center">
          <div className="col-md-6 col-lg-5">
            <div className="card shadow border-0">
              <div className="card-body p-4 p-md-5">
                <div className="text-center mb-4">
                  <img src={logoGreen} alt="Aumora" className="img-fluid mb-4" style={{ maxHeight: '80px' }} />
                  <h3 className="fw-bold text-forest-600 mb-3">Check Your Email</h3>
                </div>
                
                <div className="text-center">
                  <div className="alert alert-success py-3 mb-4" role="alert">
                    <i className="bi bi-envelope-check-fill me-2"></i>
                    Password reset email sent!
                  </div>

                  <p className="text-muted mb-4">
                    We've sent password reset instructions to <strong>{email}</strong>. 
                    Please check your inbox and click the link to reset your password.
                  </p>

                  <div className="alert alert-info py-3 mb-4" role="alert">
                    <i className="bi bi-info-circle-fill me-2"></i>
                    <strong>Don't see the email?</strong><br />
                    Check your spam folder or wait a few minutes for the email to arrive.
                  </div>

                  {resendMessage && (
                    <div className="alert alert-success py-2 mb-3" role="alert">
                      <i className="bi bi-check-circle-fill me-2"></i>
                      {resendMessage}
                    </div>
                  )}

                  {resendError && (
                    <div className="alert alert-danger py-2 mb-3" role="alert">
                      <i className="bi bi-exclamation-triangle-fill me-2"></i>
                      {resendError}
                    </div>
                  )}

                  <div className="d-grid gap-2 mb-4">
                    <button
                      type="button"
                      onClick={handleResendReset}
                      disabled={loading}
                      className="btn btn-outline-primary py-2"
                    >
                      {loading ? (
                        <>
                          <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                          Sending...
                        </>
                      ) : (
                        <>
                          <i className="bi bi-envelope-arrow-up me-2"></i>
                          Resend password reset email
                        </>
                      )}
                    </button>
                  </div>

                  <div className="text-center">
                    <Link to="/login" className="text-decoration-none">
                      <span className="fw-semibold text-forest-600">Back to Sign in</span>
                    </Link>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PasswordResetSent; 