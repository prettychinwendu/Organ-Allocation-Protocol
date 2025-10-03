# Decentralized Organ Transplant Registry Contract

A blockchain-based medical coordination platform that manages organ donation and transplantation through secure, transparent, and immutable record-keeping.

## Overview

This smart contract enables medical institutions to register donors and recipients, validate medical compatibility, coordinate transplant procedures, and maintain comprehensive audit trails of all operations while ensuring patient privacy and regulatory compliance.

## Features

- Donor and recipient registration with complete medical profiles
- Medical compatibility validation including blood type and organ matching
- Transplant procedure tracking and documentation
- Medical clearance management
- Priority-based waiting list system
- Comprehensive platform analytics
- Immutable audit trail of all operations

## Contract Architecture

### Constants

#### Error Codes

**Access Control**
- `ERR-UNAUTHORIZED-ACCESS` (200): Caller lacks required permissions
- `ERR-INSUFFICIENT-PRIVILEGES` (201): Insufficient access privileges

**Entity Registration**
- `ERR-DONOR-NOT-FOUND` (210): Donor not found in registry
- `ERR-DONOR-ALREADY-REGISTERED` (211): Donor already exists
- `ERR-RECIPIENT-NOT-FOUND` (212): Recipient not found in registry
- `ERR-RECIPIENT-ALREADY-REGISTERED` (213): Recipient already exists
- `ERR-PROCEDURE-NOT-FOUND` (214): Procedure ID invalid

**Medical Validation**
- `ERR-INVALID-ORGAN-SPECIFICATION` (220): Invalid organ type
- `ERR-INVALID-BLOOD-TYPE-SPECIFICATION` (221): Invalid blood type
- `ERR-ORGAN-UNAVAILABLE` (222): Requested organ not available
- `ERR-MEDICAL-INCOMPATIBILITY-DETECTED` (223): Medical incompatibility found
- `ERR-INVALID-PATIENT-STATUS` (224): Invalid patient status
- `ERR-INVALID-PRIORITY-SPECIFICATION` (225): Invalid priority level
- `ERR-MEDICAL-CLEARANCE-REQUIRED` (226): Medical clearance needed

**Patient Data Validation**
- `ERR-INVALID-PATIENT-INFORMATION` (230): Invalid patient data
- `ERR-MISSING-PATIENT-IDENTIFIER` (231): Missing patient identifier
- `ERR-INVALID-AGE-SPECIFICATION` (232): Invalid age value

#### Organ Types

- `organ-type-heart` (1): Heart
- `organ-type-kidney` (2): Kidney
- `organ-type-liver` (3): Liver
- `organ-type-lung` (4): Lung
- `organ-type-pancreas` (5): Pancreas
- `organ-type-cornea` (6): Cornea

#### Blood Types

- `blood-a-positive` (1): A+
- `blood-b-positive` (2): B+
- `blood-ab-positive` (3): AB+
- `blood-o-positive` (4): O+

#### Patient Status

- `status-active` (1): Active in system
- `status-matched` (2): Matched for procedure
- `status-completed` (3): Procedure completed
- `status-inactive` (4): Inactive

#### Priority Levels

- `priority-critical` (1): Critical urgency
- `priority-urgent` (2): Urgent
- `priority-high` (3): High priority
- `priority-moderate` (4): Moderate priority
- `priority-routine` (5): Routine

## Public Functions

### Donor Management

#### register-donor
Registers a new organ donor with complete medical profile.

**Parameters:**
- `name` (string-ascii 100): Patient name
- `age` (uint): Patient age (1-119)
- `blood-type` (uint): Blood type code (1-4)
- `organs` (list 10 uint): List of available organ types

**Returns:** `(ok true)` on success

**Requirements:**
- Name must not be empty
- Age must be between 1 and 119
- Blood type must be valid (1-4)
- All organs must be valid types (1-6)
- Donor must not already be registered

#### set-donor-clearance
Updates medical clearance status for a registered donor.

**Parameters:**
- `donor-address` (principal): Donor's address
- `clearance-approved` (bool): Clearance status
- `physician` (optional principal): Assigned physician

**Returns:** `(ok true)` on success

**Requirements:**
- Caller must be contract owner
- Donor must exist in registry

