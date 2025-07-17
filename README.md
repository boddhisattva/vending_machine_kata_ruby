# Vending Machine Kata (Ruby)

## Features
- Default currency: Euro (€)
- Supports session-based purchase flow (recommended for extensibility and real-world use)
- Coin denominations supported: 1, 2, 5, 10, 20, 50, 100, 200 cents
- Displays available change and coin breakdown in plain English

## Usage

### Running the CLI

```sh
ruby bin/vending_machine_cli.rb
```

### CLI Options
- **1. Display available items**
- **2. Purchase item with session (recommended)**
  - Select item by number
  - Enter payment as a hash, e.g. `{100 => 2, 50 => 1}` for €2.50
  - You can insert more coins until the price is met
  - Type `cancel` to cancel the session
- **3. Display current balance**
- **4. Return change**
- **5. Display machine status**
- **q. Quit**

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

## Notes
- All currency is displayed as Euro (€) with two decimals (e.g., `€1.50`)
- Only the session-based purchase flow is supported (no legacy/one-step purchase)
- Coin breakdown is always shown in plain English

## Running the Demo

```sh
ruby bin/demo.rb
```

This will run a scripted demo of the vending machine's features.

