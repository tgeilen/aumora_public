import React, { useState } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import useAuth from '../hooks/useAuth';
import logoGreen from '../assets/logos/logo-green-nobg.png';

const ForgotPassword = () => {
  const { requestPasswordReset, isAuthenticated, loading, error } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [submitError, setSubmitError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);

    if (!email.trim()) {
      setSubmitError('Please enter your email address');
      return;
    }

    try {
      await requestPasswordReset(email.trim());
      // Redirect to password reset sent page with email as parameter
      navigate(`/password-reset-sent?email=${encodeURIComponent(email.trim())}`);
    } catch (err: any) {
      console.error('Password reset request error:', err);
      setSubmitError('Failed to send password reset email. Please try again.');
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
                  <h3 className="fw-bold text-forest-600 mb-3">Reset your password</h3>
                  <p className="text-muted">
                    Enter your email address and we'll send you a link to reset your password.
                  </p>
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
                      placeholder="Enter your email address"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                    />
                  </div>

                  {(error || submitError) && (
                    <div className="alert alert-danger py-2" role="alert">
                      {error || submitError}
                    </div>
                  )}

                  <div className="d-grid gap-2 mb-4">
                    <button
                      type="submit"
                      disabled={loading}
                      className="btn btn-primary py-2"
                    >
                      {loading ? (
                        <>
                          <span className="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
                          Sending...
                        </>
                      ) : (
                        'Send reset instructions'
                      )}
                    </button>
                  </div>

                  <div className="text-center">
                    <Link to="/login" className="text-decoration-none">
                      <span className="fw-semibold text-forest-600">Back to Sign in</span>
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

export default ForgotPassword; 