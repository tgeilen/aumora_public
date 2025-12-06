import React from 'react';

interface DeleteConfirmationModalProps {
  itemName: string;
  itemType: string;
  handleDelete: () => void;
  setShowDeleteConfirm: (show: boolean) => void;
  resetSelection: () => void;
  isPending: boolean;
}

const DeleteConfirmationModal: React.FC<DeleteConfirmationModalProps> = ({
  itemName,
  itemType,
  handleDelete,
  setShowDeleteConfirm,
  resetSelection,
  isPending
}) => {
  return (
    <>
      <div className="modal-backdrop fade show"></div>
      <div className="modal fade show" style={{ display: 'block' }} tabIndex={-1} role="dialog">
        <div className="modal-dialog modal-dialog-centered">
          <div className="modal-content">
            <div className="modal-header">
              <h5 className="modal-title">Confirm Removal</h5>
              <button 
                type="button" 
                className="btn-close" 
                onClick={() => {
                  setShowDeleteConfirm(false);
                  resetSelection();
                }}
              ></button>
            </div>
            <div className="modal-body">
              <p>
                Are you sure you want to remove <strong>{itemName}</strong> from your portfolio?
              </p>
            </div>
            <div className="modal-footer">
              <button 
                type="button"
                onClick={() => {
                  setShowDeleteConfirm(false);
                  resetSelection();
                }}
                className="btn btn-secondary"
              >
                Cancel
              </button>
              <button 
                onClick={handleDelete}
                className="btn btn-danger"
                disabled={isPending}
              >
                {isPending ? 'Removing...' : 'Remove'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default DeleteConfirmationModal; 