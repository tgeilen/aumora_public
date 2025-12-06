import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import portfolioService from '../services/portfolio';

const ETFList = () => {
  const [searchTerm, setSearchTerm] = useState('');

  // Fetch all ETFs
  const { 
    data: etfs, 
    isLoading, 
    error 
  } = useQuery({
    queryKey: ['etfs'],
    queryFn: () => portfolioService.getETFs(),
  });

  // Filter ETFs based on search term
  const filteredETFs = etfs?.filter(etf => 
    etf.ticker.toLowerCase().includes(searchTerm.toLowerCase()) || 
    etf.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (isLoading) {
    return <div className="text-center p-4">Loading ETFs...</div>;
  }

  if (error) {
    return <div className="text-center p-4 text-danger">Error loading ETFs</div>;
  }

  return (
    <div className="container-fluid py-4">
      <h1 className="fw-bold mb-4">Browse ETFs</h1>
      
      <div className="mb-4">
        <div className="position-relative">
          <input
            type="text"
            placeholder="Search ETFs by name or ticker..."
            className="form-control form-control-lg ps-3 pe-5"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
          <div className="position-absolute top-50 end-0 translate-middle-y pe-3 text-muted">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" className="bi bi-search" viewBox="0 0 16 16">
              <path d="M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001c.03.04.062.078.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1.007 1.007 0 0 0-.115-.1zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0z"/>
            </svg>
          </div>
        </div>
      </div>

      {filteredETFs && filteredETFs.length > 0 ? (
        <div className="card card-forest mb-4">
          <div className="table-responsive">
            <table className="table table-hover table-striped mb-0">
              <thead className="table-light">
                <tr>
                  <th scope="col" className="border-bottom border-2" style={{ borderColor: 'var(--bs-forest-200) !important' }}>
                    <div className="text-uppercase small fw-semibold text-secondary">Ticker</div>
                  </th>
                  <th scope="col" className="border-bottom border-2" style={{ borderColor: 'var(--bs-forest-200) !important' }}>
                    <div className="text-uppercase small fw-semibold text-secondary">Name</div>
                  </th>
                  <th scope="col" className="border-bottom border-2" style={{ borderColor: 'var(--bs-forest-200) !important' }}>
                    <div className="text-uppercase small fw-semibold text-secondary">Provider</div>
                  </th>
                  <th scope="col" className="border-bottom border-2" style={{ borderColor: 'var(--bs-forest-200) !important' }}>
                    <div className="text-uppercase small fw-semibold text-secondary">Last Updated</div>
                  </th>
                  <th scope="col" className="text-end border-bottom border-2" style={{ borderColor: 'var(--bs-forest-200) !important' }}>
                    <div className="text-uppercase small fw-semibold text-secondary">Actions</div>
                  </th>
                </tr>
              </thead>
              <tbody>
                {filteredETFs.map((etf) => (
                  <tr key={etf.id}>
                    <td className="fw-semibold">{etf.ticker}</td>
                    <td>{etf.name}</td>
                    <td>{etf.provider.name}</td>
                    <td>{etf.last_updated_at ? new Date(etf.last_updated_at).toLocaleDateString() : '-'}</td>
                    <td className="text-end">
                      <Link to={`/etfs/${etf.id}`} className="btn btn-sm btn-outline-primary">
                        View Details
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="card card-forest p-5 text-center">
          <div className="py-4">
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" fill="currentColor" className="bi bi-search text-forest-400 mb-3" viewBox="0 0 16 16">
              <path d="M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001c.03.04.062.078.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1.007 1.007 0 0 0-.115-.1zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0"/>
            </svg>
            <h3 className="fw-medium mb-3">
              {searchTerm ? 'No ETFs match your search' : 'No ETFs available'}
            </h3>
            <p className="text-muted">
              {searchTerm 
                ? 'Try a different search term or browse all ETFs' 
                : 'ETF data will appear here once synchronized'}
            </p>
          </div>
        </div>
      )}
    </div>
  );
};

export default ETFList; 