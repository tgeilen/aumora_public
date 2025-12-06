import React, { useState } from 'react';
import { useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import portfolioService, { PortfolioHoldingsBreakdown } from '../services/portfolio';
import { getTopXAndOthers, CHART_COLORS, useIsMobile, getChartConfig } from '../utils/chartHelpers';
import { useETFManagement } from '../hooks/useETFManagement';
import { useAssetManagement } from '../hooks/useAssetManagement';
import { usePortfolioData } from '../hooks/usePortfolioData';
import { usePrivacy } from '../contexts/PrivacyContext';
import { formatCurrency, formatPercentage } from '../utils/formatters';

// Components
import PortfolioHeader from '../components/portfolio/PortfolioHeader';
import PortfolioTabNavigation from '../components/portfolio/PortfolioTabNavigation';
import ETFInvestmentsSection from '../components/portfolio/ETFInvestmentsSection';
import DirectInvestmentsSection from '../components/portfolio/DirectInvestmentsSection';
import TypeSpecificDiversificationSection from '../components/portfolio/TypeSpecificDiversificationSection';
import TotalExposureSection from '../components/portfolio/TotalExposureSection';
import LoadingSpinner from '../components/ui/LoadingSpinner';
import ChartContainer from '../components/ui/ChartContainer';

const PortfolioDetail = () => {
  const { id } = useParams<{ id: string }>();
  const portfolioId = parseInt(id || '0', 10);
  const { isPrivateMode } = usePrivacy();

  // Responsive chart configuration
  const isMobile = useIsMobile();
  const chartConfig = getChartConfig(isMobile);

  // View state
  const [activeTab, setActiveTab] = useState<'total' | 'etfs' | 'assets'>('total');

  // ETF management hook
  const etfManagement = useETFManagement(portfolioId);

  // Asset management hook
  const assetManagement = useAssetManagement(portfolioId);

  // Fetch portfolio details
  const { 
    data: portfolio, 
    isLoading: portfolioLoading, 
    error: portfolioError
  } = useQuery({
    queryKey: ['portfolio', portfolioId],
    queryFn: () => portfolioService.getPortfolio(portfolioId),
    enabled: !!portfolioId,
  });

  // Fetch available ETFs for dropdown
  const {
    data: etfs,
    isLoading: etfsLoading,
    error: etfsError
  } = useQuery({
    queryKey: ['etfs'],
    queryFn: () => portfolioService.getETFs(),
  });
  
  // Fetch combined portfolio holdings breakdown
  const {
    data: combinedHoldingsBreakdown,
    isLoading: combinedHoldingsBreakdownLoading,
    error: combinedHoldingsBreakdownError
  } = useQuery({
    queryKey: ['portfolio-holdings-breakdown', portfolioId],
    queryFn: () => portfolioService.getPortfolioHoldingsBreakdown(portfolioId),
    enabled: !!portfolioId,
  });

  // Fetch ETF-specific portfolio holdings breakdown
  const {
    data: etfHoldingsBreakdown,
    isLoading: etfHoldingsBreakdownLoading,
    error: etfHoldingsBreakdownError
  } = useQuery({
    queryKey: ['portfolio-etf-holdings-breakdown', portfolioId],
    queryFn: () => portfolioService.getPortfolioETFHoldingsBreakdown(portfolioId),
    enabled: !!portfolioId,
  });

  // Fetch asset-specific portfolio holdings breakdown
  const {
    data: assetHoldingsBreakdown,
    isLoading: assetHoldingsBreakdownLoading,
    error: assetHoldingsBreakdownError
  } = useQuery({
    queryKey: ['portfolio-asset-holdings-breakdown', portfolioId],
    queryFn: () => portfolioService.getPortfolioAssetHoldingsBreakdown(portfolioId),
    enabled: !!portfolioId,
  });

  // Fetch total securities exposure (direct + via ETFs)
  const {
    data: totalExposureData,
    isLoading: totalExposureLoading,
    error: totalExposureError
  } = useQuery({
    queryKey: ['portfolio-total-exposure', portfolioId],
    queryFn: () => portfolioService.getPortfolioTotalExposure(portfolioId),
    enabled: !!portfolioId && activeTab === 'total',
  });

  // Fetch available assets for dropdown
  const {
    data: assets,
    isLoading: assetsLoading,
    error: assetsError
  } = useQuery({
    queryKey: ['assets'],
    queryFn: () => portfolioService.getAssets(),
  });

  // Use the portfolio data hook to calculate values
  const {
    etfAllocationData,
    assetAllocationData,
    totalEtfValue,
    totalAssetValue,
    totalPortfolioValue
  } = usePortfolioData(portfolio);

  // Prepare data for combined industry and country charts
  const transformBreakdownData = (breakdown: PortfolioHoldingsBreakdown | undefined) => {
    // Add debug logging
    console.log('Holdings breakdown data:', breakdown);
    
    if (!breakdown) {
      console.log('No breakdown data available');
      return { industryData: [], countryData: [] };
    }
    
    // Convert objects to arrays with name-value pairs
    const industries = breakdown.industries ? 
      Object.entries(breakdown.industries).map(([name, value]) => ({
        name,
        value: typeof value === 'number' ? value : Number(value)
      })) : [];

    const countries = breakdown.countries ? 
      Object.entries(breakdown.countries).map(([name, value]) => ({
        name,
        value: typeof value === 'number' ? value : Number(value)
      })) : [];

    // Log the extracted arrays
    console.log('Industries array:', industries);
    console.log('Countries array:', countries);

    const industryData = getTopXAndOthers(industries);
    const countryData = getTopXAndOthers(countries);

    // Log the transformed data
    console.log('Transformed industry data:', industryData);
    console.log('Transformed country data:', countryData);

    return { industryData, countryData };
  };

  // Transform Combined breakdown data for Total view
  const { 
    industryData: combinedIndustryData, 
    countryData: combinedCountryData 
  } = transformBreakdownData(combinedHoldingsBreakdown);

  // Transform ETF breakdown data
  const { 
    industryData: etfIndustryData, 
    countryData: etfCountryData 
  } = transformBreakdownData(etfHoldingsBreakdown);

  // Transform Asset breakdown data
  const { 
    industryData: assetIndustryData, 
    countryData: assetCountryData 
  } = transformBreakdownData(assetHoldingsBreakdown);

  // Determine if loading based on active tab
  const isLoading = 
    portfolioLoading || 
    etfsLoading || 
    assetsLoading || 
    (activeTab === 'total' && (combinedHoldingsBreakdownLoading || totalExposureLoading)) ||
    (activeTab === 'etfs' && etfHoldingsBreakdownLoading) || 
    (activeTab === 'assets' && assetHoldingsBreakdownLoading);

  // Determine if error based on active tab
  const hasError =
    !!portfolioError || 
    !!etfsError || 
    !!assetsError || 
    !portfolio || 
    (activeTab === 'total' && (!!combinedHoldingsBreakdownError || !!totalExposureError)) ||
    (activeTab === 'etfs' && !!etfHoldingsBreakdownError) || 
    (activeTab === 'assets' && !!assetHoldingsBreakdownError);

  if (isLoading) {
    return (
      <LoadingSpinner 
        size="lg" 
        color="forest" 
        text={`Loading ${activeTab === 'total' ? 'portfolio' : activeTab === 'etfs' ? 'ETF' : 'asset'} data...`}
      />
    );
  }

  if (hasError) {
    return <div className="text-center p-4 text-red-500">Error loading portfolio data</div>;
  }

  return (
    <div className="container-fluid py-4">
      {/* Portfolio header */}
      <PortfolioHeader 
        portfolio={portfolio} 
        totalPortfolioValue={totalPortfolioValue} 
      />

      {/* Investment type tabs */}
      <PortfolioTabNavigation
        activeTab={activeTab}
        setActiveTab={setActiveTab}
      />

      {/* Total Portfolio View */}
      {activeTab === 'total' && (
        <>
          <div className="row g-4 mb-4">
            <div className="col-12 col-md-6">
              <div className="card card-forest h-100">
                <div className="card-body p-3 p-md-4">
                  <h5 className="card-title mb-3 fw-bold text-forest-600">Portfolio Summary</h5>
                  <div className="d-flex flex-column gap-2">
                    <div className="d-flex justify-content-between">
                      <span>ETF Investments:</span>
                      <span className="fw-bold">{formatCurrency(totalEtfValue, isPrivateMode)}</span>
                    </div>
                    <div className="d-flex justify-content-between">
                      <span>Direct Investments:</span>
                      <span className="fw-bold">{formatCurrency(totalAssetValue, isPrivateMode)}</span>
                    </div>
                    <hr className="my-2" />
                    <div className="d-flex justify-content-between">
                      <span>Total Value:</span>
                      <span className="fw-bold">{formatCurrency(totalPortfolioValue, isPrivateMode)}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div className="col-12 col-md-6">
              <div className="card card-forest h-100">
                <div className="card-body p-3 p-md-4">
                  <h5 className="card-title mb-3 fw-bold text-forest-600">Asset Allocation</h5>
                  {totalPortfolioValue > 0 ? (
                    <ChartContainer size="sm">
                      <ResponsiveContainer width="100%" height="100%">
                        <PieChart>
                          <Pie
                            data={[
                              { name: 'ETFs', value: totalEtfValue },
                              { name: 'Direct Assets', value: totalAssetValue }
                            ]}
                            {...chartConfig.pieChart}
                            dataKey="value"
                          >
                            {[0, 1].map((index) => (
                              <Cell key={`cell-${index}`} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                            ))}
                          </Pie>
                          <Tooltip 
                            formatter={(value) => {
                              const percentage = ((value as number) / totalPortfolioValue * 100).toFixed(1);
                              return isPrivateMode 
                                ? [`${percentage}%`, 'Allocation'] 
                                : [(value==totalEtfValue? 'ETF: ': 'Direct Assets: ') + `${formatCurrency(value as number, false)} (${percentage}%)`];
                            }}
                          />
                          {chartConfig.legend && (
                            <Legend 
                              formatter={(value) => {
                                const percentage = 
                                  value === 'ETFs' 
                                    ? ((totalEtfValue / totalPortfolioValue) * 100).toFixed(1) 
                                    : ((totalAssetValue / totalPortfolioValue) * 100).toFixed(1);
                                return `${value} (${percentage}%)`;
                              }}
                              {...chartConfig.legend}
                            />
                          )}
                        </PieChart>
                      </ResponsiveContainer>
                    </ChartContainer>
                  ) : (
                    <div className="d-flex flex-column gap-2">
                      <div className="d-flex justify-content-between">
                        <span>ETFs:</span>
                        <span className="fw-bold">{((totalEtfValue / totalPortfolioValue) * 100).toFixed(1)}%</span>
                      </div>
                      <div className="d-flex justify-content-between">
                        <span>Direct Assets:</span>
                        <span className="fw-bold">{((totalAssetValue / totalPortfolioValue) * 100).toFixed(1)}%</span>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
          <TypeSpecificDiversificationSection
            investmentType="total"
            top5IndustryData={combinedIndustryData}
            top5CountryData={combinedCountryData}
            isLoading={combinedHoldingsBreakdownLoading}
          />
          <TotalExposureSection 
            exposureData={totalExposureData}
            isLoading={totalExposureLoading}
          />
        </>
      )}

      {/* ETF investments section */}
      {activeTab === 'etfs' && (
        <>
          <ETFInvestmentsSection
            portfolio={portfolio}
            etfs={etfs}
            totalEtfValue={totalEtfValue}
            etfAllocationData={etfAllocationData}
            {...etfManagement}
          />
          <TypeSpecificDiversificationSection
            investmentType="etfs"
            top5IndustryData={etfIndustryData}
            top5CountryData={etfCountryData}
            isLoading={etfHoldingsBreakdownLoading}
          />
        </>
      )}

      {/* Direct asset investments section */}
      {activeTab === 'assets' && (
        <>
          <DirectInvestmentsSection
            portfolio={portfolio}
            assets={assets}
            totalAssetValue={totalAssetValue}
            assetAllocationData={assetAllocationData}
            {...assetManagement}
          />
          <TypeSpecificDiversificationSection
            investmentType="assets"
            top5IndustryData={assetIndustryData}
            top5CountryData={assetCountryData}
            isLoading={assetHoldingsBreakdownLoading}
          />
        </>
      )}
    </div>
  );
};

export default PortfolioDetail; 