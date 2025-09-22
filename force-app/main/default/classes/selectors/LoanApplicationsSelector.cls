public with sharing class LoanApplicationsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Loan_Application__c.Id,
            Loan_Application__c.Borrower__c,
            Loan_Application__c.Amount__c,
            Loan_Application__c.Status__c,
            Loan_Application__c.Product__c,
            Loan_Application__c.Approval_Outcome__c
        };
    }
    
    public Schema.SObjectType getSObjectType() {
        return Loan_Application__c.sObjectType;
    }
    
    public List<Loan_Application__c> selectById(Set<Id> idSet) {
        return (List<Loan_Application__c>) selectSObjectsById(idSet);
    }
    
    public List<Loan_Application__c> selectByIdWithBorrower(Set<Id> idSet) {
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.selectField('Borrower__r.Email');
        queryFactory.selectField('Borrower__r.Annual_Income__c');
        queryFactory.selectField('Borrower__r.Credit_Score__c');
        queryFactory.setCondition('Id IN :idSet');
        
        return (List<Loan_Application__c>) Database.query(queryFactory.toSOQL());
    }
    
    public List<Loan_Application__c> selectByStatus(String status) {
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('Status__c = :status');
        
        return (List<Loan_Application__c>) Database.query(queryFactory.toSOQL());
    }
    
    public static LoanApplicationsSelector newInstance() {
        return (LoanApplicationsSelector) Application.Selector.newInstance(Loan_Application__c.SObjectType);
    }
}