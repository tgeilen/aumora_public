import React, { useState } from 'react';
import { TotalExposureData } from '../../services/portfolio';
import { usePrivacy } from '../../contexts/PrivacyContext';
import { formatCurrency } from '../../utils/formatters';
import LoadingSpinner from '../ui/LoadingSpinner';

interface TotalExposureSectionProps {
  exposureData: TotalExposureData | undefined;
  isLoading: boolean;
}

const TotalExposureSection: React.FC<TotalExposureSectionProps> = ({
  exposureData,
  isLoading
}) => {
  const [displayCount, setDisplayCount] = useState(10);
  const { isPrivateMode } = usePrivacy();
  
  if (isLoading) {
    return (
      <div className="card card-forest mb-4">
        <div className="card-body p-3 p-md-4">
          <h5 className="card-title mb-4 fw-bold text-forest-600">Top Security Exposures</h5>
          <div className="d-flex align-items-center justify-content-center py-5">
            <LoadingSpinner text="Loading security exposure data..." />
          </div>
        </div>
      </div>
    );
  }

  if (!exposureData || !exposureData.securities || exposureData.securities.length === 0) {
    return (
      <div className="card card-forest mb-4">
        <div className="card-body p-3 p-md-4">
          <h5 className="card-title mb-4 fw-bold text-forest-600">Top Security Exposures</h5>
          <div className="text-center text-muted py-5">
            No securities exposure data available
          </div>
        </div>
      </div>
    );
  }

  // Sort securities by total value
  const sortedSecurities = [...exposureData.securities]
    .sort((a, b) => b.total_value - a.total_value)
    .slice(0, displayCount);

  // Function to get badge styling based on security type
  const getSecurityTypeBadge = (securityType: string) => {
    const type = securityType.toLowerCase();
    if (type === 'equity') {
      return <span className="badge bg-forest-100 text-forest-500 small py-1 px-2">Equity</span>;
    } else if (type === 'bond') {
      return <span className="badge bg-forest-300 text-forest-800 small py-1 px-2">Bond</span>;
    } else if (type === 'cash') {
      return <span className="badge bg-forest-50 text-forest-500 small py-1 px-2">Cash</span>;
    } else {
      return <span className="badge bg-forest-50 text-forest-500 small py-1 px-2">Other</span>;
    }
  };

  return (
    <div className="card card-forest mb-4">
      <div className="card-body p-3 p-md-4">
        <div className="d-flex justify-content-between align-items-center mb-4">
          <h5 className="card-title fw-bold text-forest-600 mb-0">Top Security Exposures</h5>
          <div className="d-flex align-items-center">
            <label htmlFor="displayCount" className="me-2 form-label mb-0">Show:</label>
            <select 
              id="displayCount" 
              className="form-select form-select-sm"
              value={displayCount}
              onChange={(e) => setDisplayCount(Number(e.target.value))}
              style={{ width: '80px' }}
            >
              <option value="5">5</option>
              <option value="10">10</option>
              <option value="20">20</option>
              <option value="50">50</option>
              <option value="100">100</option>
            </select>
          </div>
        </div>

        <div className="table-responsive">
          <table className="table table-hover">
            <thead>
              <tr>
                <th>Security</th>
                <th>Type</th>
                <th>Total Shares</th>
                <th>Total Value</th>
                <th>% of Portfolio</th>
                <th>Direct Investment</th>
                <th>Via ETFs</th>
              </tr>
            </thead>
            <tbody>
              {sortedSecurities.map((security) => {
                const portfolioPercentage = ((security.total_value / exposureData.total_portfolio_value) * 100).toFixed(2);
                const directPercentage = ((security.direct_value / security.total_value) * 100).toFixed(1);
                const etfPercentage = ((security.etf_value / security.total_value) * 100).toFixed(1);

                return (
                  <tr key={security.identifier}>
                    <td>
                      <div><strong>{security.identifier}</strong></div>
                      <div className="small text-muted">{security.name}</div>
                    </td>
                    <td>{getSecurityTypeBadge(security.security_type)}</td>
                    <td>
                      {isPrivateMode ? '***' : (
                        typeof security.total_shares === 'number' 
                          ? security.total_shares.toFixed(2) 
                          : Number(security.total_shares).toFixed(2)
                      )}
                    </td>
                    <td>
                      {formatCurrency(
                        typeof security.total_value === 'number' 
                          ? security.total_value 
                          : Number(security.total_value),
                        isPrivateMode
                      )}
                    </td>
                    <td>{portfolioPercentage}%</td>
                    <td>
                      <div>
                        {formatCurrency(
                          typeof security.direct_value === 'number' 
                            ? security.direct_value 
                            : Number(security.direct_value),
                          isPrivateMode
                        )}
                      </div>
                      <div className={isPrivateMode ? '' : 'small'}>
                        {isPrivateMode ? (
                          `${directPercentage}%`
                        ) : (
                          <span className="text-muted">
                            {typeof security.direct_shares === 'number' 
                              ? security.direct_shares.toFixed(2) 
                              : Number(security.direct_shares).toFixed(2)} shares ({directPercentage}%)
                          </span>
                        )}
                      </div>
                    </td>
                    <td>
                      <div>
                        {formatCurrency(
                          typeof security.etf_value === 'number' 
                            ? security.etf_value 
                            : Number(security.etf_value),
                          isPrivateMode
                        )}
                      </div>
                      <div className={isPrivateMode ? '' : 'small'}>
                        {isPrivateMode ? (
                          `${etfPercentage}%`
                        ) : (
                          <span className="text-muted">
                            {typeof security.etf_shares === 'number' 
                              ? security.etf_shares.toFixed(2) 
                              : Number(security.etf_shares).toFixed(2)} shares ({etfPercentage}%)
                          </span>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default TotalExposureSection; 