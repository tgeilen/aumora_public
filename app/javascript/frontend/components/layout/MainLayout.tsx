import React, { useState, useEffect } from 'react';
import { Outlet } from 'react-router-dom';
import Navbar from './Navbar';
import Sidebar from './Sidebar';

const MainLayout = () => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [isDesktop, setIsDesktop] = useState(false);

  // Initialize sidebar state based on screen size
  useEffect(() => {
    const handleResize = () => {
      const desktop = window.innerWidth >= 992;
      setIsDesktop(desktop);
      
      if (desktop) {
        // Desktop: sidebar always open
        setIsSidebarOpen(true);
      } else {
        // Mobile: sidebar closed by default
        setIsSidebarOpen(false);
      }
    };

    // Set initial state
    handleResize();

    // Listen for window resize
    window.addEventListener('resize', handleResize);
    
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  const toggleSidebar = () => {
    setIsSidebarOpen(!isSidebarOpen);
  };

  const closeSidebar = () => {
    setIsSidebarOpen(false);
  };

  return (
    <div className="min-vh-100 d-flex flex-column bg-light">
      <Navbar onToggleSidebar={toggleSidebar} isSidebarOpen={isSidebarOpen} />
      <div className="d-flex" style={{ marginTop: '56px', height: 'calc(100vh - 56px)' }}>
        {/* Sidebar component */}
        <Sidebar isOpen={isSidebarOpen} onClose={closeSidebar} />
        
        {/* Main content area */}
        <main 
          className="flex-grow-1 overflow-auto"
          style={{
            marginLeft: isDesktop && isSidebarOpen ? '250px' : '0',
            transition: 'margin-left 0.3s ease-in-out',
            padding: '1rem'
          }}
        >
          <div className="container-fluid py-2 px-0">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
};

export default MainLayout; 