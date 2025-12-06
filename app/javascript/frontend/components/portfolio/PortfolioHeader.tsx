import React from 'react';
import { Portfolio } from '../../services/portfolio';
import { usePrivacy } from '../../contexts/PrivacyContext';
import { formatCurrency } from '../../utils/formatters';

interface PortfolioHeaderProps {
  portfolio: Portfolio;
  totalPortfolioValue: number;
}

const PortfolioHeader: React.FC<PortfolioHeaderProps> = ({ portfolio, totalPortfolioValue }) => {
  const { isPrivateMode } = usePrivacy();

  // Format the last ETF sync time or show a fallback message
  const formatLastSyncTime = () => {
    if (portfolio.last_etf_sync_at) {
      return new Date(portfolio.last_etf_sync_at).toLocaleDateString();
    }
    return 'Never';
  };

  return (
    <div className="card card-forest mb-4 py-0">
      <div className="card-body">
        <div className="row align-items-center">
          <div className="col-12 col-md-8">
            <h2 className="h3 fw-bold text-forest-600 mb-1">{portfolio.name}</h2>
            <p className="fs-6 text-secondary mb-3 mb-md-0">Portfolio Overview</p>
          </div>
          <div className="col-12 col-md-4 text-start text-md-end">
            <div className="text-secondary">
              <div className="mb-1 fw-semibold h4 text-forest-600">
                Total Value: <span className="">{formatCurrency(totalPortfolioValue, isPrivateMode)}</span>
              </div>
              <div className="small">
                Last ETF data sync: <span className="">{formatLastSyncTime()}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PortfolioHeader; 