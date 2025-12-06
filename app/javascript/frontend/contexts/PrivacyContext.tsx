import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';

interface PrivacyContextType {
  isPrivateMode: boolean;
  togglePrivateMode: () => void;
}

const PrivacyContext = createContext<PrivacyContextType | undefined>(undefined);

// Key for localStorage
const PRIVACY_MODE_KEY = 'aumora_privacy_mode';

// Helper function to get initial privacy mode state from localStorage
const getInitialPrivacyMode = (): boolean => {
  if (typeof window === 'undefined') {
    return false; // Default for SSR
  }
  
  try {
    const stored = localStorage.getItem(PRIVACY_MODE_KEY);
    return stored ? JSON.parse(stored) : false;
  } catch (error) {
    console.warn('Failed to parse privacy mode from localStorage:', error);
    return false;
  }
};

export const PrivacyProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [isPrivateMode, setIsPrivateMode] = useState(getInitialPrivacyMode);

  // Update localStorage whenever privacy mode changes
  useEffect(() => {
    try {
      localStorage.setItem(PRIVACY_MODE_KEY, JSON.stringify(isPrivateMode));
    } catch (error) {
      console.warn('Failed to save privacy mode to localStorage:', error);
    }
  }, [isPrivateMode]);

  const togglePrivateMode = () => {
    setIsPrivateMode(prev => !prev);
  };

  return (
    <PrivacyContext.Provider value={{ isPrivateMode, togglePrivateMode }}>
      {children}
    </PrivacyContext.Provider>
  );
};

export const usePrivacy = (): PrivacyContextType => {
  const context = useContext(PrivacyContext);
  if (context === undefined) {
    throw new Error('usePrivacy must be used within a PrivacyProvider');
  }
  return context;
}; 