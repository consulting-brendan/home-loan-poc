public with sharing class ProductsSelector extends fflib_SObjectSelector {
    
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Product__c.Id,
            Product__c.Name,
            Product__c.Min_Credit_Score__c,
            Product__c.Base_Rate__c
        };
    }
    
    public Schema.SObjectType getSObjectType() {
        return Product__c.sObjectType;
    }
    
    public List<Product__c> selectById(Set<Id> idSet) {
        return (List<Product__c>) selectSObjectsById(idSet);
    }
    
    public List<Product__c> selectAll() {
        fflib_QueryFactory queryFactory = newQueryFactory();
        return (List<Product__c>) Database.query(queryFactory.toSOQL());
    }
    
    public List<Product__c> selectEligibleProducts(Decimal creditScore) {
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('Min_Credit_Score__c <= :creditScore');
        queryFactory.addOrdering('Base_Rate__c', fflib_QueryFactory.SortOrder.ASCENDING);
        
        return (List<Product__c>) Database.query(queryFactory.toSOQL());
    }
    
    public List<Product__c> selectAllForRateNormalization() {
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('Base_Rate__c < 0.5 OR Base_Rate__c > 15');
        
        return (List<Product__c>) Database.query(queryFactory.toSOQL());
    }
    
    public static ProductsSelector newInstance() {
        return (ProductsSelector) Application.Selector.newInstance(Product__c.SObjectType);
    }
}