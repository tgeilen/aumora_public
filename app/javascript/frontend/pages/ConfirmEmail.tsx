import React, { useEffect, useState, useRef } from 'react';
import { Link, Navigate } from 'react-router-dom';
import useAuth from '../hooks/useAuth';
import logoGreen from '../assets/logos/logo-green-nobg.png';

const ConfirmEmail = () => {
  const { isAuthenticated } = useAuth();
  const hasConfirmed = useRef(false); // Prevent duplicate API calls
  const [confirmationResult, setConfirmationResult] = useState<{
    message: string;
    confirmed: boolean;
    loading: boolean;
  }>({
    message: '',
    confirmed: false,
    loading: true
  });

  useEffect(() => {
    // Prevent duplicate calls in React StrictMode
    if (hasConfirmed.current) {
      return;
    }

    const searchParams = new URLSearchParams(window.location.search);
    const confirmationToken = searchParams.get('confirmation_token');
    
    if (!confirmationToken) {
      setConfirmationResult({
        message: 'Invalid confirmation link. Please check your email for the correct link.',
        confirmed: false,
        loading: false
      });
      return;
    }

    // Mark as confirming to prevent duplicate calls
    hasConfirmed.current = true;

    // Make the API call directly without using the auth context
    const confirmEmailDirectly = async () => {
      try {
        const response = await fetch(`/api/v1/confirmations?confirmation_token=${encodeURIComponent(confirmationToken)}`, {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          }
        });

        const data = await response.json();
        
        setConfirmationResult({
          message: data.message,
          confirmed: data.confirmed,
          loading: false
        });
      } catch (error) {
        setConfirmationResult({
          message: 'Email confirmation failed. The token may be invalid or expired.',
          confirmed: false,
          loading: false
        });
      }
    };

    confirmEmailDirectly();
  }, []); // Empty dependency array - only run once when component mounts

  // If user is already authenticated, redirect to dashboard
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
                  <h3 className="fw-bold text-forest-600 mb-3">Email Confirmation</h3>
                </div>
                
                <div className="text-center">
                  {confirmationResult.loading ? (
                    <div>
                      <div className="spinner-border text-primary mb-3" role="status">
                        <span className="visually-hidden">Loading...</span>
                      </div>
                      <p className="text-muted">Confirming your email address...</p>
                    </div>
                  ) : (
                    <div>
                      <div className={`alert ${confirmationResult.confirmed ? 'alert-success' : 'alert-danger'} py-3 mb-4`} role="alert">
                        <i className={`${confirmationResult.confirmed ? 'bi bi-check-circle-fill' : 'bi bi-exclamation-triangle-fill'} me-2`}></i>
                        {confirmationResult.message}
                      </div>
                      
                      {confirmationResult.confirmed ? (
                        <div>
                          <p className="text-muted mb-4">Your email has been successfully confirmed! You can now sign in to your account.</p>
                          <div className="d-grid gap-2">
                            <Link to="/login" className="btn btn-primary py-2">
                              Sign In
                            </Link>
                          </div>
                        </div>
                      ) : (
                        <div>
                          <p className="text-muted mb-4">Please try registering again or contact support if you continue to have issues.</p>
                          <div className="d-grid gap-2 mb-3">
                            <Link to="/register" className="btn btn-primary py-2">
                              Register Again
                            </Link>
                          </div>
                          <div className="text-center">
                            <Link to="/login" className="text-decoration-none">
                              <span className="fw-semibold text-forest-600">Back to Sign in</span>
                            </Link>
                          </div>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ConfirmEmail; 