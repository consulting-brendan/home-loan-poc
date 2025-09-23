public with sharing class ProductRateNormalizationBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Decimal lower = ProductRateNormalizationService.LOWER_RATE;
        Decimal upper = ProductRateNormalizationService.UPPER_RATE;

        fflib_QueryFactory qf = new ProductsSelector().newQueryFactory();
        qf.setCondition(
            'Base_Rate__c < ' + String.valueOf(lower) +
            ' OR Base_Rate__c > ' + String.valueOf(upper)
        );

        return Database.getQueryLocator(qf.toSOQL());
    }

    public void execute(Database.BatchableContext bc, List<Product__c> scope) {
        List<Product__c> normalized =
            ProductsDomain.normalizeRates(
                scope,
                ProductRateNormalizationService.LOWER_RATE,
                ProductRateNormalizationService.UPPER_RATE
            );

        if (!normalized.isEmpty()) {
            update normalized;
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
