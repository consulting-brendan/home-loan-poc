# Mortgage Application System

A Salesforce proof-of-concept implementing a simplified mortgage application process using Apex Enterprise Patterns (fflib).

## Project Structure

The solution implements two main user stories using fflib architecture:
- **Story A**: Submit Application (validation, product selection, task creation)
- **Story B**: Product Rate Normalization (async background processing) [IN PROGRESS]

## Story A: Submit Application

## Process Demo

**[▶️ Watch Story A Demo](https://www.loom.com/share/dc76320baf9944f9830bc83319938feb?sid=8e28daeb-e900-4fef-9235-734dc90a7bc2)**

See the loan application submission workflow in action - from creating Loan Application, linking product and contacts to automatic approval and task assignment.

### Process Flow
```
Broker → Create Contact → Create Product → Create Loan Application → Update Status (Draft→Submitted) → System Validation → Product Selection → Task Assignment
```

### How to Run Tests
```bash
# Run all Story A and B tests

sf apex test run \  --classnames LoanApplicationServiceTest,LoanApplicationDomainTest,ProductsSelectorTest,ProductRateNormalizationBatchTest \
  --result-format human \
  --code-coverage \
  --wait 10
```
### Test Results

<img width="523" height="173" alt="image" src="https://github.com/user-attachments/assets/9cca7755-06be-4086-b491-c02bcf006f29" />

### Design Notes & Trade-offs

**Architecture Decisions:**
- **Domain Layer**: `LoanApplications` — validation, approval, rejection rules  
- **Service Layer**: `LoanApplicationService` — orchestrates selectors, domain decisions, and DML  
- **Selector Layer**: `ContactsSelector`, `ProductsSelector`, `LoanApplicationsSelector` — data access  
- **Trigger**: Thin trigger delegates work to service layer  

**Design Trade-offs:**
- **Data Model**: Mostly followed guidelines standard Contact instead of Borrower, Loan_Application__c and Product__c and Broker is assumed user. In real solution if possible I would have used Web-to-Lead, Lead (Draft)->Opportunity (Submitted, Approved, Rejected), Contacts for borrower and broker and Product2
- **Validation Strategy**: Implemented comprehensive validation in domain layer rather than using validation rules for quicker deployment and testing results 
- **Task Assignment**: Created tasks for "broker" role generically.
- **Error Handling**: Used simple field-level error messages. 
- **Missed Service Classes**: Used only domain layer logic, due to first time using FFLIB unsure of what logic sits at domain and what sits at service. 

## Story B: Product Rate Normalization

### How to Run Tests




