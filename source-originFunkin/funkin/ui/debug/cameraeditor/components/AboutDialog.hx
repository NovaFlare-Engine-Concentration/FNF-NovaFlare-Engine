package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import haxe.ui.containers.dialogs.Dialog;

/**
 * The dialog that displays general information about the Camera Editor.
 */
@:build(originfunkin.macro.OriginEditorMacro.build('assets/exclude/ui/editors/camera-editor/dialogs/about.xml'))
class AboutDialog extends Dialog
{
}
#end
