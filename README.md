# Internet and Cable Service Management System

A comprehensive blockchain-based system for managing internet and cable services built on the Stacks blockchain using Clarity smart contracts.

## Overview

This system provides a decentralized platform for managing various aspects of internet and cable services including appointments, technical support, service quality monitoring, pricing transparency, equipment management, and streaming service integration.

## Architecture

The system consists of five main smart contracts:

### 1. Service Appointments Contract (`service-appointments.clar`)
- Schedule and manage service appointments
- Track appointment status and technician assignments
- Handle appointment cancellations and rescheduling

### 2. Technical Support Contract (`technical-support.clar`)
- Create and manage support tickets
- Track issue resolution progress
- Maintain support agent assignments

### 3. Service Quality Contract (`service-quality.clar`)
- Monitor service quality metrics
- Report and track outages
- Store customer satisfaction ratings

### 4. Pricing Management Contract (`pricing-management.clar`)
- Manage transparent pricing structures
- Handle package customization
- Track promotional offers and discounts

### 5. Equipment Management Contract (`equipment-management.clar`)
- Manage equipment rental and purchases
- Track equipment upgrades and replacements
- Handle streaming service integrations and bundles

## Key Features

- **Decentralized Service Management**: All service data stored on blockchain for transparency
- **Appointment Scheduling**: Efficient scheduling system with conflict prevention
- **Quality Monitoring**: Real-time service quality tracking and outage reporting
- **Transparent Pricing**: Clear, immutable pricing structures
- **Equipment Tracking**: Complete equipment lifecycle management
- **Bundle Management**: Flexible streaming service and package bundling

## Data Types

### Service Plans
- Basic Internet
- Premium Internet
- Cable TV
- Streaming Bundles
- Custom Packages

### Appointment Types
- Installation
- Repair
- Upgrade
- Maintenance
- Disconnection

### Equipment Types
- Modem
- Router
- Cable Box
- Streaming Device
- DVR

## Getting Started

1. Install dependencies: `npm install`
2. Run tests: `npm test`
3. Deploy contracts using Clarinet
4. Interact with contracts through the provided interfaces

## Testing

The system includes comprehensive tests using Vitest covering all contract functionality including edge cases and error conditions.

## Security Considerations

- All contracts implement proper access controls
- Input validation on all public functions
- Protection against common smart contract vulnerabilities
- Immutable pricing and service records for transparency
