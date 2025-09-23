@IsTest
private class ProductsSelectorTest {

    @IsTest
    static void selectAllOrderByRateAscReturnsInsertedProductsInCorrectOrder() {
        Product__c p1 = new Product__c(Name = 'Prod1', Min_Credit_Score__c = 700, Base_Rate__c = 10);
        Product__c p2 = new Product__c(Name = 'Prod2', Min_Credit_Score__c = 600, Base_Rate__c = 5);
        insert new List<Product__c>{ p1, p2 };

        List<Product__c> selected = new ProductsSelector().selectAllOrderByRateAsc();

        System.assert(!selected.isEmpty());
        System.assertEquals(p2.Id, selected[0].Id);
        System.assertEquals(p1.Id, selected[1].Id);
    }
}
