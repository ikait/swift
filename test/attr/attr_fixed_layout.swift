// RUN: %target-swift-frontend -typecheck -swift-version 4.2 -verify -dump-ast -enable-library-evolution %s | %FileCheck --check-prefix=RESILIENCE-ON %s
// RUN: %target-swift-frontend -typecheck -swift-version 4.2 -verify -dump-ast -enable-library-evolution -enable-testing %s | %FileCheck --check-prefix=RESILIENCE-ON %s
// RUN: not %target-swift-frontend -typecheck -swift-version 4.2 -dump-ast %s | %FileCheck --check-prefix=RESILIENCE-OFF %s
// RUN: not %target-swift-frontend -typecheck -swift-version 4.2 -dump-ast %s -enable-testing | %FileCheck --check-prefix=RESILIENCE-OFF %s

//
// Public types with @_fixed_layout are always fixed layout
//

// RESILIENCE-ON: struct_decl{{.*}}"Point" interface type='Point.Type' access=public non-resilient
// RESILIENCE-OFF: struct_decl{{.*}}"Point" interface type='Point.Type' access=public non-resilient
@_fixed_layout public struct Point {
  let x, y: Int
}

// RESILIENCE-ON: enum_decl{{.*}}"ChooseYourOwnAdventure" interface type='ChooseYourOwnAdventure.Type' access=public non-resilient
// RESILIENCE-OFF: enum_decl{{.*}}"ChooseYourOwnAdventure" interface type='ChooseYourOwnAdventure.Type' access=public non-resilient
@_frozen public enum ChooseYourOwnAdventure {
  case JumpIntoRabbitHole
  case EatMushroom
}

//
// Public types are resilient when -enable-library-evolution is on
//

// RESILIENCE-ON: struct_decl{{.*}}"Size" interface type='Size.Type' access=public resilient
// RESILIENCE-OFF: struct_decl{{.*}}"Size" interface type='Size.Type' access=public non-resilient
public struct Size {
  let w, h: Int
}

// RESILIENCE-ON: struct_decl{{.*}}"UsableFromInlineStruct" interface type='UsableFromInlineStruct.Type' access=internal non-resilient
// RESILIENCE-OFF: struct_decl{{.*}}"UsableFromInlineStruct" interface type='UsableFromInlineStruct.Type' access=internal non-resilient
@_fixed_layout @usableFromInline struct UsableFromInlineStruct {}

// RESILIENCE-ON: enum_decl{{.*}}"TaxCredit" interface type='TaxCredit.Type' access=public resilient
// RESILIENCE-OFF: enum_decl{{.*}}"TaxCredit" interface type='TaxCredit.Type' access=public non-resilient
public enum TaxCredit {
  case EarnedIncome
  case MortgageDeduction
}

//
// Internal types are always fixed layout
//

// RESILIENCE-ON: struct_decl{{.*}}"Rectangle" interface type='Rectangle.Type' access=internal non-resilient
// RESILIENCE-OFF: struct_decl{{.*}}"Rectangle" interface type='Rectangle.Type' access=internal non-resilient
struct Rectangle {
  let topLeft: Point
  let bottomRight: Size
}

//
// Diagnostics
//

@_fixed_layout struct InternalStruct { // expected-note * {{declared here}}
// expected-error@-1 {{'@_fixed_layout' attribute can only be applied to '@usableFromInline' or public declarations, but 'InternalStruct' is internal}}

  @_fixed_layout public struct NestedStruct {}
}

@_fixed_layout fileprivate struct FileprivateStruct {}
// expected-error@-1 {{'@_fixed_layout' attribute can only be applied to '@usableFromInline' or public declarations, but 'FileprivateStruct' is fileprivate}}

@_fixed_layout private struct PrivateStruct {} // expected-note * {{declared here}}
// expected-error@-1 {{'@_fixed_layout' attribute can only be applied to '@usableFromInline' or public declarations, but 'PrivateStruct' is private}}


@_fixed_layout public struct BadFields1 {
  private var field: PrivateStruct // expected-error {{type referenced from a stored property in a '@_fixed_layout' struct must be '@usableFromInline' or public}}
}

@_fixed_layout public struct BadFields2 {
  private var field: PrivateStruct? // expected-error {{type referenced from a stored property in a '@_fixed_layout' struct must be '@usableFromInline' or public}}
}

@_fixed_layout public struct BadFields3 {
  internal var field: InternalStruct? // expected-error {{type referenced from a stored property in a '@_fixed_layout' struct must be '@usableFromInline' or public}}
}

@_fixed_layout @usableFromInline struct BadFields4 {
  internal var field: InternalStruct? // expected-error {{type referenced from a stored property in a '@_fixed_layout' struct must be '@usableFromInline' or public}}
}

@_fixed_layout public struct BadFields5 {
  private var field: PrivateStruct? { // expected-error {{type referenced from a stored property in a '@_fixed_layout' struct must be '@usableFromInline' or public}}
    didSet {}
  }
}

// expected-warning@+1 {{the result of a '@usableFromInline' function should be '@usableFromInline' or public}}
@usableFromInline func notReallyUsableFromInline() -> InternalStruct? { return nil }
@_fixed_layout public struct BadFields6 {
  private var field = notReallyUsableFromInline() // expected-error {{type referenced from a stored property with inferred type 'InternalStruct?' in a '@_fixed_layout' struct must be '@usableFromInline' or public}}
}

@_fixed_layout public struct OKFields {
  private var publicTy: Size
  internal var ufiTy: UsableFromInlineStruct?

  internal static var staticProp: InternalStruct?

  private var computed: PrivateStruct? { return nil }
}
