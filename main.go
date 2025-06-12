package main

import (
	"encoding/json"
	"log"
	"os"
	"sort"
)

type SarifReport struct {
	Runs []struct {
		Properties []string `json:"properties"`
		Tool       struct {
			Driver struct {
				Rules []struct {
					Id                  string            `json:"id"`
					Help                map[string]string `json:"help"`
					Properties          map[string]string `json:"properties"` // Changed from []string to map[string]string
					PartialFingerprints map[string]string `json:"partialFingerprints"`
				} `json:"rules"`
			} `json:"driver"`
		} `json:"tool"`
		Results []struct {
			RuleId              string            `json:"ruleId"`
			PartialFingerprints map[string]string `json:"partialFingerprints"`
			Locations           []struct {
				PhysicalLocation struct {
					ArtifactLocation struct {
						Uri string `json:"uri"`
					} `json:"artifactLocation"`
				} `json:"physicalLocation"`
			} `json:"locations"`
		} `json:"results"`
	} `json:"runs"`
}

func main() {
	buf1, err := os.ReadFile("report.sarif.json")
	if err != nil {
		log.Fatal(err)
	}

	var sarifReport1 SarifReport
	err = json.Unmarshal(buf1, &sarifReport1)
	if err != nil {
		log.Fatal(err)
	}

	sort.Slice(sarifReport1.Runs[0].Results, func(i, j int) bool {
		return sarifReport1.Runs[0].Results[i].PartialFingerprints["ruleIdLocationHash/v1"] < sarifReport1.Runs[0].Results[j].PartialFingerprints["ruleIdLocationHash/v1"]
	})

	sort.Slice(sarifReport1.Runs[0].Tool.Driver.Rules, func(i, j int) bool {
		return sarifReport1.Runs[0].Tool.Driver.Rules[i].Help["markdown"] < sarifReport1.Runs[0].Tool.Driver.Rules[j].Help["markdown"]
	})

	buffer1, err := json.Marshal(&sarifReport1)
	if err != nil {
		log.Fatal(err)
	}

	err = os.WriteFile("report.new.sarif.json", buffer1, 0644)
	if err != nil {
		log.Fatal(err)
	}

	buf, err := os.ReadFile("sarif_new.json")
	if err != nil {
		log.Fatal(err)
	}

	var sarifReport2 SarifReport
	err = json.Unmarshal(buf, &sarifReport2)
	if err != nil {
		log.Fatal(err)
	}

	sort.Slice(sarifReport2.Runs[0].Results, func(i, j int) bool {
		return sarifReport2.Runs[0].Results[i].PartialFingerprints["ruleIdLocationHash/v1"] < sarifReport2.Runs[0].Results[j].PartialFingerprints["ruleIdLocationHash/v1"]
	})

	sort.Slice(sarifReport2.Runs[0].Tool.Driver.Rules, func(i, j int) bool {
		return sarifReport2.Runs[0].Tool.Driver.Rules[i].Help["markdown"] < sarifReport2.Runs[0].Tool.Driver.Rules[j].Help["markdown"]
	})

	buffer2, err := json.Marshal(&sarifReport2)
	if err != nil {
		log.Fatal(err)
	}

	err = os.WriteFile("sarif_new_sorted.json", buffer2, 0644)
	if err != nil {
		log.Fatal(err)
	}
}
