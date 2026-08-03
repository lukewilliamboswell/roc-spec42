app [main!] { spec42: platform "../platform/main.roc" }

import spec42.Artifacts
import spec42.Diagnostics
import spec42.Model

main! = |_args| {
	info = Model.info!()
	roots = Model.roots!()?
	message = "Model ${info.model_digest} has ${roots.len().to_str()} root elements.\n"
	Artifacts.emit!("summary.txt", message.to_utf8())?
	Diagnostics.log!(Info, "wrote summary.txt")
	Ok({})
}
