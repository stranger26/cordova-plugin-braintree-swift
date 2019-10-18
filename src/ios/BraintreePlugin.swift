import BraintreeDropIn
import Braintree

@objc(BraintreePlugin) class BraintreePlugin : CDVPlugin {
    var token: String!
    
    @objc(initialize:)
    func initialize(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: "Error Initializing Braintree Plugin"
        )
        self.token = command.arguments[0] as? String ?? ""
        if(self.token.isEmpty){
            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "A token is required."
            )
        }
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        BTAppSwitch.setReturnURLScheme("\(bundleIdentifier).payments")
        pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate!.send(pluginResult!, callbackId: command.callbackId)
    }
    
    @objc(presentDropInPaymentUI:)
    func presentDropInPaymentUI(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR)
        var response: [String:Any]!
        let request = BTDropInRequest()
        request.threeDSecureRequest?.amount = command.arguments[0] as! NSDecimalNumber
        let dropIn = BTDropInController(authorization: self.token, request: request)
        { (controller, result, error) in
            if (error != nil) {
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: "Something went wrong."
                )
            } else if (result?.isCancelled == true) {
                response = ["userCancelled": true]
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: response
                )
            } else if let result = result {
                response = self.getPaymentMethodNonce(paymentMethodNonce: result.paymentMethod!)
                pluginResult = CDVPluginResult(
                    status: CDVCommandStatus_OK,
                    messageAs: response
                )
            }
            self.commandDelegate!.send(pluginResult!, callbackId: command.callbackId)
            controller.dismiss(animated: true, completion: nil)
        }
        self.viewController?.present(dropIn!, animated: true, completion: nil)
    }
    
    func getPaymentMethodNonce(paymentMethodNonce: BTPaymentMethodNonce) -> [String:Any] {
        var payPalAccountNonce: BTPayPalAccountNonce
        var cardNonce: BTCardNonce
        
        var response: [String: Any] = ["userCancelled": false]
        response["nonce"] = paymentMethodNonce.nonce
        response["type"] = paymentMethodNonce.type
        response["localizedDescription"] = paymentMethodNonce.localizedDescription
        if(paymentMethodNonce is BTPayPalAccountNonce){
            payPalAccountNonce = paymentMethodNonce as! BTPayPalAccountNonce
            response["payPalAccount"] = [
                "email": payPalAccountNonce.email,
                "firstName": payPalAccountNonce.firstName,
                "lastName": payPalAccountNonce.lastName,
                "phone": payPalAccountNonce.phone,
                "clientMetadataId": payPalAccountNonce.clientMetadataId,
                "payerId": payPalAccountNonce.payerId
            ]
        }
        if(paymentMethodNonce is BTCardNonce){
            cardNonce = paymentMethodNonce as! BTCardNonce
            response["card"] = [
                "lastTwo": cardNonce.lastTwo!,
                "network": cardNonce.cardNetwork
            ]
        }
        return response
    }
}
