# Vending Machine CLI Flow Diagrams

## 1. Happy Path - Purchase with Excess Payment

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       │ Starts CLI
       ▼
┌─────────────────────────────────────────┐
│         VendingMachineCLI               │
│  Shows Menu (Options 1-6, q)            │
└──────┬──────────────────────────────────┘
       │
       │ User selects "2" (Purchase)
       ▼
┌─────────────────────────────────────────┐
│        ItemSelector                      │
│  Shows available items:                  │
│  1. Coke - €1.50 (5 available)          │
│  2. Chips - €1.00 (3 available)         │
│  3. Candy - €0.75 (8 available)         │
│  4. Water - €1.25 (2 available)         │
└──────┬──────────────────────────────────┘
       │
       │ User selects "2" (Chips €1.00)
       ▼
┌─────────────────────────────────────────┐
│      SessionManager                      │
│  Creates purchase session for Chips      │
│  "Please insert 100 cents for Chips"     │
└──────┬──────────────────────────────────┘
       │
       │ User enters {200=>1} (€2.00)
       ▼
┌─────────────────────────────────────────┐
│      ChangeValidator                     │
│  Checks if €1.00 change can be made      │
│  Sufficient coins available ✓            │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│     PaymentProcessor                     │
│  Validates payment: €2.00 > €1.00 ✓      │
│  Calculates change: €1.00                │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│      VendingMachine                      │
│  - Decrements Chips quantity: 3→2        │
│  - Updates balance:                      │
│    Before: €10.72                        │
│    + €2.00 payment                       │
│    - €1.00 change given                  │
│    After: €11.72                         │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         Output to User                   │
│  "Thank you for your purchase of Chips"  │
│  "Please collect your item and change:   │
│   1 x 100c"                             │
└─────────────────────────────────────────┘
```

## 2. Reload Item Flow

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       │ Selects "5" (Reload items)
       ▼
┌─────────────────────────────────────────┐
│         ItemReloader                     │
│  "=== Reload Items ==="                  │
│  Shows current stock:                    │
│  - Coke: 5 units                        │
│  - Chips: 2 units                       │
│  - Candy: 8 units                       │
│  - Water: 2 units                       │
└──────┬──────────────────────────────────┘
       │
       │ User enters "Chips" (existing item)
       ▼
┌─────────────────────────────────────────┐
│       ItemReloader                       │
│  "Enter quantity to add:"                │
└──────┬──────────────────────────────────┘
       │
       │ User enters "10"
       ▼
┌─────────────────────────────────────────┐
│      VendingMachine#reload_item          │
│  - Finds existing item "Chips"           │
│  - Updates quantity: 2 + 10 = 12         │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         Output to User                   │
│  "Successfully added 10 units to Chips"  │
│  "New quantity: 12"                      │
└─────────────────────────────────────────┘

Alternative: Adding New Item
       │
       │ User enters "Juice" (new item)
       ▼
┌─────────────────────────────────────────┐
│       ItemReloader                       │
│  "Item not found. Enter price in cents:" │
└──────┬──────────────────────────────────┘
       │
       │ User enters "175" (€1.75)
       ▼
┌─────────────────────────────────────────┐
│      VendingMachine#reload_item          │
│  - Creates new Item("Juice", 175, 5)     │
│  - Adds to items collection              │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         Output to User                   │
│  "Successfully added new item:           │
│   Juice - €1.75 (5 units)"              │
└─────────────────────────────────────────┘
```

## 3. Reload Coins Flow

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       │ Selects "6" (Reload change)
       ▼
┌─────────────────────────────────────────┐
│        ChangeReloader                    │
│  "=== Reload Change ==="                 │
│  "Current balance: €11.72"               │
│  "Enter coins as hash format:"           │
│  "Example: {100=>5, 50=>10}"            │
└──────┬──────────────────────────────────┘
       │
       │ User enters {100=>5, 50=>10, 20=>5}
       ▼
┌─────────────────────────────────────────┐
│      PaymentInputParser                  │
│  Parses: {100=>5, 50=>10, 20=>5}        │
│  Validates denominations ✓               │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│     VendingMachine#reload_change         │
│  Before: €11.72 (1172 cents)            │
│  Adding: €11.00 (1100 cents)            │
│  - 5 x €1.00 = €5.00                    │
│  - 10 x €0.50 = €5.00                   │
│  - 5 x €0.20 = €1.00                    │
│  After: €22.72 (2272 cents)             │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         Output to User                   │
│  "Successfully added coins:              │
│   5 1 Euro coins, 10 50-cent coins,     │
│   5 20-cent coins"                      │
│  "Total balance: €22.72"                │
└─────────────────────────────────────────┘
```

## 4. Insufficient Payment Flow

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       │ Purchase Coke (€1.50)
       ▼
┌─────────────────────────────────────────┐
│      SessionManager                      │
│  "Please insert 150 cents for Coke"      │
└──────┬──────────────────────────────────┘
       │
       │ User enters {100=>1} (€1.00)
       ▼
┌─────────────────────────────────────────┐
│     SessionManager                       │
│  accumulated_payment: €1.00              │
│  required: €1.50                         │
│  remaining: €0.50                        │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         Output to User                   │
│  "Payment received: €1.00"               │
│  "Remaining amount: €0.50"               │
│  "Please insert additional payment"      │
└──────┬──────────────────────────────────┘
       │
       │ User enters {50=>1} (€0.50)
       ▼
┌─────────────────────────────────────────┐
│     SessionManager                       │
│  accumulated_payment: €1.50              │
│  required: €1.50                         │
│  Payment complete! ✓                     │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│      PaymentProcessor                    │
│  Process payment: €1.50 = €1.50          │
│  No change needed                        │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         Output to User                   │
│  "Payment complete!"                     │
│  "Thank you for your purchase of Coke"   │
│  "Please collect your item"              │
└─────────────────────────────────────────┘
```

