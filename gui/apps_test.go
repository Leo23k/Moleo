package main

import "testing"

func TestParseWingetTable(t *testing.T) {
	out := "   - \r   \\ \rName                 Id                Version   Available Source\r\n" +
		"------------------------------------------------------------------\r\n" +
		"7-Zip 26.05 (x64)    7zip.7zip         26.05     26.06     winget\r\n" +
		"Cursor (User)        Anysphere.Cursor  3.28.7    3.31.15   winget\r\n" +
		"2 upgrades available.\r\n"
	items := parseWingetTable(out)
	if len(items) != 2 || items[0].ID != "7zip.7zip" || items[1].Available != "3.31.15" || items[1].Name != "Cursor (User)" {
		t.Fatalf("%+v", items)
	}
}

func TestListStartupLive(t *testing.T) {
	items, err := (&App{}).ListStartup()
	if err != nil {
		t.Fatal(err)
	}
	for _, it := range items {
		t.Logf("%-5v %-30s %s", it.Enabled, it.Name, it.Location)
	}
}

func TestListUpdatesLive(t *testing.T) {
	if testing.Short() {
		t.Skip()
	}
	items, err := (&App{}).ListUpdates()
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("%d updates, first: %+v", len(items), items[:min(2, len(items))])
}
