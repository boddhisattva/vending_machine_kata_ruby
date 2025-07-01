# Vending Machine Kata

A Ruby implementation of a vending machine that handles product selection, money insertion, and change management using the Money gem for robust currency handling.

## Features

- Product selection and inventory management
- Money insertion with proper currency handling
- Change calculation and return
- Support for UK currency denominations (1p, 2p, 5p, 10p, 20p, 50p, £1, £2)
- Inventory and balance tracking

## Architecture

The system is built around three main classes:

- **VendingMachine**: Main orchestrator that manages items and balance
- **Item**: Represents products with name and price (using Money objects)
- **Change**: Handles monetary denominations using the Money gem

## Currency Handling

This implementation uses the [Money gem](https://github.com/RubyMoney/money) for:
- Precise currency calculations
- Proper handling of pence and pounds
- Type safety for monetary values
- Support for UK currency (GBP)

All monetary values are handled as Money objects with amounts in pence (e.g., £1.50 = Money.new(150, 'GBP')).

## Development

### Setup
```bash
bundle install
```

### Running Tests
```bash
bundle exec rspec
```

### Code Quality
```bash
bundle exec rubocop
```

## User Stories

**User Story 1**: As a user I want to select a product and also insert the amount of money required, so that I can retrieve it from the machine

- User should be able to select a product if it exists
- User should be able to see the inventory & stock balance at a given point in time
