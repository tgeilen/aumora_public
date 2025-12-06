import { useMemo } from 'react';
import { Portfolio } from '../services/portfolio';

interface AllocationData {
  name: string;
  value: number;
  fullName: string;
}

export const usePortfolioData = (portfolio: Portfolio | undefined) => {
  // Calculate allocation data for charts
  const etfAllocationData = useMemo(() => {
    if (!portfolio?.entries) return [];
    
    return portfolio.entries.map(entry => {
      // Use current_value if available (calculated by backend), otherwise calculate manually
      const value = entry.current_value || (entry.shares * (entry.current_price || entry.purchase_price || 0));
      return {
        name: entry.etf.ticker,
        value: value,
        fullName: entry.etf.name
      };
    });
  }, [portfolio?.entries]);

  // Calculate allocation data for assets
  const assetAllocationData = useMemo(() => {
    if (!portfolio?.asset_entries) return [];
    
    return portfolio.asset_entries.map(entry => {
      // Use current_value if available (calculated by backend), otherwise calculate manually
      const value = entry.current_value || (entry.shares * (entry.current_price || entry.purchase_price || 0));
      return {
        name: entry.asset.identifier,
        value: value,
        fullName: entry.asset.name
      };
    });
  }, [portfolio?.asset_entries]);

  // Calculate total portfolio value
  const totalEtfValue = useMemo(() => 
    etfAllocationData.reduce((sum, item) => sum + item.value, 0),
  [etfAllocationData]);
  
  const totalAssetValue = useMemo(() => 
    assetAllocationData.reduce((sum, item) => sum + item.value, 0),
  [assetAllocationData]);
  
  const totalPortfolioValue = useMemo(() => 
    totalEtfValue + totalAssetValue,
  [totalEtfValue, totalAssetValue]);

  return {
    etfAllocationData,
    assetAllocationData,
    totalEtfValue,
    totalAssetValue,
    totalPortfolioValue
  };
}; 