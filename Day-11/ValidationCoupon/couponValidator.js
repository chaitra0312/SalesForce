import { LightningElement } from 'lwc';
import validateCoupon from '@salesforce/apex/CouponValidationService.validateCoupon';

export default class CouponValidator extends LightningElement {
    couponCode = '';
    resultMessage = '';
    isLoading = false;

    handleCodeChange(event) {
        this.couponCode = event.target.value;
    }

    handleApply() {
        this.isLoading = true;
        this.resultMessage = '';

        validateCoupon({ couponCode: this.couponCode })
            .then((result) => {
                this.resultMessage = result;
            })
            .catch((error) => {
                this.resultMessage = 'ERROR: ' + error.body.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}
