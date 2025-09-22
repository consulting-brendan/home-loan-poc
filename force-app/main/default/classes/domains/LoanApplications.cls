public with sharing class LoanApplications extends fflib_SObjectDomain {
    
    private static final String STATUS_DRAFT = 'Draft';
    private static final String STATUS_SUBMITTED = 'Submitted';
    private static final String STATUS_APPROVED = 'Approved';
    private static final String STATUS_REJECTED = 'Rejected';
    private static final String TASK_SUBJECT = 'Prepare documents';
    private static final String TASK_STATUS = 'Not Started';
    private static final String TASK_PRIORITY = 'Normal';
    private static final Integer DOCUMENT_PREP_DAYS = 2;
    private static final String APPROVED_OUTCOME = 'Approved with no conditions.';
    
    public LoanApplications(List<Loan_Application__c> records) {
        super(records);
    }
    
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new LoanApplications(sObjectList);
        }
    }
    
    public override void onValidate() {
        // Check object-level permissions
        if (!Schema.sObjectType.Loan_Application__c.isAccessible()) {
            throw new SecurityException('Insufficient permissions to access Loan Applications');
        }
        
        // Check field-level read permissions
        Map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Loan_Application__c.fields.getMap();
        
        if (!fieldMap.get('Borrower__c').getDescribe().isAccessible()) {
            throw new SecurityException('Insufficient permissions to read Borrower field');
        }
        if (!fieldMap.get('Amount__c').getDescribe().isAccessible()) {
            throw new SecurityException('Insufficient permissions to read Amount field');
        }
        if (!fieldMap.get('Status__c').getDescribe().isAccessible()) {
            throw new SecurityException('Insufficient permissions to read Status field');
        }
        
        // Check field-level update permissions
        if (!fieldMap.get('Status__c').getDescribe().isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update Status field');
        }
        if (!fieldMap.get('Product__c').getDescribe().isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update Product field');
        }
        if (!fieldMap.get('Approval_Outcome__c').getDescribe().isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update Approval Outcome field');
        }
    }
    
    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        // Security check before processing
        if (!Schema.sObjectType.Loan_Application__c.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update Loan Applications');
        }
        
        processStatusChanges((Map<Id, Loan_Application__c>) existingRecords);
    }
    
    private void processStatusChanges(Map<Id, Loan_Application__c> existingRecords) {
        List<Loan_Application__c> submittedApplications = filterSubmittedApplications(existingRecords);
        
        if (!submittedApplications.isEmpty()) {
            processSubmissions(submittedApplications);
        }
    }
    
    private List<Loan_Application__c> filterSubmittedApplications(Map<Id, Loan_Application__c> existingRecords) {
        List<Loan_Application__c> submittedApplications = new List<Loan_Application__c>();
        
        for (Loan_Application__c application : (List<Loan_Application__c>) Records) {
            Loan_Application__c oldRecord = existingRecords.get(application.Id);
            
            if (isStatusChangedToSubmitted(oldRecord, application)) {
                submittedApplications.add(application);
            }
        }
        
        return submittedApplications;
    }
    
    private Boolean isStatusChangedToSubmitted(Loan_Application__c oldRecord, Loan_Application__c newRecord) {
        return oldRecord.Status__c == STATUS_DRAFT && newRecord.Status__c == STATUS_SUBMITTED;
    }
    
    public void processSubmissions() {
        processSubmissions((List<Loan_Application__c>) Records);
    }
    
    private void processSubmissions(List<Loan_Application__c> applications) {
        // Check CRUD permissions for related objects
        if (!Schema.sObjectType.Contact.isAccessible()) {
            throw new SecurityException('Insufficient permissions to read Contact records');
        }
        if (!Schema.sObjectType.Product__c.isAccessible()) {
            throw new SecurityException('Insufficient permissions to read Product records');
        }
        if (!Schema.sObjectType.Task.isCreateable()) {
            throw new SecurityException('Insufficient permissions to create Task records');
        }
        
        ApplicationProcessingContext context = buildProcessingContext(applications);
        List<Task> tasksToCreate = new List<Task>();
        
        for (Loan_Application__c application : applications) {
            processIndividualApplication(application, context, tasksToCreate);
        }
        
        insertTasksIfNeeded(tasksToCreate);
    }
    
    private ApplicationProcessingContext buildProcessingContext(List<Loan_Application__c> applications) {
        Set<Id> borrowerIds = extractBorrowerIds(applications);
        Map<Id, Contact> borrowerMap = getBorrowerDetails(borrowerIds);
        List<Product__c> allProducts = getAvailableProducts();
        
        return new ApplicationProcessingContext(borrowerMap, allProducts);
    }
    
    private Set<Id> extractBorrowerIds(List<Loan_Application__c> applications) {
        Set<Id> borrowerIds = new Set<Id>();
        for (Loan_Application__c app : applications) {
            borrowerIds.add(app.Borrower__c);
        }
        return borrowerIds;
    }
    
    private Map<Id, Contact> getBorrowerDetails(Set<Id> borrowerIds) {
        return new Map<Id, Contact>(
            ContactsSelector.newInstance().selectById(borrowerIds)
        );
    }
    
    private List<Product__c> getAvailableProducts() {
        return ProductsSelector.newInstance().selectAll();
    }
    
    private void processIndividualApplication(Loan_Application__c application, 
                                            ApplicationProcessingContext context, 
                                            List<Task> tasksToCreate) {
        Contact borrower = context.getBorrower(application.Borrower__c);
        String validationResult = validateApplication(application, borrower);
        
        if (String.isBlank(validationResult)) {
            processValidApplication(application, borrower, context, tasksToCreate);
        } else {
            rejectApplication(application, validationResult);
        }
    }
    
    private void processValidApplication(Loan_Application__c application, 
                                       Contact borrower, 
                                       ApplicationProcessingContext context,
                                       List<Task> tasksToCreate) {
        Product__c selectedProduct = selectBestProduct(borrower.Credit_Score__c, context.getAllProducts());
        
        if (selectedProduct != null) {
            approveApplication(application, selectedProduct, tasksToCreate);
        } else {
            rejectForIneligibleProducts(application, borrower.Credit_Score__c);
        }
    }
    
    private void approveApplication(Loan_Application__c application, 
                                  Product__c selectedProduct, 
                                  List<Task> tasksToCreate) {
        application.Status__c = STATUS_APPROVED;
        application.Product__c = selectedProduct.Id;
        application.Approval_Outcome__c = APPROVED_OUTCOME;
        
        tasksToCreate.add(createDocumentPreparationTask(application));
    }
    
    private void rejectApplication(Loan_Application__c application, String reason) {
        application.Status__c = STATUS_REJECTED;
        application.Product__c = null;
        application.Approval_Outcome__c = reason;
    }
    
    private void rejectForIneligibleProducts(Loan_Application__c application, Decimal creditScore) {
        String reason = 'No eligible products found for credit score: ' + creditScore;
        rejectApplication(application, reason);
    }
    
    private void insertTasksIfNeeded(List<Task> tasksToCreate) {
        if (!tasksToCreate.isEmpty()) {
            // Check Task creation permissions
            if (!Schema.sObjectType.Task.isCreateable()) {
                throw new SecurityException('Insufficient permissions to create Task records');
            }
            
            // Check field-level create permissions for Task fields
            Map<String, Schema.SObjectField> taskFieldMap = Schema.sObjectType.Task.fields.getMap();
            
            if (!taskFieldMap.get('Subject').getDescribe().isCreateable()) {
                throw new SecurityException('Insufficient permissions to set Task Subject field');
            }
            if (!taskFieldMap.get('WhatId').getDescribe().isCreateable()) {
                throw new SecurityException('Insufficient permissions to set Task WhatId field');
            }
            if (!taskFieldMap.get('ActivityDate').getDescribe().isCreateable()) {
                throw new SecurityException('Insufficient permissions to set Task ActivityDate field');
            }
            if (!taskFieldMap.get('Status').getDescribe().isCreateable()) {
                throw new SecurityException('Insufficient permissions to set Task Status field');
            }
            if (!taskFieldMap.get('Priority').getDescribe().isCreateable()) {
                throw new SecurityException('Insufficient permissions to set Task Priority field');
            }
            
            insert tasksToCreate;
        }
    }
    
    private String validateApplication(Loan_Application__c application, Contact borrower) {
        ApplicationValidator validator = new ApplicationValidator();
        return validator.validate(application, borrower);
    }
    
    private Product__c selectBestProduct(Decimal creditScore, List<Product__c> allProducts) {
        ProductSelector productSelector = new ProductSelector();
        return productSelector.selectBestProduct(creditScore, allProducts);
    }
    
    private Task createDocumentPreparationTask(Loan_Application__c application) {
        return new Task(
            Subject = TASK_SUBJECT,
            WhatId = application.Id,
            ActivityDate = Date.today().addDays(DOCUMENT_PREP_DAYS),
            Status = TASK_STATUS,
            Priority = TASK_PRIORITY
        );
    }
    
    public static LoanApplications newInstance(List<Loan_Application__c> records) {
        return (LoanApplications) Application.Domain.newInstance(records);
    }
    
    public static LoanApplications newInstance(Set<Id> recordIds) {
        return (LoanApplications) Application.Domain.newInstance(recordIds);
    }
    
    private class ApplicationProcessingContext {
        private Map<Id, Contact> borrowerMap;
        private List<Product__c> allProducts;
        
        public ApplicationProcessingContext(Map<Id, Contact> borrowerMap, List<Product__c> allProducts) {
            this.borrowerMap = borrowerMap;
            this.allProducts = allProducts;
        }
        
        public Contact getBorrower(Id borrowerId) {
            return borrowerMap.get(borrowerId);
        }
        
        public List<Product__c> getAllProducts() {
            return allProducts;
        }
    }
    
    private class ApplicationValidator {
        public String validate(Loan_Application__c application, Contact borrower) {
            List<String> validationErrors = new List<String>();
            
            validateBorrower(borrower, validationErrors);
            validateApplication(application, validationErrors);
            
            return String.join(validationErrors, '; ');
        }
        
        private void validateBorrower(Contact borrower, List<String> validationErrors) {
            if (borrower == null) {
                validationErrors.add('Borrower not found');
                return;
            }
            
            if (String.isBlank(borrower.Email)) {
                validationErrors.add('Borrower email is required');
            }
            
            if (borrower.Annual_Income__c == null || borrower.Annual_Income__c <= 0) {
                validationErrors.add('Borrower annual income must be greater than 0');
            }
            
            if (borrower.Credit_Score__c == null) {
                validationErrors.add('Borrower credit score is required');
            }
        }
        
        private void validateApplication(Loan_Application__c application, List<String> validationErrors) {
            if (application.Amount__c == null || application.Amount__c <= 0) {
                validationErrors.add('Loan amount must be greater than 0');
            }
        }
    }
    
    private class ProductSelector {
        public Product__c selectBestProduct(Decimal creditScore, List<Product__c> allProducts) {
            Product__c bestProduct = null;
            Decimal lowestRate = null;
            
            for (Product__c product : allProducts) {
                if (isEligibleProduct(product, creditScore)) {
                    if (isBetterProduct(product, lowestRate)) {
                        bestProduct = product;
                        lowestRate = product.Base_Rate__c;
                    }
                }
            }
            
            return bestProduct;
        }
        
        private Boolean isEligibleProduct(Product__c product, Decimal creditScore) {
            return product.Min_Credit_Score__c <= creditScore;
        }
        
        private Boolean isBetterProduct(Product__c product, Decimal currentLowestRate) {
            return currentLowestRate == null || product.Base_Rate__c < currentLowestRate;
        }
    }
    
    // Custom exception for security violations
    public class SecurityException extends Exception {}
}