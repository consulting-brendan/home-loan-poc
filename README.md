# Mortgage Application System

A Salesforce proof-of-concept implementing a simplified mortgage application process using Apex Enterprise Patterns (fflib).

## Project Structure

The solution implements two main user stories using fflib architecture:
- **Story A**: Submit Application (validation, product selection, task creation)
- **Story B**: Product Rate Normalization (async background processing)

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
# Run all Story A tests
sf apex test run \
  --classnames LoanApplicationServiceTest,LoanApplicationDomainTest \
  --result-format human \
  --code-coverage \
  --wait 10
```

### Test Results

<img width="523" height="173" alt="image" src="https://github.com/user-attachments/assets/9cca7755-06be-4086-b491-c02bcf006f29" />

### Design Notes & Trade-offs

**Architecture Decisions:**
- **Domain Layer**: `LoanApplicationDomain` — validation, approval, rejection rules  
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

### Process Flow
```
Background Process → Query Out-of-Range Products → Apply Normalization Rules → Bulk Update → Complete
```

### Architecture Implementation

**Architecture Decisions:**
- **Domain Layer**: `ProductsDomain` — rate normalization business logic (0.5% - 15% bounds)
- **Service Layer**: `ProductRateNormalizationService` — orchestrates normalization process with constants
- **Selector Layer**: `ProductsSelector` — efficient querying of products needing normalization
- **Async Layer**: `ProductRateNormalizationBatch` — batchable implementation for background processing

**Key Features:**
- **Bulk-Safe Processing**: Queries and updates in batches, respects governor limits
- **Efficient Querying**: Only selects products outside the safe range (0.5% - 15%)
- **In-Memory Logic**: Domain layer normalizes rates without DML, returns only changed records
- **Asynchronous Processing**: Batchable Apex handles large datasets in background

### How to Run Tests

```bash
# Run all Story B tests
sf apex test run \
  --classnames ProductRateNormalizationServiceTest,ProductRateNormalizationBatchTest,ProductsSelectorTest \
  --result-format human \
  --code-coverage \
  --wait 10
```

### Design Trade-offs

**Performance Optimizations:**
- **Selective Querying**: Selector only retrieves products outside bounds rather than all products
- **Domain Efficiency**: Returns only modified records to minimize DML operations
- **Batch Size**: Default 200 records per batch for optimal performance vs. memory usage

**Error Handling Strategy:**
- **Null Safety**: Domain logic handles null Base_Rate__c values gracefully
- **Batch Resilience**: Each batch processes independently, failures don't affect other batches
- **Governor Limits**: Respects all Salesforce limits through proper batching

### Manual Testing Scripts

#### 1. Reset Script (Run First)
```apex
// RESET - Clean slate for testing
delete [SELECT Id FROM Product__c];
System.debug('All products deleted - ready for fresh test data');
```

#### 2. Create Test Data
```apex
// CREATE TEST DATA
System.debug('=== CREATING TEST DATA ===');
List<Product__c> testProducts = new List<Product__c>{
    new Product__c(Name = 'Too Low Rate', Base_Rate__c = 0.001, Min_Credit_Score__c = 600),      // 0.1%
    new Product__c(Name = 'Way Too Low', Base_Rate__c = 0.0001, Min_Credit_Score__c = 650),     // 0.01%
    new Product__c(Name = 'Too High Rate', Base_Rate__c = 0.18, Min_Credit_Score__c = 700),     // 18%
    new Product__c(Name = 'Way Too High', Base_Rate__c = 0.25, Min_Credit_Score__c = 750),      // 25%
    new Product__c(Name = 'Just Right Low', Base_Rate__c = 0.005, Min_Credit_Score__c = 580),   // 0.5%
    new Product__c(Name = 'Just Right High', Base_Rate__c = 0.15, Min_Credit_Score__c = 800),   // 15%
    new Product__c(Name = 'Normal Rate', Base_Rate__c = 0.06, Min_Credit_Score__c = 680)        // 6%
};

insert testProducts;

System.debug('Initial data created:');
List<Product__c> initial = [SELECT Name, Base_Rate__c FROM Product__c ORDER BY Base_Rate__c];
for(Product__c p : initial) {
    System.debug(p.Name + ': ' + (p.Base_Rate__c * 100) + '%');
}
```

#### 3. Test Service Layer (Synchronous)
```apex
// TEST SERVICE LAYER
System.debug('=== TESTING SERVICE LAYER ===');
ProductRateNormalizationService.normalizeProductRates();

System.debug('After service normalization:');
List<Product__c> afterService = [SELECT Name, Base_Rate__c FROM Product__c ORDER BY Base_Rate__c];
for(Product__c p : afterService) {
    System.debug(p.Name + ': ' + (p.Base_Rate__c * 100) + '%');
}
```

#### 4. Reset for Batch Test
```apex
// RESET FOR BATCH TEST
System.debug('=== RESETTING FOR BATCH TEST ===');
List<Product__c> productsToReset = [SELECT Id, Name FROM Product__c];
for(Product__c p : productsToReset) {
    if(p.Name == 'Too Low Rate') {
        p.Base_Rate__c = 0.001;
    } else if(p.Name == 'Way Too Low') {
        p.Base_Rate__c = 0.0001;
    } else if(p.Name == 'Too High Rate') {
        p.Base_Rate__c = 0.18;
    } else if(p.Name == 'Way Too High') {
        p.Base_Rate__c = 0.25;
    } else if(p.Name == 'Just Right Low') {
        p.Base_Rate__c = 0.005;
    } else if(p.Name == 'Just Right High') {
        p.Base_Rate__c = 0.15;
    } else if(p.Name == 'Normal Rate') {
        p.Base_Rate__c = 0.06;
    }
}
update productsToReset;

