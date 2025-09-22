public with sharing class ContactsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Contact.Id,
            Contact.Name,
            Contact.Email,
            Contact.Annual_Income__c,
            Contact.Credit_Score__c
        };
    }
    
    public Schema.SObjectType getSObjectType() {
        return Contact.sObjectType;
    }
    
    public List<Contact> selectById(Set<Id> idSet) {
        return (List<Contact>) selectSObjectsById(idSet);
    }
    
    public List<Contact> selectByIdWithSecurity(Set<Id> idSet) {
        return (List<Contact>) Database.query(
            newQueryFactory()
                .selectFields(getSObjectFieldList())
                .setCondition('Id IN :idSet')
                .toSOQL()
        );
    }
    
    public static ContactsSelector newInstance() {
        return (ContactsSelector) Application.Selector.newInstance(Contact.SObjectType);
    }
}