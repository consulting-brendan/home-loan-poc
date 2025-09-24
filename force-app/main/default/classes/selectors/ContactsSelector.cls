public inherited sharing class ContactsSelector extends fflib_SObjectSelector {
    
    public Schema.SObjectType getSObjectType() { 
        return Contact.SObjectType; 
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Contact.Id,
            Contact.Name,
            Contact.Email,
            Contact.Annual_Income__c,
            Contact.Credit_Score__c
        };
    }

    public Map<Id, Contact> selectByIds(Set<Id> contactIds) {
        if (contactIds == null || contactIds.isEmpty()) return new Map<Id, Contact>();

        return new Map<Id, Contact>((List<Contact>) Database.query(
            newQueryFactory()
                .assertIsAccessible()
                .setEnforceFLS(true)
                .setCondition('Id IN :contactIds').toSOQL()
        ));
    }
}
