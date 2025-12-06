import React from 'react';
import { Asset, AddPortfolioAssetEntryParams } from '../../../services/portfolio';

interface AssetsResponse {
  assets: Asset[];
  meta: {
    total_count: number;
    count: number;
  };
}

interface AddAssetModalProps {
  assets: Asset[] | AssetsResponse;
  assetSearchTerm: string;
  setAssetSearchTerm: (term: string) => void;
  assetFormData: AddPortfolioAssetEntryParams;
  handleAssetInputChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => void;
  handleAddAssetSubmit: (e: React.FormEvent) => void;
  setShowAddAssetModal: (show: boolean) => void;
  resetAssetForm: () => void;
  isPending: boolean;
}

const AddAssetModal: React.FC<AddAssetModalProps> = ({
  assets,
  assetSearchTerm,
  setAssetSearchTerm,
  assetFormData,
  handleAssetInputChange,
  handleAddAssetSubmit,
  setShowAddAssetModal,
  resetAssetForm,
  isPending
}) => {
  return (
    <div className="modal fade show" style={{ display: 'block' }} tabIndex={-1}>
      <div className="modal-dialog">
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title">Add Direct Asset Investment</h5>
            <button 
              type="button" 
              className="btn-close" 
              onClick={() => {
                setShowAddAssetModal(false);
                resetAssetForm();
              }}
            ></button>
          </div>
          <form onSubmit={handleAddAssetSubmit}>
            <div className="modal-body">
              <div className="mb-3">
                <label htmlFor="asset_id" className="form-label">Asset</label>
                <div className="mb-2">
                  <input
                    type="text"
                    className="form-control"
                    placeholder="Search assets..."
                    value={assetSearchTerm}
                    onChange={(e) => setAssetSearchTerm(e.target.value)}
                  />
                </div>
                <select
                  className="form-select"
                  id="asset_id"
                  name="asset_id"
                  value={assetFormData.asset_id || ''}
                  onChange={handleAssetInputChange}
                  required
                >
                  <option value="">Select an asset</option>
                  {(() => {
                    // Get the asset array regardless of response format
                    const assetArray = Array.isArray(assets) 
                      ? assets 
                      : (assets as AssetsResponse)?.assets || [];
                    
                    // Now filter and map the array
                    return assetArray
                      .filter(asset => 
                        assetSearchTerm === '' || 
                        asset.name?.toLowerCase().includes(assetSearchTerm.toLowerCase()) ||
                        asset.identifier?.toLowerCase().includes(assetSearchTerm.toLowerCase())
                      )
                      .map((asset: Asset) => (
                        <option key={asset.id} value={asset.id}>
                          {asset.identifier} - {asset.name}
                        </option>
                      ));
                  })()}
                </select>
              </div>
              <div className="mb-3">
                <label htmlFor="shares" className="form-label">Number of Shares</label>
                <input
                  type="number"
                  className="form-control"
                  id="shares"
                  name="shares"
                  step="0.000001"
                  min="0.000001"
                  value={assetFormData.shares || ''}
                  onChange={handleAssetInputChange}
                  required
                />
              </div>
              <div className="mb-3">
                <label htmlFor="purchase_price" className="form-label">Purchase Price (per share)</label>
                <div className="input-group">
                  <span className="input-group-text">$</span>
                  <input
                    type="number"
                    className="form-control"
                    id="purchase_price"
                    name="purchase_price"
                    step="0.01"
                    min="0.01"
                    value={assetFormData.purchase_price || ''}
                    onChange={handleAssetInputChange}
                  />
                </div>
              </div>
              <div className="mb-3">
                <label htmlFor="purchase_date" className="form-label">Purchase Date</label>
                <input
                  type="date"
                  className="form-control"
                  id="purchase_date"
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
                  setShowAddAssetModal(false);
                  resetAssetForm();
                }}
              >
                Cancel
              </button>
              <button type="submit" className="btn btn-primary" disabled={isPending}>
                {isPending ? 'Adding...' : 'Add Asset'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default AddAssetModal; 