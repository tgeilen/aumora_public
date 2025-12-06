# Aumora - ETF Portfolio Management Platform

Aumora is a full-stack portfolio management application designed for tracking and analyzing Exchange Traded Fund (ETF) investments. The platform enables users to create portfolios, track both ETF and direct asset holdings, and gain comprehensive insights into portfolio diversification through automated analysis of industry, country, and individual security exposure.

## Features

### Portfolio Management
- Create and manage multiple portfolios per user
- Track ETF holdings with shares, purchase prices, and dates
- Track direct asset holdings independently
- Real-time portfolio value calculations
- Support for multi-currency assets with automatic USD conversion

### ETF Data Synchronization
- Automated fetching of ETF holdings data from iShares
- Intelligent CSV/XLS parsing supporting multiple data formats
- Separate parsers for equity and bond ETFs
- Rate-limited web scraping to respect provider limits
- Background job processing with Sidekiq for reliable data updates
- Historical holdings tracking with date-based snapshots

### Portfolio Analysis
- **Holdings Breakdown**: Aggregate analysis combining direct holdings and ETF constituents
- **Industry Analysis**: Portfolio exposure by industry sector
- **Geographic Analysis**: Portfolio exposure by country
- **Security-Level Analysis**: Total exposure to individual securities across all holdings
- **Separate Breakdowns**: View ETF-only or direct asset-only allocations
- **Total Exposure Calculation**: Comprehensive view of all securities including those held indirectly through ETFs

### User Authentication
- JWT-based authentication
- Email confirmation workflow
- Password reset functionality
- Secure session management

### Data Management
- Asset identifier normalization to prevent duplicates
- Multi-currency price tracking with exchange rate integration
- Automatic USD price normalization for consistent analysis
- Special handling for bond assets (percentage-based pricing)

## Tech Stack

### Backend
- **Framework**: Ruby on Rails 8.0.2
- **Database**: PostgreSQL
- **Authentication**: Devise with JWT (devise-jwt)
- **Background Jobs**: Sidekiq with sidekiq-cron
- **API Serialization**: jsonapi-serializer
- **HTTP Client**: HTTParty
- **File Parsing**: Nokogiri (HTML), Creek (Excel), CSV
- **Bulk Operations**: activerecord-import

### Frontend
- **Framework**: React 18 with TypeScript
- **Build Tool**: Vite
- **Routing**: React Router v7
- **State Management**: TanStack Query (React Query)
- **Styling**: Bootstrap 5 + Tailwind CSS 4
- **Charts**: Recharts
- **HTTP Client**: Axios

### Infrastructure
- **Web Server**: Puma
- **Asset Pipeline**: Vite Rails
- **Job Queue**: Sidekiq
- **Cache**: Solid Cache
- **Cable**: Solid Cable

## Prerequisites

- Ruby 3.3.7
- PostgreSQL 9.3+
- Node.js 18+
- Yarn or npm

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd aumora
```

2. Install Ruby dependencies:
```bash
bundle install
```

3. Install JavaScript dependencies:
```bash
npm install
# or
yarn install
```

4. Set up the database:
```bash
rails db:create
rails db:migrate
```

5. Configure environment variables:
Create a `.env` file in the root directory with the following variables:
```bash
# Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your_password
DATABASE_NAME_DEVELOPMENT=aumora_development
DATABASE_NAME_TEST=aumora_test

# Rails
SECRET_KEY_BASE=your_secret_key_base
RAILS_ENV=development

# Currency API (for exchange rate conversion)
CURRENCY_API_KEY=your_currency_api_key

# Sidekiq (optional, defaults provided)
SIDEKIQ_USERNAME=admin
SIDEKIQ_PASSWORD=password

