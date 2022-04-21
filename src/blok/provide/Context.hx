package blok.provide;

#if !macro
  import blok.ui.Widget;
  import blok.ui.Component;
#end

class Context {
  #if macro
    public static function provide(value, child) {
      return ProviderBuilder.createProvider(value, child);
    }

    public static function get(el, kind) {
      return ProviderBuilder.resolveProvider(el, kind);
    }
  #else
    public static macro function provide(value, child);
    public static macro function get(type);
    
    public static function use(build) {
      return ContextUser.of({ build: build });
    }
  #end
}

#if !macro
  class ContextUser extends Component {
    @prop var build:(context:ContextUser)->Widget;
    public macro function get(type);

    function render() {
      return build(this);
    }
  }
#else
  class ContextUser {
    public static function get(self, kind) {
      return ProviderBuilder.resolveProvider(self, kind); 
    }
  }
#end
