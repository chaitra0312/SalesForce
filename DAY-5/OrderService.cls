public class OrderService {
    public void placeOrder(Id customerId, Id productId, Integer quantity) {
        if (!checkStock(productId, quantity)) {
            System.debug('Product is Out of Stock');
            return;
        }
        Decimal totalAmount = calculateTotal(productId, quantity);
        if (!processPayment(customerId, totalAmount)) {
            System.debug('Payment Failed');
            return;
        }
        Order__c order = createOrder(customerId, productId, quantity, totalAmount);
        updateStock(productId, quantity);
        createShipment(order.Id);
        System.debug('Order Placed Successfully');
    }
    private Boolean checkStock(Id productId, Integer quantity) {

        Product__c product = [
            SELECT Stock_Quantity__c
            FROM Product__c
            WHERE Id = :productId
        ];

        if(product.Stock_Quantity__c >= quantity){
            return true;
    } else {
            return false;
    }
}
private Decimal calculateTotal(Id productId, Integer quantity) {

        Product__c product = [
            SELECT Price__c
            FROM Product__c
            WHERE Id = :productId
        ];
        return product.Price__c * quantity;
    }
    private Boolean processPayment(Id customerId, Decimal totalAmount) {
        System.debug('Processing Payment of ₹' + totalAmount);
        return true;
    }
    private Order__c createOrder(Id customerId,
                                 Id productId,
                                 Integer quantity,
                                 Decimal totalAmount) {

        Order__c order = new Order__c();
        order.Customer__c = customerId;
        order.Product__c = productId;
        order.Quantity__c = quantity;
        order.Total_Amount__c = totalAmount;
        order.Status__c = 'Pending';
        insert order;
        return order;
    }
    private void updateStock(Id productId, Integer quantity) {
        Product__c product = [
            SELECT Stock_Quantity__c
            FROM Product__c
            WHERE Id = :productId
        ];
        product.Stock_Quantity__c =
            product.Stock_Quantity__c - quantity;

        update product;
    }
    private void createShipment(Id orderId) {
        Shipment__c shipment = new Shipment__c();
        shipment.Order__c = orderId;
        shipment.Delivery_Status__c = 'Pending';
        insert shipment;
    }
}
