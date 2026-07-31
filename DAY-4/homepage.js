import { LightningElement } from 'lwc';

export default class HomePage extends LightningElement {

    customerName = 'Chaitra';
    todayDate = '31 July 2026';

    totalProducts = 50;
    totalCategories = 10;
    cartItems = 0;

    status = 'Cart Empty';

    handleShopNow() {
        this.cartItems = 1;
        this.status = 'Item Added to Cart';
    }

}
