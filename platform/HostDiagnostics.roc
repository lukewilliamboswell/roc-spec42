## Internal diagnostic effects that mirror the low-level guest ABI.
HostDiagnostics := [].{
	Level : [Debug, Info, Warning, Error]

	log! : Level, Str => {}

	report! : Level, Str, [None, Some(Str)] => {}
}
