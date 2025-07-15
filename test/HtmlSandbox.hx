import blok.html.server.*;
import blok.test.*;

final sandbox = new SandboxFactory(new ServerAdaptor(), () -> new ElementPrimitive('#document'));
