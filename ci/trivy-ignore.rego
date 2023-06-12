package trivy

default ignore = false

ignore_cve_ids := {
}

ignore {
	input.VulnerabilityID == ignore_cve_ids[_]
}
