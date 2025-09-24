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
- **Validation Strategy**: Will need more time to work out if I have validated based on FFLib best practice 
- **Task Assignment**: Created tasks for "broker" role generically, with more time would have created Custom Metadata setup for various tasks assigned to various teams
- **FFLib implementation** Not entirely sure I have this done correctly, domain implements FFLib, service doesn't attempted to implement classes as per https://fflib.dev/docs/service-layer/example and got compile and version errors. (might have an older version of FFLib)
- **Testing**: Some tests coverage are quite low, I would have worked on expanding this given time. Only included FFLib mocks in LoanApplicationServiceTest, will need to update the other classes
- **Trigger Logic**: Usually I would have a handler as well to contain the run logic, not entirely sure how this works with FFLib yet 

## Story B: Product Rate Normalization

## Testing Demo

**[▶️ Watch Story B Demo](https://www.loom.com/share/1f39f40e4990498095600afbb7f6cc13?sid=a83a5302-fc4d-48dd-ac56-3d9053f91068)**

### Process Flow
```
Background Process → Query Out-of-Range Products → Apply Normalization Rules → Bulk Update → Complete
```

### How to Run Tests

```bash
# Run all Story B tests
sf apex test run \
  --classnames ProductRateNormalizationServiceTest,ProductRateNormalizationBatchTest,ProductsSelectorTest \
  --result-format human \
  --code-coverage \
  --wait 10
```

**Design Notes & Trade-offs**

**Architecture Decisions:**
* **Domain Layer**: `ProductsDomain` — rate normalization business logic (0.5% - 15% bounds)
* **Service Layer**: `ProductRateNormalizationService` — orchestrates normalization process with constants
* **Selector Layer**: `ProductsSelector` — efficient querying of products needing normalization
* **Async Layer**: `ProductRateNormalizationBatch` — batchable implementation for background processing

**Design Trade-offs:**
* **Batch Strategy**: Chose Batchable over Queueable for large dataset processing, though Queueable chains might be more flexible for smaller volumes
* **Error Handling**: Basic batch error handling, would implement more sophisticated logging and retry mechanisms with more time
* **Constants Management**: Hard-coded rate bounds in service class, would move to Custom Metadata or Custom Settings in production
* **Testing**: Focused on core functionality testing, would expand negative scenarios and governor limit edge cases given more time

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

System.debug('Before service normalization:');
List<Product__c> beforeService = [SELECT Name, Base_Rate__c FROM Product__c ORDER BY Base_Rate__c];
for(Product__c p : beforeService) {
    System.debug(p.Name + ': ' + (p.Base_Rate__c * 100) + '%');
}

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
