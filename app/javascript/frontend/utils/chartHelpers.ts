import React from 'react';

// Helper function to get top X entries and combine the rest
export const getTopXAndOthers = (data: { name: string; value: number }[], numTopEntries: number = 9) => {
  // Sort data by value in descending order
  const sortedData = [...data].sort((a, b) => b.value - a.value);
  
  if (sortedData.length <= numTopEntries) return sortedData;

  // Get top X
  const topX = sortedData.slice(0, numTopEntries);
  
  // Get the remaining entries
  const remainingEntries = sortedData.slice(numTopEntries);
  
  // Calculate others value and count
  const othersValue = remainingEntries.reduce((sum, item) => sum + item.value, 0);
  
  return [
    ...topX,
    { 
      name: `Others (${remainingEntries.length})`, 
      value: othersValue,
      isOthers: true // Flag to identify the Others category
    }
  ] as Array<{ name: string; value: number; isOthers?: boolean }>;
};

// Colors for the pie charts - matching the forest green palette
export const CHART_COLORS = [
  '#2c7c57', '#6ba88f', '#9cc7b5', '#c7e0d3', '#e3efe8', 
  '#4a7c68', '#216543', '#1c5237', '#3a8c67', '#5a9c77'
];

// Standardized chart configurations for consistent experience
export const STANDARD_PIE_CHART_CONFIG = {
  cx: "50%",
  cy: "50%",
  labelLine: false,
  outerRadius: "70%", // Responsive percentage-based radius
  fill: "#8884d8",
};

// Mobile-optimized pie chart config (smaller radius for better fit)
export const MOBILE_PIE_CHART_CONFIG = {
  ...STANDARD_PIE_CHART_CONFIG,
  outerRadius: "65%",
};

// Standard legend configuration optimized for both mobile and desktop
export const STANDARD_LEGEND_CONFIG = {
  layout: "horizontal" as const,
  wrapperStyle: {
    paddingTop: "16px",
    width: "100%",
    overflowX: "auto" as const,
    overflowY: "hidden" as const,
    fontSize: "14px"
  }
};

// Mobile-optimized legend config
export const MOBILE_LEGEND_CONFIG = {
  ...STANDARD_LEGEND_CONFIG,
  wrapperStyle: {
    ...STANDARD_LEGEND_CONFIG.wrapperStyle,
    paddingTop: "12px",
    fontSize: "12px"
  }
};

// Hook to detect mobile screen size
export const useIsMobile = () => {
  const [isMobile, setIsMobile] = React.useState(false);

  React.useEffect(() => {
    const checkIsMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };

    checkIsMobile();
    window.addEventListener('resize', checkIsMobile);
    
    return () => window.removeEventListener('resize', checkIsMobile);
  }, []);

  return isMobile;
};

// Get appropriate chart config based on screen size
export const getChartConfig = (isMobile: boolean) => ({
  pieChart: isMobile ? MOBILE_PIE_CHART_CONFIG : STANDARD_PIE_CHART_CONFIG,
  legend: isMobile ? null : STANDARD_LEGEND_CONFIG // Hide legend on mobile
}); 