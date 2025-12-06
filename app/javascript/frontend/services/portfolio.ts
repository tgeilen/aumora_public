import api from './api';

export interface ETF {
  id: number;
  ticker: string;
  name: string;
  provider: {
    id: number;
    name: string;
  };
  last_updated_at: string;
  metadata: Record<string, unknown>;
}

export interface ETFHolding {
  id: number;
  asset_identifier: string;
  asset_name: string;
  asset_type: string;
  weight: number;
  industry: string;
  country: string;
  as_of_date: string;
}

export interface Asset {
  id: number;
  identifier: string;
  name: string;
  asset_type: string;
  country?: string;
  industry?: string;
}

export interface Portfolio {
  id: number;
  name: string;
  user_id: number;
  created_at: string;
  updated_at: string;
  total_value: number;
  last_etf_sync_at: string | null;
  entries: PortfolioEntry[];
  asset_entries: PortfolioAssetEntry[];
}

export interface PortfolioEntry {
  id: number;
  portfolio_id: number;
  etf_id: number;
  etf: ETF;
  shares: number;
  purchase_price: number;
  purchase_date: string;
  current_price: number;
  current_value: number;
}

export interface PortfolioAssetEntry {
  id: number;
  portfolio_id: number;
  asset_id: number;
  asset: Asset;
  shares: number;
  purchase_price: number;
  purchase_date: string;
  current_price: number;
  current_value: number;
  weight_in_portfolio: number;
}

export interface CreatePortfolioParams {
  name: string;
}

export interface AddPortfolioEntryParams {
  etf_id: number;
  shares: number;
  purchase_price?: number;
  purchase_date?: string;
}

export interface AddPortfolioAssetEntryParams {
  asset_id: number;
  shares: number;
  purchase_price?: number;
  purchase_date?: string;
}

export interface PortfolioHoldingsBreakdown {
  industries: Record<string, number>;
  countries: Record<string, number>;
  stocks: Record<string, number>;
}

export interface SecurityExposure {
  identifier: string;
  name: string;
  security_type: string;
  total_shares: number;
  total_value: number;
  direct_shares: number;
  direct_value: number;
  etf_shares: number;
  etf_value: number;
}

export interface TotalExposureData {
  securities: SecurityExposure[];
  total_portfolio_value: number;
}

/**
 * Helper function to adapt backend response format
 * Maps portfolio_entries to entries and portfolio_asset_entries to asset_entries if needed
 */
