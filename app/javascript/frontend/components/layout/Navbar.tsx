import React from 'react';
import { Link } from 'react-router-dom';
import logoWhite from '../../assets/logos/logo-white-nobg.png';

interface NavbarProps {
  onToggleSidebar: () => void;
  isSidebarOpen: boolean;
}

const Navbar: React.FC<NavbarProps> = ({ onToggleSidebar, isSidebarOpen }) => {
  return (
    <nav className="navbar navbar-expand-lg navbar-forest shadow-sm py-2 fixed-top">
      <div className="container-fluid px-3">
        <div className="d-flex align-items-center w-100">
          {/* Mobile hamburger menu button */}
          <button
            className="btn btn-link text-white d-lg-none p-2 me-3 border-0"
            onClick={onToggleSidebar}
            aria-label="Toggle navigation"
            style={{ fontSize: '1.25rem' }}
          >
            {isSidebarOpen ? (
              // Close icon (X)
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 16 16">
                <path d="M2.146 2.854a.5.5 0 1 1 .708-.708L8 7.293l5.146-5.147a.5.5 0 0 1 .708.708L8.707 8l5.147 5.146a.5.5 0 0 1-.708.708L8 8.707l-5.146 5.147a.5.5 0 0 1-.708-.708L7.293 8 2.146 2.854Z"/>
              </svg>
            ) : (
              // Hamburger icon
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 16 16">
                <path fillRule="evenodd" d="M2.5 12a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5z"/>
              </svg>
            )}
          </button>

          {/* Logo - centered on mobile, left-aligned on desktop */}
          <Link 
            to="/" 
            className="navbar-brand d-flex align-items-center"
            style={{ 
              margin: 0,
              padding: 0
            }}
          >
            <img 
              src={logoWhite} 
              alt="Aumora Logo" 
              height="40" 
              className="d-inline-block align-text-top"
            />
          </Link>

          {/* Spacer for mobile to help center the logo */}
          <div className="d-lg-none" style={{ width: '56px' }}></div>
        </div>
      </div>
    </nav>
  );
};

export default Navbar; 