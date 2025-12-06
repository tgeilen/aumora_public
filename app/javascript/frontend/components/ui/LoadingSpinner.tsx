import React from 'react';

interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg';
  color?: 'primary' | 'secondary' | 'success' | 'danger' | 'warning' | 'info' | 'light' | 'dark' | 'forest';
  text?: string;
  fullPage?: boolean;
}

const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({
  size = 'md',
  color = 'forest',
  text = 'Loading...',
  fullPage = false
}) => {
  // Map size to Bootstrap spinner size
  const spinnerSize = {
    sm: '',
    md: 'spinner-border-md',
    lg: 'spinner-border-lg'
  }[size];

  // Map color to Bootstrap/custom color
  const spinnerColor = `text-${color}`;

  // Full page loading layout
  if (fullPage) {
    return (
      <div className="position-fixed top-0 start-0 w-100 h-100 d-flex justify-content-center align-items-center bg-white bg-opacity-75" style={{ zIndex: 1050 }}>
        <div className="text-center">
          <div className={`spinner-border ${spinnerSize} ${spinnerColor}`} role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
          {text && <p className="mt-3 text-forest-600 fw-semibold">{text}</p>}
        </div>
      </div>
    );
  }

  // Regular loading spinner
  return (
    <div className="d-flex flex-column align-items-center justify-content-center py-4">
      <div className={`spinner-border ${spinnerSize} ${spinnerColor}`} role="status">
        <span className="visually-hidden">Loading...</span>
      </div>
      {text && <p className="mt-2 text-forest-600">{text}</p>}
    </div>
  );
};

export default LoadingSpinner; 