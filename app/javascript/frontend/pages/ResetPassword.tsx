import React, { useState, useEffect } from 'react';
import { Link, Navigate, useSearchParams, useNavigate } from 'react-router-dom';
import useAuth from '../hooks/useAuth';
import logoGreen from '../assets/logos/logo-green-nobg.png';

const ResetPassword = () => {
  const { resetPassword, isAuthenticated, loading, error } = useAuth();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [password, setPassword] = useState('');
  const [passwordConfirmation, setPasswordConfirmation] = useState('');
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [resetToken, setResetToken] = useState<string | null>(null);

  useEffect(() => {
    const token = searchParams.get('reset_password_token');
    if (!token) {
      navigate('/forgot-password');
      return;
    }
    setResetToken(token);
  }, [searchParams, navigate]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);
    setSuccessMessage(null);

    if (!resetToken) {
      setSubmitError('Invalid reset token');
      return;
    }

    if (!password || !passwordConfirmation) {
      setSubmitError('Please fill in all fields');
      return;
    }

    if (password !== passwordConfirmation) {
      setSubmitError('Passwords do not match');
      return;
    }

    if (password.length < 6) {
      setSubmitError('Password must be at least 6 characters long');
      return;
    }

    try {
      const response = await resetPassword({
        reset_password_token: resetToken,
        password,
        password_confirmation: passwordConfirmation
      });
      
      if (response.success) {
        setSuccessMessage(response.message);
        // Redirect to login after 3 seconds
        setTimeout(() => {
          navigate('/login');
        }, 3000);
      }
    } catch (err: any) {
      console.error('Password reset error:', err);
      
      // Try to get specific error message from API response
      let errorMessage = 'Failed to reset password. Please try again.';
      
      if (err.response?.data?.message) {
        errorMessage = err.response.data.message;
      } else if (err.response?.data?.errors && Array.isArray(err.response.data.errors)) {
        errorMessage = err.response.data.errors.join(', ');
      }
      
      setSubmitError(errorMessage);
    }
  };

  if (isAuthenticated) {
    return <Navigate to="/" />;
  }

  if (!resetToken) {
    return null; // Will redirect to forgot-password
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
                    Enter your new password below.
                  </p>
                </div>
                
                {!successMessage ? (
                  <form className="mb-3" onSubmit={handleSubmit}>
                    <div className="mb-3">
                      <label htmlFor="password" className="form-label">New Password</label>
                      <input
                        id="password"
                        name="password"
                        type="password"
                        autoComplete="new-password"
                        required
                        className="form-control"
                        placeholder="Enter new password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                      />
                    </div>
                    
                    <div className="mb-4">
                      <label htmlFor="password-confirmation" className="form-label">Confirm New Password</label>
                      <input
                        id="password-confirmation"
                        name="password-confirmation"
                        type="password"
                        autoComplete="new-password"
                        required
                        className="form-control"
                        placeholder="Confirm new password"
                        value={passwordConfirmation}
                        onChange={(e) => setPasswordConfirmation(e.target.value)}
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
                            Resetting password...
                          </>
                        ) : (
                          'Reset password'
                        )}
                      </button>
                    </div>

                    <div className="text-center">
                      <Link to="/login" className="text-decoration-none">
                        <span className="fw-semibold text-forest-600">Back to Sign in</span>
                      </Link>
                    </div>
                  </form>
                ) : (
                  <div className="text-center">
                    <div className="alert alert-success py-3 mb-4" role="alert">
                      <i className="bi bi-check-circle-fill me-2"></i>
                      {successMessage}
                    </div>

                    <p className="text-muted mb-4">
                      Your password has been successfully reset. You will be redirected to the login page shortly.
                    </p>

                    <div className="d-grid gap-2">
                      <Link to="/login" className="btn btn-primary py-2">
                        Sign in now
                      </Link>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ResetPassword; 