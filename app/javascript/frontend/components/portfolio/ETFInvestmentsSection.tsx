import React from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import { Portfolio, PortfolioEntry, ETF, AddPortfolioEntryParams } from '../../services/portfolio';
import { CHART_COLORS, useIsMobile, getChartConfig } from '../../utils/chartHelpers';
import { usePrivacy } from '../../contexts/PrivacyContext';
import { formatCurrency, formatNumber, formatPercentage } from '../../utils/formatters';
import AddETFModal from './modals/AddETFModal';
import EditETFModal from './modals/EditETFModal';
import DeleteConfirmationModal from './modals/DeleteConfirmationModal';
import ChartContainer from '../ui/ChartContainer';

interface ETFInvestmentsSectionProps {
  portfolio: Portfolio;
  etfs: ETF[] | undefined;
  totalEtfValue: number;
  etfAllocationData: Array<{ name: string; value: number; fullName: string }>;
  
  // Modal state
  showAddModal: boolean;
  setShowAddModal: (show: boolean) => void;
  showEditModal: boolean;
  setShowEditModal: (show: boolean) => void;
  showDeleteConfirm: boolean;
  setShowDeleteConfirm: (show: boolean) => void;
  selectedEntry: PortfolioEntry | null;
  setSelectedEntry: (entry: PortfolioEntry | null) => void;
  
  // Form state
  etfSearchTerm: string;
  setEtfSearchTerm: (term: string) => void;
  formData: AddPortfolioEntryParams;
  setFormData: React.Dispatch<React.SetStateAction<AddPortfolioEntryParams>>;
  
  // Mutations
  addEntryMutation: {
    mutate: (data: AddPortfolioEntryParams) => void;
    isPending: boolean;
  };
  updateEntryMutation: {
    mutate: (data: { entryId: number; data: Partial<AddPortfolioEntryParams> }) => void;
    isPending: boolean;
  };
  removeEntryMutation: {
    mutate: (entryId: number) => void;
    isPending: boolean;
  };
  
  // Event handlers
  handleInputChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => void;
  handleAddSubmit: (e: React.FormEvent) => void;
  handleEditSubmit: (e: React.FormEvent) => void;
  handleDelete: () => void;
  resetForm: () => void;
  openEditModal: (entry: PortfolioEntry) => void;
  openDeleteConfirm: (entry: PortfolioEntry) => void;
}

