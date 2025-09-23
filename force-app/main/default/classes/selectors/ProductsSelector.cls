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

    public override String getOrderBy() {
        return 'Base_Rate__c ASC, Min_Credit_Score__c ASC, Name ASC';
    }

    public List<Product__c> selectAllOrderByRateAsc() {
        return (List<Product__c>) Database.query(
            newQueryFactory().toSOQL()
        );
    }
}
