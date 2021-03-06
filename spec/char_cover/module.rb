### Empty module
    module A
    end.to_s

#### Explicit global module
    module ::B
    end.to_s

#### Scoped module
    module String::B
    end.to_s

### Raising
#### Module/Class clash
    module String
#>  xxxxxx
    end.to_s rescue nil
#>  xxxxxxxx

#### Invalid path
    module String::Foo::A
#>  xxxxxx            xxx
    end.to_s rescue nil
#>  xxxxxxxx

#### Invalid (longer) path
    module String::Foo::Bar::A
#>  xxxxxx            xxxxxxxx
    end.to_s rescue nil
#>  xxxxxxxx

#### Raise inside block
    module M
      42
      raise
      44
#>X
    end.to_s rescue nil
#>     xxxxx

### Empty class
    class C
    end.to_s

#### Explicit global module
    class ::N
    end.to_s

#### Scoped module
    class String::N
    end.to_s

### Raising
#### Module/Class clash
    class Enumerable
#>  xxxxx
    end.to_s rescue nil
#>  ---xxxxx

#### Invalid path
    class String::Foo::M
#>  xxxxx            xxx
    end.to_s rescue nil
#>  ---xxxxx

#### Invalid (longer) path
    class String::Foo::Bar::M
#>  xxxxx            xxxxxxxx
    end.to_s rescue nil
#>  ---xxxxx

#### Raise inside block
    class N
      42
      raise
      44
#>X
    end.to_s rescue nil
#>  ---xxxxx
