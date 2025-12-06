import React from 'react';
import { NavLink } from 'react-router-dom';
import { useState, useRef, useEffect } from 'react';
import { Link } from 'react-router-dom';
import useAuth from '../../hooks/useAuth';
import PrivacyToggle from '../portfolio/PrivacyToggle';

interface NavItem {
  name: string;
  to: string;
  icon: React.ReactNode;
}

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

const navigation: NavItem[] = [
  {
    name: 'Dashboard',
    to: '/',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="bi" width="18" height="18" viewBox="0 0 16 16" fill="currentColor">
        <path d="M8.354 1.146a.5.5 0 0 0-.708 0l-6 6A.5.5 0 0 0 1.5 7.5v7a.5.5 0 0 0 .5.5h4.5a.5.5 0 0 0 .5-.5v-4h2v4a.5.5 0 0 0 .5.5H14a.5.5 0 0 0 .5-.5v-7a.5.5 0 0 0-.146-.354L13 5.793V2.5a.5.5 0 0 0-.5-.5h-1a.5.5 0 0 0-.5.5v1.293L8.354 1.146zM2.5 14V7.707l5.5-5.5 5.5 5.5V14H10v-4a.5.5 0 0 0-.5-.5h-3a.5.5 0 0 0-.5.5v4H2.5z"/>
      </svg>
    ),
  },
  {
    name: 'Portfolios',
    to: '/portfolios',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="bi" width="18" height="18" viewBox="0 0 16 16" fill="currentColor">
        <path d="M2.5 3.5a.5.5 0 0 1 0-1h11a.5.5 0 0 1 0 1h-11zm2-2a.5.5 0 0 1 0-1h7a.5.5 0 0 1 0 1h-7zM0 13a1.5 1.5 0 0 0 1.5 1.5h13A1.5 1.5 0 0 0 16 13V6a1.5 1.5 0 0 0-1.5-1.5h-13A1.5 1.5 0 0 0 0 6v7zm1.5.5A.5.5 0 0 1 1 13V6a.5.5 0 0 1 .5-.5h13a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-.5.5h-13z"/>
      </svg>
    ),
  },
  {
    name: 'ETFs',
    to: '/etfs',
    icon: (
      <svg xmlns="http://www.w3.org/2000/svg" className="bi" width="18" height="18" viewBox="0 0 16 16" fill="currentColor">
        <path d="M0 0h1v15h15v1H0V0Zm14.817 3.113a.5.5 0 0 1 .07.704l-4.5 5.5a.5.5 0 0 1-.74.037L7.06 6.767l-3.656 5.027a.5.5 0 0 1-.808-.588l4-5.5a.5.5 0 0 1 .758-.06l2.609 2.61 4.15-5.073a.5.5 0 0 1 .704-.07Z"/>
      </svg>
    ),
  },
];

