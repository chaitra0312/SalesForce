public class NotificationService {

    public static void sendOrderNotifications(
        List<Order__c> newOrders,
        Map<Id, Order__c> oldMap
    ) {

        for(Order__c ord : newOrders){

            Order__c oldOrder = oldMap.get(ord.Id);

            if(oldOrder != null &&
               oldOrder.Status__c != ord.Status__c){

                System.debug('Notification: Order Status changed to '
                             + ord.Status__c);
            }

        }

    }

}
