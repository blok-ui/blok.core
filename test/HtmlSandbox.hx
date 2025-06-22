import blok.html.server.*;
import blok.test.*;

using blok.Modifiers;

final sandbox = new Sandbox(new ServerAdaptor(), () -> new ElementPrimitive('#document'));
