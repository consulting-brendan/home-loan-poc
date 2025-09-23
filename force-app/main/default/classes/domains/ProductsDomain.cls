public with sharing class ProductsDomain extends fflib_SObjectDomain {
    public ProductsDomain(List<Product__c> scope) {
        super(scope);
    }

    /**
     * Normalize rates in-memory; returns only changed records for update.
     */
    public static List<Product__c> normalizeRates(
        List<Product__c> products, 
        Decimal lowerBound, 
        Decimal upperBound
    ) {
        List<Product__c> changed = new List<Product__c>();
        for (Product__c product : products) {
            if (product.Base_Rate__c == null) continue;
            Decimal oldRate = product.Base_Rate__c;
            Decimal newRate = oldRate;
            if (oldRate < lowerBound) {
                newRate = lowerBound;
            } else if (oldRate > upperBound) {
                newRate = upperBound;
            }
            if (newRate != oldRate) {
                product.Base_Rate__c = newRate;
                changed.add(product);
            }
        }
        return changed;
    }
}
