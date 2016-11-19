package require Itcl

itcl::class ItclStack {
  constructor {} {set _stackObject [new]}
  destructor {destroy}

  # Class Methods
  public method push {val_} {$_stackObject push $val_}
  public method pop {} {$_stackObject pop}
  public method peek {} {$_stackObject peek}
  public method destroy {} {rename $_stackObject {}}
  private method new {} @createNewStack

  # Class Data Members
  private variable _stackObject
}