### Recipient Management

#### register-recipient
Registers a new transplant recipient with medical requirements.

**Parameters:**
- `name` (string-ascii 100): Patient name
- `age` (uint): Patient age (1-119)
- `blood-type` (uint): Blood type code (1-4)
- `organ-needed` (uint): Required organ type (1-6)
- `priority` (uint): Priority level (1-5)

**Returns:** `(ok true)` on success

**Requirements:**
- Name must not be empty
- Age must be between 1 and 119
- Blood type must be valid (1-4)
- Organ type must be valid (1-6)
- Priority must be valid (1-5)
- Recipient must not already be registered

### Procedure Management

#### initiate-procedure
Initiates a transplant procedure between matched donor and recipient.

**Parameters:**
- `donor-address` (principal): Donor's address
- `recipient-address` (principal): Recipient's address
- `organ-type` (uint): Organ being transplanted

**Returns:** `(ok procedure-id)` on success

**Requirements:**
- Caller must be contract owner
- Donor must have medical clearance
- Both parties must have active status
- Donor must have requested organ available
- Organ types must match
- Blood types must be compatible

#### complete-procedure
Marks a transplant procedure as successfully completed.

**Parameters:**
- `procedure-id` (uint): Procedure identifier

**Returns:** `(ok true)` on success

**Requirements:**
- Caller must be contract owner
- Procedure must exist
- Procedure status must be matched

#### analyze-recipient-compatibility
Analyzes recipient compatibility requirements and medical urgency.

**Parameters:**
- `recipient-address` (principal): Recipient's address

**Returns:** Compatibility analysis object

**Requirements:**
- Recipient must exist
- Recipient must have active status

## Read-Only Functions

### get-donor
Retrieves complete donor profile by principal address.

**Parameters:**
- `donor-address` (principal): Donor's address

**Returns:** Optional donor profile object

### get-recipient
Retrieves complete recipient profile by principal address.

**Parameters:**
- `recipient-address` (principal): Recipient's address

**Returns:** Optional recipient profile object

### get-procedure
Retrieves procedure details by procedure identifier.

**Parameters:**
- `procedure-id` (uint): Procedure identifier

**Returns:** Optional procedure object

### get-platform-stats
Returns comprehensive platform statistics and metrics.

**Returns:** Object containing:
- `donors-registered`: Total donors
- `recipients-registered`: Total recipients
- `transplants-completed`: Successful transplants
- `procedures-ongoing`: Active procedures
- `next-procedure-number`: Next procedure ID

### check-blood-compatibility
Validates blood type compatibility between two blood types.

**Parameters:**
- `donor-blood` (uint): Donor blood type
- `recipient-blood` (uint): Recipient blood type

**Returns:** Boolean indicating compatibility

### get-admin
Returns the contract administrator principal address.

**Returns:** Principal address of contract owner

## Blood Type Compatibility Rules

The contract implements the following compatibility logic:
- O+ can donate to all blood types
- AB+ can receive from all blood types
- Exact blood type matches are always compatible
- A+ can donate to AB+
- B+ can donate to AB+

## Security Considerations

- Only the contract owner can approve medical clearances
- Only the contract owner can initiate and complete procedures
- All patient data is stored on-chain and immutable
- Comprehensive validation prevents invalid medical data
- Status checks prevent duplicate or invalid operations

## Usage Example

```clarity
;; Register a donor
(contract-call? .organ-registry register-donor 
  "John Doe" 
  u35 
  blood-a-positive 
  (list organ-type-kidney organ-type-liver))

;; Register a recipient
(contract-call? .organ-registry register-recipient 
  "Jane Smith" 
  u42 
  blood-a-positive 
  organ-type-kidney 
  priority-urgent)

;; Set donor clearance (owner only)
(contract-call? .organ-registry set-donor-clearance 
  'SP123... 
  true 
  (some 'SP456...))

;; Initiate procedure (owner only)
(contract-call? .organ-registry initiate-procedure 
  'SP123... 
  'SP789... 
  organ-type-kidney)

;; Complete procedure (owner only)
(contract-call? .organ-registry complete-procedure u1)

;; Check platform statistics
(contract-call? .organ-registry get-platform-stats)
```