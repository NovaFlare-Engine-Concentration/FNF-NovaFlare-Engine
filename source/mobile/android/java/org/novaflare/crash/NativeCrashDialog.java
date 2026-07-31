package org.novaflare.crash;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import org.haxe.extension.Extension;

/**
 * Displays the final native-crash message on Android's UI thread while the
 * faulting hxcpp thread waits. The native handler re-raises the fatal signal
 * only after the player confirms the dialog (or after the safety timeout).
 */
public final class NativeCrashDialog
{
	private NativeCrashDialog() {}

	public static boolean showAndWait()
	{
		final Activity activity = Extension.mainActivity;
		if (activity == null || activity.isFinishing())
			return false;

		final CountDownLatch dismissed = new CountDownLatch(1);
		final AtomicBoolean confirmed = new AtomicBoolean(false);

		try
		{
			activity.runOnUiThread(new Runnable()
			{
				@Override
				public void run()
				{
					try
					{
						AlertDialog dialog = new AlertDialog.Builder(activity)
							.setTitle("NovaFlare Engine - 应用程序闪退 / Application Crash")
							.setMessage(
								"应用程序已闪退，错误信息已保存至 crash 文件夹。\n\n"
								+ "The application has crashed. Error information was saved to the crash folder.")
							.setCancelable(false)
							.setPositiveButton("确定 / OK", new DialogInterface.OnClickListener()
							{
								@Override
								public void onClick(DialogInterface source, int which)
								{
									confirmed.set(true);
									dismissed.countDown();
								}
							})
							.create();

						dialog.setCanceledOnTouchOutside(false);
						dialog.setOnDismissListener(new DialogInterface.OnDismissListener()
						{
							@Override
							public void onDismiss(DialogInterface source)
							{
								dismissed.countDown();
							}
						});
						dialog.show();
					}
					catch (Throwable error)
					{
						dismissed.countDown();
					}
				}
			});

			return dismissed.await(60, TimeUnit.SECONDS) && confirmed.get();
		}
		catch (Throwable error)
		{
			return false;
		}
	}
}
