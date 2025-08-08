# Vending Machine (Ruby)

## About
Solves for building a Vending Machine  based on the problem statement here: [problem_statement.md](https://github.com/boddhisattva/vending_machine_kata_ruby/blob/main/problem_statement.md)

## Visual Representation of Key Flows with using Vending Machine Functionality
Please refer to `[docs/cli_flow_diagrams.md](https://github.com/boddhisattva/vending_machine_kata_ruby/blob/main/docs/cli_flow_diagrams.md)` for Key Flows
involving the Vending Machine usage including
- Happy path
- Reload functionality
- Partial payment and being prompted to pay more
- Key components that make up the app


## Architecture & Design

  ### Core Architecture Principles

  #### Separation of Concerns

  ```
    ┌─────────────────┐
    │   CLI Layer     │  (User Interface)
    │  bin/ & lib/cli/│
    └────────┬────────┘
            │
    ┌────────▼────────┐
    │  Business Logic │  (Core Domain)
    │      lib/       │
    └────────┬────────┘
            │
    ┌────────▼────────┐
    │   Data Layer    │  (State Management)
    │  Items, Balance │
    └─────────────────┘
  ```

  #### Key Components of the Vending Machine CLI
  **Core Components:**
    - **VendingMachine**: Main orchestrator, delegates to specialized components
    - **PurchaseSessionOrchestrator**: CLI-specific coordinator that manages the interactive payment collection loop, handling user input and payment parsing until purchase
    completion
    - **PaymentProcessor**: Handles all payment transactions and change calculation
    - **SessionManager**: Manages multi-step purchase sessions
    - **ReloadManager**: Handles inventory and change reloading
    - **Validators**: Dedicated classes for each validation concern
      - PaymentValidator: Validates denominations and amounts
      - ReloadValidator: Validates reload operations
      - ChangeValidator: Ensures change can be made
    - **Formatters**: Consistent formatting across the application
      - CurrencyFormatter: Euro formatting

  **CLI-Specific Components:**
    - PurchaseExecutor: Orchestrates the item selection phase of a CLI purchase
    - ItemSelector: Handles item selection by number with validation and display
    - UserInputHandler: Captures and sanitizes user keyboard input
    - VendingMachineDisplay: Renders all UI output (menus, status, messages)
    - PaymentInputParser: Parses string input like "{100 => 2}" into payment hashes
    - MenuRouter: Routes menu choices to appropriate actions
    - ItemReloader: Handles CLI flow for reloading items interactively
    - ChangeReloader: Handles CLI flow for reloading change interactively

  ### Session-Based Purchase Flow

  The modern session-based API provides a realistic vending machine experience:

  ```ruby
  1. START SESSION
     ↓
  2. ACCUMULATE PAYMENTS (multiple insertions allowed)
     ↓
  3. VALIDATE CHANGE AVAILABILITY
     ↓
  4. COMPLETE or AUTO-CANCEL WITH REFUND

## Features
- Default currency: Euro (€)
- Check machine status(of remaining items & balance) at anytime
- Check machine balance at any point in time
- Supports session-based purchase flow
- Add reload functionality for
  - Existing and New Items
  - To Add change
- Coin denominations supported: 1, 2, 5, 10, 20, 50, 100, 200 cents
- Displays available change and coin breakdown in plain English

## Performance Optimizations
  - O(1) Item Lookup

  # Instead of O(n) linear search:
  items.find { |item| item.name == item_name }  # Slow for large inventories

  # We use O(1) hash lookup:
  @items_index[item_name]  # Instant access regardless of inventory size

## Assumptions
- A user can purchase only one item at a time

## Usage

### Running the Vending Machine CLI

```sh
ruby bin/vending_machine_cli.rb
```

### CLI Options
- **1. Display available items**
  - Shows all items with prices and quantities available
- **2. Purchase item with session**
  - Select item by number
  - Enter payment as a hash, e.g. `{100 => 2, 50 => 1}` for €2.50
  - You can insert more coins until the price is met
  - Type `cancel` to cancel the session
- **3. Display current balance**
  - Shows available change in the machine with coin breakdown
- **4. Display machine status**
  - Shows complete machine status including balance and inventory
- **5. Reload or add new items**
  - Add quantity to existing items or add new items with prices
- **6. Reload change**
  - Add coins to the machine's balance
- **q. Quit** (also accepts `quit` or `exit`)

### Example Payment Format
- `{100 => 2, 50 => 1}` means 2 €1 coins and 1 50-cent coin (total: €2.50)
- Valid denominations: 1, 2, 5, 10, 20, 50, 100, 200 (all in cents)

### Initial Machine Balance
The machine starts with the following coins:
```
{
  50 => 6,
  10 => 10,
  20 => 10,
  100 => 2,
  200 => 1,
  5 => 10,
  2 => 10,
  1 => 2
}
```

### Initial Items in Vending Machine
```
  INITIAL_ITEMS = [
    { name: 'Coke', price: 150, quantity: 5 },
    { name: 'Chips', price: 100, quantity: 3 },
    { name: 'Candy', price: 75, quantity: 8 },
    { name: 'Water', price: 125, quantity: 2 }
  ]
```

## Notes
- All currency is displayed as Euro (€) with two decimals (e.g., `€1.50`)
- Only the session-based purchase flow is supported (no legacy/one-step purchase)
- Coin breakdown is always shown in plain English

