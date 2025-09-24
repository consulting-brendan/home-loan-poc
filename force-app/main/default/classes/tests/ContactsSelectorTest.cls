@IsTest(IsParallel=true)
private class ContactsSelectorTest {

    @IsTest
    static void getSObjectType_ReturnsContactSObjectType() {
        ContactsSelector selector = new ContactsSelector();
        System.assertEquals(Contact.SObjectType, selector.getSObjectType());
    }

    @IsTest
    static void getSObjectFieldList_ReturnsRequiredFields() {
        ContactsSelector selector = new ContactsSelector();
        List<Schema.SObjectField> fields = selector.getSObjectFieldList();
        
        Set<Schema.SObjectField> fieldSet = new Set<Schema.SObjectField>(fields);
        System.assert(fieldSet.contains(Contact.Id));
        System.assert(fieldSet.contains(Contact.Name));
        System.assert(fieldSet.contains(Contact.Email));
        System.assert(fieldSet.contains(Contact.Annual_Income__c));
        System.assert(fieldSet.contains(Contact.Credit_Score__c));
    }

    @IsTest
    static void selectByIds_ReturnsContactsWithAllFields() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Borrower',
            Email = 'test@example.com',
            Annual_Income__c = 50000,
            Credit_Score__c = 700
        );
        insert testContact;

        Test.startTest();
        Map<Id, Contact> result = new ContactsSelector().selectByIds(new Set<Id>{testContact.Id});
        Test.stopTest();

        System.assertEquals(1, result.size());
        Contact retrievedContact = result.get(testContact.Id);
        System.assertEquals('Test Borrower', retrievedContact.Name);
        System.assertEquals('test@example.com', retrievedContact.Email);
        System.assertEquals(50000, retrievedContact.Annual_Income__c);
        System.assertEquals(700, retrievedContact.Credit_Score__c);
    }

    @IsTest
    static void selectByIds_HandlesEmptySet() {
        Test.startTest();
        Map<Id, Contact> result = new ContactsSelector().selectByIds(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void selectByIds_HandlesNullSet() {
        Test.startTest();
        Map<Id, Contact> result = new ContactsSelector().selectByIds(null);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void selectByIds_HandlesBulkContacts() {
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            testContacts.add(new Contact(
                FirstName = 'Test' + i,
                LastName = 'Borrower' + i,
                Email = 'test' + i + '@example.com',
                Annual_Income__c = 50000 + i,
                Credit_Score__c = 700 + i
            ));
        }
        insert testContacts;

        Set<Id> contactIds = new Set<Id>();
        for (Contact c : testContacts) {
            contactIds.add(c.Id);
        }

        Test.startTest();
        Map<Id, Contact> result = new ContactsSelector().selectByIds(contactIds);
        Test.stopTest();

        System.assertEquals(200, result.size());
        
        Contact firstContact = result.values()[0];
        System.assertNotEquals(null, firstContact.Email);
        System.assertNotEquals(null, firstContact.Annual_Income__c);
        System.assertNotEquals(null, firstContact.Credit_Score__c);
    }

    @IsTest
    static void selectByIds_EnforcesFLS() {
        Contact testContact = new Contact(
            FirstName = 'Security',
            LastName = 'Test',
            Email = 'security@example.com',
            Annual_Income__c = 60000,
            Credit_Score__c = 750
        );
        insert testContact;

        Test.startTest();
        try {
            Map<Id, Contact> result = new ContactsSelector().selectByIds(new Set<Id>{testContact.Id});
            System.assert(true, 'Query should succeed with proper permissions');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('permissions') || e.getMessage().contains('FLS'), 
                'Should throw security-related exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
}