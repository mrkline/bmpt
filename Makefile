
bmpt: *.d
	dmd -debug -unittest -w -wi *.d -ofbmpt -L-lcurl
