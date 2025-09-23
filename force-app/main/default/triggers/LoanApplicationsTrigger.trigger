trigger LoanApplicationsTrigger on Loan_Application__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Loan_Application__c> submitted = new List<Loan_Application__c>();
        for (Loan_Application__c la : Trigger.new) {
            Loan_Application__c old = Trigger.oldMap.get(la.Id);
            if (old.Status__c == 'Draft' && la.Status__c == 'Submitted') {
                submitted.add(la);
            }
        }
        if (!submitted.isEmpty()) {
            LoanApplicationService.submitApplications(submitted);
        }
    }
}
