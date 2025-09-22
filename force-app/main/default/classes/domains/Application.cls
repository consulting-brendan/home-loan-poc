public class Application {
    
    // Configure and create the SelectorFactory for this application
    public static final fflib_Application.SelectorFactory Selector = 
        new fflib_Application.SelectorFactory(
            new Map<SObjectType, Type> {
                Contact.SObjectType => ContactsSelector.class,
                Product__c.SObjectType => ProductsSelector.class,
                Loan_Application__c.SObjectType => LoanApplicationsSelector.class
            });
    
    // Configure and create the DomainFactory for this application
    public static final fflib_Application.DomainFactory Domain = 
        new fflib_Application.DomainFactory(
            Application.Selector,
            new Map<SObjectType, Type> {
                Loan_Application__c.SObjectType => LoanApplications.Constructor.class
            });
}