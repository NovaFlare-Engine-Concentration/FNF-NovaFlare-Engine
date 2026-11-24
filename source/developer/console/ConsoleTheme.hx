package developer.console;

import general.backend.Paths;

enum abstract ConsoleMode(Int) {
	var NovaFlare;
	var CodeName;
	var Origin;
}

typedef ConsoleTheme = {
	final font:String;
	final panel:Int;
	final border:Int;
	final header:Int;
	final launcher:Int;
	final launcherHover:Int;
	final launcherBorder:Int;
	final control:Null<Int>;
}

class ConsoleThemes {
	public static function forMode(mode:ConsoleMode):ConsoleTheme {
		return switch (mode) {
			case NovaFlare: {
				font: Paths.font("Lang-ZH.ttf"),
				panel: 0x111820, border: 0x40505F, header: 0x1D2A35,
				launcher: 0x243746, launcherHover: 0x355A6D, launcherBorder: 0x8BD3FF,
				control: null
			};
			case CodeName: {
				font: "_sans",
				panel: 0x17152A, border: 0x695CAE, header: 0x302856,
				launcher: 0x403674, launcherHover: 0x5D4AAC, launcherBorder: 0xBAA8FF,
				control: 0x4C3E88
			};
			case Origin: {
				font: "_sans",
				panel: 0x211A12, border: 0x916836, header: 0x47311B,
				launcher: 0x69481F, launcherHover: 0x8B612D, launcherBorder: 0xFDE871,
				control: 0x755225
			};
		}
	}
}
