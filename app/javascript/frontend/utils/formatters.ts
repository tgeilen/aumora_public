/**
 * Format currency value - if in private mode, shows *** instead of the actual value
 */
export const formatCurrency = (
  value: number, 
  isPrivateMode: boolean, 
  options: Intl.NumberFormatOptions = { minimumFractionDigits: 2, maximumFractionDigits: 2 }
): string => {
  if (isPrivateMode) {
    return '***';
  }
  return `$${value.toLocaleString('en-US', options)}`;
};

/**
 * Format number - if in private mode, shows *** instead of the actual value
 */
export const formatNumber = (
  value: number, 
  isPrivateMode: boolean,
  options: Intl.NumberFormatOptions = { minimumFractionDigits: 2, maximumFractionDigits: 2 }
): string => {
  if (isPrivateMode) {
    return '***';
  }
  return value.toLocaleString('en-US', options);
};

/**
 * Format percentage - always visible regardless of private mode
 */
export const formatPercentage = (
  value: number,
  options: Intl.NumberFormatOptions = { minimumFractionDigits: 1, maximumFractionDigits: 1 }
): string => {
  return `${value.toLocaleString('en-US', options)}%`;
}; 