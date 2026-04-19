// Re-Export aus dem Shared-Package `fegh_core`.
//
// Die Doku-App nutzt ab jetzt das gemeinsame Employee-Modell.
// Der Typedef `Mitarbeiter = Employee` in fegh_core haelt die
// bestehenden Call-Sites lauffaehig (Mitarbeiter(...), List<Mitarbeiter>).
export 'package:fegh_core/fegh_core.dart'
    show
        Employee,
        Mitarbeiter,
        Address,
        EmergencyContact,
        EmployeeStatus,
        ContractType,
        MitarbeiterBereich,
        EmployeeStatusDisplay,
        ContractTypeDisplay,
        MitarbeiterBereichDisplay;