## 5. Insufficient Change → Auto-Cancel Flow

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       │ Purchase Chips (€1.00)
       ▼
┌─────────────────────────────────────────┐
│      SessionManager                      │
│  "Please insert 100 cents for Chips"     │
└──────┬──────────────────────────────────┘
       │
       │ User enters {200=>1} (€2.00)
       ▼
┌─────────────────────────────────────────┐
│     SessionManager                       │
│  Payment received: €2.00                 │
│  Required: €1.00                         │
│  Change needed: €1.00                    │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│      ChangeValidator (NEW)               │
│  Checks if €1.00 change can be made      │
│  Available coins insufficient ✗          │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│    VendingMachine#auto_cancel_with_      │
│         refund (NEW)                     │
│  - Cancels session automatically         │
│  - Returns payment to user               │
│  - Clears session state                  │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         Output to User                   │
│  "Cannot provide change."                │
│  "Payment refunded: 1 x €2"              │
│  "Please try with exact amount."         │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│   PurchaseSessionOrchestrator            │
│  Recognizes refund message               │
│  Exits payment loop                      │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         Main Menu Display                │
│  Choose an option:                       │
│  1. Display available items              │
│  2. Purchase item with session           │
│  3. Display current balance              │
│  4. Display machine status               │
│  5. Reload items                         │
│  6. Reload change                        │
│  q. Quit                                 │
│  Enter your choice: _                    │
└─────────────────────────────────────────┘
```

## 6. Invalid Denomination → Correction Flow

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       │ Purchase Candy (€0.75)
       ▼
┌─────────────────────────────────────────┐
│      SessionManager                      │
│  "Please insert 75 cents for Candy"      │
└──────┬──────────────────────────────────┘
       │
       │ User enters {25=>3} (invalid coin)
       ▼
┌─────────────────────────────────────────┐
│      PaymentInputParser                  │
│  Validates denominations                 │
│  25 ∉ [1,2,5,10,20,50,100,200] ✗        │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         Output to User                   │
│  "Error: Invalid coin denominations"     │
│  "25 cent coins are not accepted"        │
│  "Acceptable: 1,2,5,10,20,50,100,200"   │
│  "Session remains active"                │
└──────┬──────────────────────────────────┘
       │
       │ User enters {50=>1, 20=>1, 5=>1}
       ▼
┌─────────────────────────────────────────┐
│      PaymentInputParser                  │
│  Validates: 50,20,5 ✓                   │
│  Total: €0.75                           │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│     SessionManager                       │
│  Payment: €0.75 = Required: €0.75 ✓      │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│      PaymentProcessor                    │
│  Exact payment - no change needed        │
│  Update balance with new coins           │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│      VendingMachine                      │
│  - Decrements Candy quantity: 8→7        │
│  - Balance updated with:                 │
│    + 1 x 50-cent coin                   │
│    + 1 x 20-cent coin                   │
│    + 1 x 5-cent coin                    │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         Output to User                   │
│  "Payment complete!"                     │
│  "Thank you for your purchase of Candy"  │
│  "Please collect your item"              │
└─────────────────────────────────────────┘
```

## Key Components & Responsibilities

### Component Interaction Map (Updated)
```
┌──────────────────────────────────────────────────────────┐
│                    VendingMachineCLI                      │
│  - Main orchestrator                                      │
│  - Menu navigation                                        │
│  - User interaction loop                                  │
└────────────┬─────────────────────────────┬───────────────┘
             │                             │
             ▼                             ▼
┌─────────────────────────┐   ┌─────────────────────────┐
│   PurchaseOrchestrator  │   │    ItemReloader/        │
│   - Purchase flow       │   │    ChangeReloader       │
│   - Session management  │   │    - Reload flows       │
│   - Auto-cancel detect  │   │                         │
└───────────┬─────────────┘   └───────────┬─────────────┘
            │                              │
            ▼                              ▼
┌─────────────────────────────────────────────────────────┐
│                    VendingMachine                        │
│  - Core business logic                                   │
│  - State management (items, balance)                     │
│  - Auto-cancel with refund (NEW)                         │
│  - Delegates to specialized components                   │
└────┬────────┬────────┬────────┬────────┬────────┬──────┘
     │        │        │        │        │        │
     ▼        ▼        ▼        ▼        ▼        ▼
┌──────┐ ┌────────┐ ┌──────────┐ ┌────────┐ ┌──────────────┐
│Items │ │Change  │ │Payment   │ │Session │ │Change        │
│      │ │        │ │Processor │ │Manager │ │Validator(NEW)│
└──────┘ └────────┘ └──────────┘ └────────┘ └──────────────┘
                         │                          │
                         ▼                          ▼
                    ┌──────────────────────────────────┐
                    │   ChangeCalculator (Shared)      │
                    │   - make_change algorithm        │
                    │   - can_make_exact_change?       │
                    └──────────────────────────────────┘
```
