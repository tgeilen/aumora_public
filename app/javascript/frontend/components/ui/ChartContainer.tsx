import React from 'react';

interface ChartContainerProps {
  children: React.ReactNode;
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

const ChartContainer: React.FC<ChartContainerProps> = ({ 
  children, 
  size = 'md',
  className = ''
}) => {
  // Responsive height classes based on screen size and chart size
  const getHeightClasses = () => {
    const baseClasses = 'chart-container';
    const sizeClasses = {
      sm: 'chart-container-sm',
      md: 'chart-container-md', 
      lg: 'chart-container-lg'
    };
    
    return `${baseClasses} ${sizeClasses[size]} ${className}`;
  };

  return (
    <div className={getHeightClasses()}>
      {children}
    </div>
  );
};

export default ChartContainer; 