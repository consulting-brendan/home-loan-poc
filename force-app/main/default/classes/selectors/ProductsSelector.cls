public with sharing class ProductsSelector extends fflib_SObjectSelector {
    public Schema.SObjectType getSObjectType() {
        return Product__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Product__c.Id,
            Product__c.Name,
            Product__c.Min_Credit_Score__c,
            Product__c.Base_Rate__c
        };
    }

    // Override to enforce ascending order by Base_Rate__c, then Min_Credit_Score__c
    public override String getOrderBy() {
        return 'Base_Rate__c ASC, Min_Credit_Score__c ASC';
    }

    // Story A: return all products ordered by rate (lowest first)
    public List<Product__c> selectAllOrderByRateAsc() {
        return (List<Product__c>) Database.query(newQueryFactory().toSOQL());
    }

    // Story B: only return products outside safe range
    public List<Product__c> selectForRateNormalization() {
        Decimal lower = ProductRateNormalizationService.LOWER_RATE;
        Decimal upper = ProductRateNormalizationService.UPPER_RATE;

        fflib_QueryFactory qf = newQueryFactory();
        qf.setCondition('Base_Rate__c < :lower OR Base_Rate__c > :upper');
        return (List<Product__c>) Database.query(qf.toSOQL());
    }

    public static ProductsSelector newInstance() {
        return new ProductsSelector();
    }
}
