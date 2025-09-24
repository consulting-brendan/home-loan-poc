public with sharing class LoanApplicationsSelector extends fflib_SObjectSelector {
    public Schema.SObjectType getSObjectType() { return Loan_Application__c.SObjectType; }
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Loan_Application__c.Id,
            Loan_Application__c.Borrower__c,
            Loan_Application__c.Amount__c,
            Loan_Application__c.Status__c,
            Loan_Application__c.Product__c,
            Loan_Application__c.Approval_Outcome__c
        };
    }

    public List<Loan_Application__c> selectByIds(Set<Id> ids) {
        if (ids == null || ids.isEmpty()) return new List<Loan_Application__c>();
        return (List<Loan_Application__c>) Database.query(
            newQueryFactory().setCondition('Id IN :ids').toSOQL()
        );
    }
}