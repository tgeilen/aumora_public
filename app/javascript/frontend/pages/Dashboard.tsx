import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import portfolioService from '../services/portfolio';
import useAuth from '../hooks/useAuth';
import { usePrivacy } from '../contexts/PrivacyContext';
import { formatCurrency } from '../utils/formatters';

const Dashboard = () => {
  const { user } = useAuth();
  const { isPrivateMode } = usePrivacy();
  const [totalValue, setTotalValue] = useState(0);

  // Fetch user portfolios
  const { 
    data: portfolios = [], // Provide default empty array to avoid undefined
    isLoading, 
    error 
  } = useQuery({
    queryKey: ['portfolios'],
    queryFn: () => portfolioService.getPortfolios(),
  });

  // Calculate total portfolio value
  useEffect(() => {
    if (portfolios) {
      console.log('Portfolios received:', portfolios);
      const total = portfolios.reduce((sum, portfolio) => {
        console.log(`Portfolio ${portfolio.name}: total_value = ${portfolio.total_value}`);
        // Use the total_value calculated by the backend
        return sum + (portfolio.total_value || 0);
      }, 0);
      console.log('Calculated total value:', total);
      setTotalValue(total);
    }
  }, [portfolios]);

  if (isLoading) {
    return <div className="text-center p-4">Loading your portfolios...</div>;
  }

  if (error) {
    return <div className="text-center p-4 text-danger">Error loading portfolios</div>;
  }

  // Get user's name or fallback to a default
  const userName = user && typeof user === 'object' && 'name' in user ? 
    user.name as string : 'Investor';

  return (
    <div className="container-fluid py-4 px-0">
      <div className="row mb-4">
        <div className="col-12">
          <div className="d-flex flex-column flex-md-row justify-content-between align-items-md-center">
            <div>
              <h1 className="fw-bold mb-1">Dashboard</h1>
              <p className="text-muted">Welcome back, {userName}!</p>
            </div>
          </div>
        </div>
      </div>

      <div className="row g-4 mb-4">
        <div className="col-12 col-md-6 col-lg-3">
          <div className="card card-forest h-100">
            <div className="card-body">
              <div className="d-flex justify-content-between align-items-center mb-3">
                <h5 className="card-title fw-bold text-forest-600">Total Value</h5>
                <div className="bg-forest-50 rounded-circle p-2">
                  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" className="bi bi-wallet2 text-forest-500" viewBox="0 0 16 16">
                    <path d="M12.136.326A1.5 1.5 0 0 1 14 1.78V3h.5A1.5 1.5 0 0 1 16 4.5v9a1.5 1.5 0 0 1-1.5 1.5h-13A1.5 1.5 0 0 1 0 13.5v-9a1.5 1.5 0 0 1 1.432-1.499L12.136.326zM5.562 3H13V1.78a.5.5 0 0 0-.621-.484L5.562 3zM1.5 4a.5.5 0 0 0-.5.5v9a.5.5 0 0 0 .5.5h13a.5.5 0 0 0 .5-.5v-9a.5.5 0 0 0-.5-.5h-13z"/>
                  </svg>
                </div>
              </div>
              <div className="h3 fw-bold mb-0 text-forest-600">{formatCurrency(totalValue, isPrivateMode)}</div>
              <div className="small text-muted mt-1">Total investments value</div>
            </div>
          </div>
        </div>

        <div className="col-12 col-md-6 col-lg-3">
          <div className="card card-forest h-100">
            <div className="card-body">
              <div className="d-flex justify-content-between align-items-center mb-3">
                <h5 className="card-title fw-bold text-forest-600">Portfolios</h5>
                <div className="bg-forest-50 rounded-circle p-2">
                  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" className="bi bi-briefcase-fill text-forest-500" viewBox="0 0 16 16">
                    <path d="M6.5 1A1.5 1.5 0 0 0 5 2.5V3H1.5A1.5 1.5 0 0 0 0 4.5v1.384l7.614 2.03a1.5 1.5 0 0 0 .772 0L16 5.884V4.5A1.5 1.5 0 0 0 14.5 3H11v-.5A1.5 1.5 0 0 0 9.5 1h-3zm0 1h3a.5.5 0 0 1 .5.5V3H6v-.5a.5.5 0 0 1 .5-.5z"/>
                    <path d="M0 12.5A1.5 1.5 0 0 0 1.5 14h13a1.5 1.5 0 0 0 1.5-1.5V6.85L8.129 8.947a.5.5 0 0 1-.258 0L0 6.85v5.65z"/>
                  </svg>
                </div>
              </div>
              <div className="h3 fw-bold mb-0 text-forest-600">{portfolios.length}</div>
              <div className="small text-muted mt-1">Active portfolios</div>
              <div className="mt-3">
                <Link to="/portfolios" className="btn btn-sm btn-outline-primary">Manage Portfolios</Link>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="row mb-4">
        <div className="col-12">
          <h2 className="h4 fw-bold mb-3">Your Portfolios</h2>
        </div>
      </div>
      
      {portfolios && portfolios.length > 0 ? (
        <div className="row g-4">
          {portfolios.map((portfolio) => (
            <div className="col-md-6 col-lg-4" key={portfolio.id}>
              <Link
                to={`/portfolios/${portfolio.id}`}
                className="card card-forest h-100 text-decoration-none"
              >
                <div className="card-body">
                  <h5 className="card-title">{portfolio.name}</h5>
                  <p className="card-text text-muted">
                    {(portfolio.entries?.length || 0) + (portfolio.asset_entries?.length || 0)} holdings • {formatCurrency(portfolio.total_value || 0, isPrivateMode)}
                  </p>
                  <div className="d-flex justify-content-between align-items-center mt-3">
                    <span className="text-forest-600 fw-medium">View Details</span>
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" className="bi bi-chevron-right text-forest" viewBox="0 0 16 16">
                      <path fillRule="evenodd" d="M4.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L10.293 8 4.646 2.354a.5.5 0 0 1 0-.708z"/>
                    </svg>
                  </div>
                </div>
              </Link>
            </div>
          ))}
        </div>
      ) : (
        <div className="card card-forest text-center p-5">
          <div className="py-4">
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" fill="currentColor" className="bi bi-briefcase text-forest-300 mb-3" viewBox="0 0 16 16">
              <path d="M6.5 1A1.5 1.5 0 0 0 5 2.5V3H1.5A1.5 1.5 0 0 0 0 4.5v8A1.5 1.5 0 0 0 1.5 14h13a1.5 1.5 0 0 0 1.5-1.5v-8A1.5 1.5 0 0 0 14.5 3H11v-.5A1.5 1.5 0 0 0 9.5 1h-3zm0 1h3a.5.5 0 0 1 .5.5V3H6v-.5a.5.5 0 0 1 .5-.5zm1.886 6.914L15 7.151V12.5a.5.5 0 0 1-.5.5h-13a.5.5 0 0 1-.5-.5V7.15l6.614 1.764a1.5 1.5 0 0 0 .772 0zM1.5 4h13a.5.5 0 0 1 .5.5v1.616L8.129 7.948a.5.5 0 0 1-.258 0L1 6.116V4.5a.5.5 0 0 1 .5-.5z"/>
            </svg>
            <h3 className="fw-medium mb-3">You don't have any portfolios yet</h3>
            <p className="text-muted mb-4">Create your first portfolio to start tracking your investments</p>
            <Link to="/portfolios" className="btn btn-primary">Create Portfolio</Link>
          </div>
        </div>
      )}
    </div>
  );
};

export default Dashboard; 