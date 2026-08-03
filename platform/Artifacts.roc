## Files emitted by a generator. Paths are interpreted relative to Spec42's
## output directory and validated by the host.
Artifacts := [].{

	## Stage raw bytes at a relative output path.
	emit! : Str, List(U8) => Try({}, Str)
}
