import React from 'react';
import { ETF, AddPortfolioEntryParams } from '../../../services/portfolio';

interface AddETFModalProps {
  etfs: ETF[] | undefined;
  etfSearchTerm: string;
  setEtfSearchTerm: (term: string) => void;
  formData: AddPortfolioEntryParams;
  handleInputChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => void;
  handleAddSubmit: (e: React.FormEvent) => void;
  setShowAddModal: (show: boolean) => void;
  resetForm: () => void;
  isPending: boolean;
}

const AddETFModal: React.FC<AddETFModalProps> = ({
  etfs,
  etfSearchTerm,
  setEtfSearchTerm,
  formData,
  handleInputChange,
  handleAddSubmit,
  setShowAddModal,
  resetForm,
  isPending
}) => {
  return (
    <>
      <div className="modal-backdrop fade show"></div>
      <div className="modal fade show" style={{ display: 'block' }} tabIndex={-1} role="dialog">
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content">
            <div className="modal-header">
              <h5 className="modal-title">Add ETF to Portfolio</h5>
              <button 
                type="button" 
                className="btn-close" 
                onClick={() => {
                  setShowAddModal(false);
                  resetForm();
                }}
              ></button>
            </div>
            <div className="modal-body">
              <form onSubmit={handleAddSubmit}>
                <div className="mb-3">
                  <label className="form-label">ETF</label>
                  <div className="input-group mb-2">
                    <input
                      type="text"
                      className="form-control"
                      placeholder="Search ETFs by name or ticker..."
                      value={etfSearchTerm}
                      onChange={(e) => setEtfSearchTerm(e.target.value)}
                    />
                    {etfSearchTerm && (
                      <button
                        className="btn btn-outline-secondary"
                        type="button"
                        onClick={() => setEtfSearchTerm('')}
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" className="bi bi-x" viewBox="0 0 16 16">
                          <path d="M4.646 4.646a.5.5 0 0 1 .708 0L8 7.293l2.646-2.647a.5.5 0 0 1 .708.708L8.707 8l2.647 2.646a.5.5 0 0 1-.708.708L8 8.707l-2.646 2.647a.5.5 0 0 1-.708-.708L7.293 8 4.646 5.354a.5.5 0 0 1 0-.708z"/>
                        </svg>
                      </button>
                    )}
                  </div>
                  <select 
                    name="etf_id" 
                    value={formData.etf_id || ''} 
                    onChange={handleInputChange}
                    className="form-select"
                    required
                  >
                    <option value="">Select an ETF</option>
                    {etfs?.filter(etf => 
                      etfSearchTerm === '' ||
                      etf.ticker.toLowerCase().includes(etfSearchTerm.toLowerCase()) || 
                      etf.name.toLowerCase().includes(etfSearchTerm.toLowerCase())
                    ).map(etf => (
                      <option key={etf.id} value={etf.id}>
                        {etf.ticker} - {etf.name}
                      </option>
                    ))}
                  </select>
                  {etfs && etfSearchTerm && etfs.filter(etf => 
                    etf.ticker.toLowerCase().includes(etfSearchTerm.toLowerCase()) || 
                    etf.name.toLowerCase().includes(etfSearchTerm.toLowerCase())
                  ).length === 0 && (
                    <div className="text-danger mt-1 small">No ETFs found matching "{etfSearchTerm}"</div>
                  )}
                </div>
                <div className="mb-3">
                  <label className="form-label">Shares</label>
                  <input 
                    type="number" 
                    name="shares" 
                    value={formData.shares || ''} 
                    onChange={handleInputChange}
                    className="form-control"
                    required
                    step="0.01"
                    min="0.01"
                  />
                </div>
                <div className="mb-3">
                  <label className="form-label">Purchase Price ($)</label>
                  <input 
                    type="number" 
                    name="purchase_price" 
                    value={formData.purchase_price || ''} 
                    onChange={handleInputChange}
                    className="form-control"
                    step="0.01"
                    min="0.01"
                  />
                </div>
                <div className="mb-3">
                  <label className="form-label">Purchase Date</label>
                  <input 
                    type="date" 
                    name="purchase_date" 
                    value={formData.purchase_date || ''} 
                    onChange={handleInputChange}
                    className="form-control"
                  />
                </div>
                <div className="modal-footer px-0 pb-0">
                  <button 
                    type="button"
                    onClick={() => {
                      setShowAddModal(false);
                      resetForm();
                    }}
                    className="btn btn-secondary"
                  >
                    Cancel
                  </button>
                  <button 
                    type="submit"
                    className="btn btn-primary"
                    disabled={isPending}
                  >
                    {isPending ? 'Adding...' : 'Add ETF'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default AddETFModal; 