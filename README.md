# Mortgage Application System

A Salesforce proof-of-concept implementing a simplified mortgage application process using Apex Enterprise Patterns (fflib).

## Project Structure

The solution implements two main user stories using fflib architecture:
- **Story A**: Submit Application (validation, product selection, task creation)
- **Story B**: Product Rate Normalization (async background processing) [IN PROGRESS]

## Story A: Submit Application

## Process Demo

**[▶️ Watch Story A Demo](https://www.loom.com/share/dc76320baf9944f9830bc83319938feb?sid=8e28daeb-e900-4fef-9235-734dc90a7bc2)**

See the complete loan application submission workflow in action - from creating contacts and products to automatic approval and task assignment.

### Process Flow
```
Broker → Create Contact → Create Product → Create Loan Application → Update Status (Draft→Submitted) → System Validation → Product Selection → Task Assignment
```

### How to Run Tests
```bash
# Run all Story A tests
sf apex run test -t LoanApplicationsTest,LoanApplicationsUnitTest -o consulting.brendan@gmail.com

# Get detailed test results (use the test run ID from above command)
sf apex get test -i <TEST_RUN_ID> -o consulting.brendan@gmail.com

# Alternative: Run specific test classes
sf apex run test -t LoanApplicationsTest -o consulting.brendan@gmail.com
sf apex run test -t LoanApplicationsUnitTest -o consulting.brendan@gmail.com
```

### Design Notes & Trade-offs

**Architecture Decisions:**
- **Domain Layer**: `LoanApplications` handles business logic for validation, product selection, and approval workflow
- **Selector Layer**: `LoanApplicationsSelector`, `ContactsSelector`, `ProductsSelector` for data access
- **Service Layer**: Orchestrates complex operations and external integrations
- **Trigger Handler**: Thin trigger delegates to domain layer

**Design Trade-offs:**
- **Data Model**: Mostly followed guidelines standard Contact instead of Borrower, Loan_Application__c and Product__c and Broker is assumed user. In real solution if possible I would have used Web-to-Lead, Lead (Draft)->Opportunity (Submitted, Approved, Rejected), Contacts for borrower and broker and Product2
- **Validation Strategy**: Implemented comprehensive validation in domain layer rather than using validation rules for quicker deployment and testing results 
- **Task Assignment**: Created tasks for "broker" role generically.
- **Error Handling**: Used simple field-level error messages. 
- **Missed Service Classes**: Used only domain layer logic, due to first time using FFLIB unsure of what logic sits at domain and what sits at service. 

## Story B: Product Rate Normalization

### How to Run Tests