const adaptPortfolioResponse = (data: any): Portfolio => {
  let result: any = { ...data };
  
  // Ensure total_value is a number, default to 0 if not present
  result.total_value = data.total_value ? Number(data.total_value) : 0;
  
  // Handle portfolio entries (ETFs)
  if (data.portfolio_entries && !data.entries) {
    // Process portfolio entries to ensure correct data types
    const normalizedEntries = data.portfolio_entries.map((entry: any) => ({
      ...entry,
      shares: typeof entry.shares === 'number' ? entry.shares : Number(entry.shares),
      purchase_price: entry.purchase_price 
        ? (typeof entry.purchase_price === 'number' 
          ? entry.purchase_price 
          : Number(entry.purchase_price))
        : null,
      current_price: entry.current_price 
        ? (typeof entry.current_price === 'number' 
          ? entry.current_price 
          : Number(entry.current_price))
        : null,
      current_value: entry.current_value 
        ? (typeof entry.current_value === 'number' 
          ? entry.current_value 
          : Number(entry.current_value))
        : null
    }));
    
    result.entries = normalizedEntries;
  } else if (data.entries) {
    // If entries exist but may need type normalization
    const normalizedEntries = data.entries.map((entry: any) => ({
      ...entry,
      shares: typeof entry.shares === 'number' ? entry.shares : Number(entry.shares),
      purchase_price: entry.purchase_price 
        ? (typeof entry.purchase_price === 'number' 
          ? entry.purchase_price 
          : Number(entry.purchase_price))
        : null,
      current_price: entry.current_price 
        ? (typeof entry.current_price === 'number' 
          ? entry.current_price 
          : Number(entry.current_price))
        : null,
      current_value: entry.current_value 
        ? (typeof entry.current_value === 'number' 
          ? entry.current_value 
          : Number(entry.current_value))
        : null
    }));
    
    result.entries = normalizedEntries;
  } else {
    // If entries is undefined, ensure it's at least an empty array
    result.entries = [];
  }
  
  // Handle asset entries (direct investments)
  if (data.portfolio_asset_entries && !data.asset_entries) {
    // Process asset entries to ensure correct data types
    const normalizedAssetEntries = data.portfolio_asset_entries.map((entry: any) => ({
      ...entry,
      shares: typeof entry.shares === 'number' ? entry.shares : Number(entry.shares),
      purchase_price: entry.purchase_price 
        ? (typeof entry.purchase_price === 'number' 
          ? entry.purchase_price 
          : Number(entry.purchase_price))
        : null,
      current_price: entry.current_price 
        ? (typeof entry.current_price === 'number' 
          ? entry.current_price 
          : Number(entry.current_price))
        : null,
      current_value: entry.current_value 
        ? (typeof entry.current_value === 'number' 
          ? entry.current_value 
          : Number(entry.current_value))
        : null,
      weight_in_portfolio: entry.weight_in_portfolio 
        ? (typeof entry.weight_in_portfolio === 'number' 
          ? entry.weight_in_portfolio 
          : Number(entry.weight_in_portfolio))
        : 0
    }));
    
    result.asset_entries = normalizedAssetEntries;
  } else if (data.asset_entries) {
    // If asset entries exist but may need type normalization
    const normalizedAssetEntries = data.asset_entries.map((entry: any) => ({
      ...entry,
      shares: typeof entry.shares === 'number' ? entry.shares : Number(entry.shares),
      purchase_price: entry.purchase_price 
        ? (typeof entry.purchase_price === 'number' 
          ? entry.purchase_price 
          : Number(entry.purchase_price))
        : null,
      current_price: entry.current_price 
        ? (typeof entry.current_price === 'number' 
          ? entry.current_price 
          : Number(entry.current_price))
        : null,
      current_value: entry.current_value 
        ? (typeof entry.current_value === 'number' 
          ? entry.current_value 
          : Number(entry.current_value))
        : null,
      weight_in_portfolio: entry.weight_in_portfolio 
        ? (typeof entry.weight_in_portfolio === 'number' 
          ? entry.weight_in_portfolio 
          : Number(entry.weight_in_portfolio))
        : 0
    }));
    
    result.asset_entries = normalizedAssetEntries;
  } else {
    // If asset_entries is undefined, ensure it's at least an empty array
    result.asset_entries = [];
  }
  
  return result as Portfolio;
};

/**
 * Portfolio service for managing user portfolios and ETFs
 */
