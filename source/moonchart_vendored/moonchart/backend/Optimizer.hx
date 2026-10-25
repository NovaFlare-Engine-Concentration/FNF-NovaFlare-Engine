package moonchart.backend;

class Optimizer
{
	public static function removeDefaultValues<T>(chart:T, fields:Dynamic):Void
	{
		// Look for each set default field
		for (field in Reflect.fields(fields))
		{
			// Look if the chart has the field
			if (Reflect.hasField(chart, field))
			{
				var chartValue:Dynamic = Reflect.field(chart, field);
				var isValue:Bool = false;

				if (chartValue is Array)
				{
					isValue = chartValue.length <= 0;
				}
				else
				{
					var fieldValue:Dynamic = Reflect.field(fields, field);
					isValue = chartValue == fieldValue;
				}

				// Remove if the value is the same as the default or empty
				if (isValue)
				{
					Reflect.deleteField(chart, field);
				}
			}
		}
	}

	public static function addDefaultValues<T>(chart:Null<T>, fields:Dynamic):T
	{
		if (chart == null)
			return fields;

		// Look for each set default field
		for (field in Reflect.fields(fields))
		{
			var chartValue:Dynamic = Reflect.field(chart, field);

			// If the chart doesnt have the value, set it to the default
			if (chartValue == null)
			{
				var fieldValue:Dynamic = Reflect.field(fields, field);
				Reflect.setField(chart, field, fieldValue);
			}
		}

		return chart;
	}
}
