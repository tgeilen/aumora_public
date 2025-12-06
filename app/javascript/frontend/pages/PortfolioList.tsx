import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import portfolioService from '../services/portfolio';
import { usePrivacy } from '../contexts/PrivacyContext';
import LoadingSpinner from '../components/ui/LoadingSpinner';

const PortfolioList = () => {
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [portfolioName, setPortfolioName] = useState('');
  const { isPrivateMode } = usePrivacy();

  const { 
    data: portfolios, 
    isLoading, 
    error,
    refetch
  } = useQuery({
    queryKey: ['portfolios'],
    queryFn: () => portfolioService.getPortfolios(),
  });

  const handleCreatePortfolio = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!portfolioName.trim()) return;

    try {
      await portfolioService.createPortfolio({ name: portfolioName });
      setShowCreateModal(false);
      setPortfolioName('');
      refetch();
    } catch (error) {
      console.error('Failed to create portfolio', error);
    }
  };

  if (isLoading) {
    return (
      <div className="d-flex justify-content-center align-items-center" style={{ minHeight: '400px' }}>
        <LoadingSpinner size="lg" text="Loading portfolios..." />
      </div>
    );
  }

  if (error) {
    return (
      <div className="alert alert-danger" role="alert">
        <div className="d-flex align-items-center">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" className="bi bi-exclamation-triangle-fill flex-shrink-0 me-2" viewBox="0 0 16 16">
            <path d="M8.982 1.566a1.13 1.13 0 0 0-1.96 0L.165 13.233c-.457.778.091 1.767.98 1.767h13.713c.889 0 1.438-.99.98-1.767L8.982 1.566zM8 5c.535 0 .954.462.9.995l-.35 3.507a.552.552 0 0 1-1.1 0L7.1 5.995A.905.905 0 0 1 8 5zm.002 6a1 1 0 1 1 0 2 1 1 0 0 1 0-2z"/>
          </svg>
          <div>Error loading portfolios</div>
        </div>
      </div>
    );
  }

  return (
    <div className="container-fluid py-4 px-0">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <div>
          <h1 className="fw-bold mb-1">Your Portfolios</h1>
          <p className="text-muted mb-0">Manage and track your ETF investment portfolios</p>
        </div>
        <div>
          <button
            onClick={() => setShowCreateModal(true)}
            className="btn btn-primary d-flex align-items-center"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" className="bi bi-plus-lg me-2" viewBox="0 0 16 16">
              <path fillRule="evenodd" d="M8 2a.5.5 0 0 1 .5.5v5h5a.5.5 0 0 1 0 1h-5v5a.5.5 0 0 1-1 0v-5h-5a.5.5 0 0 1 0-1h5v-5A.5.5 0 0 1 8 2Z"/>
            </svg>
            Create Portfolio
          </button>
        </div>
      </div>

      {portfolios && portfolios.length > 0 ? (
        <div className="row g-4">
          {portfolios.map((portfolio) => (
            <div key={portfolio.id} className="col-12 col-md-6 col-lg-4">
              <Link
                to={`/portfolios/${portfolio.id}`}
                className="card card-forest h-100 text-decoration-none"
              >
                <div className="card-body">
                  <div className="d-flex justify-content-between align-items-start mb-3">
                    <div>
                      <h3 className="h5 fw-bold text-forest-600 mb-1">{portfolio.name}</h3>
                      <div className="text-muted small">
                        {portfolio.entries?.length || 0} ETFs in portfolio
                      </div>
                    </div>
                    <div className="bg-forest-50 rounded-circle p-2">
                      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" className="bi bi-pie-chart-fill text-forest-500" viewBox="0 0 16 16">
                        <path d="M15.985 8.5H8.207l-5.5 5.5a8 8 0 0 0 13.277-5.5zM2 13.292A8 8 0 0 1 7.5.015v7.778l-5.5 5.5zM8.5.015V7.5h7.485A8.001 8.001 0 0 0 8.5.015z"/>
                      </svg>
                    </div>
                  </div>
                  <div className="d-flex align-items-center text-forest-600">
                    <span className="small fw-medium">View Details</span>
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" className="bi bi-arrow-right ms-2" viewBox="0 0 16 16">
                      <path fillRule="evenodd" d="M1 8a.5.5 0 0 1 .5-.5h11.793l-3.147-3.146a.5.5 0 0 1 .708-.708l4 4a.5.5 0 0 1 0 .708l-4 4a.5.5 0 0 1-.708-.708L13.293 8.5H1.5A.5.5 0 0 1 1 8z"/>
                    </svg>
                  </div>
                </div>
              </Link>
            </div>
          ))}
        </div>
      ) : (
        <div className="card card-forest p-5 text-center">
          <div className="py-4">
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" fill="currentColor" className="bi bi-pie-chart text-forest-400 mb-3" viewBox="0 0 16 16">
              <path d="M7.5 1.018a7 7 0 0 0-4.79 11.566L7.5 7.793V1.018zm1 0V7.5h6.482A7.001 7.001 0 0 0 8.5 1.018zM14.982 8.5H8.207l-4.79 4.79A7 7 0 0 0 14.982 8.5zM0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8z"/>
            </svg>
            <h3 className="fw-medium mb-3">
              You don't have any portfolios yet
            </h3>
            <p className="text-muted mb-4">
              Create your first portfolio to start tracking your ETF investments
            </p>
            <button
              onClick={() => setShowCreateModal(true)}
              className="btn btn-primary"
            >
              Create Portfolio
            </button>
          </div>
        </div>
      )}

      {/* Create Portfolio Modal */}
      {showCreateModal && (
        <>
          <div className="modal fade show" style={{ display: 'block' }} tabIndex={-1} aria-modal="true" role="dialog">
            <div className="modal-dialog">
              <div className="modal-content">
                <div className="modal-header">
                  <h5 className="modal-title">Create New Portfolio</h5>
                  <button type="button" className="btn-close" onClick={() => setShowCreateModal(false)} aria-label="Close"></button>
                </div>
                <form onSubmit={handleCreatePortfolio}>
                  <div className="modal-body">
                    <div className="mb-3">
                      <label htmlFor="portfolioName" className="form-label">Portfolio Name</label>
                      <input
                        type="text"
                        className="form-control"
                        id="portfolioName"
                        value={portfolioName}
                        onChange={(e) => setPortfolioName(e.target.value)}
                        placeholder="My ETF Portfolio"
                        required
                      />
                    </div>
                  </div>
                  <div className="modal-footer">
                    <button type="button" className="btn btn-secondary" onClick={() => setShowCreateModal(false)}>Cancel</button>
                    <button type="submit" className="btn btn-primary">Create Portfolio</button>
                  </div>
                </form>
              </div>
            </div>
          </div>
          <div className="modal-backdrop fade show"></div>
        </>
      )}
    </div>
  );
};

export default PortfolioList; 