# Portfolio Components

This directory contains the components used to build the Portfolio Detail page. The components are structured in a modular way to improve code maintainability and reusability.

## Component Structure

- **PortfolioHeader**: Displays the portfolio name, description, and total value.
- **PortfolioTabNavigation**: Handles tab navigation between ETF and direct asset investments.
- **ETFInvestmentsSection**: Displays ETF allocation chart and ETF holdings table. Manages ETF-related modals.
- **DirectInvestmentsSection**: Displays direct asset allocation chart and asset holdings table. Manages asset-related modals.
- **PortfolioDiversificationSection**: Displays industry and country breakdown charts.

### Modals

The `modals` subdirectory contains modal components:

- **AddETFModal**: Form modal for adding a new ETF to the portfolio.
- **EditETFModal**: Form modal for editing an existing ETF entry.
- **AddAssetModal**: Form modal for adding a new direct asset to the portfolio.
- **EditAssetModal**: Form modal for editing an existing direct asset entry.
- **DeleteConfirmationModal**: Generic confirmation modal for deletion operations.

## Custom Hooks

The application uses custom hooks located in the `hooks` directory to manage state and side effects:

- **useETFManagement**: Manages ETF-related state, mutations, and event handlers.
- **useAssetManagement**: Manages asset-related state, mutations, and event handlers.
- **usePortfolioData**: Computes derived state for portfolio data (allocation, totals, etc.).

## Utilities

- **chartHelpers**: Provides utility functions for chart data manipulation, such as combining smaller categories into an "Others" section.

## Component Flow

1. The main `PortfolioDetail` component fetches data and passes it to child components.
2. Each child component is responsible for rendering a specific part of the UI.
3. Custom hooks manage state and API interactions, separating this logic from the UI components.
4. Modal components handle user interactions for CRUD operations.

This modular structure makes the code more maintainable and easier to test. Each component has a clearly defined responsibility, and the separation of concerns improves code quality. 