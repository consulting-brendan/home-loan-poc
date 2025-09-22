trigger LoanApplicationsTrigger on Loan_Application__c (before insert, before update, after insert, after update, before delete) {
    fflib_SObjectDomain.triggerHandler(LoanApplications.class);
}