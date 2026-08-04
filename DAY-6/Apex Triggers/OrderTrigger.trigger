trigger OrderTrigger on Order__c (before insert, after update) {

    if (Trigger.isBefore && Trigger.isInsert) {

        OrderTriggerHandler.beforeInsert(Trigger.new);

    }

    if (Trigger.isAfter && Trigger.isUpdate) {

        OrderTriggerHandler.afterUpdate(
            Trigger.new,
            Trigger.oldMap
        );

    }

}