const portfolioService = {
  /**
   * Get all portfolios for the current user
   */
  getPortfolios: async (): Promise<Portfolio[]> => {
    const response = await api.get('/users/current/portfolios');
    return Array.isArray(response.data) 
      ? response.data.map(adaptPortfolioResponse)
      : [];
  },

  /**
   * Get a specific portfolio by ID
   */
  getPortfolio: async (id: number): Promise<Portfolio> => {
    const response = await api.get(`/portfolios/${id}`);
    return adaptPortfolioResponse(response.data);
  },

  /**
   * Create a new portfolio
   */
  createPortfolio: async (data: CreatePortfolioParams): Promise<Portfolio> => {
    const response = await api.post('/portfolios', { portfolio: data });
    return adaptPortfolioResponse(response.data);
  },

  /**
   * Update a portfolio
   */
  updatePortfolio: async (id: number, data: Partial<CreatePortfolioParams>): Promise<Portfolio> => {
    const response = await api.put(`/portfolios/${id}`, { portfolio: data });
    return adaptPortfolioResponse(response.data);
  },

  /**
   * Delete a portfolio
   */
  deletePortfolio: async (id: number): Promise<void> => {
    await api.delete(`/portfolios/${id}`);
  },

  /**
   * Add an ETF to a portfolio
   */
  addPortfolioEntry: async (portfolioId: number, data: AddPortfolioEntryParams): Promise<PortfolioEntry> => {
    const response = await api.post(`/portfolios/${portfolioId}/entries`, { entry: data });
    return response.data;
  },

  /**
   * Update a portfolio entry
   */
  updatePortfolioEntry: async (
    portfolioId: number, 
    entryId: number, 
    data: Partial<AddPortfolioEntryParams>
  ): Promise<PortfolioEntry> => {
    const response = await api.put(`/portfolios/${portfolioId}/entries/${entryId}`, { entry: data });
    return response.data;
  },

  /**
   * Remove an ETF from a portfolio
   */
  removePortfolioEntry: async (portfolioId: number, entryId: number): Promise<void> => {
    await api.delete(`/portfolios/${portfolioId}/entries/${entryId}`);
  },

  /**
   * Get all available ETFs
   */
  getETFs: async (): Promise<ETF[]> => {
    const response = await api.get('/etfs');
    return response.data;
  },

  /**
   * Get a specific ETF by ID
   */
  getETF: async (id: number): Promise<ETF> => {
    try {
      const response = await api.get(`/etfs/${id}`);
      
      // Check if the ETF is nested in an 'etf' field (API returns {etf: {...}, metadata: {...}, last_updated_at: '...'})
      if (response.data && response.data.etf) {
        // The response has a nested ETF object format, so extract and return the ETF with the metadata
        return {
          ...response.data.etf,
          metadata: response.data.metadata || {},
          last_updated_at: response.data.last_updated_at
        };
      }
      
      // Return as-is if not nested
      return response.data;
    } catch (error) {
      console.error('Error fetching ETF details:', error);
      throw error; // Re-throw to allow React Query to handle the error
    }
  },

  /**
   * Get holdings for a specific ETF
   */
  getETFHoldings: async (etfId: number): Promise<ETFHolding[]> => {
    try {
      const response = await api.get(`/etfs/${etfId}/holdings`);
      
      // Handle different response formats
      if (response.data && Array.isArray(response.data)) {
        return response.data;
      } else if (response.data && response.data.holdings && Array.isArray(response.data.holdings)) {
        return response.data.holdings;
      } else if (response.data && response.data.meta && response.data.holdings && Array.isArray(response.data.holdings)) {
        return response.data.holdings;
      } else {
        console.error('Unexpected holdings response format:', response.data);
        return [];
      }
    } catch (error) {
      console.error('Error fetching ETF holdings:', error);
      return [];
    }
  },

  /**
   * Get holdings breakdown for a portfolio
   */
  getPortfolioHoldingsBreakdown: async (portfolioId: number): Promise<PortfolioHoldingsBreakdown> => {
    const response = await api.get(`/portfolios/${portfolioId}/holdings_breakdown`);
    return response.data;
  },

  /**
   * Get all assets available for direct investment
   */
  getAssets: async (): Promise<Asset[]> => {
    const response = await api.get('/assets');
    // Handle both response formats: {assets: Asset[]} or Asset[] directly
    return response.data.assets || response.data;
  },

  /**
   * Get a specific asset by ID
   */
  getAsset: async (id: number): Promise<Asset> => {
    try {
      const response = await api.get(`/assets/${id}`);
      return response.data;
    } catch (error) {
      console.error('Error fetching asset details:', error);
      throw error;
    }
  },

  /**
   * Get all direct asset investments for a portfolio
   */
  getPortfolioAssetEntries: async (portfolioId: number): Promise<PortfolioAssetEntry[]> => {
    const response = await api.get(`/portfolios/${portfolioId}/asset_entries`);
    return response.data;
  },

  /**
   * Add a direct asset investment to a portfolio
   */
  addPortfolioAssetEntry: async (portfolioId: number, data: AddPortfolioAssetEntryParams): Promise<PortfolioAssetEntry> => {
    const response = await api.post(`/portfolios/${portfolioId}/asset_entries`, { portfolio_asset_entry: data });
    return response.data;
  },

  /**
   * Update a direct asset investment
   */
  updatePortfolioAssetEntry: async (
    portfolioId: number, 
    entryId: number, 
    data: Partial<AddPortfolioAssetEntryParams>
  ): Promise<PortfolioAssetEntry> => {
    const response = await api.put(`/portfolios/${portfolioId}/asset_entries/${entryId}`, { portfolio_asset_entry: data });
    return response.data;
  },

  /**
   * Remove a direct asset investment from a portfolio
   */
  removePortfolioAssetEntry: async (portfolioId: number, entryId: number): Promise<void> => {
    await api.delete(`/portfolios/${portfolioId}/asset_entries/${entryId}`);
  },

  getPortfolioETFHoldingsBreakdown: async (portfolioId: number): Promise<PortfolioHoldingsBreakdown> => {
    const response = await api.get(`/portfolios/${portfolioId}/etf_holdings_breakdown`);
    return response.data;
  },

  getPortfolioAssetHoldingsBreakdown: async (portfolioId: number): Promise<PortfolioHoldingsBreakdown> => {
    const response = await api.get(`/portfolios/${portfolioId}/asset_holdings_breakdown`);
    return response.data;
  },

  /**
   * Get total exposure to individual securities (direct + via ETFs)
   */
  getPortfolioTotalExposure: async (portfolioId: number): Promise<TotalExposureData> => {
    try {
      const response = await api.get(`/portfolios/${portfolioId}/total_holdings_exposure`);
      return response.data;
    } catch (error) {
      console.error('Error fetching portfolio total exposure:', error);
      throw error;
    }
  }
};

export default portfolioService; 