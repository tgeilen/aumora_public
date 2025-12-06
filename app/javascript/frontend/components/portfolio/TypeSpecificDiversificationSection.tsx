import React from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import { CHART_COLORS, useIsMobile, getChartConfig } from '../../utils/chartHelpers';
import LoadingSpinner from '../ui/LoadingSpinner';
import ChartContainer from '../ui/ChartContainer';

interface DiversificationData {
  name: string;
  value: number;
  isOthers?: boolean;
}

interface TypeSpecificDiversificationSectionProps {
  investmentType: 'total' | 'etfs' | 'assets';
  top5IndustryData: DiversificationData[];
  top5CountryData: DiversificationData[];
  isLoading: boolean;
}

const TypeSpecificDiversificationSection: React.FC<TypeSpecificDiversificationSectionProps> = ({
  investmentType,
  top5IndustryData,
  top5CountryData,
  isLoading
}) => {
  // Responsive chart configuration
  const isMobile = useIsMobile();
  const chartConfig = getChartConfig(isMobile);

  const getTitle = () => {
    switch (investmentType) {
      case 'total': return 'Total Portfolio';
      case 'etfs': return 'ETF';
      case 'assets': return 'Direct Asset';
      default: return '';
    }
  };

  const title = getTitle();

  return (
    <div className="row g-4 mb-4">
      {/* Industry breakdown chart */}
      <div className="col-12 col-lg-6">
        <div className="card card-forest h-100">
          <div className="card-body p-3 p-md-4">
            <h5 className="card-title mb-4 fw-bold text-forest-600">{title} Industry Breakdown</h5>
            {!isLoading && top5IndustryData.length > 0 ? (
              <ChartContainer size="md">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={top5IndustryData}
                      {...chartConfig.pieChart}
                      labelLine={true}
                      dataKey="value"
                    >
                      {top5IndustryData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip 
                      formatter={(value: number) => `${(value * 100).toFixed(2)}%`}
                      labelFormatter={(label) => `${label}`}
                    />
                    {chartConfig.legend && (
                      <Legend 
                        formatter={(value, entry) => {
                          const payload = (entry as { payload: { value: number; isOthers?: boolean } }).payload;
                          const percentage = (payload.value * 100).toFixed(1);
                          return `${value} (${percentage}%)`;
                        }}
                        {...chartConfig.legend}
                      />
                    )}
                  </PieChart>
                </ResponsiveContainer>
              </ChartContainer>
            ) : (
              <div className="d-flex align-items-center justify-content-center py-5">
                {isLoading ? (
                  <LoadingSpinner size="sm" text="Loading industry data..." />
                ) : (
                  <span className="text-muted">No industry data available</span>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Country breakdown chart */}
      <div className="col-12 col-lg-6">
        <div className="card card-forest h-100">
          <div className="card-body p-3 p-md-4">
            <h5 className="card-title mb-4 fw-bold text-forest-600">{title} Country Breakdown</h5>
            {!isLoading && top5CountryData.length > 0 ? (
              <ChartContainer size="md">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={top5CountryData}
                      {...chartConfig.pieChart}
                      labelLine={true}
                      dataKey="value"
                    >
                      {top5CountryData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip 
                      formatter={(value: number) => `${(value * 100).toFixed(2)}%`}
                      labelFormatter={(label) => `${label}`}
                    />
                    {chartConfig.legend && (
                      <Legend 
                        formatter={(value, entry) => {
                          const payload = (entry as { payload: { value: number; isOthers?: boolean } }).payload;
                          const percentage = (payload.value * 100).toFixed(1);
                          return `${value} (${percentage}%)`;
                        }}
                        {...chartConfig.legend}
                      />
                    )}
                  </PieChart>
                </ResponsiveContainer>
              </ChartContainer>
            ) : (
              <div className="d-flex align-items-center justify-content-center py-5">
                {isLoading ? (
                  <LoadingSpinner size="sm" text="Loading country data..." />
                ) : (
                  <span className="text-muted">No country data available</span>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default TypeSpecificDiversificationSection; 