const ETFInvestmentsSection: React.FC<ETFInvestmentsSectionProps> = ({
  portfolio,
  etfs,
  totalEtfValue,
  etfAllocationData,
  showAddModal,
  setShowAddModal,
  showEditModal,
  setShowEditModal,
  showDeleteConfirm,
  setShowDeleteConfirm,
  selectedEntry,
  setSelectedEntry,
  etfSearchTerm,
  setEtfSearchTerm,
  formData,
  setFormData,
  addEntryMutation,
  updateEntryMutation,
  removeEntryMutation,
  handleInputChange,
  handleAddSubmit,
  handleEditSubmit,
  handleDelete,
  resetForm,
  openEditModal,
  openDeleteConfirm
}) => {
  const { isPrivateMode } = usePrivacy();
  
  // Responsive chart configuration
  const isMobile = useIsMobile();
  const chartConfig = getChartConfig(isMobile);

  return (
    <>
      {/* ETF allocation chart */}
      <div className="card card-forest mb-4">
        <div className="card-body p-3 p-md-4">
          <div className="d-flex flex-column flex-sm-row justify-content-between align-items-start align-items-sm-center gap-3 mb-4">
            <h5 className="card-title fw-bold text-forest-600 mb-0">ETF Allocation</h5>
            <button 
              onClick={() => setShowAddModal(true)}
              className="btn btn-primary btn-sm w-sm-auto"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" className="bi bi-plus-lg me-2" viewBox="0 0 16 16">
                <path fillRule="evenodd" d="M8 2a.5.5 0 0 1 .5.5v5h5a.5.5 0 0 1 0 1h-5v5a.5.5 0 0 1-1 0v-5h-5a.5.5 0 0 1 0-1h5v-5A.5.5 0 0 1 8 2Z"/>
              </svg>
              Add ETF
            </button>
          </div>
          {etfAllocationData.length > 0 ? (
            <ChartContainer size="md">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={etfAllocationData}
                    {...chartConfig.pieChart}
                    dataKey="value"
                  >
                    {etfAllocationData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={CHART_COLORS[index % CHART_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip 
                    formatter={(value, name) => {
                      const item = etfAllocationData.find(item => item.name === name);
                      const percentage = item ? ((item.value / totalEtfValue) * 100).toFixed(1) : '0.0';
                      return isPrivateMode 
                        ? [`${percentage}%`, 'Allocation'] 
                        : [name +': ' + `$${(value as number).toFixed(2)} (${percentage}%)`];
                    }}
                    labelFormatter={(label) => {
                      const item = etfAllocationData.find(item => item.name === label);
                      return item ? `${item.name} - ${item.fullName}` : label;
                    }}
                  />
                  {chartConfig.legend && (
                    <Legend 
                      formatter={(value) => {
                        const item = etfAllocationData.find(item => item.name === value);
                        return item ? `${item.name} (${((item.value / totalEtfValue) * 100).toFixed(1)}%)` : value;
                      }}
                      {...chartConfig.legend}
                    />
                  )}
                </PieChart>
              </ResponsiveContainer>
            </ChartContainer>
          ) : (
            <div className="d-flex align-items-center justify-content-center py-5">
              <div className="text-center">
                <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" fill="currentColor" className="bi bi-pie-chart text-forest-300 mb-3" viewBox="0 0 16 16">
                  <path d="M7.5 1.018a7 7 0 0 0-4.79 11.566L7.5 7.793V1.018zm1 0V7.5h6.482A7.001 7.001 0 0 0 8.5 1.018zM14.982 8.5H8.207l-4.79 4.79A7 7 0 0 0 14.982 8.5zM0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8z"/>
                </svg>
                <h4 className="h5 mb-3">No ETFs in this portfolio</h4>
                <button 
                  onClick={() => setShowAddModal(true)}
                  className="btn btn-primary"
                >
                  Add your first ETF
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Portfolio entries table */}
      {portfolio.entries && portfolio.entries.length > 0 && (
        <div className="card card-forest mb-4">
          <div className="card-header bg-white py-3">
            <div className="d-flex flex-column flex-sm-row justify-content-between align-items-start align-items-sm-center gap-3">
              <h5 className="mb-0 fw-bold fs-4 text-forest-600">ETF Holdings</h5>
              <button 
                onClick={() => setShowAddModal(true)}
                className="btn btn-primary btn-sm d-sm-none w-100"
              >
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" className="bi bi-plus-lg me-2" viewBox="0 0 16 16">
                  <path fillRule="evenodd" d="M8 2a.5.5 0 0 1 .5.5v5h5a.5.5 0 0 1 0 1h-5v5a.5.5 0 0 1-1 0v-5h-5a.5.5 0 0 1 0-1h5v-5A.5.5 0 0 1 8 2Z"/>
                </svg>
                Add ETF
              </button>
            </div>
          </div>
          <div className="table-responsive">
            <table className="table table-hover">
              <thead>
                <tr>
                  <th>ETF</th>
                  <th>Shares</th>
                  <th>Purchase Price</th>
                  <th>Current Price</th>
                  <th>Purchase Value</th>
                  <th>Current Value</th>
                  <th>Weight</th>
                  <th>Date</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {portfolio.entries.map((entry) => {
                  const purchaseValue = Number(entry.shares) * (entry.purchase_price ? Number(entry.purchase_price) : 0);
                  const currentValue = Number(entry.shares) * (entry.current_price ? Number(entry.current_price) : 0);
                  const weight = (currentValue / totalEtfValue) * 100;
                  
                  return (
                    <tr key={entry.id}>
                      <td>
                        <div className="fw-semibold">{entry.etf.ticker}</div>
                        <div className="small text-muted">{entry.etf.name}</div>
                      </td>
                      <td>{isPrivateMode ? '***' : entry.shares.toFixed(2)}</td>
                      <td>{formatCurrency(entry.purchase_price || 0, isPrivateMode)}</td>
                      <td>{formatCurrency(entry.current_price || 0, isPrivateMode)}</td>
                      <td>{formatCurrency(purchaseValue, isPrivateMode)}</td>
                      <td>{formatCurrency(currentValue, isPrivateMode)}</td>
                      <td>{formatPercentage(weight)}</td>
                      <td>{entry.purchase_date ? new Date(entry.purchase_date).toLocaleDateString() : '-'}</td>
                      <td>
                        <div className="d-flex gap-2 justify-content-end">
                          <button 
                            onClick={() => openEditModal(entry)}
                            className="btn btn-icon border bg-transparent"
                            style={{ width: '32px', height: '32px', padding: '0', display: 'inline-flex', alignItems: 'center', justifyContent: 'center'}}
                            title="Edit"
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="grey" viewBox="0 0 16 16">
                              <path d="M15.502 1.94a.5.5 0 0 1 0 .706L14.459 3.69l-2-2L13.502.646a.5.5 0 0 1 .707 0l1.293 1.293zm-1.75 2.456-2-2L4.939 9.21a.5.5 0 0 0-.121.196l-.805 2.414a.25.25 0 0 0 .316.316l2.414-.805a.5.5 0 0 0 .196-.12l6.813-6.814z"/>
                              <path fillRule="evenodd" d="M1 13.5A1.5 1.5 0 0 0 2.5 15h11a1.5 1.5 0 0 0 1.5-1.5v-6a.5.5 0 0 0-1 0v6a.5.5 0 0 1-.5.5h-11a.5.5 0 0 1-.5-.5v-11a.5.5 0 0 1 .5-.5H9a.5.5 0 0 0 0-1H2.5A1.5 1.5 0 0 0 1 2.5v11z"/>
                            </svg>
                          </button>
                          <button 
                            onClick={() => openDeleteConfirm(entry)}
                            className="btn btn-icon border bg-transparent"
                            style={{ width: '32px', height: '32px', padding: '0', display: 'inline-flex', alignItems: 'center', justifyContent: 'center'}}
                            title="Remove"
                          >
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="red" viewBox="0 0 16 16">
                              <path d="M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5Zm2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5Zm3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0V6Z"/>
                              <path d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1v1ZM4.118 4 4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4H4.118ZM2.5 3h11V2h-11v1Z"/>
                            </svg>
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Modals */}
      {showAddModal && (
        <AddETFModal
          etfs={etfs}
          etfSearchTerm={etfSearchTerm}
          setEtfSearchTerm={setEtfSearchTerm}
          formData={formData}
          handleInputChange={handleInputChange}
          handleAddSubmit={handleAddSubmit}
          setShowAddModal={setShowAddModal}
          resetForm={resetForm}
          isPending={addEntryMutation.isPending}
        />
      )}

      {showEditModal && selectedEntry && (
        <EditETFModal
          selectedEntry={selectedEntry}
          formData={formData}
          handleInputChange={handleInputChange}
          handleEditSubmit={handleEditSubmit}
          setShowEditModal={setShowEditModal}
          resetForm={resetForm}
          isPending={updateEntryMutation.isPending}
        />
      )}

      {showDeleteConfirm && selectedEntry && (
        <DeleteConfirmationModal
          itemName={selectedEntry.etf.ticker}
          handleDelete={handleDelete}
          setShowDeleteConfirm={setShowDeleteConfirm}
          resetSelection={() => setSelectedEntry(null)}
          isPending={removeEntryMutation.isPending}
          itemType="ETF"
        />
      )}
    </>
  );
};

export default ETFInvestmentsSection; 