# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview
This is a Ruby implementation of a vending machine kata. The project models a vending machine that can:
- Accept product selection and money insertion
- Return correct products and change
- Track inventory and change denominations
- Handle reloading of products and change

## Workflow
- Please avoid redundant specs when writing new specs

## Core Architecture
The system is built around three main classes:
- `VendingMachine`: Main orchestrator that manages items and balance
- `Item`: Represents products with name and price
- `Change`: Handles monetary denominations (1p, 2p, 5p, 10p, 20p, 50p, £1, £2)

All classes are in `lib/` directory and follow Ruby conventions with corresponding specs in `spec/lib/`.

## Development Commands

### Running Tests
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/lib/vending_machine_spec.rb

# Run with specific format
bundle exec rspec --format documentation
```

### Code Quality
```bash
# Run RuboCop linter
bundle exec rubocop

# Run RuboCop with auto-correct
bundle exec rubocop -a

# Additional quality tools available:
bundle exec reek      # Code smell detection
bundle exec flog      # Complexity analysis
bundle exec fasterer  # Performance suggestions
bundle exec rubycritic # Overall code quality report
```

### Dependencies
```bash
# Install dependencies
bundle install

# Update dependencies
bundle update
```

## Project Structure
- Core logic in `lib/` with classes: VendingMachine, Item, Change
- Specs in `spec/lib/` mirroring the lib structure
- RSpec configured to auto-load all lib files via `spec_helper.rb`
- Ruby 3.4.4 with comprehensive linting and code quality tools

## Key Implementation Details
- Uses the Money gem for precise currency handling
- Change denominations are defined as Money objects in the Change class
- All monetary values are handled as Money objects with amounts in pence
- Items accept either numeric values (converted to Money) or Money objects directly
- The VendingMachine initializes with items and balance collections
- Follow TDD approach - specs are the primary way to verify functionality

### Money Gem Usage
- All prices and amounts use `Money.new(amount_in_pence, 'GBP')`
- Example: £1.50 = `Money.new(150, 'GBP')`
- Acceptable coins: 1p, 2p, 5p, 10p, 20p, 50p, £1, £2
- Classes automatically convert numeric inputs to Money objects
