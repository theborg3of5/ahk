=Unit test for Selector
+ShowDataInputs=1
+RowsPerColumn=5
+MinColumnWidth=500

(	NAME												ABBREV	RESULT	MODIFIER
)	0													0			1			2

	# Label 1
	Option 1											a			A			1
	Option 2											b			B			2
	Option 3											c			C			3
	Two abbrevs (z,z1)							d|d1		D			4
	Option 5 (newlined by RowsPerColumn)	e			E			5

	# Label 3
	Option 6											f			F			6
	*Hidden 7										g			G			7
	*Hidden 8 (two abbrevs)						h|h1		H			8

	# | Newline'd label 5
	Option 9											i			I			9

	# Skipped label 6 (no contents)

	# Shown label 7
	Actual option									j			J			0
