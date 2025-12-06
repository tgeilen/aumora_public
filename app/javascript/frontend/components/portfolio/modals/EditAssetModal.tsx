import React from 'react';
import { PortfolioAssetEntry, AddPortfolioAssetEntryParams } from '../../../services/portfolio';

interface EditAssetModalProps {
  selectedAssetEntry: PortfolioAssetEntry;
  assetFormData: AddPortfolioAssetEntryParams;
  handleAssetInputChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => void;
  handleEditAssetSubmit: (e: React.FormEvent) => void;
  setShowEditAssetModal: (show: boolean) => void;
  resetAssetForm: () => void;
  isPending: boolean;
}

const EditAssetModal: React.FC<EditAssetModalProps> = ({
  selectedAssetEntry,
  assetFormData,
  handleAssetInputChange,
  handleEditAssetSubmit,
  setShowEditAssetModal,
  resetAssetForm,
  isPending
}) => {
  return (
    <div className="modal fade show" style={{ display: 'block' }} tabIndex={-1}>
      <div className="modal-dialog">
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title">Edit Asset Investment</h5>
            <button 
              type="button" 
              className="btn-close" 
              onClick={() => {
                setShowEditAssetModal(false);
                resetAssetForm();
              }}
            ></button>
          </div>
          <form onSubmit={handleEditAssetSubmit}>
            <div className="modal-body">
              <div className="mb-3">
                <label className="form-label">Asset</label>
                <p className="form-control-static">
                  {selectedAssetEntry.asset.identifier} - {selectedAssetEntry.asset.name}
                </p>
              </div>
              <div className="mb-3">
                <label htmlFor="edit_shares" className="form-label">Number of Shares</label>
                <input
                  type="number"
                  className="form-control"
                  id="edit_shares"
                  name="shares"
                  step="0.000001"
                  min="0.000001"
                  value={assetFormData.shares || ''}
                  onChange={handleAssetInputChange}
                  required
                />
              </div>
              <div className="mb-3">
                <label htmlFor="edit_purchase_price" className="form-label">Purchase Price (per share)</label>
                <div className="input-group">
                  <span className="input-group-text">$</span>
                  <input
                    type="number"
                    className="form-control"
                    id="edit_purchase_price"
                    name="purchase_price"
                    step="0.01"
                    min="0.01"
                    value={assetFormData.purchase_price || ''}
                    onChange={handleAssetInputChange}
                  />
                </div>
              </div>
              <div className="mb-3">
                <label htmlFor="edit_purchase_date" className="form-label">Purchase Date</label>
                <input
                  type="date"
                  className="form-control"
                  id="edit_purchase_date"
                  name="purchase_date"
                  value={assetFormData.purchase_date || ''}
                  onChange={handleAssetInputChange}
                />
              </div>
            </div>
            <div className="modal-footer">
              <button 
                type="button" 
                className="btn btn-secondary" 
                onClick={() => {
                  setShowEditAssetModal(false);
                  resetAssetForm();
                }}
              >
                Cancel
              </button>
              <button type="submit" className="btn btn-primary" disabled={isPending}>
                {isPending ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default EditAssetModal; 