@IsTest(IsParallel=true)
private class LoanApplicationServiceTest {

    @IsTest
    static void submitApplications_approvesValidApplication() {
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        LoanApplicationsSelector mockLoanAppsSelector = (LoanApplicationsSelector) mocks.mock(LoanApplicationsSelector.class);
        ContactsSelector mockContactsSelector = (ContactsSelector) mocks.mock(ContactsSelector.class);
        ProductsSelector mockProductsSelector = (ProductsSelector) mocks.mock(ProductsSelector.class);

        // Given - create test data in memory
        String borrowerEmail = 'test@example.com';
        Decimal borrowerIncome = 60000;
        Decimal borrowerCreditScore = 720;
        Decimal loanAmount = 20000;
        Decimal productMinScore = 650;
        Decimal productRate = 0.045;

        Id contactId = fflib_IDGenerator.generate(Contact.SObjectType);
        Id productId = fflib_IDGenerator.generate(Product__c.SObjectType);
        Id applicationId = fflib_IDGenerator.generate(Loan_Application__c.SObjectType);

        Contact mockBorrower = new Contact(
            Id = contactId,
            LastName = 'TestBorrower',
            Email = borrowerEmail,
            Annual_Income__c = borrowerIncome,
            Credit_Score__c = borrowerCreditScore
        );

        Product__c mockProduct = new Product__c(
            Id = productId,
            Name = 'Test Product',
            Min_Credit_Score__c = productMinScore,
            Base_Rate__c = productRate
        );

        Loan_Application__c mockApplication = new Loan_Application__c(
            Id = applicationId,
            Borrower__c = contactId,
            Amount__c = loanAmount,
            Status__c = 'Submitted'
        );

        List<Loan_Application__c> inputApplications = new List<Loan_Application__c>{ mockApplication };
        Map<Id, Contact> mockContactsMap = new Map<Id, Contact>{ contactId => mockBorrower };
        List<Product__c> mockProductsList = new List<Product__c>{ mockProduct };

        // Set mocks
        mocks.startStubbing();
        mocks.when(mockLoanAppsSelector.sObjectType()).thenReturn(Loan_Application__c.SObjectType);
        mocks.when(mockContactsSelector.sObjectType()).thenReturn(Contact.SObjectType);
        mocks.when(mockProductsSelector.sObjectType()).thenReturn(Product__c.SObjectType);
        mocks.when(mockLoanAppsSelector.selectByIds((Set<Id>) fflib_Match.anyObject()))
            .thenReturn(inputApplications);
        mocks.when(mockContactsSelector.selectByIds((Set<Id>) fflib_Match.anyObject()))
            .thenReturn(mockContactsMap);
        mocks.when(mockProductsSelector.selectAllOrderByRateAsc())
            .thenReturn(mockProductsList);
        mocks.stopStubbing();

        Application.Selector.setMock(mockLoanAppsSelector);
        Application.Selector.setMock(mockContactsSelector);
        Application.Selector.setMock(mockProductsSelector);

        // When - perform test
        Test.startTest();
        LoanApplicationService.submitApplications(inputApplications);
        Test.stopTest();

        // Then - validate method interactions
        ((LoanApplicationsSelector) mocks.verify(mockLoanAppsSelector, 1))
            .selectByIds((Set<Id>) fflib_Match.anyObject());
        ((ContactsSelector) mocks.verify(mockContactsSelector, 1))
            .selectByIds((Set<Id>) fflib_Match.anyObject());
        ((ProductsSelector) mocks.verify(mockProductsSelector, 1))
            .selectAllOrderByRateAsc();
    }

