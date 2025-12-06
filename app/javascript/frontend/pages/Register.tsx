import React, { useState } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import useAuth from '../hooks/useAuth';
import logoGreen from '../assets/logos/logo-green-nobg.png';

const Register = () => {
  const { register, isAuthenticated, loading, error } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [passwordConfirmation, setPasswordConfirmation] = useState('');
  const [submitError, setSubmitError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);

    if (password !== passwordConfirmation) {
      setSubmitError('Passwords do not match');
      return;
    }

    try {
      const response = await register({ 
        email, 
        password, 
        password_confirmation: passwordConfirmation 
      });
      
      if (response.confirmationRequired) {
        // Redirect to confirmation info page with email as parameter
        navigate(`/confirmation-info?email=${encodeURIComponent(email)}`);
      }
    } catch {
      setSubmitError('Registration failed. Please try again.');
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
                  <h3 className="fw-bold text-forest-600 mb-3">Create a new account</h3>
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
                  
                  <div className="mb-3">
                    <label htmlFor="password" className="form-label">Password</label>
                    <input
                      id="password"
                      name="password"
                      type="password"
                      autoComplete="new-password"
                      required
                      className="form-control"
                      placeholder="Password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                    />
                  </div>
                  
                  <div className="mb-4">
                    <label htmlFor="password-confirmation" className="form-label">Confirm Password</label>
                    <input
                      id="password-confirmation"
                      name="password-confirmation"
                      type="password"
                      autoComplete="new-password"
                      required
                      className="form-control"
                      placeholder="Confirm Password"
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
                      {loading ? 'Creating account...' : 'Sign up'}
                    </button>
                  </div>

                  <div className="text-center">
                    <Link to="/login" className="text-decoration-none">
                      Already have an account? <span className="fw-semibold text-forest-600">Sign in</span>
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

export default Register; 