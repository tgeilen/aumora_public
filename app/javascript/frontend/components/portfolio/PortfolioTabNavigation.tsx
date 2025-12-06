import React from 'react';

interface PortfolioTabNavigationProps {
  activeTab: 'total' | 'etfs' | 'assets';
  setActiveTab: (tab: 'total' | 'etfs' | 'assets') => void;
}

const PortfolioTabNavigation: React.FC<PortfolioTabNavigationProps> = ({ 
  activeTab, 
  setActiveTab 
}) => {
  const styles = {
    navLinkActive: {
      fontWeight: 'bold',
      color: 'var(--bs-forest-500)',
      backgroundColor: 'var(--bs-forest-50)',
      
      
    },
  };

  return (
    <ul className="nav nav-tabs nav-fill mb-4">
      <li className="nav-item">
        <button 
          className={`nav-link ${activeTab === 'total' ? 'active nav-link-active' : ''}`} 
          style={activeTab === 'total' ? styles.navLinkActive : {}}
          onClick={() => setActiveTab('total')}
        >
          Total Portfolio
        </button>
      </li>
      <li className="nav-item">
        <button 
          className={`nav-link ${activeTab === 'etfs' ? 'active nav-link-active' : ''}`} 
          style={activeTab === 'etfs' ? styles.navLinkActive : {}}
          onClick={() => setActiveTab('etfs')}
        >
          ETF Investments
        </button>
      </li>
      <li className="nav-item">
        <button 
          className={`nav-link ${activeTab === 'assets' ? 'active nav-link-active' : ''}`} 
          style={activeTab === 'assets' ? styles.navLinkActive : {}}
          onClick={() => setActiveTab('assets')}
        >
          Direct Investments
        </button>
      </li>
    </ul>
  );
};

export default PortfolioTabNavigation; 