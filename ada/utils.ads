package Utils
   with pure
is
   type Byte is mod 256;

   type Terminal_Verification_Results is record
       pinEntryRequiredPinPadPresentButPinWasNotEntered: Boolean;
       pinEntryRequiredButNoPinPadPresentOrNotWorking: Boolean;
   end record;

   type Nok_Reason is (N_CHIP_ERROR);

   type Terminal_Transaction_Data is record
       tvr: Terminal_Verification_Results;
       chipPinEntered: Boolean;
       cardholderRequestedChangeOfApplication: Boolean;
       pinPadNotWorking: Boolean;
       pinEntryBypassed: Boolean;
       nokReason: Nok_Reason;
   end record;

   type CvmEnum is (
       CVM_SUCCESS,
       PLAINTEXT_PIN_VERIFICATION_PERFORMED_BY_ICC,
       ENCIPHERED_PIN_VERIFIED_ONLINE,
       PLAINTEXT_PIN_VERIFICATION_PERFORMED_BY_ICC_AND_SIGNATURE,
       ENCIPHERED_PIN_VERIFIED_BY_ICC,
       ENCIPHERED_PIN_VERFIFIED_BY_ICC_AND_SIGNATURE,
       CVM_SIGNATURE,
       NO_CVM_REQUIRED
   );

   type Pin_Type is (
       OFFLINE, ONLINE, NONE);

   type Result is (
       OK,
       NOK,
       BAIL,
       CVM_RETRY,
       CVM_UNSUCCESSFUL,
       CVM_SUCCESSFUL
   );

   type CVM_Code is record
       cvm: CvmEnum;
       applyRuleOnFail: Boolean;
   end record;

   type CVM_Condition is (
       ALWAYS,
       IF_UNATTENDED_CASH,
       IF_NO_CASH,
       IF_SUPPORTED,
       IF_MANUAL_CASH,
       IF_PURCHASE_WITH_CASHBACK
   );

   type CVR is record
       code: CVM_Code;
       condition: CVM_Condition;
   end record;

   type Card_Status is (
       E_AUTHENTICATION_METHOD_BLOCKED,
       E_REFERENCED_DATA_REVERSIBLY_BLOCKED,
       I_COMMAND_OK,
       W_STATE_OF_NON_VOLATILE_MEMORY_CHANGED
   );

   type Card_Response is record
       sw1sw2: Card_Status;
   end record;

   type Cardholder_Verification is record
       pinTryCounter: Integer;
   end record;

   subtype int is Card_Status;
end;
