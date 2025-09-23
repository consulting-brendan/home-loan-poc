public with sharing class LoanApplicationDomain extends fflib_SObjectDomain {
    public LoanApplicationDomain(List<Loan_Application__c> scope) { super(scope); }

    public class Decision {
        public Id applicationId;
        public Boolean isValid;
        public Id selectedProductId;
        public String rejectionReason;
        public Decision(Id appId) { applicationId = appId; isValid = false; }
    }

    public static Map<Id, Decision> evaluateApplications(
        List<Loan_Application__c> applications,
        Map<Id, Contact> contactsById,
        List<Product__c> productsAscByRate
    ) {
        Map<Id, Decision> out = new Map<Id, Decision>();
        if (applications == null || applications.isEmpty()) return out;

        for (Loan_Application__c app : applications) {
            Decision d = new Decision(app.Id);

            if (app.Amount__c == null || app.Amount__c <= 0) {
                d.rejectionReason = 'Loan amount must be greater than zero.';
                out.put(app.Id, d); continue;
            }

            Contact c = contactsById.get(app.Borrower__c);
            if (c == null) {
                d.rejectionReason = 'Borrower not found.';
                out.put(app.Id, d); continue;
            }
            if (String.isBlank(c.Email)) {
                d.rejectionReason = 'Borrower email is required.';
                out.put(app.Id, d); continue;
            }
            if (c.Annual_Income__c == null || c.Annual_Income__c <= 0) {
                d.rejectionReason = 'Annual income must be greater than zero.';
                out.put(app.Id, d); continue;
            }
            if (c.Credit_Score__c == null) {
                d.rejectionReason = 'Credit score is required.';
                out.put(app.Id, d); continue;
            }

            for (Product__c prod : productsAscByRate) {
                if (prod.Min_Credit_Score__c != null 
                    && prod.Min_Credit_Score__c <= c.Credit_Score__c) {
                    d.isValid = true;
                    d.selectedProductId = prod.Id;
                    break;
                }
            }
            if (!d.isValid) d.rejectionReason = 'No eligible product for borrower credit profile.';
            out.put(app.Id, d);
        }
        return out;
    }
}