System.debug('Data reset for batch test:');
List<Product__c> beforeBatch = [SELECT Name, Base_Rate__c FROM Product__c ORDER BY Base_Rate__c];
for(Product__c p : beforeBatch) {
    System.debug(p.Name + ': ' + (p.Base_Rate__c * 100) + '%');
}
```

#### 5. Execute Batch Job (Asynchronous)
```apex
// EXECUTE BATCH JOB
System.debug('=== EXECUTING BATCH JOB ===');
ProductRateNormalizationBatch batch = new ProductRateNormalizationBatch();
Id batchId = Database.executeBatch(batch, 200);
System.debug('Batch Job ID: ' + batchId);
System.debug('Check Setup > Apex Jobs for completion status');
System.debug('Run verification script after batch completes');
```

#### 6. Verify Batch Results (Run After Batch Completes)
```apex
// VERIFY BATCH RESULTS - Run after batch job completes
System.debug('=== FINAL VERIFICATION - BATCH RESULTS ===');
List<Product__c> finalResults = [SELECT Name, Base_Rate__c FROM Product__c ORDER BY Base_Rate__c];

Integer normalizedToLower = 0;
Integer normalizedToUpper = 0;
Integer unchanged = 0;

for(Product__c p : finalResults) {
    String status = '';
    if(p.Base_Rate__c == 0.005) {
        status = ' (normalized to lower bound 0.5%)';
        normalizedToLower++;
    } else if(p.Base_Rate__c == 0.15) {
        status = ' (normalized to upper bound 15%)';
        normalizedToUpper++;
    } else {
        status = ' (unchanged - within range)';
        unchanged++;
    }
    
    System.debug(p.Name + ': ' + (p.Base_Rate__c * 100) + '%' + status);
}

System.debug('');
System.debug('=== SUMMARY ===');
System.debug('Records normalized to lower bound: ' + normalizedToLower);
System.debug('Records normalized to upper bound: ' + normalizedToUpper);
System.debug('Records unchanged: ' + unchanged);
System.debug('Total records processed: ' + finalResults.size());
```

#### 7. Complete Test Script (All-in-One)
```apex
// COMPLETE STORY B TEST - Execute all steps except batch verification
System.debug('=== STEP 1: CREATING TEST DATA ===');
delete [SELECT Id FROM Product__c];

List<Product__c> testProducts = new List<Product__c>{
    new Product__c(Name = 'Too Low Rate', Base_Rate__c = 0.001, Min_Credit_Score__c = 600),
    new Product__c(Name = 'Way Too Low', Base_Rate__c = 0.0001, Min_Credit_Score__c = 650),
    new Product__c(Name = 'Too High Rate', Base_Rate__c = 0.18, Min_Credit_Score__c = 700),
    new Product__c(Name = 'Way Too High', Base_Rate__c = 0.25, Min_Credit_Score__c = 750),
    new Product__c(Name = 'Just Right Low', Base_Rate__c = 0.005, Min_Credit_Score__c = 580),
    new Product__c(Name = 'Just Right High', Base_Rate__c = 0.15, Min_Credit_Score__c = 800),
    new Product__c(Name = 'Normal Rate', Base_Rate__c = 0.06, Min_Credit_Score__c = 680)
};
insert testProducts;

System.debug('=== STEP 2: TESTING SERVICE LAYER ===');
ProductRateNormalizationService.normalizeProductRates();

System.debug('=== STEP 3: RESETTING FOR BATCH TEST ===');
List<Product__c> productsToReset = [SELECT Id, Name FROM Product__c];
for(Product__c p : productsToReset) {
    if(p.Name == 'Too Low Rate') p.Base_Rate__c = 0.001;
    else if(p.Name == 'Way Too Low') p.Base_Rate__c = 0.0001;
    else if(p.Name == 'Too High Rate') p.Base_Rate__c = 0.18;
    else if(p.Name == 'Way Too High') p.Base_Rate__c = 0.25;
    else if(p.Name == 'Just Right Low') p.Base_Rate__c = 0.005;
    else if(p.Name == 'Just Right High') p.Base_Rate__c = 0.15;
    else if(p.Name == 'Normal Rate') p.Base_Rate__c = 0.06;
}
update productsToReset;

System.debug('=== STEP 4: EXECUTING BATCH JOB ===');
ProductRateNormalizationBatch batch = new ProductRateNormalizationBatch();
Id batchId = Database.executeBatch(batch, 200);
System.debug('Batch Job ID: ' + batchId);
System.debug('Run verification script (#6) after batch completes');
```

### Expected Results

After normalization, you should see:
- **Too Low Rate** & **Way Too Low**: `0.5%` (normalized from lower values)
- **Too High Rate** & **Way Too High**: `15%` (normalized from higher values)  
- **Just Right Low**, **Just Right High**, **Normal Rate**: unchanged

The batch job should only process the out-of-range records (4 out of 7 in this test), demonstrating efficient querying.
