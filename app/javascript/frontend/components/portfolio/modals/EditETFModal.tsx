import React from 'react';
import { PortfolioEntry, AddPortfolioEntryParams } from '../../../services/portfolio';

interface EditETFModalProps {
  selectedEntry: PortfolioEntry;
  formData: AddPortfolioEntryParams;
  handleInputChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => void;
  handleEditSubmit: (e: React.FormEvent) => void;
  setShowEditModal: (show: boolean) => void;
  resetForm: () => void;
  isPending: boolean;
}

const EditETFModal: React.FC<EditETFModalProps> = ({
  selectedEntry,
  formData,
  handleInputChange,
  handleEditSubmit,
  setShowEditModal,
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
              <h5 className="modal-title">Edit ETF Entry</h5>
              <button 
                type="button" 
                className="btn-close" 
                onClick={() => {
                  setShowEditModal(false);
                  resetForm();
                }}
              ></button>
            </div>
            <div className="modal-body">
              <form onSubmit={handleEditSubmit}>
                <div className="mb-3">
                  <label className="form-label">ETF</label>
                  <div className="form-control bg-light">
                    {selectedEntry.etf.ticker} - {selectedEntry.etf.name}
                  </div>
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
                      setShowEditModal(false);
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
                    {isPending ? 'Updating...' : 'Update ETF'}
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

export default EditETFModal; 