import React from 'react';
import { useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import portfolioService from '../services/portfolio';
import { getTopXAndOthers, CHART_COLORS, useIsMobile, getChartConfig } from '../utils/chartHelpers';
import ChartContainer from '../components/ui/ChartContainer';

const ETFDetail = () => {
  const { id } = useParams<{ id: string }>();
  const etfId = parseInt(id || '0', 10);
  
  // Responsive chart configuration
  const isMobile = useIsMobile();
  const chartConfig = getChartConfig(isMobile);

  // Fetch ETF details
  const {
    data: etf,
    isLoading: etfLoading,
    error: etfError
  } = useQuery({
    queryKey: ['etf', etfId],
    queryFn: () => portfolioService.getETF(etfId),
    enabled: !!etfId,
  });

  // Fetch ETF holdings
  const {
    data: holdings,
    isLoading: holdingsLoading,
    error: holdingsError
  } = useQuery({
    queryKey: ['etf-holdings', etfId],
    queryFn: () => portfolioService.getETFHoldings(etfId),
    enabled: !!etfId,
  });

  // Safely handle holdings data
  const safeHoldings = holdings || [];

  // Prepare data for industry pie chart
  const industryData = safeHoldings.length > 0 ? 
    Object.entries(
      safeHoldings.reduce((acc, holding) => {
        if (holding && holding.industry) {
          // Ensure weight is a number
          const weight = typeof holding.weight === 'number' ? holding.weight : parseFloat(holding.weight) || 0;
          acc[holding.industry] = (acc[holding.industry] || 0) + weight;
        }
        return acc;
      }, {} as Record<string, number>)
    ).map(([name, value]) => ({ name, value }))
    : [];

  const top3IndustryData = getTopXAndOthers(industryData, 5);

  // Prepare data for country pie chart
  const countryData = safeHoldings.length > 0 ? 
    Object.entries(
      safeHoldings.reduce((acc, holding) => {
        if (holding && holding.country) {
          // Ensure weight is a number
          const weight = typeof holding.weight === 'number' ? holding.weight : parseFloat(holding.weight) || 0;
          acc[holding.country] = (acc[holding.country] || 0) + weight;
        }
        return acc;
      }, {} as Record<string, number>)
    ).map(([name, value]) => ({ name, value }))
    : [];

  const top3CountryData = getTopXAndOthers(countryData, 5);

  // Loading state
  if (etfLoading || holdingsLoading) {
    return <div className="text-center p-4">Loading ETF details...</div>;
  }

  // Error state
  if (etfError || holdingsError || !etf) {
    return <div className="text-center p-4 text-danger">Error loading ETF data</div>;
  }

  return (
    <div className="container-fluid py-4">
      <div className="card card-forest mb-4">
        <div className="card-body">
          <div className="row align-items-center">
            <div className="col-md-8">
              <h1 className="display-6 fw-bold text-forest-600 mb-1">{etf?.ticker || 'Unknown Ticker'}</h1>
              <p className="fs-5 text-secondary mb-0">{etf?.name || 'Unknown Name'}</p>
            </div>
            <div className="col-md-4 text-md-end mt-3 mt-md-0">
              <div className="text-secondary">
                <div className="mb-1">Provider: <span className="fw-medium">{etf?.provider?.name || 'Unknown Provider'}</span></div>
                <div>Last updated: <span className="fw-medium">{etf?.last_updated_at ? new Date(etf.last_updated_at).toLocaleDateString() : '-'}</span></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="row g-4 mb-4">
        {/* Industry breakdown chart */}
        <div className="col-md-6">
          <div className="card card-forest h-100">
            <div className="card-body">
              <h5 className="card-title mb-4 fw-bold text-forest-600">Industry Breakdown</h5>
              {industryData.length > 0 ? (
                <ChartContainer size="md">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={top3IndustryData}
                        {...chartConfig.pieChart}
                        dataKey="value"
                      >
                        {top3IndustryData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip formatter={(value) => `${((value as number) * 100).toFixed(2)}%`} />
                      {chartConfig.legend && (
                        <Legend 
                          formatter={(value, entry) => {
                            const payload = (entry as { payload: { value: number; isOthers?: boolean } }).payload;
                            const percentage = (payload.value * 100).toFixed(1);
                            // If it's the Others category, the count is already in the name
                            return `${value} (${percentage}%)`;
                          }}
                          {...chartConfig.legend}
                        />
                      )}
                    </PieChart>
                  </ResponsiveContainer>
                </ChartContainer>
              ) : (
                <div className="d-flex align-items-center justify-content-center h-100 text-muted">
                  No industry data available
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Country breakdown chart */}
        <div className="col-md-6">
          <div className="card card-forest h-100">
            <div className="card-body">
              <h5 className="card-title mb-4 fw-bold text-forest-600">Country Breakdown</h5>
              {countryData.length > 0 ? (
                <ChartContainer size="md">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={top3CountryData}
                        {...chartConfig.pieChart}
                        dataKey="value"
                      >
                        {top3CountryData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip formatter={(value) => `${((value as number) * 100).toFixed(2)}%`} />
                      {chartConfig.legend && (
                        <Legend 
                          formatter={(value, entry) => {
                            const payload = (entry as { payload: { value: number; isOthers?: boolean } }).payload;
                            const percentage = (payload.value * 100).toFixed(1);
                            // If it's the Others category, the count is already in the name
                            return `${value} (${percentage}%)`;
                          }}
                          {...chartConfig.legend}
                        />
                      )}
                    </PieChart>
                  </ResponsiveContainer>
                </ChartContainer>
              ) : (
                <div className="d-flex align-items-center justify-content-center h-100 text-muted">
                  No country data available
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="card card-forest mb-4">
        <div className="card-header bg-white py-3">
          <h5 className="mb-0 fw-bold fs-4 text-forest-600">Holdings</h5>
        </div>
        {safeHoldings && safeHoldings.length > 0 ? (
          <div className="table-responsive">
            <table className="table table-hover table-striped align-middle mb-0">
              <thead className="table-light">
                <tr>
                  <th scope="col" className="border-bottom border-2" style={{ borderColor: 'var(--bs-forest-200) !important', width: '25%' }}>
                    <div className="text-uppercase small fw-semibold text-secondary">Asset</div>
                  </th>
                  <th scope="col" className="border-bottom border-2" style={{ borderColor: 'var(--bs-forest-200) !important', width: '15%' }}>
                    <div className="text-uppercase small fw-semibold text-secondary">Type</div>
                  </th>
                  <th scope="col" className="border-bottom border-2" style={{ borderColor: 'var(--bs-forest-200) !important', width: '15%' }}>
                    <div className="text-uppercase small fw-semibold text-secondary">Weight</div>
                  </th>
                  <th scope="col" className="border-bottom border-2" style={{ borderColor: 'var(--bs-forest-200) !important', width: '20%' }}>
                    <div className="text-uppercase small fw-semibold text-secondary">Industry</div>
                  </th>
                  <th scope="col" className="border-bottom border-2" style={{ borderColor: 'var(--bs-forest-200) !important', width: '25%' }}>
                    <div className="text-uppercase small fw-semibold text-secondary">Country</div>
                  </th>
                </tr>
              </thead>
              <tbody>
                {safeHoldings.map((holding) => (
                  <tr key={holding.id}>
                    <td>
                      <div className="fw-semibold">{holding.asset_identifier}</div>
                      <div className="small text-secondary">{holding.asset_name}</div>
                    </td>
                    <td>{holding.asset_type || <span className="text-muted fst-italic small">-</span>}</td>
                    <td>
                      <span className="badge bg-forest-100 text-forest-700 fw-semibold px-2 py-1 border border-forest-200">
                        {typeof holding.weight === 'number' 
                          ? (holding.weight * 100).toFixed(3)
                          : (parseFloat(holding.weight)*100 || 0).toFixed(3)}%
                      </span>
                    </td>
                    <td>
                      {holding.industry ? (
                        <span className="badge bg-forest-200 text-forest-800 fw-semibold px-2 py-1 border border-forest-300">
                          {holding.industry}
                        </span>
                      ) : <span className="text-muted fst-italic small">-</span>}
                    </td>
                    <td>
                      {holding.country ? (
                        <span className="badge bg-forest-50 text-forest-700 fw-semibold px-2 py-1 border border-forest-200">
                          {holding.country}
                        </span>
                      ) : <span className="text-muted fst-italic small">-</span>}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="p-5 text-center text-muted">
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" fill="currentColor" className="bi bi-table text-forest-300 mb-3" viewBox="0 0 16 16">
              <path d="M0 2a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V2zm15 2h-4v3h4V4zm0 4h-4v3h4V8zm0 4h-4v3h3a1 1 0 0 0 1-1v-2zm-5 3v-3H6v3h4zm-5 0v-3H1v2a1 1 0 0 0 1 1h3zm-4-4h4V8H1v3zm0-4h4V4H1v3zm5-3v3h4V4H6zm4 4H6v3h4V8z"/>
            </svg>
            <h4>No holdings data available for this ETF</h4>
          </div>
        )}
      </div>
    </div>
  );
};

export default ETFDetail; 