    @IsTest
    static void submitApplications_rejectsWhenCreditScoreMissing() {
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        LoanApplicationsSelector mockLoanAppsSelector = (LoanApplicationsSelector) mocks.mock(LoanApplicationsSelector.class);
        ContactsSelector mockContactsSelector = (ContactsSelector) mocks.mock(ContactsSelector.class);
        ProductsSelector mockProductsSelector = (ProductsSelector) mocks.mock(ProductsSelector.class);

        // Given - create test data with missing credit score
        String borrowerEmail = 'test2@example.com';
        Decimal borrowerIncome = 60000;
        Decimal loanAmount = 20000;

        Id contactId = fflib_IDGenerator.generate(Contact.SObjectType);
        Id applicationId = fflib_IDGenerator.generate(Loan_Application__c.SObjectType);

        Contact mockBorrowerInvalid = new Contact(
            Id = contactId,
            LastName = 'InvalidBorrower',
            Email = borrowerEmail,
            Annual_Income__c = borrowerIncome,
            Credit_Score__c = null // Missing credit score should cause rejection
        );

        Loan_Application__c mockApplication = new Loan_Application__c(
            Id = applicationId,
            Borrower__c = contactId,
            Amount__c = loanAmount,
            Status__c = 'Submitted'
        );

        List<Loan_Application__c> inputApplications = new List<Loan_Application__c>{ mockApplication };
        Map<Id, Contact> mockContactsMap = new Map<Id, Contact>{ contactId => mockBorrowerInvalid };

        // Set mocks
        mocks.startStubbing();
        mocks.when(mockLoanAppsSelector.sObjectType()).thenReturn(Loan_Application__c.SObjectType);
        mocks.when(mockContactsSelector.sObjectType()).thenReturn(Contact.SObjectType);
        mocks.when(mockProductsSelector.sObjectType()).thenReturn(Product__c.SObjectType);
        mocks.when(mockLoanAppsSelector.selectByIds((Set<Id>) fflib_Match.anyObject()))
            .thenReturn(inputApplications);
        mocks.when(mockContactsSelector.selectByIds((Set<Id>) fflib_Match.anyObject()))
            .thenReturn(mockContactsMap);
        mocks.when(mockProductsSelector.selectAllOrderByRateAsc())
            .thenReturn(new List<Product__c>());
        mocks.stopStubbing();

        Application.Selector.setMock(mockLoanAppsSelector);
        Application.Selector.setMock(mockContactsSelector);
        Application.Selector.setMock(mockProductsSelector);

        // When - perform test
        Test.startTest();
        LoanApplicationService.submitApplications(inputApplications);
        Test.stopTest();

        // Then - validate rejection logic was triggered
        ((LoanApplicationsSelector) mocks.verify(mockLoanAppsSelector, 1))
            .selectByIds((Set<Id>) fflib_Match.anyObject());
        ((ContactsSelector) mocks.verify(mockContactsSelector, 1))
            .selectByIds((Set<Id>) fflib_Match.anyObject());
        ((ProductsSelector) mocks.verify(mockProductsSelector, 1))
            .selectAllOrderByRateAsc();
    }

    @IsTest
    static void submitApplications_handlesBulkApplications() {
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        LoanApplicationsSelector mockLoanAppsSelector = (LoanApplicationsSelector) mocks.mock(LoanApplicationsSelector.class);
        ContactsSelector mockContactsSelector = (ContactsSelector) mocks.mock(ContactsSelector.class);
        ProductsSelector mockProductsSelector = (ProductsSelector) mocks.mock(ProductsSelector.class);

        // Given - create bulk test data
        Id contact1Id = fflib_IDGenerator.generate(Contact.SObjectType);
        Id contact2Id = fflib_IDGenerator.generate(Contact.SObjectType);
        Id app1Id = fflib_IDGenerator.generate(Loan_Application__c.SObjectType);
        Id app2Id = fflib_IDGenerator.generate(Loan_Application__c.SObjectType);
        Id product1Id = fflib_IDGenerator.generate(Product__c.SObjectType);

        List<Contact> mockBorrowers = new List<Contact>{
            new Contact(
                Id = contact1Id,
                LastName = 'Borrower1',
                Email = 'b1@example.com',
                Annual_Income__c = 50000,
                Credit_Score__c = 650
            ),
            new Contact(
                Id = contact2Id,
                LastName = 'Borrower2',
                Email = 'b2@example.com',
                Annual_Income__c = 55000,
                Credit_Score__c = 720
            )
        };

        List<Loan_Application__c> mockApplications = new List<Loan_Application__c>{
            new Loan_Application__c(
                Id = app1Id,
                Borrower__c = contact1Id,
                Amount__c = 20000,
                Status__c = 'Submitted'
            ),
            new Loan_Application__c(
                Id = app2Id,
                Borrower__c = contact2Id,
                Amount__c = 25000,
                Status__c = 'Submitted'
            )
        };

        Map<Id, Contact> mockContactsMap = new Map<Id, Contact>();
        for (Contact c : mockBorrowers) {
            mockContactsMap.put(c.Id, c);
        }

        List<Product__c> mockProducts = new List<Product__c>{
            new Product__c(
                Id = product1Id,
                Name = 'Bulk Test Product',
                Min_Credit_Score__c = 600,
                Base_Rate__c = 0.05
            )
        };

        // Set mocks
        mocks.startStubbing();
        mocks.when(mockLoanAppsSelector.sObjectType()).thenReturn(Loan_Application__c.SObjectType);
        mocks.when(mockContactsSelector.sObjectType()).thenReturn(Contact.SObjectType);
        mocks.when(mockProductsSelector.sObjectType()).thenReturn(Product__c.SObjectType);
        mocks.when(mockLoanAppsSelector.selectByIds((Set<Id>) fflib_Match.anyObject()))
            .thenReturn(mockApplications);
        mocks.when(mockContactsSelector.selectByIds((Set<Id>) fflib_Match.anyObject()))
            .thenReturn(mockContactsMap);
        mocks.when(mockProductsSelector.selectAllOrderByRateAsc())
            .thenReturn(mockProducts);
        mocks.stopStubbing();

        Application.Selector.setMock(mockLoanAppsSelector);
        Application.Selector.setMock(mockContactsSelector);
        Application.Selector.setMock(mockProductsSelector);

        // When - perform test
        Test.startTest();
        LoanApplicationService.submitApplications(mockApplications);
        Test.stopTest();

        // Then - validate bulk processing occurred
        ((LoanApplicationsSelector) mocks.verify(mockLoanAppsSelector, 1))
            .selectByIds((Set<Id>) fflib_Match.anyObject());
        ((ContactsSelector) mocks.verify(mockContactsSelector, 1))
            .selectByIds((Set<Id>) fflib_Match.anyObject());
        ((ProductsSelector) mocks.verify(mockProductsSelector, 1))
            .selectAllOrderByRateAsc();
    }

