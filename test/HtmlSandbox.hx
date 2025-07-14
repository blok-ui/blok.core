import blok.html.server.*;
import blok.test.*;

using blok.Modifiers;

final sandbox = new SandboxFactory(new ServerAdaptor(), () -> new ElementPrimitive('#document'));
