public with sharing class LoanApplicationService {

    private static final String STATUS_APPROVED  = 'Approved';
    private static final String STATUS_REJECTED  = 'Rejected';

    private static final String TASK_SUBJECT     = 'Prepare documents';
    private static final Integer DOCUMENT_PREP_DAYS = 2;

    public static void submitApplications(List<Loan_Application__c> submittedApplicationsFromTrigger) {
        if (submittedApplicationsFromTrigger == null || submittedApplicationsFromTrigger.isEmpty()) return;

        Set<Id> applicationIds = new Map<Id, Loan_Application__c>(submittedApplicationsFromTrigger).keySet();
        List<Loan_Application__c> applications = new LoanApplicationsSelector().selectByIds(applicationIds);

        Set<Id> borrowerIds = new Set<Id>();
        for (Loan_Application__c application : applications) {
            if (application.Borrower__c != null) {
                borrowerIds.add(application.Borrower__c);
            }
        }
        Map<Id, Contact> contactsById = new ContactsSelector().selectByIds(borrowerIds);

        List<Product__c> productsOrdered = new ProductsSelector().selectAllOrderByRateAsc();

        Map<Id, LoanApplicationDomain.Decision> decisions =
            LoanApplicationDomain.evaluateApplications(applications, contactsById, productsOrdered);

        List<Loan_Application__c> applicationsToUpdate = new List<Loan_Application__c>();
        List<Task> tasksToInsert = new List<Task>();

        for (Loan_Application__c application : applications) {
            LoanApplicationDomain.Decision decision = decisions.get(application.Id);
            if (decision == null) continue;

            Loan_Application__c updatedApplication = new Loan_Application__c(Id = application.Id);

            if (decision.isValid) {
                updatedApplication.Status__c   = STATUS_APPROVED;
                updatedApplication.Product__c  = decision.selectedProductId;

                Task prepareDocumentsTask = new Task(
                    Subject      = TASK_SUBJECT,
                    OwnerId      = UserInfo.getUserId(),
                    WhatId       = application.Id,
                    ActivityDate = Date.today().addDays(DOCUMENT_PREP_DAYS)
                );
                tasksToInsert.add(prepareDocumentsTask);
            } else {
                updatedApplication.Status__c         = STATUS_REJECTED;
                updatedApplication.Approval_Outcome__c = decision.rejectionReason;
            }

            applicationsToUpdate.add(updatedApplication);
        }

        if (!applicationsToUpdate.isEmpty()) {
            update applicationsToUpdate;
        }
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}