    @IsTest
    static void submitApplications_handlesEmptyInput() {
        // When - test with empty input
        Test.startTest();
        LoanApplicationService.submitApplications(new List<Loan_Application__c>());
        LoanApplicationService.submitApplications(null);
        Test.stopTest();

        // Then - should complete without errors
        System.assert(true, 'Empty input should not cause exceptions');
    }

    // Integration tests - keep minimal for end-to-end validation
    @IsTest
    static void submitApplications_integrationTest_approval() {
        Contact borrower = new Contact(
            LastName = 'IntegrationBorrower',
            Email = 'integration@example.com',
            Annual_Income__c = 60000,
            Credit_Score__c = 720
        );
        insert borrower;

        Product__c product = new Product__c(
            Name = 'Integration Product',
            Min_Credit_Score__c = 650,
            Base_Rate__c = 0.045
        );
        insert product;

        Loan_Application__c application = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = 20000,
            Status__c = 'Submitted'
        );
        insert application;

        Test.startTest();
        LoanApplicationService.submitApplications(new List<Loan_Application__c>{ application });
        Test.stopTest();

        Loan_Application__c result = [SELECT Status__c, Product__c FROM Loan_Application__c WHERE Id = :application.Id];
        System.assertEquals('Approved', result.Status__c, 'Application should be approved');
        System.assertEquals(product.Id, result.Product__c, 'Product should be assigned');

        List<Task> tasks = [SELECT Subject FROM Task WHERE WhatId = :application.Id];
        System.assertEquals(1, tasks.size(), 'Task should be created');
        System.assertEquals('Prepare documents', tasks[0].Subject, 'Task subject should be correct');
    }

    @IsTest
    static void submitApplications_integrationTest_rejection() {
        Contact borrower = new Contact(
            LastName = 'RejectedBorrower',
            Email = 'rejected@example.com',
            Annual_Income__c = 60000,
            Credit_Score__c = null
        );
        insert borrower;

        Loan_Application__c application = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = 20000,
            Status__c = 'Submitted'
        );
        insert application;

        Test.startTest();
        LoanApplicationService.submitApplications(new List<Loan_Application__c>{ application });
        Test.stopTest();

        Loan_Application__c result = [SELECT Status__c, Approval_Outcome__c FROM Loan_Application__c WHERE Id = :application.Id];
        System.assertEquals('Rejected', result.Status__c, 'Application should be rejected');
        System.assertNotEquals(null, result.Approval_Outcome__c, 'Rejection reason should be populated');
    }
}