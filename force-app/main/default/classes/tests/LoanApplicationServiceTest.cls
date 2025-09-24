@IsTest
private class LoanApplicationServiceTest {

    @IsTest
    static void submitApplicationsApprovesAndCreatesTask() {
        Contact borrower = new Contact(LastName = 'Borrower', Email = 'borrower@example.com', Annual_Income__c = 60000, Credit_Score__c = 720);
        insert borrower;
        Product__c product = new Product__c(Name = 'Product A', Min_Credit_Score__c = 650, Base_Rate__c = 4.5);
        insert product;
        Loan_Application__c application = new Loan_Application__c(Borrower__c = borrower.Id, Amount__c = 20000, Status__c = 'Submitted');
        insert application;

        LoanApplicationService.submitApplications(new List<Loan_Application__c>{ application });

        Loan_Application__c updatedApplication = [
            SELECT Status__c, Product__c, Approval_Outcome__c 
            FROM Loan_Application__c 
            WHERE Id = :application.Id
        ];
        System.assertEquals('Approved', updatedApplication.Status__c);
        System.assertEquals(product.Id, updatedApplication.Product__c);
        System.assertEquals(null, updatedApplication.Approval_Outcome__c);

        Task createdTask = [SELECT Subject, ActivityDate, WhatId FROM Task WHERE WhatId = :application.Id LIMIT 1];
        System.assertEquals('Prepare documents', createdTask.Subject);
        System.assertEquals(Date.today().addDays(2), createdTask.ActivityDate);
    }

    @IsTest
    static void submitApplicationsRejectsWhenCreditScoreMissing() {
        Contact borrower = new Contact(LastName = 'Borrower2', Email = 'borrower2@example.com', Annual_Income__c = 60000, Credit_Score__c = null);
        insert borrower;
        Product__c product = new Product__c(Name = 'Product B', Min_Credit_Score__c = 600, Base_Rate__c = 4.5);
        insert product;
        Loan_Application__c application = new Loan_Application__c(Borrower__c = borrower.Id, Amount__c = 20000, Status__c = 'Submitted');
        insert application;

        LoanApplicationService.submitApplications(new List<Loan_Application__c>{ application });

        Loan_Application__c updatedApplication = [
            SELECT Status__c, Approval_Outcome__c 
            FROM Loan_Application__c 
            WHERE Id = :application.Id
        ];
        System.assertEquals('Rejected', updatedApplication.Status__c);
        System.assertNotEquals(null, updatedApplication.Approval_Outcome__c);
    }

    @IsTest
    static void submitApplicationsHandlesBulkApplications() {
        List<Contact> borrowers = new List<Contact>{
            new Contact(LastName = 'B1', Email = 'b1@example.com', Annual_Income__c = 50000, Credit_Score__c = 650),
            new Contact(LastName = 'B2', Email = 'b2@example.com', Annual_Income__c = 50000, Credit_Score__c = 550)
        };
        insert borrowers;

        List<Product__c> products = new List<Product__c>{
            new Product__c(Name = 'Prod1', Min_Credit_Score__c = 600, Base_Rate__c = 5.0),
            new Product__c(Name = 'Prod2', Min_Credit_Score__c = 500, Base_Rate__c = 6.0)
        };
        insert products;

        List<Loan_Application__c> applications = new List<Loan_Application__c>{
            new Loan_Application__c(Borrower__c = borrowers[0].Id, Amount__c = 20000, Status__c = 'Submitted'),
            new Loan_Application__c(Borrower__c = borrowers[1].Id, Amount__c = 20000, Status__c = 'Submitted')
        };
        insert applications;

        LoanApplicationService.submitApplications(applications);

        List<Loan_Application__c> updatedApplications = [
            SELECT Status__c, Product__c, Approval_Outcome__c 
            FROM Loan_Application__c 
            WHERE Id IN :applications
        ];
        System.assertEquals(2, updatedApplications.size());
    }
}