import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import portfolioService, { 
  AddPortfolioAssetEntryParams, 
  PortfolioAssetEntry 
} from '../services/portfolio';

export const useAssetManagement = (portfolioId: number) => {
  const queryClient = useQueryClient();

  // Modal state
  const [showAddAssetModal, setShowAddAssetModal] = useState(false);
  const [showEditAssetModal, setShowEditAssetModal] = useState(false);
  const [showDeleteAssetConfirm, setShowDeleteAssetConfirm] = useState(false);
  const [selectedAssetEntry, setSelectedAssetEntry] = useState<PortfolioAssetEntry | null>(null);
  const [assetSearchTerm, setAssetSearchTerm] = useState('');
  const [assetFormData, setAssetFormData] = useState<AddPortfolioAssetEntryParams>({
    asset_id: 0,
    shares: 0,
    purchase_price: undefined,
    purchase_date: undefined,
  });

  // Add Asset mutation
  const addAssetEntryMutation = useMutation({
    mutationFn: (data: AddPortfolioAssetEntryParams) => 
      portfolioService.addPortfolioAssetEntry(portfolioId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['portfolio', portfolioId] });
      setShowAddAssetModal(false);
      resetAssetForm();
    },
    onError: (error) => {
      console.error('Failed to add asset', error);
    }
  });

  // Update Asset mutation
  const updateAssetEntryMutation = useMutation({
    mutationFn: ({ entryId, data }: { entryId: number, data: Partial<AddPortfolioAssetEntryParams> }) => 
      portfolioService.updatePortfolioAssetEntry(portfolioId, entryId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['portfolio', portfolioId] });
      setShowEditAssetModal(false);
      resetAssetForm();
    },
    onError: (error) => {
      console.error('Failed to update asset', error);
    }
  });

  // Remove Asset mutation
  const removeAssetEntryMutation = useMutation({
    mutationFn: (entryId: number) => 
      portfolioService.removePortfolioAssetEntry(portfolioId, entryId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['portfolio', portfolioId] });
      setShowDeleteAssetConfirm(false);
      setSelectedAssetEntry(null);
    },
    onError: (error) => {
      console.error('Failed to remove asset', error);
    }
  });

  // Form handlers
  const handleAssetInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setAssetFormData(prev => ({
      ...prev,
      [name]: name === 'asset_id' ? parseInt(value, 10) : 
              name === 'shares' ? parseFloat(value) : 
              name === 'purchase_price' ? parseFloat(value) : value
    }));
  };

  const handleAddAssetSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    addAssetEntryMutation.mutate(assetFormData);
  };

  const handleEditAssetSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedAssetEntry) {
      updateAssetEntryMutation.mutate({
        entryId: selectedAssetEntry.id,
        data: assetFormData
      });
    }
  };

  const handleDeleteAsset = () => {
    if (selectedAssetEntry) {
      removeAssetEntryMutation.mutate(selectedAssetEntry.id);
    }
  };

  const openEditAssetModal = (entry: PortfolioAssetEntry) => {
    setSelectedAssetEntry(entry);
    setAssetFormData({
      asset_id: entry.asset_id,
      shares: entry.shares,
      purchase_price: entry.purchase_price,
      purchase_date: entry.purchase_date
    });
    setShowEditAssetModal(true);
  };

  const openDeleteAssetConfirm = (entry: PortfolioAssetEntry) => {
    setSelectedAssetEntry(entry);
    setShowDeleteAssetConfirm(true);
  };

  const resetAssetForm = () => {
    setAssetFormData({
      asset_id: 0,
      shares: 0,
      purchase_price: undefined,
      purchase_date: undefined
    });
    setSelectedAssetEntry(null);
    setAssetSearchTerm('');
  };

  return {
    // Modal state
    showAddAssetModal,
    setShowAddAssetModal,
    showEditAssetModal,
    setShowEditAssetModal,
    showDeleteAssetConfirm,
    setShowDeleteAssetConfirm,
    selectedAssetEntry,
    setSelectedAssetEntry,
    
    // Form state
    assetSearchTerm,
    setAssetSearchTerm,
    assetFormData,
    setAssetFormData,
    
    // Mutations
    addAssetEntryMutation,
    updateAssetEntryMutation,
    removeAssetEntryMutation,
    
    // Event handlers
    handleAssetInputChange,
    handleAddAssetSubmit,
    handleEditAssetSubmit,
    handleDeleteAsset,
    resetAssetForm,
    openEditAssetModal,
    openDeleteAssetConfirm
  };
}; 