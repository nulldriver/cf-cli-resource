package trivy

default ignore = false

ignore_cve_ids := {
  # opt/cf-cli-7.5.0/cf7 (gobinary)
  "CVE-2017-11468",
  # opt/cf-cli-8.4.0/cf8 (gobinary)
  "CVE-2021-43565"
}

ignore {
	input.VulnerabilityID == ignore_cve_ids[_]
}
