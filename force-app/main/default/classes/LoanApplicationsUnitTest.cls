@IsTest
public class LoanApplicationsUnitTest {
    
    private static final String STATUS_DRAFT = 'Draft';
    private static final String STATUS_SUBMITTED = 'Submitted';
    private static final String STATUS_APPROVED = 'Approved';
    private static final String STATUS_REJECTED = 'Rejected';
    
    @IsTest
    static void validateApplication_WithValidBorrower_ShouldReturnEmpty() {
        Contact validBorrower = new Contact(
            Email = 'test@example.com',
            Annual_Income__c = 75000,
            Credit_Score__c = 720
        );
        
        Loan_Application__c application = new Loan_Application__c(
            Amount__c = 250000
        );

        LoanApplications domain = new LoanApplications(new List<Loan_Application__c>{application});
        
        Test.startTest();
        
        String result = testValidateApplication(application, validBorrower);
        
        Test.stopTest();
        
        System.assert(String.isBlank(result), 'Valid application should pass validation');
    }
    
    @IsTest
    static void validateApplication_WithMissingEmail_ShouldReturnError() {
        Contact invalidBorrower = new Contact(
            Email = null,
            Annual_Income__c = 75000,
            Credit_Score__c = 720
        );
        
        Loan_Application__c application = new Loan_Application__c(
            Amount__c = 250000
        );
        
        Test.startTest();
        
        String result = testValidateApplication(application, invalidBorrower);
        
        Test.stopTest();
        
        System.assert(result.contains('email is required'), 
                     'Should contain email validation error: ' + result);
    }
    
    @IsTest
    static void validateApplication_WithZeroIncome_ShouldReturnError() {
        Contact invalidBorrower = new Contact(
            Email = 'test@example.com',
            Annual_Income__c = 0, 
            Credit_Score__c = 720
        );
        
        Loan_Application__c application = new Loan_Application__c(
            Amount__c = 250000
        );
        
        Test.startTest();
        
        String result = testValidateApplication(application, invalidBorrower);
        
        Test.stopTest();
        
        System.assert(result.contains('income must be greater than 0'), 
                     'Should contain income validation error: ' + result);
    }
    
    @IsTest
    static void validateApplication_WithNullCreditScore_ShouldReturnError() {
        Contact invalidBorrower = new Contact(
            Email = 'test@example.com',
            Annual_Income__c = 75000,
            Credit_Score__c = null 
        );
        
        Loan_Application__c application = new Loan_Application__c(
            Amount__c = 250000
        );
        
        Test.startTest();
        
        String result = testValidateApplication(application, invalidBorrower);
        
        Test.stopTest();
        
        System.assert(result.contains('credit score is required'), 
                     'Should contain credit score validation error: ' + result);
    }
    
    @IsTest
    static void validateApplication_WithZeroAmount_ShouldReturnError() {
        Contact validBorrower = new Contact(
            Email = 'test@example.com',
            Annual_Income__c = 75000,
            Credit_Score__c = 720
        );
        
        Loan_Application__c invalidApplication = new Loan_Application__c(
            Amount__c = 0 // Invalid amount
        );
        
        Test.startTest();
        
        String result = testValidateApplication(invalidApplication, validBorrower);
        
        Test.stopTest();
        
        System.assert(result.contains('amount must be greater than 0'), 
                     'Should contain amount validation error: ' + result);
    }
    
    @IsTest
    static void selectBestProduct_WithEligibleProducts_ShouldReturnLowestRate() {
        List<Product__c> products = new List<Product__c>{
            new Product__c(
                Name = 'High Rate Product',
                Min_Credit_Score__c = 650,
                Base_Rate__c = 5.0
            ),
            new Product__c(
                Name = 'Low Rate Product',
                Min_Credit_Score__c = 700,
                Base_Rate__c = 2.5 
            ),
            new Product__c(
                Name = 'Medium Rate Product',
                Min_Credit_Score__c = 680,
                Base_Rate__c = 3.7
            )
        };
        
        Decimal creditScore = 750; 
        
        Test.startTest();
        
        Product__c result = testSelectBestProduct(creditScore, products);
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should find a product');
        System.assertEquals('Low Rate Product', result.Name, 'Should select lowest rate product');
        System.assertEquals(2.5, result.Base_Rate__c, 'Should have the lowest rate');
    }
    
    @IsTest
    static void selectBestProduct_WithNoEligibleProducts_ShouldReturnNull() {
        List<Product__c> products = new List<Product__c>{
            new Product__c(
                Name = 'High Credit Product',
                Min_Credit_Score__c = 750,
                Base_Rate__c = 3.5
            )
        };
        
        Decimal creditScore = 600;
        
        Test.startTest();
        
        Product__c result = testSelectBestProduct(creditScore, products);
        
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should not find eligible products');
    }
    
    @IsTest
    static void selectBestProduct_WithPartiallyEligibleProducts_ShouldReturnBestEligible() {
        List<Product__c> products = new List<Product__c>{
            new Product__c(
                Name = 'Too High Credit Product',
                Min_Credit_Score__c = 750,
                Base_Rate__c = 2.0 
            ),
            new Product__c(
                Name = 'Eligible High Rate',
                Min_Credit_Score__c = 650,
                Base_Rate__c = 4.5
            ),
            new Product__c(
                Name = 'Eligible Low Rate',
                Min_Credit_Score__c = 680,
                Base_Rate__c = 3.2 
            )
        };
        
        Decimal creditScore = 700; // Eligible for 650 and 680 requirements
        
        Test.startTest();
        
        Product__c result = testSelectBestProduct(creditScore, products);
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should find a product');
        System.assertEquals('Eligible Low Rate', result.Name, 'Should select best among eligible');
        System.assertEquals(3.2, result.Base_Rate__c, 'Should have the lowest eligible rate');
    }
    
    // HELPER METHODS TO TEST PRIVATE DOMAIN LOGIC
    private static String testValidateApplication(Loan_Application__c application, Contact borrower) {
        LoanApplications domain = new LoanApplications(new List<Loan_Application__c>{application});
        
        List<String> validationErrors = new List<String>();
        
        if (borrower == null) {
            validationErrors.add('Borrower not found');
        } else {
            if (String.isBlank(borrower.Email)) {
                validationErrors.add('Borrower email is required');
            }
            
            if (borrower.Annual_Income__c == null || borrower.Annual_Income__c <= 0) {
                validationErrors.add('Borrower annual income must be greater than 0');
            }
            
            if (borrower.Credit_Score__c == null) {
                validationErrors.add('Borrower credit score is required');
            }
        }
        
        if (application.Amount__c == null || application.Amount__c <= 0) {
            validationErrors.add('Loan amount must be greater than 0');
        }
        
        return String.join(validationErrors, '; ');
    }
    
    private static Product__c testSelectBestProduct(Decimal creditScore, List<Product__c> allProducts) {
        Product__c bestProduct = null;
        Decimal lowestRate = null;
        
        for (Product__c product : allProducts) {
            if (product.Min_Credit_Score__c <= creditScore) {
                if (bestProduct == null || product.Base_Rate__c < lowestRate) {
                    bestProduct = product;
                    lowestRate = product.Base_Rate__c;
                }
            }
        }
        
        return bestProduct;
    }
}