# Frontend URL (for email links)
FRONTEND_URL=http://localhost:5173
```

6. Seed initial data (optional):
```bash
# Import iShares ETF list
rails etf_data:import_ishares_etfs
```

## Running the Application

### Development

Start the Rails server:
```bash
rails server
```

In a separate terminal, start the Vite dev server:
```bash
npm run dev
# or
yarn dev
```

Start Sidekiq for background jobs:
```bash
bundle exec sidekiq
```

The application will be available at:
- Frontend: http://localhost:5173
- Backend API: http://localhost:3000
- Sidekiq Dashboard: http://localhost:3000/sidekiq

### Production

Build assets:
```bash
npm run build
# or
yarn build
```

Start the application:
```bash
rails server -e production
```

## Project Structure

```
aumora/
├── app/
│   ├── controllers/
│   │   └── api/v1/          # RESTful API controllers
│   ├── models/               # ActiveRecord models
│   ├── services/             # Business logic services
│   │   └── etf_data/         # ETF data fetching and parsing
│   ├── jobs/                 # Background jobs
│   └── javascript/
│       └── frontend/         # React/TypeScript frontend
│           ├── components/  # React components
│           ├── pages/       # Page components
│           ├── hooks/       # Custom React hooks
│           └── services/    # API service layer
├── config/                   # Rails configuration
├── db/
│   ├── migrate/             # Database migrations
│   └── seed_data/           # Seed data files
└── lib/tasks/               # Rake tasks
```

## API Endpoints

### Authentication
- `POST /api/v1/login` - User login
- `DELETE /api/v1/logout` - User logout
- `POST /api/v1/users` - User registration
- `GET /api/v1/users/current` - Current user info

### Portfolios
- `GET /api/v1/portfolios` - List user portfolios
- `POST /api/v1/portfolios` - Create portfolio
- `GET /api/v1/portfolios/:id` - Get portfolio details
- `PUT /api/v1/portfolios/:id` - Update portfolio
- `DELETE /api/v1/portfolios/:id` - Delete portfolio
- `GET /api/v1/portfolios/:id/holdings_breakdown` - Combined breakdown
- `GET /api/v1/portfolios/:id/etf_holdings_breakdown` - ETF-only breakdown
- `GET /api/v1/portfolios/:id/asset_holdings_breakdown` - Asset-only breakdown
- `GET /api/v1/portfolios/:id/total_holdings_exposure` - Total exposure analysis

### Portfolio Entries
- `POST /api/v1/portfolios/:id/entries` - Add ETF to portfolio
- `PUT /api/v1/portfolios/:id/entries/:entry_id` - Update ETF entry
- `DELETE /api/v1/portfolios/:id/entries/:entry_id` - Remove ETF

### Portfolio Asset Entries
- `POST /api/v1/portfolios/:id/asset_entries` - Add direct asset
- `PUT /api/v1/portfolios/:id/asset_entries/:id` - Update asset entry
- `DELETE /api/v1/portfolios/:id/asset_entries/:id` - Remove asset

### ETFs
- `GET /api/v1/etfs` - List all ETFs
- `GET /api/v1/etfs/:id` - Get ETF details
- `GET /api/v1/etfs/:id/holdings` - Get ETF holdings

### ETF Synchronization
- `POST /api/v1/etfs/sync` - Trigger ETF data synchronization

## Background Jobs

### ETF Data Synchronization
The application uses Sidekiq to process ETF data fetching asynchronously:

- `EtfSyncJob`: Orchestrates batch ETF synchronization with rate limiting
- `EtfDataFetchJob`: Fetches holdings data for individual ETFs
- `ScheduledEtfSyncJob`: Scheduled job for automatic updates

Jobs are configured with throttling to respect provider rate limits:
- Batch processing with configurable batch sizes
- Staggered execution to avoid overwhelming external APIs
- Automatic retry on failure

## Data Models

### Core Models
- **User**: Authentication and user accounts
- **Portfolio**: User-owned portfolio containers
- **ETF**: Exchange-traded funds with provider information
- **Asset**: Individual securities (stocks, bonds, etc.)
- **ETFProvider**: Data source providers (e.g., iShares)

### Relationship Models
- **PortfolioEntry**: Links portfolios to ETFs (shares owned)
- **PortfolioAssetEntry**: Direct asset holdings in portfolios
- **EtfHolding**: Links ETFs to Assets with weights and dates
- **ExchangeRate**: Currency conversion rates

## Key Features Implementation

### Asset Identifier Normalization
The system normalizes asset identifiers to prevent duplicates by:
- Removing exchange prefixes (NYSE:, NASDAQ:, etc.)
- Standardizing separators
- Handling ISINs specially
- Using PostgreSQL advisory locks for concurrency safety

### Multi-Currency Support
- Tracks asset prices in original currency
- Automatically converts to USD using exchange rate API
- Handles bond assets differently (percentage-based pricing)
- Updates exchange rates periodically

### Portfolio Analysis Engine
The analysis engine aggregates:
1. Direct asset holdings (shares × current price)
2. ETF holdings (ETF shares × ETF price × constituent weights)
3. Calculates exposure by:
   - Individual securities
   - Industry sectors
   - Geographic regions

## Development

### Running Tests
```bash
rails test
```

### Code Quality
The project uses RuboCop for Ruby code style:
```bash
bundle exec rubocop
```

### Database Migrations
```bash
rails db:migrate
rails db:rollback
```

### Rake Tasks
- `rails etf_data:import_ishares_etfs` - Import ETF list from XLS
- `rails etf_data:process_holdings_file[TICKER,FILE_PATH]` - Process holdings file
- `rails exchange_rates:fetch` - Update exchange rates

## Deployment

The application includes:
- Dockerfile for containerization
- Kamal deployment configuration
- Production-ready Sidekiq setup
- Health check endpoint at `/up`
