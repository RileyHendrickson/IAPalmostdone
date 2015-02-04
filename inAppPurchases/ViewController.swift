import UIKit
import StoreKit

class ViewController: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    var product_id: NSString?;
    
    override func viewDidLoad() {
        product_id = "CL4";
        super.viewDidLoad()
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        addBotton();
    }
    
    func addBotton(){
        let buyBottom = UIButton(frame: CGRectMake(100, 320, 200, 40))
        buyBottom.setTitle("Buy Consumable", forState: UIControlState.Normal);
        buyBottom.backgroundColor = UIColor(red: 0.0, green: 0.2, blue: 0.2, alpha: 1.0)
        buyBottom.addTarget(self, action: "buyConsumable", forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(buyBottom);
        
    }
    
    
    func buyConsumable(){
        println("About to fetch the products");
        // We check that we are allow to make the purchase.
        if (SKPaymentQueue.canMakePayments())
        {
            var productID:NSSet = NSSet(object: self.product_id!);
            var productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID);
            productsRequest.delegate = self;
            productsRequest.start();
            println("Fething Products");
        }else{
            println("can't make purchases");
        }
    }
    
    // Helper Methods
    
    func buyProduct(product: SKProduct){
        println("Sending the Payment Request to Apple");
        var payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment);
        
    }
    
    
    // Delegate Methods for IAP
    
    func productsRequest (request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        println("got the request from Apple")
        var count : Int = response.products.count
        if (count>0) {
            var validProducts = response.products
            var validProduct: SKProduct = response.products[0] as SKProduct
            if (validProduct.productIdentifier == self.product_id) {
                println(validProduct.localizedTitle)
                println(validProduct.localizedDescription)
                println(validProduct.price)
                buyProduct(validProduct);
            } else {
                println(validProduct.productIdentifier)
            }
        } else {
            println("nothing")
        }
    }
    
    
    func request(request: SKRequest!, didFailWithError error: NSError!) {
        println("La vaina fallo");
    }
    
    func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!)    {
        println("Received Payment Transaction Response from Apple");
        
        for transaction:AnyObject in transactions {
            if let trans:SKPaymentTransaction = transaction as? SKPaymentTransaction{
                switch trans.transactionState {
                case .Purchased:
                    println("Product Purchased");
                    validateRecipt()
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as SKPaymentTransaction)
                    break;
                case .Failed:
                    println("Purchased Failed");
                    SKPaymentQueue.defaultQueue().finishTransaction(transaction as SKPaymentTransaction)
                    break;
                    // case .Restored:
                    //[self restoreTransaction:transaction];
                default:
                    break;
                }
            }
        }
    }

    
    
    
   
    // this is SKStoreProductViewControllerDelegate implementation
    //implicitly unwrapped) optional closure (() -> Void)!
    
    
    
    //Server side
    func validateRecipt(){
        var response: NSURLResponse?
        var error: NSError?
        
        var recuptUrl = NSBundle.mainBundle().appStoreReceiptURL
        var receipt: NSData = NSData(contentsOfURL:recuptUrl!, options: nil, error: nil)!
        
        
        //var testOutput = NSString(data: receipt, encoding: NSUTF8StringEncoding)
        //println(testOutput)
        
        let receiptdata = receipt.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        
        //println(receiptdata)
        
        
        var request = NSMutableURLRequest(URL: NSURL(string: "http://104.236.212.56/validate")!)
        
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        var err: NSError?
        
        let bodyParameters = [
            "data" : receiptdata
        ]
        
        let bodyString = stringFromQueryParameters(bodyParameters)
        request.HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        //request.HTTPBody = receiptdata.dataUsingEncoding(NSUTF8StringEncoding)
        
        var task = session.dataTaskWithRequest(request, completionHandler:
            {data, response, error -> Void in
                var err: NSError?
                var json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &err) as? NSDictionary
                
                if(err != nil) {
                    println(err!.localizedDescription)
                    let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println("Error could not parse JSON: '\(jsonStr)'")
                }
                else {
                    if let parseJSON = json {
                        println("Recipt \(parseJSON)")
                    }
                    else {
                        let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                        println("Recipt Error: \(jsonStr)")
                    }
                }
        })
        
        task.resume()
        
    }
    
    func stringFromQueryParameters(queryParameters : Dictionary<String, String>) -> String {
        var parts: [String] = []
        for (name, value) in queryParameters {
            var part = NSString(format: "%@=%@",
                name.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!,
                value.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
            parts.append(part)
        }
        return "&".join(parts)
    }
    
    func NSURLByAppendingQueryParameters(URL : NSURL!, queryParameters : Dictionary<String, String>) -> NSURL {
        let URLString : NSString = NSString(format: "%@?%@", URL.absoluteString!, stringFromQueryParameters(queryParameters))
        return NSURL(string: URLString)!
    }
    
}


