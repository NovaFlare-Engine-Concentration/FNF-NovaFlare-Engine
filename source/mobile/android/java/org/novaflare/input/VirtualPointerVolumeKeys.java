package org.novaflare.input;

import android.app.Activity;
import android.view.KeyEvent;
import android.view.Window;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import org.haxe.extension.Extension;

/** Observes the volume-key chord without consuming Android's normal volume keys. */
public final class VirtualPointerVolumeKeys {
    private static boolean up, down, latched;
    private static int pending;

    private VirtualPointerVolumeKeys() {}

    public static void install() {
        final Activity activity = Extension.mainActivity;
        if (activity == null) return;
        activity.runOnUiThread(() -> {
            final Window window = activity.getWindow();
            final Window.Callback previous = window.getCallback();
            if (previous == null || (Proxy.isProxyClass(previous.getClass())
                    && Proxy.getInvocationHandler(previous) instanceof Observer)) return;
            window.setCallback((Window.Callback) Proxy.newProxyInstance(
                    Window.Callback.class.getClassLoader(), new Class<?>[] { Window.Callback.class },
                    new Observer(previous)));
        });
    }

    public static synchronized int consumeToggles() {
        int result = pending;
        pending = 0;
        return result;
    }

    private static synchronized void observe(KeyEvent event) {
        int code = event.getKeyCode();
        if (code != KeyEvent.KEYCODE_VOLUME_UP && code != KeyEvent.KEYCODE_VOLUME_DOWN) return;
        if (event.getAction() == KeyEvent.ACTION_DOWN) {
            if (code == KeyEvent.KEYCODE_VOLUME_UP) up = true; else down = true;
            if (up && down && !latched) { pending++; latched = true; }
        } else if (event.getAction() == KeyEvent.ACTION_UP) {
            if (code == KeyEvent.KEYCODE_VOLUME_UP) up = false; else down = false;
            if (!up && !down) latched = false;
        }
    }

    private static synchronized void clearKeys() { up = down = latched = false; }

    private static final class Observer implements InvocationHandler {
        private final Window.Callback delegate;
        Observer(Window.Callback delegate) { this.delegate = delegate; }
        @Override public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            if ("dispatchKeyEvent".equals(method.getName()) && args != null && args.length == 1
                    && args[0] instanceof KeyEvent) observe((KeyEvent) args[0]);
            else if ("onWindowFocusChanged".equals(method.getName()) && args != null
                    && args.length == 1 && Boolean.FALSE.equals(args[0])) clearKeys();
            try { return method.invoke(delegate, args); }
            catch (InvocationTargetException ex) { throw ex.getCause(); }
        }
    }
}
