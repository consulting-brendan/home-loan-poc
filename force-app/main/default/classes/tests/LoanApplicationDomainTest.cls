@IsTest
private class LoanApplicationDomainTest {

    @IsTest
    static void evaluateApplicationsReturnsValidDecision() {
        Contact borrower = new Contact(
            LastName = 'Valid Borrower',
            Email = 'borrower@example.com',
            Annual_Income__c = 60000,
            Credit_Score__c = 720
        );
        insert borrower;

        Product__c eligibleProduct = new Product__c(
            Name = 'Eligible Product',
            Min_Credit_Score__c = 650,
            Base_Rate__c = 5.0
        );
        insert eligibleProduct;

        Loan_Application__c application = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = 20000,
            Status__c = 'Submitted'
        );
        insert application;

        Map<Id, Contact> borrowerMap = new Map<Id, Contact>{ borrower.Id => borrower };
        List<Product__c> products = new List<Product__c>{ eligibleProduct };

        Map<Id, LoanApplicationDomain.Decision> results =
            LoanApplicationDomain.evaluateApplications(new List<Loan_Application__c>{ application }, borrowerMap, products);

        LoanApplicationDomain.Decision decision = results.get(application.Id);
        System.assertEquals(true, decision.isValid);
        System.assertEquals(eligibleProduct.Id, decision.selectedProductId);
        System.assertEquals(null, decision.rejectionReason);
    }

    @IsTest
    static void evaluateApplicationsReturnsRejectionWhenEmailMissing() {
        Contact borrower = new Contact(
            LastName = 'Invalid Borrower',
            Email = null,
            Annual_Income__c = 60000,
            Credit_Score__c = 700
        );
        insert borrower;

        Product__c product = new Product__c(
            Name = 'Basic Product',
            Min_Credit_Score__c = 600,
            Base_Rate__c = 5.0
        );
        insert product;

        Loan_Application__c application = new Loan_Application__c(
            Borrower__c = borrower.Id,
            Amount__c = 20000,
            Status__c = 'Submitted'
        );
        insert application;

        Map<Id, Contact> borrowerMap = new Map<Id, Contact>{ borrower.Id => borrower };
        List<Product__c> products = new List<Product__c>{ product };

        Map<Id, LoanApplicationDomain.Decision> results =
            LoanApplicationDomain.evaluateApplications(new List<Loan_Application__c>{ application }, borrowerMap, products);

        LoanApplicationDomain.Decision decision = results.get(application.Id);
        System.assertEquals(false, decision.isValid);
        System.assertNotEquals(null, decision.rejectionReason);
    }
}