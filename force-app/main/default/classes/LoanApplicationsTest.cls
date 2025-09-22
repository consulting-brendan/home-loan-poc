@IsTest
public with sharing class LoanApplicationsTest {
    
    private static final String BORROWER_EMAIL = 'john.doe@test.com';
    private static final Decimal HIGH_CREDIT_SCORE = 720;
    private static final Decimal MEDIUM_CREDIT_SCORE = 680;
    private static final Decimal LOW_CREDIT_SCORE = 600;
    private static final Decimal ANNUAL_INCOME = 75000;
    private static final Decimal LOAN_AMOUNT = 250000;
    
    private static final String PREMIUM_PRODUCT_NAME = 'Premium Loan';
    private static final String STANDARD_PRODUCT_NAME = 'Standard Loan';
    private static final String HIGH_CREDIT_PRODUCT_NAME = 'High Credit Loan';
    
    private static final String STATUS_DRAFT = 'Draft';
    private static final String STATUS_SUBMITTED = 'Submitted';
    private static final String STATUS_APPROVED = 'Approved';
    private static final String STATUS_REJECTED = 'Rejected';
    
    @TestSetup
    static void setupTestData() {
        List<Product__c> products = new List<Product__c>{
            new Product__c(Name = PREMIUM_PRODUCT_NAME, Min_Credit_Score__c = 700, Base_Rate__c = 3.5),
            new Product__c(Name = STANDARD_PRODUCT_NAME, Min_Credit_Score__c = 650, Base_Rate__c = 4.2),
            new Product__c(Name = HIGH_CREDIT_PRODUCT_NAME, Min_Credit_Score__c = 750, Base_Rate__c = 2.9)
        };
        insert products;
        
        Contact borrower = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = BORROWER_EMAIL,
            Annual_Income__c = ANNUAL_INCOME,
            Credit_Score__c = HIGH_CREDIT_SCORE
        );
        insert borrower;
        
        Loan_Application__c loanApp = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = LOAN_AMOUNT,
            Status__c = STATUS_DRAFT
        );
        insert loanApp;
    }
    
    // STORY A: Success Flow Tests
    @IsTest
    static void givenValidApplication_whenSubmitted_thenShouldApproveAndSelectBestProduct() {
        Contact borrower = [SELECT Id, Credit_Score__c FROM Contact LIMIT 1];
        Loan_Application__c loanApp = [SELECT Id, Borrower__c FROM Loan_Application__c LIMIT 1];
        
        Test.startTest();
        
        loanApp.Status__c = STATUS_SUBMITTED;
        update loanApp;
        
        Test.stopTest();
        
        assertApplicationApproved(loanApp.Id, PREMIUM_PRODUCT_NAME);
    }
    
    @IsTest
    static void givenHighCreditScoreBorrower_whenSubmitted_thenShouldSelectLowestRateProduct() {
        Contact borrower = new Contact(
            FirstName = 'Test',
            LastName = 'Borrower',
            Email = BORROWER_EMAIL,
            Annual_Income__c = ANNUAL_INCOME,
            Credit_Score__c = 750
        );
        insert borrower;
        
        Loan_Application__c loanApp = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = LOAN_AMOUNT,
            Status__c = STATUS_DRAFT
        );
        insert loanApp;
        
        Test.startTest();
        
        loanApp.Status__c = STATUS_SUBMITTED;
        update loanApp;
        
        Test.stopTest();
        
        assertApplicationApproved(loanApp.Id, HIGH_CREDIT_PRODUCT_NAME);
    }
    
    // STORY A: Validation Failure Tests
    @IsTest
    static void givenBorrowerWithoutEmail_whenSubmitted_thenShouldRejectWithValidationError() {
        Contact borrower = new Contact(
            FirstName = 'No',
            LastName = 'Email',
            Email = null, // Missing email
            Annual_Income__c = ANNUAL_INCOME,
            Credit_Score__c = HIGH_CREDIT_SCORE
        );
        insert borrower;
        
        Loan_Application__c loanApp = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = LOAN_AMOUNT,
            Status__c = STATUS_DRAFT
        );
        insert loanApp;
        
        Test.startTest();
        
        loanApp.Status__c = STATUS_SUBMITTED;
        update loanApp;
        
        Test.stopTest();
        
        assertApplicationRejected(loanApp.Id, 'email is required');
    }
    
    @IsTest
    static void givenBorrowerWithZeroIncome_whenSubmitted_thenShouldRejectWithValidationError() {
        Contact borrower = new Contact(
            FirstName = 'Income',
            LastName = 'Test',
            Email = BORROWER_EMAIL,
            Annual_Income__c = 0,
            Credit_Score__c = HIGH_CREDIT_SCORE
        );
        insert borrower;
        
        Loan_Application__c loanApp = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = LOAN_AMOUNT,
            Status__c = STATUS_DRAFT
        );
        insert loanApp;
        
        Test.startTest();
        
        loanApp.Status__c = STATUS_SUBMITTED;
        update loanApp;
        
        Test.stopTest();
        
        assertApplicationRejected(loanApp.Id, 'income must be greater than 0');
    }
    
    @IsTest
    static void givenBorrowerWithNullCreditScore_whenSubmitted_thenShouldRejectWithValidationError() {
        Contact borrower = new Contact(
            FirstName = 'Test',
            LastName = 'Borrower',
            Email = BORROWER_EMAIL,
            Annual_Income__c = ANNUAL_INCOME,
            Credit_Score__c = null
        );
        insert borrower;
        
        Loan_Application__c loanApp = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = LOAN_AMOUNT,
            Status__c = STATUS_DRAFT
        );
        insert loanApp;
        
        Test.startTest();
        
        loanApp.Status__c = STATUS_SUBMITTED;
        update loanApp;
        
        Test.stopTest();
        
        assertApplicationRejected(loanApp.Id, 'credit score is required');
    }
    
    @IsTest
    static void givenApplicationWithZeroAmount_whenSubmitted_thenShouldRejectWithValidationError() {
        Contact borrower = [SELECT Id FROM Contact LIMIT 1];
        
        Loan_Application__c loanApp = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = 0,
            Status__c = STATUS_DRAFT
        );
        insert loanApp;
        
        Test.startTest();
        
        loanApp.Status__c = STATUS_SUBMITTED;
        update loanApp;
        
        Test.stopTest();
        
        assertApplicationRejected(loanApp.Id, 'amount must be greater than 0');
    }
    
    @IsTest
    static void givenBorrowerWithLowCreditScore_whenSubmitted_thenShouldRejectForIneligibleProducts() {
        Contact borrower = new Contact(
            FirstName = 'Test',
            LastName = 'Borrower',
            Email = BORROWER_EMAIL,
            Annual_Income__c = ANNUAL_INCOME,
            Credit_Score__c = LOW_CREDIT_SCORE
        );
        insert borrower;
        
        Loan_Application__c loanApp = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = LOAN_AMOUNT,
            Status__c = STATUS_DRAFT
        );
        insert loanApp;
        
        Test.startTest();
        
        loanApp.Status__c = STATUS_SUBMITTED;
        update loanApp;
        
        Test.stopTest();
        
        assertApplicationRejected(loanApp.Id, 'No eligible products found');
        assertApplicationRejected(loanApp.Id, String.valueOf(LOW_CREDIT_SCORE));
    }
    
    // STORY A: Bulk Processing Tests
    @IsTest
    static void givenMultipleApplications_whenSubmittedTogether_thenShouldProcessAllCorrectly() {
        List<Contact> borrowers = new List<Contact>{
            new Contact(
                FirstName = 'Bulk1',
                LastName = 'Test',
                Email = 'bulk1@test.com',
                Annual_Income__c = ANNUAL_INCOME,
                Credit_Score__c = HIGH_CREDIT_SCORE
            ),
            new Contact(
                FirstName = 'Bulk2',
                LastName = 'Test',
                Email = 'bulk2@test.com',
                Annual_Income__c = ANNUAL_INCOME,
                Credit_Score__c = HIGH_CREDIT_SCORE
            )
        };
        insert borrowers;
        
        List<Loan_Application__c> applications = new List<Loan_Application__c>{
            new Loan_Application__c(
                Borrower__c = borrowers[0].Id,
                Amount__c = LOAN_AMOUNT,
                Status__c = STATUS_DRAFT
            ),
            new Loan_Application__c(
                Borrower__c = borrowers[1].Id,
                Amount__c = LOAN_AMOUNT,
                Status__c = STATUS_DRAFT
            )
        };
        insert applications;
        
        Test.startTest();
        
        for (Loan_Application__c app : applications) {
            app.Status__c = STATUS_SUBMITTED;
        }
        update applications;
        
        Test.stopTest();
        
        for (Loan_Application__c app : applications) {
            assertApplicationApproved(app.Id, PREMIUM_PRODUCT_NAME);
        }
        
        System.assert(Limits.getQueries() < Limits.getLimitQueries(), 
                     'Should not exceed SOQL query limits during bulk processing');
    }
    
    // STORY A: Task Creation Tests
    @IsTest
    static void givenApprovedApplication_whenProcessed_thenShouldCreateDocumentPreparationTask() {
        Contact borrower = [SELECT Id FROM Contact LIMIT 1];
        Loan_Application__c loanApp = [SELECT Id FROM Loan_Application__c LIMIT 1];
        Integer initialTaskCount = getTaskCount(loanApp.Id);
        
        Test.startTest();
        
        loanApp.Status__c = STATUS_SUBMITTED;
        update loanApp;
        
        Test.stopTest();
        
        Integer finalTaskCount = getTaskCount(loanApp.Id);
        System.assertEquals(initialTaskCount + 1, finalTaskCount, 'Should create one task');
        
        Task createdTask = getLatestTask(loanApp.Id);
        assertTaskProperties(createdTask);
    }
    
    // Edge Case Tests
    @IsTest
    static void givenApplicationWithMultipleValidationErrors_whenSubmitted_thenShouldRejectWithAllErrors() {
        Contact borrower = new Contact(
            FirstName = 'Invalid',
            LastName = 'Borrower',
            Email = null, // Missing email
            Annual_Income__c = 0, // Invalid income
            Credit_Score__c = HIGH_CREDIT_SCORE
        );
        insert borrower;
        
        Loan_Application__c loanApp = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = LOAN_AMOUNT,
            Status__c = STATUS_DRAFT
        );
        insert loanApp;
        
        Test.startTest();
        
        loanApp.Status__c = STATUS_SUBMITTED;
        update loanApp;
        
        Test.stopTest();
        
        Loan_Application__c result = [SELECT Approval_Outcome__c FROM Loan_Application__c 
                                     WHERE Id = :loanApp.Id];
        System.assert(result.Approval_Outcome__c.contains('email is required'), 
                     'Should contain email error');
        System.assert(result.Approval_Outcome__c.contains('income must be greater than 0'), 
                     'Should contain income error');
    }
    
    @IsTest 
    static void givenNonDraftToSubmittedTransition_whenUpdated_thenShouldNotTriggerProcessing() {
        Contact borrower = [SELECT Id FROM Contact LIMIT 1];
        Loan_Application__c loanApp = [SELECT Id FROM Loan_Application__c LIMIT 1];
        loanApp.Status__c = STATUS_SUBMITTED;
        update loanApp;
        
        Test.startTest();
        
        loanApp.Status__c = STATUS_APPROVED; // Manual approval
        update loanApp;
        
        Test.stopTest();
        
        Loan_Application__c result = [SELECT Status__c FROM Loan_Application__c 
                                     WHERE Id = :loanApp.Id];
        System.assertEquals(STATUS_APPROVED, result.Status__c);
    }
    
    // Product Selection Logic Tests
    @IsTest
    static void givenMultipleEligibleProducts_whenSubmitted_thenShouldSelectLowestRate() {
        List<Product__c> additionalProducts = new List<Product__c>{
            new Product__c(Name = 'Low Rate Test', Min_Credit_Score__c = 650, Base_Rate__c = 2.5),
            new Product__c(Name = 'High Rate Test', Min_Credit_Score__c = 650, Base_Rate__c = 5.0)
        };
        insert additionalProducts;
        
        Contact borrower = new Contact(
            FirstName = 'Test',
            LastName = 'Borrower',
            Email = BORROWER_EMAIL,
            Annual_Income__c = ANNUAL_INCOME,
            Credit_Score__c = HIGH_CREDIT_SCORE
        );
        insert borrower;
        
        Loan_Application__c loanApp = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = LOAN_AMOUNT,
            Status__c = STATUS_DRAFT
        );
        insert loanApp;
        
        Test.startTest();
        
        loanApp.Status__c = STATUS_SUBMITTED;
        update loanApp;
        
        Test.stopTest();
        
        Loan_Application__c result = [SELECT Product__c FROM Loan_Application__c 
                                     WHERE Id = :loanApp.Id];
        Product__c selectedProduct = [SELECT Name FROM Product__c WHERE Id = :result.Product__c];
        System.assertEquals('Low Rate Test', selectedProduct.Name);
    }
    
    // HELPER METHODS AND ASSERTIONS
    private static void assertApplicationApproved(Id applicationId, String expectedProductName) {
        Loan_Application__c result = [SELECT Status__c, Product__c, Approval_Outcome__c 
                                     FROM Loan_Application__c WHERE Id = :applicationId];
        
        System.assertEquals(STATUS_APPROVED, result.Status__c, 'Application should be approved');
        System.assertNotEquals(null, result.Product__c, 'Product should be selected');
        System.assertEquals('Approved with no conditions.', result.Approval_Outcome__c);
        
        if (String.isNotBlank(expectedProductName)) {
            Product__c selectedProduct = [SELECT Name FROM Product__c WHERE Id = :result.Product__c];
            System.assertEquals(expectedProductName, selectedProduct.Name, 
                               'Should select the expected product');
        }
    }
    
    private static void assertApplicationRejected(Id applicationId, String expectedErrorFragment) {
        Loan_Application__c result = [SELECT Status__c, Product__c, Approval_Outcome__c 
                                     FROM Loan_Application__c WHERE Id = :applicationId];
        
        System.assertEquals(STATUS_REJECTED, result.Status__c, 'Application should be rejected');
        System.assertEquals(null, result.Product__c, 'No product should be selected');
        System.assert(result.Approval_Outcome__c.contains(expectedErrorFragment), 
                     'Should contain expected error: ' + expectedErrorFragment + 
                     '. Actual: ' + result.Approval_Outcome__c);
    }
    
    private static Integer getTaskCount(Id applicationId) {
        return [SELECT COUNT() FROM Task WHERE WhatId = :applicationId];
    }
    
    private static Task getLatestTask(Id applicationId) {
        return [SELECT Subject, Status, Priority, ActivityDate 
                FROM Task WHERE WhatId = :applicationId 
                ORDER BY CreatedDate DESC LIMIT 1];
    }
    
    private static void assertTaskProperties(Task createdTask) {
        System.assert(createdTask.Subject.contains('Prepare documents'), 
                     'Task should be about document preparation');
        System.assertEquals('Not Started', createdTask.Status, 'Task should not be started');
        System.assertEquals('Normal', createdTask.Priority, 'Task should have normal priority');
        System.assertEquals(Date.today().addDays(2), createdTask.ActivityDate, 
                           'Task should be due in 2 business days');
    }
}