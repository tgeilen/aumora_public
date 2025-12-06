import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import portfolioService, { AddPortfolioEntryParams, PortfolioEntry } from '../services/portfolio';

export const useETFManagement = (portfolioId: number) => {
  const queryClient = useQueryClient();

  // Modal state
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [selectedEntry, setSelectedEntry] = useState<PortfolioEntry | null>(null);
  const [etfSearchTerm, setEtfSearchTerm] = useState('');
  const [formData, setFormData] = useState<AddPortfolioEntryParams>({
    etf_id: 0,
    shares: 0,
    purchase_price: undefined,
    purchase_date: undefined,
  });

  // Add ETF mutation
  const addEntryMutation = useMutation({
    mutationFn: (data: AddPortfolioEntryParams) => 
      portfolioService.addPortfolioEntry(portfolioId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['portfolio', portfolioId] });
      setShowAddModal(false);
      resetForm();
    },
    onError: (error) => {
      console.error('Failed to add ETF', error);
    }
  });

  // Update ETF mutation
  const updateEntryMutation = useMutation({
    mutationFn: ({ entryId, data }: { entryId: number, data: Partial<AddPortfolioEntryParams> }) => 
      portfolioService.updatePortfolioEntry(portfolioId, entryId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['portfolio', portfolioId] });
      setShowEditModal(false);
      resetForm();
    },
    onError: (error) => {
      console.error('Failed to update ETF', error);
    }
  });

  // Remove ETF mutation
  const removeEntryMutation = useMutation({
    mutationFn: (entryId: number) => 
      portfolioService.removePortfolioEntry(portfolioId, entryId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['portfolio', portfolioId] });
      setShowDeleteConfirm(false);
      setSelectedEntry(null);
    },
    onError: (error) => {
      console.error('Failed to remove ETF', error);
    }
  });

  // Form handlers
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'etf_id' ? parseInt(value, 10) : 
              name === 'shares' ? parseFloat(value) : 
              name === 'purchase_price' ? parseFloat(value) : value
    }));
  };

  const handleAddSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    addEntryMutation.mutate(formData);
  };

  const handleEditSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedEntry) {
      updateEntryMutation.mutate({
        entryId: selectedEntry.id,
        data: formData
      });
    }
  };

  const handleDelete = () => {
    if (selectedEntry) {
      removeEntryMutation.mutate(selectedEntry.id);
    }
  };

  const openEditModal = (entry: PortfolioEntry) => {
    setSelectedEntry(entry);
    setFormData({
      etf_id: entry.etf_id,
      shares: entry.shares,
      purchase_price: entry.purchase_price,
      purchase_date: entry.purchase_date
    });
    setShowEditModal(true);
  };

  const openDeleteConfirm = (entry: PortfolioEntry) => {
    setSelectedEntry(entry);
    setShowDeleteConfirm(true);
  };

  const resetForm = () => {
    setFormData({
      etf_id: 0,
      shares: 0,
      purchase_price: undefined,
      purchase_date: undefined
    });
    setSelectedEntry(null);
    setEtfSearchTerm('');
  };

  return {
    // Modal state
    showAddModal,
    setShowAddModal,
    showEditModal,
    setShowEditModal,
    showDeleteConfirm,
    setShowDeleteConfirm,
    selectedEntry,
    setSelectedEntry,
    
    // Form state
    etfSearchTerm,
    setEtfSearchTerm,
    formData,
    setFormData,
    
    // Mutations
    addEntryMutation,
    updateEntryMutation,
    removeEntryMutation,
    
    // Event handlers
    handleInputChange,
    handleAddSubmit,
    handleEditSubmit,
    handleDelete,
    resetForm,
    openEditModal,
    openDeleteConfirm
  };
}; 