const Sidebar: React.FC<SidebarProps> = ({ isOpen, onClose }) => {
  const { user, logout } = useAuth();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const sidebarRef = useRef<HTMLDivElement>(null);

  // Check if mobile on mount and resize
  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 992);
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const toggleDropdown = () => {
    setDropdownOpen(!dropdownOpen);
  };

  const handleSignOut = async () => {
    await logout();
    setDropdownOpen(false);
    onClose();
  };

  const handleNavClick = () => {
    // Close sidebar on mobile when navigation item is clicked
    if (isMobile) {
      onClose();
    }
  };

  // Get the first letter of the user's email
  const getInitial = (email: string): string => {
    return email && email.length > 0 ? email[0].toUpperCase() : '?';
  };

  // Set up click outside listener with proper cleanup
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setDropdownOpen(false);
      }
      
      // Close sidebar on mobile when clicking outside
      if (isMobile && 
          sidebarRef.current && 
          !sidebarRef.current.contains(e.target as Node) && 
          isOpen) {
        onClose();
      }
    };

    // Add event listener
    document.addEventListener('mousedown', handleClickOutside);
    
    // Cleanup function
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen, onClose, isMobile]);

  // Handle escape key to close sidebar on mobile
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen && isMobile) {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen, onClose, isMobile]);

  // Prevent body scroll when mobile sidebar is open
  useEffect(() => {
    if (isMobile) {
      if (isOpen) {
        document.body.style.overflow = 'hidden';
      } else {
        document.body.style.overflow = 'unset';
      }
    }

    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, isMobile]);

  // Calculate sidebar styles based on mobile/desktop
  const sidebarStyles = {
    position: 'fixed' as const,
    top: '56px',
    left: 0,
    width: '250px',
    height: 'calc(100vh - 56px)',
    display: 'flex',
    flexDirection: 'column' as const,
    overflowY: 'hidden' as const,
    backgroundColor: '#f8f9fa', // Light gray background
    borderRight: '1px solid #dee2e6', // Border for definition
    zIndex: isMobile ? 1041 : 1020,
    transform: isOpen ? 'translateX(0)' : (isMobile ? 'translateX(-100%)' : 'translateX(0)'),
    transition: 'transform 0.3s ease-in-out',
    boxShadow: isMobile ? '2px 0 10px rgba(0, 0, 0, 0.1)' : 'none' // Shadow on mobile for depth
  };

  return (
    <>
      {/* Mobile backdrop */}
      {isOpen && isMobile && (
        <div 
          className="position-fixed w-100 h-100"
          style={{ 
            top: '56px',
            left: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            zIndex: 1040
          }}
          onClick={onClose}
        />
      )}
      
      {/* Sidebar */}
      <div 
        ref={sidebarRef}
        className="bg-light border-end"
        style={sidebarStyles}
      >
        {/* Navigation section with scrollable container */}
        <div className="overflow-auto flex-grow-1" style={{ height: 'calc(100% - 120px)' }}>
          <div className="p-3">
            <div className="list-group list-group-flush">
              {navigation.map((item) => (
                <NavLink
                  key={item.name}
                  to={item.to}
                  onClick={handleNavClick}
                  className={({ isActive }) =>
                    `list-group-item list-group-item-action my-1 py-2 border-0 ${
                      isActive
                        ? 'bg-forest-100 text-forest-600 fw-semibold rounded-3'
                        : 'bg-transparent'
                    }`
                  }
                >
                  <div className="d-flex align-items-center">
                    <span className="me-3">{item.icon}</span>
                    {item.name}
                  </div>
                </NavLink>
              ))}
            </div>
          </div>
        </div>
        
        {/* Privacy toggle section */}
        <div className="border-top px-3 py-2 bg-light">
          <PrivacyToggle compact={true} />
        </div>
        
        {/* User management section - fixed at bottom */}
        {user && (
          <div className="border-top position-relative px-3 py-3" 
               ref={dropdownRef} 
               style={{ backgroundColor: '#f8f9fa' }}>
            <div className="card shadow-sm mb-0 py-2">
              <div 
                onClick={toggleDropdown}
                className="card-body d-flex align-items-center justify-content-between py-0 px-0"
                style={{ cursor: 'pointer' }}
              >
                <div className="d-flex align-items-center">
                  <div 
                    className="bg-forest d-flex align-items-center justify-content-center me-3 text-white rounded-circle"
                    style={{ 
                      width: '32px', 
                      height: '32px', 
                      fontSize: '14px',
                      fontWeight: 600
                    }}
                  >
                    {getInitial(user.email)}
                  </div>
                  <div>
                    <div className="text-truncate fw-medium" style={{ maxWidth: "160px", fontSize: "0.9rem" }}>{user.email.split('@')[0]}</div>
                    <div className="text-muted" style={{ fontSize: "0.75rem" }}>Account Settings</div>
                  </div>
                </div>
                <svg 
                  xmlns="http://www.w3.org/2000/svg" 
                  width="14" 
                  height="14" 
                  fill="currentColor" 
                  viewBox="0 0 16 16"
                  className="text-muted ms-2"
                  style={{ transform: dropdownOpen ? 'rotate(180deg)' : 'rotate(0deg)', transition: 'transform 0.2s' }}
                >
                  <path d="M7.247 11.14 2.451 5.658C1.885 5.013 2.345 4 3.204 4h9.592a1 1 0 0 1 .753 1.659l-4.796 5.48a1 1 0 0 1-1.506 0z"/>
                </svg>
              </div>
            </div>
            
            {dropdownOpen && (
              <div className="dropdown-menu shadow show position-absolute" 
                   style={{ bottom: '70px', left: '0', zIndex: 1000, width: '88%', marginLeft: '6%' }}>
                <div className="dropdown-header fw-bold">User Management</div>
                <Link to="/profile" className="dropdown-item py-2" onClick={() => { setDropdownOpen(false); handleNavClick(); }}>
                  Profile
                </Link>
                <Link to="/settings" className="dropdown-item py-2" onClick={() => { setDropdownOpen(false); handleNavClick(); }}>
                  Settings
                </Link>
                <div className="dropdown-divider"></div>
                <button className="dropdown-item py-2 text-danger" onClick={handleSignOut}>
                  Sign Out
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </>
  );
};

export default Sidebar; 