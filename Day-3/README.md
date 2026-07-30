# Salesforce Flow Automation Assignment

## Project Title
Order Automation using Salesforce Flow and Validation Rules

## Project Description
This project demonstrates how Salesforce declarative tools can be used to automate business processes without writing Apex code. A Record-Triggered Flow was created to automate order processing, and Validation Rules were implemented to ensure data integrity.

---

## Objectives

- Automate Order processing using Flow Builder.
- Validate user input using Validation Rules.
- Understand when to use Flow, Validation Rules, and Apex.

---

## Technologies Used

- Salesforce Developer Edition
- Flow Builder
- Record-Triggered Flow
- Validation Rules
- Email Action
- Custom Object (Order)

---

## Flow Implementation

### Record-Triggered Flow

**Flow Type:**
- Record-Triggered Flow

**Object:**
- Order

**Trigger:**
- A record is created

**Flow Actions:**
1. Automatically assigns the current date to the Order Date field.
2. Updates the Order record.
3. Sends an email notification to the administrator.

---

## Flow Structure

Start
↓
Set Order Date (Assignment)
↓
Update Records
↓
Send Email
↓
End

---

## Validation Rules Implemented

### Validation Rule 1
**Rule Name:**
Validate_Total_Amount

**Purpose:**
Ensures Total Amount is greater than zero.

**Formula**

```
Total_Amount__c <= 0
```

**Error Message**

```
Total Amount must be greater than 0.
```

### Validation Rule 2

**Rule Name:**
Order_Date_Required

**Purpose:**
Ensures Order Date is not left blank.

**Formula**

```
ISBLANK(Order_Date__c)
```

**Error Message**

```
Order Date is mandatory.
```

---

### Validation Rule 3

**Rule Name:**
Customer_Required

**Purpose:**
Ensures a Customer is selected before saving the record.

**Formula**

```
ISBLANK(Customer__c)
```

**Error Message**

```
Please select a Customer.
```

---

# Project Files

```
Salesforce-Flow-Automation
│
├── Flow Export
│      Order Auto Setup.flow-meta.xml
│
├── Validation Rules
│      Validation Rule Formulas
│
├── Screenshots
│      Flow Canvas.png
│      Successful Email.png
│      Successful Execution.png
│
└── README.md
```

---

# Screenshots Included

- Flow Canvas
- Assignment Element
- Update Records Element
- Send Email Action
- Successful Email Notification
- Successful Flow Execution

---

# Assignment Questions

## 1. Which requirements did you solve using Flow?

The following requirements were implemented using a Record-Triggered Flow:

- Automatically set the Order Date when a new Order is created.
- Update the Order record.
- Send an email notification to the administrator after the Order is created.

---

## 2. Which requirements required Validation Rules?

Validation Rules were used to prevent invalid data from being saved.

Implemented rules include:

- Total Amount must be greater than zero.
- Order Date cannot be blank.
- Customer must be selected before saving the record.

---

## 3. Which requirements still needed Apex?

No Apex code was required for this project because all business requirements were simple and could be implemented using Salesforce declarative tools.

Examples of scenarios where Apex would be required include:

- Complex business logic
- External API integrations
- Bulk processing
- Advanced calculations across multiple objects

---

## 4. Why did you choose those solutions?

Flow was chosen because it provides a no-code solution for automating business processes such as updating records and sending emails.

Validation Rules were chosen because they prevent invalid data from being saved and maintain data quality.

Apex was not used because the project requirements were straightforward and could be completed efficiently using declarative Salesforce features.

---

# Learning Outcomes

After completing this project, I learned:

- How to create a Record-Triggered Flow.
- How Assignment and Update Records elements work.
- How to send emails using Flow.
- How Validation Rules improve data quality.
- When to use Flow, Validation Rules, and Apex in Salesforce.
