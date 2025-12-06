import React from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import { CHART_COLORS } from '../../utils/chartHelpers';

interface DiversificationData {
  name: string;
  value: number;
  isOthers?: boolean;
}

interface PortfolioDiversificationSectionProps {
  top5IndustryData: DiversificationData[];
  top5CountryData: DiversificationData[];
  holdingsBreakdownLoading: boolean;
}

const PortfolioDiversificationSection: React.FC<PortfolioDiversificationSectionProps> = ({
  top5IndustryData,
  top5CountryData,
  holdingsBreakdownLoading
}) => {
  return (
    <div className="row g-4 mb-4">
      {/* Industry breakdown chart */}
      <div className="col-12 col-lg-6">
        <div className="card card-forest h-100">
          <div className="card-body p-3 p-md-4">
            <h5 className="card-title mb-4 fw-bold text-forest-600">Industry Breakdown</h5>
            {!holdingsBreakdownLoading && top5IndustryData.length > 0 ? (
              <div style={{ height: "350px", minHeight: "300px" }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={top5IndustryData}
                      cx="50%"
                      cy="50%"
                      labelLine={true}
                      outerRadius="80%"
                      fill="#8884d8"
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
                    <Legend 
                      formatter={(value, entry) => {
                        const payload = (entry as { payload: { value: number; isOthers?: boolean } }).payload;
                        const percentage = (payload.value * 100).toFixed(1);
                        return `${value} (${percentage}%)`;
                      }}
                      layout="horizontal"
                      wrapperStyle={{
                        paddingTop: "20px",
                        width: "100%",
                        overflowX: "auto",
                        overflowY: "hidden"
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            ) : (
              <div className="d-flex align-items-center justify-content-center py-5 text-muted">
                {holdingsBreakdownLoading ? 'Loading...' : 'No industry data available'}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Country breakdown chart */}
      <div className="col-12 col-lg-6">
        <div className="card card-forest h-100">
          <div className="card-body p-3 p-md-4">
            <h5 className="card-title mb-4 fw-bold text-forest-600">Country Breakdown</h5>
            {!holdingsBreakdownLoading && top5CountryData.length > 0 ? (
              <div style={{ height: "350px", minHeight: "300px" }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={top5CountryData}
                      cx="50%"
                      cy="50%"
                      labelLine={true}
                      outerRadius="80%"
                      fill="#8884d8"
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
                    <Legend 
                      formatter={(value, entry) => {
                        const payload = (entry as { payload: { value: number; isOthers?: boolean } }).payload;
                        const percentage = (payload.value * 100).toFixed(1);
                        return `${value} (${percentage}%)`;
                      }}
                      layout="horizontal"
                      wrapperStyle={{
                        paddingTop: "20px",
                        width: "100%",
                        overflowX: "auto",
                        overflowY: "hidden"
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            ) : (
              <div className="d-flex align-items-center justify-content-center py-5 text-muted">
                {holdingsBreakdownLoading ? 'Loading...' : 'No country data available'}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default PortfolioDiversificationSection; 