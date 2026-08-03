## Structured logging and diagnostics reported by a generator.
import HostDiagnostics
import Model

Diagnostics := [].{

	## Severity attached to a generator message.
	Level : [Debug, Info, Warning, Error]

	## Whether a diagnostic is general or associated with a model element.
	Context := [General, ForElement(Model.ElementHandle)]

	## Publish a bounded message without element context.
	log! : Level, Str => {}
	log! = |level, message| HostDiagnostics.log!(level, message)

	## Publish a bounded diagnostic with optional model-element context.
	report! : Level, Str, Context => {}
	report! = |level, message, context| {
		host_element = match context {
			General => None
			ForElement(ElementHandle(handle)) => Some(handle)
		}
		HostDiagnostics.report!(level, message, host_element)
	}
}
